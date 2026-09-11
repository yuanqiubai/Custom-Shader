Shader "Custom/AnimeGrass"
{
    Properties
    {
        _BaseColor("基础颜色", Color) = (1, 1, 1, 1)

        _BaseMap("基础纹理", 2D) = "white" {}
        _GradientMapA("渐变纹理A", 2D) = "white" {}
        _GradientMapB("渐变纹理B", 2D) = "white" {}

        _ABMapLerp("渐变纹理过度值", Range(0, 1)) = 0.5
        _LightColor("高亮色", Color) = (0.55, 0.85, 0.35, 1)
        _ShadowColor("阴影色", Color) = (0.18, 0.45, 0.20, 1)

        _ShadowThreshold("阴影阈值", Range(0, 1)) = 0.5
        _ShadowSmoothness("阴影平滑度", Range(0.001, 2)) = 0.02

        _Cutoff("Alpha裁剪阈值", Range(0, 1)) = 0.5
    }

    SubShader
    {
        Tags { 
            "Queue" = "AplhaTest"
            "LightMode" = "UniversalForward"
            "RenderType" = "TransparentCutout"
            "RenderPipeline" = "UniversalPipeline"
        }

        LOD 200

        Pass
        {
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_BaseMap);
            TEXTURE2D(_GradientMapA);
            TEXTURE2D(_GradientMapB);
            SAMPLER(sampler_BaseMap);
            SAMPLER(sampler_GradientMapA);
            SAMPLER(sampler_GradientMapB);

            CBUFFER_START(UnityPerMaterial)
                half4 _BaseColor;
                half4 _LightColor;
                half4 _ShadowColor;

                float _Cutoff;
                float _ABMapLerp;
                float _ShadowThreshold;
                float _ShadowSmoothness;

                float4 _BaseMap_ST;
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
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float2 uv          : TEXCOORD2;
            };

            // 动漫光
            struct AnimeLight
            {
                float ndotl;
                float ndoth;
                float halfLambert;

                float3 color;
                float3 direction;
            };

            // 计算动漫光
            AnimeLight PrepareAnimeLight(Varyings IN, Light mainLight)
            {
                AnimeLight al;

                al.color       = mainLight.color;
                al.direction   = mainLight.direction;
                al.ndotl       = max(0, dot(al.direction, IN.normalWS));
                al.halfLambert = al.ndotl * 0.5 + 0.5;

                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float3 halfDir = normalize(al.direction + viewDir); // 避免出现纯黑色，导致背面细节无法渲染
                al.ndoth       = max(0, dot(IN.normalWS, halfDir)); // 半程向量

                return al;
            }

            // 卡通高光
            float3 CalculateToonSpecular(AnimeLight al, float4 gradientMap)
            {
                
            }

            // 噪声灰度值渐变处理
            float3 CalculateNoiseGrayscaleGradientLerp(AnimeLight al)
            {
                float2 uv = float2(al.halfLambert, 0.5);
                float4 gradientMapA = SAMPLE_TEXTURE2D(_GradientMapA, sampler_GradientMapA, uv);
                float4 gradientMapB = SAMPLE_TEXTURE2D(_GradientMapB, sampler_GradientMapB, uv);   
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS  = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS    = normalize(TransformObjectToWorldNormal(IN.normalOS));
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight();
                AnimeLight al = PrepareAnimeLight(IN, mainLight);

                half4 baseMap = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half4 gradientMap = SAMPLE_TEXTURE2D(_GradientMapA, sampler_GradientMapA, float2(al.halfLambert, 0.5));

                clip(baseMap.a - _Cutoff);

                return baseMap;
            }
            ENDHLSL
        }
    }
}
