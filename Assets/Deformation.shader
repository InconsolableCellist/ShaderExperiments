Shader "Unlit/Deformation" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _DepthTex ("Depth", 2D) = "white" {}
        _BlurSize ("Blur Size", Range(0.0, 5)) = 1.27
        _DepthWeight ("Depth Weight", Range(0.0, 1)) = 0.08
    }
    SubShader {
        Tags { "RenderType"="Opaque" }
        LOD 100
        // Deforms the _MainTex vertices proportional to the intensity of the _DepthMap values, which it blurs
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            
            sampler2D   _MainTex;
            sampler2D   _DepthTex;
            float4      _MainTex_ST;
            float       _DepthWeight;
            float       _BlurSize;
            float4      _DepthTex_TexelSize;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            float gauss(float x, float y, const float sigma) {
                return 1.0f / (2.0f * 3.1415927f * sigma * sigma) * exp(-(x * x + y * y) / (2.0f * sigma * sigma));
            }
            
            v2f vert (appdata v) {
                v2f o;

                float   sum = 0;
                float2  uvOffset;
                float   weight;
                float4  depth = 0;
                
                const int KERNEL_SIZE = 32;

                // Gaussian blur the _DepthMap, to simulate gradations of fabric deformation
                for (int j = -KERNEL_SIZE/2; j <= KERNEL_SIZE/2; ++j) {
                    for (int k = -KERNEL_SIZE/2; k <= KERNEL_SIZE/2; ++k) {
                        uvOffset = v.uv;
                        uvOffset.x += j * _DepthTex_TexelSize.x;
                        uvOffset.y += k * _DepthTex_TexelSize.y;
                        weight = gauss(j, k, _BlurSize * 10);

                        // sample the DepthTex but flip the texture on the x and z axes
                        depth += tex2Dlod(_DepthTex, float4(1.0 - uvOffset.x, uvOffset.y, 0, 0)) * weight;
                        sum += weight;
                    }
                }
                depth *= (1.0f / sum);
                
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o, o.vertex);

                o.vertex.y += depth.r * 255 * _DepthWeight;
                
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 col = tex2D(_MainTex, i.uv);
                UNITY_APPLY_FOG(o.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
