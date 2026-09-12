#ifndef TOOL_NODE_HLSL
#define TOOL_NODE_HLSL

// 基础的Billboard函数(球形 billboard)
void BillboardBase_float(float3 positionOS, out float3 newPositionOS)
{
    float3 center = float3(0, 0, 0);

    float3 cameraPosOS = TransformWorldToObject(_WorldSpaceCameraPos);

    // 计算朝向相机的方向(newZ)
    float3 cameraDirOS = normalize(cameraPosOS - center);

    // 竖直向上(tempY)
    float3 upOS = float3(0, 1, 0);

    // 向右的正方向(newX)
    float3 rightOS = normalize(cross(upOS, cameraDirOS));

    // 用叉乘计算出垂直于 cameraDirOS 的 rightOS 和 Up(即 newY)
    float3 correctedUpOS = cross(cameraDirOS, rightOS);

    newPositionOS = 
        center + 
        rightOS       * positionOS.x + 
        correctedUpOS * positionOS.y + 
        cameraDirOS   * positionOS.z;
}

void BillboardBase_half(half3 positionOS, out half3 newPositionOS)
{
    half3 center = half3(0, 0, 0);

    half3 cameraPosOS = TransformWorldToObject(_WorldSpaceCameraPos);

    // 计算朝向相机的方向(newZ)
    half3 cameraDirOS = normalize(cameraPosOS - center);

    // 竖直向上(tempY)
    half3 upOS = half3(0, 1, 0);

    // 向右的正方向(newX)
    half3 rightOS = normalize(cross(upOS, cameraDirOS));

    // 用叉乘计算出垂直于 cameraDirOS 的 rightOS 和 Up(即 newY)
    half3 correctedUpOS = cross(cameraDirOS, rightOS);

    newPositionOS = 
        center + 
        rightOS       * positionOS.x + 
        correctedUpOS * positionOS.y + 
        cameraDirOS   * positionOS.z;
}

// 圆柱形 billboard(只在水平面上旋转)
void Billboard_float(float3 positionOS, out float3 newPositionOS)
{
    float3 center = float3(0, 0, 0);

    float3 cameraPosOS = TransformWorldToObject(_WorldSpaceCameraPos);

    // 计算朝向相机的方向(newZ)
    float3 cameraDirOS = normalize(cameraPosOS - center);

    cameraDirOS.y = 0;
    cameraDirOS = normalize(cameraDirOS);
    
    // 去除竖直分量，使 billboard 只在水平面上旋转
    // 避免除零，但不使用分支
    float lengthSquared = max(dot(cameraDirOS, cameraDirOS), 0.0001);
    cameraDirOS = cameraDirOS / sqrt(lengthSquared);
    
    // 竖直向上(tempY)
    float3 upOS = float3(0, 1, 0);

    // 向右的正方向(newX)
    float3 rightOS = normalize(cross(upOS, cameraDirOS));

    // 用叉乘计算出垂直于 cameraDirOS 的 rightOS 和 Up(即 newY)
    float3 correctedUpOS = cross(cameraDirOS, rightOS);

    newPositionOS = 
        center + 
        rightOS       * positionOS.x + 
        correctedUpOS * positionOS.y + 
        cameraDirOS   * positionOS.z;
}

void Billboard_half(half3 positionOS, out half3 newPositionOS)
{
    half3 center = half3(0, 0, 0);

    half3 cameraPosOS = TransformWorldToObject(_WorldSpaceCameraPos);

    // 计算朝向相机的方向(newZ)
    half3 cameraDirOS = normalize(cameraPosOS - center);

    cameraDirOS.y = 0;
    cameraDirOS = normalize(cameraDirOS);

    // 去除竖直分量，使 billboard 只在水平面上旋转
    half lengthSquared = max(dot(cameraDirOS, cameraDirOS), 0.0001);
    cameraDirOS = cameraDirOS / sqrt(lengthSquared);

    // 竖直向上(tempY)
    half3 upOS = half3(0, 1, 0);

    // 向右的正方向(newX)
    half3 rightOS = normalize(cross(upOS, cameraDirOS));

    // 用叉乘计算出垂直于 cameraDirOS 的 rightOS 和 Up(即 newY)
    half3 correctedUpOS = cross(cameraDirOS, rightOS);

    newPositionOS = 
        center + 
        rightOS       * positionOS.x + 
        correctedUpOS * positionOS.y + 
        cameraDirOS   * positionOS.z;
}

