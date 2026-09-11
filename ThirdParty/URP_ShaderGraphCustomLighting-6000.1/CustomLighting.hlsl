#ifndef CUSTOM_LIGHTING_INCLUDED
#define CUSTOM_LIGHTING_INCLUDED

// @Cyanilux | https://github.com/Cyanilux/URP_ShaderGraphCustomLighting
// 此版本适用于 Unity 6.1+
// 对于旧版本，请参阅 github 仓库中的分支！

//------------------------------------------------------------------------------------------------------
// 关键字编译指示
//------------------------------------------------------------------------------------------------------

#ifndef SHADERGRAPH_PREVIEW
	#if SHADERPASS != SHADERPASS_FORWARD && SHADERPASS != SHADERPASS_GBUFFER
		// 如果此文件被包含在 Lit Graph 中，使用 #if 以避免 "duplicate keyword" 警告

    	#pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
    	#pragma multi_compile_fragment _ _SHADOWS_SOFT _SHADOWS_SOFT_LOW _SHADOWS_SOFT_MEDIUM _SHADOWS_SOFT_HIGH
		#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
		#pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
		#pragma multi_compile _ _CLUSTER_LIGHT_LOOP

		// 一些关键字（例如，光照分层、Cookie）保留在子图中，以帮助避免不必要的着色器变体
		// 但这意味着如果这些子图被嵌套在另一个子图中，您需要从黑板中复制这些关键字

	#endif
#endif

//------------------------------------------------------------------------------------------------------
// 主光源
//------------------------------------------------------------------------------------------------------

/*
- 获取主方向光的方向、颜色和距离衰减
- （距离衰减为 1 或 0，取决于对象是否在光源的剔除遮罩中）
- 阴影相关功能，请参阅 MainLightShadows_float
- 要使 DistanceAtten 输出在 Forward+ 路径中工作，需要 "_CLUSTER_LIGHT_LOOP" 关键字
*/
void MainLight_float(out float3 Direction, out float3 Color, out float DistanceAtten){
	#ifdef SHADERGRAPH_PREVIEW
		Direction = normalize(float3(1,1,-0.4));
		Color = float4(1,1,1,1);
		DistanceAtten = 1;
	#else
		Light mainLight = GetMainLight();
		Direction = mainLight.direction;
		Color = mainLight.color;
		DistanceAtten = mainLight.distanceAttenuation;
	#endif
}

/*
- 测试主光源图层遮罩是否出现在渲染器的渲染层中
- （用于支持光照分层，将主光源的着色结果传入此函数）
- 要在 Unlit Graph 中工作，需要以下关键字：
	- 布尔关键字，全局多编译 "_LIGHT_LAYERS"
*/
void MainLightLayer_float(float3 Shading, out float3 Out){
	#ifdef SHADERGRAPH_PREVIEW
		Out = Shading;
	#else
		Out = 0;
		uint meshRenderingLayers = GetMeshRenderingLayer();
		#ifdef _LIGHT_LAYERS
			if (IsMatchingLightLayer(GetMainLight().layerMask, meshRenderingLayers))
		#endif
		{
			Out = Shading;
		}
	#endif
}

/*
- 获取分配给主光源的光照 Cookie
- （用法：您需要将结果与光照颜色相乘）
- 要在 Unlit Graph 中工作，需要以下关键字：
	- 布尔关键字，全局多编译 "_LIGHT_COOKIES"
*/
void MainLightCookie_float(float3 WorldPos, out float3 Cookie){
	Cookie = 1;
	#if defined(_LIGHT_COOKIES)
        Cookie = SampleMainLightCookie(WorldPos);
    #endif
}

//------------------------------------------------------------------------------------------------------
// 主光源阴影
//------------------------------------------------------------------------------------------------------

/*
- 根据传入的世界位置，对主光源的阴影贴图进行采样。（位置节点）
*/
void MainLightShadows_float(float3 WorldPos, half4 Shadowmask, out float ShadowAtten){
	#ifdef SHADERGRAPH_PREVIEW
		ShadowAtten = 1;
	#else
		#if defined(_MAIN_LIGHT_SHADOWS_SCREEN) && !defined(_SURFACE_TYPE_TRANSPARENT)
		float4 shadowCoord = ComputeScreenPos(TransformWorldToHClip(WorldPos));
		#else
		float4 shadowCoord = TransformWorldToShadowCoord(WorldPos);
		#endif
		ShadowAtten = MainLightShadow(shadowCoord, WorldPos, Shadowmask, _MainLightOcclusionProbes);
	#endif
}

