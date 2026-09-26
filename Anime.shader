Shader "Custom/Anime"
{
    Properties
    {
        // ===== 基础纹理 =====
        _BaseMap("基础纹理", 2D) = "white" {}
        _GradientMap("卡通渐变纹理", 2D) = "white" {}
        _GradientMap2("备用渐变纹理", 2D) = "white" {}
        _SpecularMap("高光遮罩纹理", 2D) = "white" {}      // 新增：控制高光区域
        
        // ===== 颜色 =====
        _BaseColor("基础颜色", Color) = (0.3, 0.8, 0.3, 1)
        _LightColor("高亮色", Color) = (0.55, 0.85, 0.35, 1)
        _ShadowColor("阴影色", Color) = (0.18, 0.45, 0.20, 1)
        _AmbientColor("环境光颜色", Color) = (0.2, 0.25, 0.35, 1)  // 新增
        
        // ===== 光照阈值 =====
        _ShadowThreshold("阴影阈值", Range(0, 1)) = 0.5
        _ShadowSmoothness("阴影平滑度", Range(0.001, 2)) = 0.02
        _ShadowSteps("阴影级数", Range(1, 8)) = 3              // 新增：多级阴影
        
        // ===== 高光 =====
        _Gloss("光泽度", Range(0.1, 20)) = 4.0
        _SpecularStrength("镜面反射强度", Range(0, 5)) = 1.0
        _SpecularThreshold("镜面反射阈值", Range(0.01, 1)) = 0.8
        _SpecularSmoothness("镜面反射平滑度", Range(0.01, 1)) = 0.05
        _SpecularType("高光类型", Range(0, 3)) = 0            // 新增：0圆形 1星形 2十字 3自定义
        
        // ===== 边缘光 =====
        _RimColor("边缘光颜色", Color) = (0.8, 0.6, 1.0, 1)  // 新增
        _RimStrength("边缘光强度", Range(0, 3)) = 1.0        // 新增
        _RimThreshold("边缘光阈值", Range(0, 1)) = 0.3       // 新增
        _RimSmoothness("边缘光平滑度", Range(0.01, 1)) = 0.1 // 新增
        
        // ===== 描边 =====
        _OutlineColor("描边颜色", Color) = (0, 0, 0, 1)      // 新增
        _OutlineWidth("描边宽度", Range(0, 0.1)) = 0.02      // 新增
        _OutlineThreshold("描边深度阈值", Range(0, 1)) = 0.1 // 新增
        
        // ===== 头发高光 =====
        _HairSpecularColor("头发高光颜色", Color) = (1, 0.8, 0.6, 1) // 新增
        _HairSpecularStrength("头发高光强度", Range(0, 3)) = 1.0     // 新增
        
        // ===== 环境 =====
        _AmbientStrength("环境光强度", Range(0, 2)) = 0.3
        
        // ===== Alpha裁剪 =====
        _Cutoff("Alpha裁剪阈值", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Cull Off
        Tags { 
            "RenderType" = "TransparentCutout"
            "Queue" = "AlphaTest"
            "RenderPipeline" = "UniversalPipeline" 
            "LightMode" = "UniversalForward"
        }

        // ============================================================
        // 主渲染Pass
        // ============================================================
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_GradientMap);
            TEXTURE2D(_GradientMap2);
            TEXTURE2D(_SpecularMap);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_GradientMap);
            SAMPLER(sampler_GradientMap2);
            SAMPLER(sampler_SpecularMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _LightColor;
                float4 _ShadowColor;
                float4 _AmbientColor;
                float4 _RimColor;
                float4 _OutlineColor;
                float4 _HairSpecularColor;
                
                float4 _BaseMap_ST;
                float4 _GradientMap_ST;
                float4 _SpecularMap_ST;
                
                float _ShadowThreshold;
                float _ShadowSmoothness;
                float _ShadowSteps;
                
                float _Gloss;
                float _SpecularStrength;
                float _SpecularThreshold;
                float _SpecularSmoothness;
                float _SpecularType;
                
                float _RimStrength;
                float _RimThreshold;
                float _RimSmoothness;
                
                float _OutlineWidth;
                float _OutlineThreshold;
                
                float _HairSpecularStrength;
                float _AmbientStrength;
                float _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;  // 新增：切线
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float3 tangentWS   : TEXCOORD2;  // 新增
                float2 uv          : TEXCOORD3;
                float3 viewDir     : TEXCOORD4;  // 新增
            };

            // ============================================
            // 自定义光照数据结构
            // ============================================
            struct AnimeLight
            {
                float3 direction;
                float3 color;
                float ndotl;
                float ndoth;
                float halfLambert;
                float shadowAttenuation;
            };

            // ============================================
            // 光照计算函数
            // ============================================
            AnimeLight PrepareAnimeLight(Varyings IN, Light mainLight)
            {
                AnimeLight al;
                
                al.direction = mainLight.direction;
                al.color = mainLight.color;
                al.ndotl = saturate(dot(IN.normalWS, al.direction));
                al.halfLambert = al.ndotl * 0.5 + 0.5;
                al.shadowAttenuation = mainLight.shadowAttenuation;
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float3 halfDir = normalize(al.direction + viewDir);
                al.ndoth = max(0, dot(IN.normalWS, halfDir));
                
                return al;
            }

            // ============================================
            // 多级卡通漫反射
            // ============================================
            float3 CalculateToonDiffuse(AnimeLight al, float4 gradientMap)
            {
                // 多级阴影
                float steps = _ShadowSteps;
                float toonLight = floor(al.ndotl * steps) / steps;
                
                // 应用阴影衰减
                toonLight *= al.shadowAttenuation;
                
                // 平滑过渡
                toonLight = smoothstep(
                    _ShadowThreshold - _ShadowSmoothness,
                    _ShadowThreshold + _ShadowSmoothness,
                    toonLight
                );
                
                float4 toonColor = lerp(_ShadowColor, _LightColor, toonLight) * gradientMap;
                return toonColor.rgb;
            }

            // ============================================
            // 多类型卡通高光
            // ============================================
            float3 CalculateToonSpecular(Varyings IN, AnimeLight al)
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float3 halfDir = normalize(al.direction + viewDir);
                
                float specDot = al.ndoth;
                
                // 不同类型高光
                if (_SpecularType == 1) // 星形
                {
                    float3 offset1 = float3(0.15, 0, 0);
                    float3 offset2 = float3(-0.15, 0, 0);
                    float3 offset3 = float3(0, 0.15, 0);
                    float3 offset4 = float3(0, -0.15, 0);
                    
                    float h1 = max(0, dot(IN.normalWS, normalize(halfDir + offset1)));
                    float h2 = max(0, dot(IN.normalWS, normalize(halfDir + offset2)));
                    float h3 = max(0, dot(IN.normalWS, normalize(halfDir + offset3)));
                    float h4 = max(0, dot(IN.normalWS, normalize(halfDir + offset4)));
                    
                    specDot = max(max(h1, h2), max(h3, h4));
                }
                else if (_SpecularType == 2) // 十字（适合眼睛高光）
                {
                    float h1 = max(0, dot(IN.normalWS, normalize(halfDir + float3(0.1, 0, 0))));
                    float h2 = max(0, dot(IN.normalWS, normalize(halfDir + float3(-0.1, 0, 0))));
                    float h3 = max(0, dot(IN.normalWS, normalize(halfDir + float3(0, 0.1, 0))));
                    float h4 = max(0, dot(IN.normalWS, normalize(halfDir + float3(0, -0.1, 0))));
                    
                    specDot = max(max(h1, h2), max(h3, h4));
                }
                
                // 采样高光遮罩
                float4 specMask = SAMPLE_TEXTURE2D(_SpecularMap, sampler_SpecularMap, IN.uv);
                
                float specToon = smoothstep(
                    _SpecularThreshold - _SpecularSmoothness,
                    _SpecularThreshold + _SpecularSmoothness,
                    pow(specDot, _Gloss)
                );
                
                return al.color * _SpecularStrength * specToon * specMask.r;
            }

            // ============================================
            // 边缘光计算
            // ============================================
            float3 CalculateRimLight(Varyings IN)
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float rim = 1.0 - saturate(dot(IN.normalWS, viewDir));
                
                rim = smoothstep(
                    _RimThreshold - _RimSmoothness,
                    _RimThreshold + _RimSmoothness,
                    rim
                );
                
                return _RimColor.rgb * _RimStrength * rim;
            }

            // ============================================
            // 头发高光（各向异性）
            // ============================================
            float3 CalculateHairSpecular(Varyings IN, AnimeLight al)
            {
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float3 halfDir = normalize(al.direction + viewDir);
                
                // 使用切线计算各向异性高光
                float3 tangent = normalize(IN.tangentWS);
                float TdotH = dot(tangent, halfDir);
                float spec = pow(1 - TdotH * TdotH, _Gloss * 0.5);
                
                // 第二条高光（头发通常有两条高光）
                float spec2 = pow(1 - TdotH * TdotH - 0.2, _Gloss * 0.3);
                spec = max(spec, spec2 * 0.5);
                
                return _HairSpecularColor.rgb * _HairSpecularStrength * spec;
            }

            // ============================================
            // 环境光计算
            // ============================================
            float3 CalculateAmbient(Varyings IN)
            {
                // 使用自定义环境光颜色
                float3 ambient = _AmbientColor.rgb * _AmbientStrength;
                
                // 顶部和底部颜色微调（模拟天光）
                float3 up = float3(0, 1, 0);
                float sky = saturate(dot(IN.normalWS, up) * 0.5 + 0.5);
                float3 skyColor = lerp(float3(0.1, 0.1, 0.15), float3(0.2, 0.25, 0.35), sky);
                
                return ambient * skyColor;
            }

            // ============================================
            // 顶点着色器
            // ============================================
            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                
                // 顶点位置
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.positionWS = positionWS;
                OUT.positionHCS = TransformWorldToHClip(positionWS);
                
                // 法线和切线
                OUT.normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.tangentWS = normalize(TransformObjectToWorldDir(IN.tangentOS.xyz));
                
                // UV
                OUT.uv = IN.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                
                // 视角方向
                OUT.viewDir = normalize(_WorldSpaceCameraPos.xyz - positionWS);
                
                return OUT;
            }

            // ============================================
            // 片元着色器
            // ============================================
            float4 frag(Varyings IN) : SV_Target
            {
                // 1. 获取主光源（带阴影）
                Light mainLight = GetMainLight(TransformWorldToShadowCoord(IN.positionWS));
                
                // 2. 准备光照数据
                AnimeLight al = PrepareAnimeLight(IN, mainLight);
                
                // 3. 采样纹理
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                float4 gradientMap = SAMPLE_TEXTURE2D(_GradientMap, sampler_GradientMap, float2(al.halfLambert, 0.5));
                float4 gradientMap2 = SAMPLE_TEXTURE2D(_GradientMap2, sampler_GradientMap2, float2(al.halfLambert, 0.5));
                
                // Alpha裁剪
                clip(baseMap.a - _Cutoff);
                
                // 4. 计算各光照分量
                float3 albedo = baseMap.rgb * gradientMap2.rgb * _BaseColor.rgb;
                float3 diffuse = CalculateToonDiffuse(al, gradientMap);
                float3 specular = CalculateToonSpecular(IN, al);
                float3 rim = CalculateRimLight(IN);
                float3 hairSpec = CalculateHairSpecular(IN, al);
                float3 ambient = CalculateAmbient(IN);
                
                // 5. 合成最终颜色（动漫风格）
                float3 baseColor = lerp(_ShadowColor, _LightColor, diffuse) * albedo;
                float3 finalColor = ambient + baseColor + specular + rim + hairSpec;
                
                // 6. 色彩增强（动漫风格饱和度提升）
                finalColor = saturate(finalColor);
                
                return float4(finalColor, baseMap.a);
            }
            ENDHLSL
        }

        // ============================================================
        // 描边Pass
        // ============================================================
        Pass
        {
            Name "Outline"
            Tags { 
                "LightMode" = "Outline"
                "RenderType" = "TransparentCutout"
            }
            
            Cull Front
            ZWrite On
            
            HLSLPROGRAM
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _OutlineColor;
                float _OutlineWidth;
                float _OutlineThreshold;
                float _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            Varyings OutlineVert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = IN.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;
                
                // 顶点沿法线方向偏移（实现描边）
                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));
                
                // 根据视角距离调整描边宽度（保持屏幕空间宽度一致）
                float4 positionHCS = TransformWorldToHClip(positionWS);
                float outlineWidth = _OutlineWidth * positionHCS.w;
                
                // 法线偏移
                float3 offsetPos = positionWS + normalWS * outlineWidth;
                OUT.positionHCS = TransformWorldToHClip(offsetPos);
                
                return OUT;
            }

            half4 OutlineFrag(Varyings IN) : SV_TARGET
            {
                // Alpha裁剪（描边也支持透明度）
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                clip(baseMap.a - _Cutoff);
                
                return _OutlineColor;
            }
            ENDHLSL
        }

        // ============================================================
        // 阴影投射Pass
        // ============================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { 
                "LightMode" = "ShadowCaster"
                "RenderType" = "TransparentCutout"
            }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex ShadowVert
            #pragma fragment ShadowFrag
            #pragma target 2.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);
            
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float _Cutoff;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            float3 _LightDirection;

            Varyings ShadowVert(Attributes IN)
            {
                Varyings OUT;
                OUT.uv = IN.uv * _BaseMap_ST.xy + _BaseMap_ST.zw;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = normalize(TransformObjectToWorldNormal(IN.normalOS));

                float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, _LightDirection));

                #if UNITY_REVERSED_Z
                    positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                OUT.positionCS = positionCS;
                return OUT;
            }

            half4 ShadowFrag(Varyings IN) : SV_TARGET
            {
                float4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                clip(baseMap.a - _Cutoff);
                return 0;
            }
            ENDHLSL
        }
    }
    
    // ============================================================
    // Fallback
    // ============================================================
    Fallback "Universal Render Pipeline/Lit"
}