// --------------------------------- Y轴权重计算 ------------------------------------
// 根据草的高度和Y轴权重计算偏移量(此函数要求模型自身的锚点必须在模型底部)
// 方案1: 线性计算
void CalculateYWeightedOffset_float(float3 positionOS, float yWeight, out float3 newYWeightPositionOS)
{
    // 直接使用positionOS.y作为草的高度权重（锚点在底部，y=0为地面）
    float heightWeight = saturate(positionOS.y);
    
    // 以高度为权重计算X轴和Z轴的偏移幅度
    float xOffset = heightWeight * yWeight;
    float zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = float3(xOffset, 0, zOffset);
}

void CalculateYWeightedOffset_half(half3 positionOS, half yWeight, out half3 newYWeightPositionOS)
{
    // 直接使用positionOS.y作为草的高度权重（锚点在底部，y=0为地面）
    half heightWeight = saturate(positionOS.y);
    
    // 以高度为权重计算X轴和Z轴的偏移幅度
    half xOffset = heightWeight * yWeight;
    half zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = half3(xOffset, 0, zOffset);
}

// 方案2: 二次曲线（底部变化平缓，顶部变化剧烈）
void CalculateYWeightedOffset_Quadratic_float(float3 positionOS, float yWeight, out float3 newYWeightPositionOS)
{
    float height = max(0, positionOS.y);
    float heightWeight = height * height; // 二次曲线
    
    float xOffset = heightWeight * yWeight;
    float zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = float3(xOffset, 0, zOffset);
}

void CalculateYWeightedOffset_Quadratic_half(half3 positionOS, half yWeight, out half3 newYWeightPositionOS)
{
    half height = max(0, positionOS.y);
    half heightWeight = height * height; // 二次曲线
    
    half xOffset = heightWeight * yWeight;
    half zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = half3(xOffset, 0, zOffset);
}

// 方案3: 正弦曲线（底部和顶部变化平缓，中间变化剧烈）
void CalculateYWeightedOffset_Sine_float(float3 positionOS, float yWeight, out float3 newYWeightPositionOS)
{
    float height = max(0, positionOS.y);
    float heightWeight = sin(height * 3.14159 * 0.5); // 0到PI/2区间
    
    float xOffset = heightWeight * yWeight;
    float zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = float3(xOffset, 0, zOffset);
}

void CalculateYWeightedOffset_Sine_half(half3 positionOS, half yWeight, out half3 newYWeightPositionOS)
{
    half height = max(0, positionOS.y);
    half heightWeight = sin(height * 3.14159 * 0.5); // 0到PI/2区间
    
    half xOffset = heightWeight * yWeight;
    half zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = half3(xOffset, 0, zOffset);
}


// 方案4: Smoothstep（底部和顶部平缓，中间线性）
void CalculateYWeightedOffset_Smoothstep_float(float3 positionOS, float maxHeight, float yWeight, out float3 newYWeightPositionOS)
{
    float height = max(0, positionOS.y);
    float heightWeight = smoothstep(0, maxHeight, height);
    
    float xOffset = heightWeight * yWeight;
    float zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = float3(xOffset, 0, zOffset);
}

void CalculateYWeightedOffset_Smoothstep_half(half3 positionOS, half maxHeight, half yWeight, out half3 newYWeightPositionOS)
{
    half height = max(0, positionOS.y);
    half heightWeight = smoothstep(0, maxHeight, height);
    
    half xOffset = heightWeight * yWeight;
    half zOffset = heightWeight * yWeight;
    
    newYWeightPositionOS = half3(xOffset, 0, zOffset);
}