void MainLightShadows_float(float3 WorldPos, out float ShadowAtten){
	MainLightShadows_float(WorldPos, half4(1,1,1,1), ShadowAtten);
}

//------------------------------------------------------------------------------------------------------
// 烘焙全局光照 (GI)
//------------------------------------------------------------------------------------------------------

/*
- 用于支持光照窗口中的 "Shadowmask" 烘焙 GI 模式。
- 理想情况下，在图中采样一次，然后输入到主光源阴影和/或附加光源子图/函数中。
- 要在 Unlit Graph 中工作，可能需要以下关键字：
	- 布尔关键字，全局多编译 "SHADOWS_SHADOWMASK"
	- 布尔关键字，全局多编译 "LIGHTMAP_SHADOW_MIXING"
	- （还需要 LIGHTMAP_ON，但我认为 Shader Graph 已经定义了它）
*/
void Shadowmask_half(float2 lightmapUV, out half4 Shadowmask){
	#ifdef SHADERGRAPH_PREVIEW
		Shadowmask = half4(1,1,1,1);
	#else
		OUTPUT_LIGHTMAP_UV(lightmapUV, unity_LightmapST, lightmapUV);
		Shadowmask = SAMPLE_SHADOWMASK(lightmapUV);
	#endif
}

/*
- 用于支持光照窗口中的 "Subtractive" 烘焙 GI 模式
- 输入应为来自主光源阴影子图的 ShadowAtten、法线向量（世界空间）和 Baked GI 节点
- 要在 Unlit Graph 中工作，可能需要以下关键字：
	- 布尔关键字，全局多编译 "LIGHTMAP_SHADOW_MIXING"
	- （还需要 LIGHTMAP_ON，但我认为 Shader Graph 已经定义了它）
*/
void SubtractiveGI_float(float ShadowAtten, float3 NormalWS, float3 BakedGI, out half3 result){
	#ifdef SHADERGRAPH_PREVIEW
		result = half3(1,1,1);
	#else
		Light mainLight = GetMainLight();
		mainLight.shadowAttenuation = ShadowAtten;
		MixRealtimeAndBakedGI(mainLight, NormalWS, BakedGI);
		result = BakedGI;
	#endif
}

//------------------------------------------------------------------------------------------------------
// 默认附加光源
//------------------------------------------------------------------------------------------------------

/*
- 处理附加光源（例如，附加方向光、点光源、聚光灯）
- 对于自定义光照，您可能希望复制此函数并替换其中的 LightingLambert / LightingSpecular 函数。请参阅下面的 Toon 示例！
- 需要关键字 "_ADDITIONAL_LIGHTS"、"_ADDITIONAL_LIGHT_SHADOWS" 和 "_CLUSTER_LIGHT_LOOP"
*/
void AdditionalLights_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView, half4 Shadowmask,
							out float3 Diffuse, out float3 Specular) {
	float3 diffuseColor = 0;
	float3 specularColor = 0;
#ifndef SHADERGRAPH_PREVIEW
	Smoothness = exp2(10 * Smoothness + 1);
	uint pixelLightCount = GetAdditionalLightsCount();
	uint meshRenderingLayers = GetMeshRenderingLayer();

	#if USE_CLUSTER_LIGHT_LOOP
	for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++) {
		CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
		Light light = GetAdditionalLight(lightIndex, WorldPosition, Shadowmask);
	#ifdef _LIGHT_LAYERS
		if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
	#endif
		{
			// Blinn-Phong
			float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
			diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
			specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, float4(SpecColor, 0), Smoothness);
		}
	}
	#endif

	// 对于 Forward+，LIGHT_LOOP_BEGIN 宏会使用 inputData.normalizedScreenSpaceUV、inputData.positionWS，因此创建这些数据：
	InputData inputData = (InputData)0;
	float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPosition));
	inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
	inputData.positionWS = WorldPosition;

	LIGHT_LOOP_BEGIN(pixelLightCount)
		Light light = GetAdditionalLight(lightIndex, WorldPosition, Shadowmask);
	#ifdef _LIGHT_LAYERS
		if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
	#endif
		{
			// Blinn-Phong
			float3 attenuatedLightColor = light.color * (light.distanceAttenuation * light.shadowAttenuation);
			diffuseColor += LightingLambert(attenuatedLightColor, light.direction, WorldNormal);
			specularColor += LightingSpecular(attenuatedLightColor, light.direction, WorldNormal, WorldView, float4(SpecColor, 0), Smoothness);
		}
	LIGHT_LOOP_END
