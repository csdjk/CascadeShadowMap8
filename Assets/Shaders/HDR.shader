Shader "LcL/LambertShaderExample"
{
    Properties
    {
        _CubeMap ("Texture", Cube) = "" {}
        _BaseColor ("Example Colour", Color) = (1, 1,1, 1)
        _Cutoff ("Alpha Cutoff", Float) = 0.5
    }
    SubShader
    {
        Tags
        {
            "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        CBUFFER_START(UnityPerMaterial)
            float4 _BaseColor;
            float _Cutoff;
        CBUFFER_END
        ENDHLSL

        Pass
        {
            Tags
            {
                "LightMode"="UniversalForward"
            }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;

                float4 normalOS : NORMAL;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv : TEXCOORD0;
                float4 color : COLOR;

                float3 normalWS : NORMAL;
                float3 positionWS : TEXCOORD2;
            };

            TEXTURECUBE(_CubeMap);
            SAMPLER(sampler_CubeMap);
            real4 _CubeMap_HDR;

            Varyings vert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionCS = positionInputs.positionCS;
                output.uv = input.uv;
                output.color = input.color;
                output.positionWS = positionInputs.positionWS;
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS.xyz);
                output.normalWS = normalInputs.normalWS;

                return output;
            }

            half4 frag(Varyings input) : SV_Target
            {
                float3 normal = normalize(input.normalWS);
                half mip = PerceptualRoughnessToMipmapLevel(0);
                half4 encodedIrradiance = half4(SAMPLE_TEXTURECUBE_LOD(_CubeMap, sampler_CubeMap, normal, mip));

                float3 irradiance = encodedIrradiance.rgb;

                #if !defined(UNITY_USE_NATIVE_HDR)
                    irradiance = DecodeHDREnvironment(encodedIrradiance, _CubeMap_HDR);
                #endif

                return half4(irradiance, 1);
            }
            ENDHLSL
        }

    }
}