// --------------------------------- 计算地形UV ------------------------------------
void CalculateTerrainUV_float(float3 positionWS, float3 terrainPosition, float3 terrainSize, out float2 TerrainUV)
{
    float2 terrainUV = (positionWS.xz - terrainPosition.xz) / terrainSize.xz;
    float2 terrainUVClamped = saturate(terrainUV);
    TerrainUV = terrainUVClamped;
}

void CalculateTerrainUV_half(half3 positionWS, half3 terrainPosition, half3 terrainSize, out half2 TerrainUV)
{
    half2 terrainUV = (positionWS.xz - terrainPosition.xz) / terrainSize.xz;
    half2 terrainUVClamped = saturate(terrainUV);
    TerrainUV = terrainUVClamped;
}

// --------------------------------- 计算地形最终颜色 ------------------------------------
void CalculateTerrainColor_float(float4 controlMap_1, float4 controlMap_2, 
    float3 layer_0, float3 layer_1, float3 layer_2, float3 layer_3,
    float3 layer_4, float3 layer_5, float3 layer_6, float3 layer_7, 
    out float3 finalColor)
{
    float3 color_0 = layer_0 * controlMap_1.x;
    float3 color_1 = layer_1 * controlMap_1.y;
    float3 color_2 = layer_2 * controlMap_1.z;
    float3 color_3 = layer_3 * controlMap_1.w;

    float3 color_4 = layer_4 * controlMap_2.x;
    float3 color_5 = layer_5 * controlMap_2.y;
    float3 color_6 = layer_6 * controlMap_2.z;
    float3 color_7 = layer_7 * controlMap_2.w;

    finalColor = color_0 + color_1 + color_2 + color_3 + color_4 + color_5 + color_6 + color_7;
}

void CalculateTerrainColor_half(half4 controlMap_1, half4 controlMap_2, 
    half3 layer_0, half3 layer_1, half3 layer_2, half3 layer_3,
    half3 layer_4, half3 layer_5, half3 layer_6, half3 layer_7, 
    out half3 finalColor)
{
    half3 color_0 = layer_0 * controlMap_1.x;
    half3 color_1 = layer_1 * controlMap_1.y;
    half3 color_2 = layer_2 * controlMap_1.z;
    half3 color_3 = layer_3 * controlMap_1.w;

    half3 color_4 = layer_4 * controlMap_2.x;
    half3 color_5 = layer_5 * controlMap_2.y;
    half3 color_6 = layer_6 * controlMap_2.z;
    half3 color_7 = layer_7 * controlMap_2.w;

    finalColor = color_0 + color_1 + color_2 + color_3 + color_4 + color_5 + color_6 + color_7;
}

// --------------------------------- 根阴影物体空间 ------------------------------------
// 针对不是按照高度方向展开的UV
// 参数:
// positionOS: 模型空间下的顶点位置
// rootHeight: 根阴影的高度范围
// fadeHeight: 根阴影的渐变高度范围
// strength: 根阴影的强度
void RootShadowOS_float(float3 positionOS, float3 normalOS, float rootHeight, float fadeHeight, float strength, out float mask)
{
    float rootMask = 1.0 - smoothstep(rootHeight, rootHeight + fadeHeight, positionOS.y);
    float groundFacing = saturate(-normalOS.y);
    
    rootMask *= lerp(0.5, 1.0, groundFacing);
    
    mask = saturate(rootMask * strength);
}

void RootShadowOS_half(half3 positionOS, half3 normalOS, half rootHeight, half fadeHeight, half strength, out half mask)
{
    half rootMask = 1.0 - smoothstep(rootHeight, rootHeight + fadeHeight, positionOS.y);
    half groundFacing = saturate(-normalOS.y);

    rootMask *= lerp(0.5, 1.0, groundFacing);

    mask = saturate(rootMask * strength);
}
#endif