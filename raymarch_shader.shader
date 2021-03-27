Shader "Unlit/raymarch_shader"
{
    Properties
    {
        _Primitive ("Primitive", Int) = 0

        [Header(Cube)]
        _CubeSize ("Cube Size", Float) = 1
        
        [Header(Sphere)]
        _SphereRadius ("Sphere Radius", Float) = .5
        
        [Header(Capsule)]
        _CapsuleHeight("Capsule Height", Float) = 1
        _CapsuleRadius("Capsule Radius", Float) = .25
        
        [Header(Torus)]
        _TorusRadiusOuter ("Torus Radius Outer", Float) = .5
        _TorusRadiusInner ("Torus Radius Inner", Float) = .1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            #define RAYMARCH_MAX_STEPS 100
            #define RAYMARCH_MAX_DIST 1000
            #define RAYMARCH_SURF_DIST .001
            #define RAYMARCH_EPSILON .0001

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.hitPos = v.vertex;
                if (unity_OrthoParams.w > 0)
                {
                    // Orthographic
                    float3 viewSpaceForwardDir = mul(float3(0, 0, -1), (float3x3)UNITY_MATRIX_V);
                    o.ro = v.vertex - viewSpaceForwardDir;
                }
                else
                {
                    // Perspective
                    o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                }
                
                return o;
            }

            int _Primitive;
            float _CubeSize;
            float _SphereRadius;
            float _CapsuleHeight;
            float _CapsuleRadius;
            float _TorusRadiusOuter;
            float _TorusRadiusInner;

            float distToCube(float3 p, float width)
            {
                return length(max(abs(p) - width * .5, 0));
            }

            float distToSphere(float3 p, float radius)
            {
                return length(p) - radius;
            }

            float distToCapsule(float3 p, float height, float radius)
            {
                float3 a = float3(0, height * .5 - radius, 0);
                float3 b = float3(0, -height * .5 + radius, 0);
                float3 ab = b - a;
                float3 ap = p - a;
                float t = dot(ab, ap) / dot(ab, ab);
                t = clamp(t, 0, 1);
                float3 c = a + t * ab;
                return length(p - c) - radius;
            }

            float distToTorus(float3 p, float radiusOuter, float radiusInner)
            {
                return length(float2(length(p.xz) - radiusOuter, p.y)) - radiusInner;
            }

            float boolIntersect(float dA, float dB)
            {
                return max(dA, dB);
            }

            float boolUnion(float dA, float dB)
            {
                return min(dA, dB);
            }

            float boolDifference(float dA, float dB)
            {
                return max(dA, -dB);
            }

            float getDist (float3 p)
            {
                float d;
                if (_Primitive == 1)
                {
                    d = distToSphere(p, _SphereRadius);
                }
                else if (_Primitive == 2)
                {
                    d = distToCapsule(p, _CapsuleHeight, _CapsuleRadius);
                }
                else if (_Primitive == 3)
                {
                    d = distToTorus(p, _TorusRadiusOuter, _TorusRadiusInner);
                }
                else
                {
                    d = distToCube(p, _CubeSize);
                }
                
                return d;
            }

            float raymarch (float3 ro, float3 rd)
            {
                float dO = 0;  // Distance from origin
                float dS;  // Distance to scene

                for (int i = 0; i < RAYMARCH_MAX_DIST; i++)
                {
                    float3 p = ro + dO * rd;  // Current position
                    dS = getDist(p);
                    dO += dS;

                    if (dS < RAYMARCH_SURF_DIST || dO > RAYMARCH_MAX_DIST)
                    {
                        break;
                    }
                }

                return dO;
            }

            float3 getNormal(float3 p)
            {
                float2 e = float2(RAYMARCH_EPSILON, 0);
                // derivative function to get the difference between this point, and the points slightly
                //     offset from it in each direction.
                float3 offsetPositive = float3(getDist(p+e.xyy), getDist(p+e.yxy), getDist(p+e.yyx));
                float3 offsetNegative = float3(getDist(p-e.xyy), getDist(p-e.yxy), getDist(p-e.yyx));
                float3 n = offsetPositive - offsetNegative;
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 ro;  // Ray origin
                float3 rd;  // Ray direction

                ro = i.ro;
                rd = normalize(i.hitPos - ro);

                float d = raymarch(ro, rd);

                fixed4 col = 0;
                if (d >= RAYMARCH_MAX_DIST)
                {
                    discard;
                }
                else
                {
                    float3 p = ro + rd * d;
                    float3 n = getNormal(p);
                    col.rgb = n;
                }
                return col;
            }
            ENDCG
        }
    }
}
