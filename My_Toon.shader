Shader "Custom/My_Toon"
{
    Properties
    {
        _MainColor("主色", Color) = (1, 1, 1, 1)
        _GradientTex("渐变纹理（Ramp）", 2D) = "white" {}
        _BIntensity("强度系数 B", Range(0, 2)) = 1.0
        _Gloss("光泽度", Range(0.1, 2)) = 1.0
    }

    SubShader
    {
        Tags 
        { 
            "RenderType" = "Opaque" 
            "RenderPipeline" = "UniversalPipeline" 
            "Queue" = "Geometry"
        }

        LOD 300

        Pass
        {
            Name "Toon"
            Tags {"LightMode" = "UniversalForward"}

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"         

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0; 
                float3 normalWS    : TEXCOORD1; 
            };

            TEXTURE2D(_GradientTex);
            SAMPLER(sampler_GradientTex);

            CBUFFER_START(UnityPerMaterial)
                half4  _MainColor;
                float4 _GradientTex_ST;
                float  _BIntensity;
                float  _Gloss;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                
                return OUT;
            }

            // 计算漫反射
            float CalculateNDotL(Varyings IN)
            {   
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                
                // 归一化法线
                float3 worldNormal = normalize(IN.normalWS);
                float ndotl = dot(lightDir, worldNormal);
                return saturate(ndotl);
            }

            // 计算半程向量高光
            float CalculateSpecular(Varyings IN)
            {
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);
                
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float3 halfDir = normalize(lightDir + viewDir); // 计算半角向量
                
                float3 worldNormal = normalize(IN.normalWS);
                float NdotH = max(0, dot(worldNormal, halfDir));
                
                return pow(NdotH, _Gloss);
            }

            half4 frag(Varyings IN) : SV_Target
            {
                Light mainLight = GetMainLight();  //  统一命名
                
                float ndotl = CalculateNDotL(IN);
                float specIntensity = CalculateSpecular(IN);
                
                // 漫反射颜色
                float3 diffuseColor = _MainColor.rgb * ndotl;
                
                // 高光颜色（纯白高光，乘以光源颜色）
                float3 specularColor = mainLight.color * specIntensity;
                
                // 漫反射 + 高光（相加）
                float3 finalColor = diffuseColor + specularColor;
                
                // 可选：使用渐变纹理
                // float ramp = SAMPLE_TEXTURE2D(_GradientTex, sampler_GradientTex, float2(ndotl, 0.5)).r;
                // float3 finalColor = _MainColor.rgb * ramp + specularColor;
                
                return float4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }
}