#endif

	Diffuse = diffuseColor;
	Specular = specularColor;
}

//------------------------------------------------------------------------------------------------------
// 附加光源 Toon（卡通/三渲二）示例
//------------------------------------------------------------------------------------------------------

/*
- 计算光照衰减值以产生多个色带，实现卡通效果。请参阅下面的 AdditionalLightsToon 函数
*/
#ifndef SHADERGRAPH_PREVIEW
float ToonAttenuation(int lightIndex, float3 positionWS, float pointBands, float spotBands){
	#if !USE_CLUSTER_LIGHT_LOOP
		lightIndex = GetPerObjectLightIndex(lightIndex);
	#endif
	#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
		float4 lightPositionWS = _AdditionalLightsBuffer[lightIndex].position;
		half4 spotDirection = _AdditionalLightsBuffer[lightIndex].spotDirection;
		half4 distanceAndSpotAttenuation = _AdditionalLightsBuffer[lightIndex].attenuation;
	#else
		float4 lightPositionWS = _AdditionalLightsPosition[lightIndex];
		half4 spotDirection = _AdditionalLightsSpotDir[lightIndex];
		half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[lightIndex];
	#endif

	// 点光源
	float3 lightVector = lightPositionWS.xyz - positionWS * lightPositionWS.w;
	float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);
	float range = rsqrt(distanceAndSpotAttenuation.x);
	float dist = sqrt(distanceSqr) / range;

	// 聚光灯
	half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
	half SdotL = dot(spotDirection.xyz, lightDirection);
	half spotAtten = saturate(SdotL * distanceAndSpotAttenuation.z + distanceAndSpotAttenuation.w);
	spotAtten *= spotAtten;
	float maskSpotToRange = step(dist, 1);

	// 衰减
	bool isSpot = (distanceAndSpotAttenuation.z > 0);
	return isSpot ? 
		//step(0.01, spotAtten) :		// 如果您只想为聚光灯使用 "1" 个色带，这种方式更省性能
		(floor(spotAtten * spotBands) / spotBands) * maskSpotToRange :
		saturate(1.0 - floor(dist * pointBands) / pointBands);
}
#endif

