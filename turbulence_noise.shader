Shader "Custom/turbulence_noise"
{
    Properties
    {
        _MainTex ("Texture (RGB)", 2D) = "white" {}
        _Turbulence("Turbulence", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM

        #pragma surface surf Standard fullforwardshadows
        #pragma target 3.0

        sampler2D _MainTex;
        float _Turbulence;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPos;
        };

        // Return a random number between 0 and 1
        float random(float2 st)
        {
            return frac(sin(dot(st.xy, float2(12.9898,78.233))) * 45678.56789);
        }

        // Return a random number on 2 axis between -1 and 1
        float random2(float2 st)
        {
            st = float2(
                dot(st, float2(127.1, 311.7)),
                dot(st, float2(269.5, 183.3)));
            return frac(sin(st)*43758.5453123) * 2.0 - 1.0;
        }

        // Perlin noise function from thebookofshaders.com
        float noise(float2 st)
        {
            float2 i = floor(st);  // integer
            float2 f = frac(st);  // fraction 0-1

            // Four corners in 2D of a tile
            float a = random(i);
            float b = random(i + float2(1.0, 0.0));
            float c = random(i + float2(0.0, 1.0));
            float d = random(i + float2(1.0, 1.0));

            // Smooth Interpolation
            float2 u = smoothstep(0.0, 1.0, f);

            // Mix 4 corners percentages
            float n = lerp(
                lerp(
                    dot(random2(i + float2(0.0, 0.0)), f - float2(0.0, 0.0)),
                    dot(random2(i + float2(1.0, 0.0)), f - float2(1.0, 0.0)),
                    u.x),
                lerp(
                    dot(random2(i + float2(0.0, 1.0)), f - float2(0.0, 1.0)),
                    dot(random2(i + float2(1.0, 1.0)), f - float2(1.0, 1.0)),
                    u.x),
                u.y
            );

            return n;
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float3 P = IN.worldPos;
            float2 uv = IN.uv_MainTex;
            float2 st = uv;

            // Offset the UVs with Perlin noise; scaled by the Turbulence value
            float noise_scale = 10.0;
            float2 noise2d = float2(noise(st*noise_scale), noise(st*noise_scale+987.0));
            float2 turbulence = noise2d * _Turbulence;
            st += turbulence;

            // Pass in the offset UVs to the texture
            float4 color = tex2D(_MainTex, st);

            o.Albedo = color.rgb;
            o.Metallic = 0.0;
            o.Smoothness = 0.0;
            o.Alpha = color.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
