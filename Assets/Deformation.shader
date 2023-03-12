// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/Deformation"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthTex ("Depth", 2D) = "white" {}
        _BlurSize ("Blur Size", Range(0.0, 5)) = 2
        _DepthWeight ("Depth Weight", Range(0.0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
//        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        LOD 100
//        RenderTexture _blurredDepthTex;
//        
//        Pass {
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//            
//            // Uniforms
//            uniform sampler2D _DepthMap;
//
//            float4 vPos : SV_POSITION;
//
//            // Constants
//            float Pi = 6.28318530718; // Pi*2
//
//            // GAUSSIAN BLUR SETTINGS {{{
//            float Directions = 16.0; // BLUR DIRECTIONS (Default 16.0 - More is better but slower)
//            float Quality = 3.0; // BLUR QUALITY (Default 4.0 - More is better but slower)
//            float Size = 1.0; // BLUR SIZE (Radius)
//            // GAUSSIAN BLUR SETTINGS }}}
//            
//            struct appdata {
//                float4 vertex : POSITION;
//                float4 tangent : TANGENT;
//                float3 normal : NORMAL;
//                float4 texcoord : TEXCOORD0;
//                float4 texcoord1 : TEXCOORD1;
//                float4 texcoord2 : TEXCOORD2;
//                float4 texcoord3 : TEXCOORD3;
//                fixed4 color : COLOR;
//            };
//
//            void vert(inout appdata v) {
//                v.vertex = UnityObjectToClipPos(v.vertex);
//                v.vertex.y += 10;
//            }
//
//            void frag (in float4 vPos : SV_POSITION, out float4 fragColor : SV_Target) {
//                float2 radius = 1.0;
//
//                float2 uv = vPos.xy;
//                
//                // Pixel colour
//                float4 Color = tex2D(_DepthMap, uv);
//
//                // Blur calculations
//                for(float d=0.0; d<Pi; d+=Pi/Directions)
//                    for(float i=1.0/Quality; i<=1.0; i+=1.0/Quality)
//                        Color += tex2D(_DepthMap, uv+float2(cos(d),sin(d))*radius*i);     
//
//                // Output to screen
//                Color /= Quality * Directions - 15.0;
//                fragColor = Color;
//                fragColor = tex2D(_DepthMap, vPos);
//            }
//            ENDCG
//        }

        // This pass blurs the _DepthTex to create a smoother gradient for deformation of the verts
//        Pass { 
//            CGPROGRAM
//            #pragma vertex vert
//            #pragma fragment frag
//            
//            sampler2D _DepthTex;
//            float _BlurSize;
//            float4 _DepthTex_TexelSize;
//
//            struct appdata {
//                float4 vertex : POSITION;
//                float2 uv : TEXCOORD0;
//            };
//            
//            struct v2f {
//                float2 uv : TEXCOORD0;
//                float4 vertex : SV_POSITION;
//            };
//
//            v2f vert (appdata v) {
//                v2f o;
//                o.vertex = UnityObjectToClipPos(v.vertex);
//                o.uv = v.uv;
//                o.vertex.y += 10;
//                return o;
//            }
//
//            float gauss(float x, float y, const float sigma) {
//                return 1.0f / (2.0f * 3.1415927f * sigma * sigma) * exp(-(x * x + y * y) / (2.0f * sigma * sigma));
//            }
//
//            float4 frag (v2f i) : SV_Target {
//                float4 o = 0;
//                float sum = 0;
//                float2 uvOffset;
//                float weight;
//                
//                const int KERNEL_SIZE = 32;
//
//                for (int j = -KERNEL_SIZE/2; j <= KERNEL_SIZE/2; ++j) {
//                    for (int k = -KERNEL_SIZE/2; k <= KERNEL_SIZE/2; ++k) {
//                        uvOffset = i.uv;
//                        uvOffset.x += j * _DepthTex_TexelSize.x;
//                        uvOffset.y += k * _DepthTex_TexelSize.y;
//                        weight = gauss(j, k, _BlurSize * 10);
//
//                        // o += tex2D(_DepthTex, uvOffset) * weight;
//                        // sample the DepthTex but flip the texture on the x and z axes
//                        // float4 depth = tex2Dlod(_DepthTex, float4(1.0 - v.uv.x, v.uv.y, 0, 0));
//                        o += tex2Dlod(_DepthTex, float4(1.0 - uvOffset.x, uvOffset.y, 0, 0)) * weight;
//                        sum += weight;
//                    }
//                }
//                o *= (1.0f / sum);
//
//                return o;
//            }
//            ENDCG
//        }
        
        // Deforms the _MainTex vertices proportional to the intensity of the _DepthMap values
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                // float2 uv : TEXCOORD1;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                //float2 uv : TEXCOORD1;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                // float3 normal : TEXCOORD1;
            };
            
            sampler2D _MainTex;
            sampler2D _DepthTex;
            float4 _MainTex_ST;
            float _DepthWeight;
            float _BlurSize;
            float4 _DepthTex_TexelSize;
            

            float gauss(float x, float y, const float sigma) {
                return 1.0f / (2.0f * 3.1415927f * sigma * sigma) * exp(-(x * x + y * y) / (2.0f * sigma * sigma));
            }
            v2f vert (appdata v) {
                v2f o;


                // float4 o = 0;
                float sum = 0;
                float2 uvOffset;
                float weight;
                float4 color = 0;
                
                const int KERNEL_SIZE = 32;

                for (int j = -KERNEL_SIZE/2; j <= KERNEL_SIZE/2; ++j) {
                    for (int k = -KERNEL_SIZE/2; k <= KERNEL_SIZE/2; ++k) {
                        uvOffset = v.uv;
                        uvOffset.x += j * _DepthTex_TexelSize.x;
                        uvOffset.y += k * _DepthTex_TexelSize.y;
                        weight = gauss(j, k, _BlurSize * 10);

                        // o += tex2D(_DepthTex, uvOffset) * weight;
                        // sample the DepthTex but flip the texture on the x and z axes
                        // float4 depth = tex2Dlod(_DepthTex, float4(1.0 - v.uv.x, v.uv.y, 0, 0));
                        color += tex2Dlod(_DepthTex, float4(1.0 - uvOffset.x, uvOffset.y, 0, 0)) * weight;
                        sum += weight;
                    }
                }
                color *= (1.0f / sum);

                
                
                // float4 depth = tex2Dlod(_DepthTex, float4(v.uv, 0, 0));
                // float3 flippedNormal = v.normal * -1.0;

                // Sample the depth texture but flip the texture on the x and z axes
                // float4 depth = tex2Dlod(_DepthTex, float4(1.0 - v.uv.x, v.uv.y, 0, 0));
                float4 depth = color;
                
                // o.vertex = UnityObjectToClipPos(v.vertex + flippedNormal * depth.r * _DepthWeight);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                o.vertex.y += depth.r * 255 * _DepthWeight;
                // o.normal = flippedNormal;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(o.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