/*
- 处理附加光源（例如，点光源、聚光灯），并带有带状卡通效果
- 需要关键字 "_ADDITIONAL_LIGHTS"、"_ADDITIONAL_LIGHT_SHADOWS" 和 "_CLUSTER_LIGHT_LOOP"
*/
void AdditionalLightsToon_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView, half4 Shadowmask,
						float PointLightBands, float SpotLightBands,
						out float3 Diffuse, out float3 Specular) {
	float3 diffuseColor = 0;
	float3 specularColor = 0;

#ifndef SHADERGRAPH_PREVIEW
	Smoothness = exp2(10 * Smoothness + 1);
	uint pixelLightCount = GetAdditionalLightsCount();
	uint meshRenderingLayers = GetMeshRenderingLayer();

	#if USE_CLUSTER_LIGHT_LOOP
	for (uint lightIndex = 0; lightIndex < min(URP_FP_DIRECTIONAL_LIGHTS_COUNT, MAX_VISIBLE_LIGHTS); lightIndex++) {
		CLUSTER_LIGHT_LOOP_SUBTRACTIVE_LIGHT_CHECK
		Light light = GetAdditionalLight(lightIndex, WorldPosition, Shadowmask);
	#ifdef _LIGHT_LAYERS
		if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
	#endif
		{
			if (PointLightBands <= 1 && SpotLightBands <= 1){
				// 纯色光照
				diffuseColor += light.color * step(0.0001, light.distanceAttenuation * light.shadowAttenuation);
			}else{
				// 多色带
				diffuseColor += light.color * light.shadowAttenuation * ToonAttenuation(lightIndex, WorldPosition, PointLightBands, SpotLightBands);
			}
		}
	}
	#endif

	// 对于 Forward+，LIGHT_LOOP_BEGIN 宏会使用 inputData.normalizedScreenSpaceUV、inputData.positionWS，因此创建这些数据：
	InputData inputData = (InputData)0;
	float4 screenPos = ComputeScreenPos(TransformWorldToHClip(WorldPosition));
	inputData.normalizedScreenSpaceUV = screenPos.xy / screenPos.w;
	inputData.positionWS = WorldPosition;

	LIGHT_LOOP_BEGIN(pixelLightCount)
		Light light = GetAdditionalLight(lightIndex, WorldPosition, Shadowmask);
	#ifdef _LIGHT_LAYERS
		if (IsMatchingLightLayer(light.layerMask, meshRenderingLayers))
	#endif
		{
			if (PointLightBands <= 1 && SpotLightBands <= 1){
				// 纯色光照
				diffuseColor += light.color * step(0.0001, light.distanceAttenuation * light.shadowAttenuation);
			}else{
				// 多色带
				diffuseColor += light.color * light.shadowAttenuation * ToonAttenuation(lightIndex, WorldPosition, PointLightBands, SpotLightBands);
			}
		}
	LIGHT_LOOP_END
#endif

/*
#ifndef SHADERGRAPH_PREVIEW
	Smoothness = exp2(10 * Smoothness + 1);
	WorldNormal = normalize(WorldNormal);
	WorldView = SafeNormalize(WorldView);
	int pixelLightCount = GetAdditionalLightsCount();
	for (int i = 0; i < pixelLightCount; ++i) {
		Light light = GetAdditionalLight(i, WorldPosition, Shadowmask);

		// 漫反射
		if (PointLightBands <= 1 && SpotLightBands <= 1){
			// 纯色光照
			diffuseColor += light.color * step(0.0001, light.distanceAttenuation * light.shadowAttenuation);
		}else{
			// 多色带 :
			diffuseColor += light.color * light.shadowAttenuation * ToonAttenuation(i, WorldPosition, PointLightBands, SpotLightBands);
		}
	}
#endif
*/

	Diffuse = diffuseColor;
	Specular = specularColor;
	// 在此卡通着色器中不喜欢高光光照的外观，因此将其保持为 0
}

//------------------------------------------------------------------------------------------------------
// 已弃用 / 向后兼容
//------------------------------------------------------------------------------------------------------

// 为了向后兼容（在 Shadowmask 引入之前）
void AdditionalLights_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView, 
							out float3 Diffuse, out float3 Specular) {
AdditionalLights_float(SpecColor, Smoothness, WorldPosition, WorldNormal, WorldView, half4(1,1,1,1), Diffuse, Specular);
}

// （在 Shadowmask 引入之前）
void AdditionalLightsToon_float(float3 SpecColor, float Smoothness, float3 WorldPosition, float3 WorldNormal, float3 WorldView,
						float PointLightBands, float SpotLightBands,
						out float3 Diffuse, out float3 Specular) {
AdditionalLightsToon_float(SpecColor, Smoothness, WorldPosition, WorldNormal, WorldView, half4(1,1,1,1),
	PointLightBands, SpotLightBands,Diffuse, Specular);
}

/*
- 根据光照选项卡中的 Fog 设置，将雾效添加到输入颜色中
- 通常在图中的 Base Color 输出之前连接
- 对于 v12+ 不是必需的，可以使用 Lerp 代替。请参阅 "Mix Fog" 子图
*/
void MixFog_float(float3 Colour, float Fog, out float3 Out){
	#ifdef SHADERGRAPH_PREVIEW
		Out = Colour;
	#else
		Out = MixFog(Colour, Fog);
	#endif
}

/*
- 使用 "SampleSH"，即环境光照/光照探头使用的球谐函数
- 但应使用内置的 "Baked GI" 节点而不是此函数，它能处理更多情况（包括新的自适应探头体积，需配合相应的关键字：https://github.com/Cyanilux/URP_ShaderGraphCustomLighting/issues/27）
*/
void AmbientSampleSH_float(float3 WorldNormal, out float3 Ambient){
	#ifdef SHADERGRAPH_PREVIEW
		Ambient = float3(0.1, 0.1, 0.1); // 预览的默认环境色
	#else
		Ambient = SampleSH(WorldNormal);
	#endif
}

#endif // CUSTOM_LIGHTING_INCLUDED