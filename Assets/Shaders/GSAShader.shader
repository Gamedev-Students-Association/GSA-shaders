//DISCLAIMER!!!!
//ten plik to automatyczny generator grafik
//w stylu loga kola GSA
//(generuje pattern na caly ekran, ktory mozna potem zewnetrznie wyciac)
//jest to shader robiony na Unity (built-in)
//wierze ze moi nastepcy w kole tworzenia gier
//beda umieli takie cos poprawnie otworzyc
//~Magiczna Matryca

Shader "Hidden/GSAShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _GridTranslation ("_GridTranslation", vector) = (0, 0, 0, 0)
        _GridScale ("_GridScale", vector) = (0, 0, 0, 0)
        _CubeSize ("_CubeSize", vector) = (0, 0, 0, 0)
        _CubeCornerSize ("_CubeCornerSize", float) = 0
        _ColorsSeed ("_ColorsSeed", float) = 0
        _LinesCount ("_LinesCount", int) = 0
        _LinesDarken ("_LinesDarken", range(0, 1)) = 0
        _LinesSeed ("_LinesSeed", float) = 0
        _LineASpread ("_LineASpread", vector) = (0.5, 12, 0, 0)
        _LineBSpread ("_LineBSpread", vector) = (-6, 6, 0, 0)

        _GraphicStyle ("_Style", int) = 0 //0 = image pattern 1 = text pattern
    }
    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            //rgb/hsv convertions //yoinked from internet
            float3 HUEtoRGB(in float H)
            {
                float R = abs(H * 6 - 3) - 1;
                float G = 2 - abs(H * 6 - 2);
                float B = 2 - abs(H * 6 - 4);
                return saturate(float3(R, G, B));
            }
            float3 HSVtoRGB(in float3 HSV)
            {
                float3 RGB = HUEtoRGB(HSV.x);
                return ((RGB - 1) * HSV.y + 1) * HSV.z;
            }

            float Epsilon = 1e-10;

            float3 RGBtoHCV(in float3 RGB)
            {
                // Based on work by Sam Hocevar and Emil Persson
                float4 P = (RGB.g < RGB.b) ? float4(RGB.bg, -1.0, 2.0 / 3.0) : float4(RGB.gb, 0.0, -1.0 / 3.0);
                float4 Q = (RGB.r < P.x) ? float4(P.xyw, RGB.r) : float4(RGB.r, P.yzx);
                float C = Q.x - min(Q.w, Q.y);
                float H = abs((Q.w - Q.y) / (6 * C + Epsilon) + Q.z);
                return float3(H, C, Q.x);
            }
            float3 RGBtoHSV(in float3 RGB)
            {
                float3 HCV = RGBtoHCV(RGB);
                float S = HCV.y / (HCV.z + Epsilon);
                return float3(HCV.x, S, HCV.z);
            }

            //cube generation
            float CubeShape2D(float2 p, float3 s)
            {
                p = abs(p);

                p /= s.xy;

                float result = length(float2(max(0, p.x - 1), max(0, p.y - 1)));
                if (p.x < 1 && p.y < 1)
                {
                    result = max(p.x - 1, p.y - 1);
                }

                return result - s.z;
            }

            //noises
            float PseudoRand(float2 uv)
            {
                return frac(sin(dot(uv, float2(12.9898, 78.233))) * 43758.5453);
            }

            float2 WhiteNoise2d(float2 data, float2 seed)
            {
                return float2(PseudoRand(float2(data.x, seed.x)), PseudoRand(float2(data.y, seed.y)));
            }

            float2 LinearCombineNoise2d(float2 pos, float2 seed)
            {
                return WhiteNoise2d(float2((pos.x * pos.y) * pos.y, (pos.x * pos.y) * pos.x), seed);
            }

            sampler2D _MainTex;

            uniform vector _GridTranslation; //float2
            uniform vector _GridScale; //float2
            uniform vector _CubeSize; //float2
            uniform float _CubeCornerSize;
            uniform float _ColorsSeed;
            uniform uint _LinesCount;
            uniform float _LinesDarken;
            uniform float _LinesSeed;

            uniform vector _LineASpread;
            uniform vector _LineBSpread;

            uniform uint _GraphicStyle;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 transform = i.uv - _GridTranslation;

                if (_GraphicStyle == 0)
                {
                    float2 chunkId = round(transform / _GridScale) * _GridScale;
                    float2 chunkPos = (transform - chunkId) / _GridScale * 2;

                    //make corner size a percentage
                    if (CubeShape2D(chunkPos, float3(_CubeSize.x, _CubeSize.y, _CubeCornerSize)) < 0)
                    {
                        //basic hue by x
                        //hue by angle (reality is somewhere between)
                        //float angle = abs(atan2(transform.x, transform.y) / 3.14);
                        float2 normId = chunkId / length(chunkId);
                        float angle = abs(atan2(normId.x, normId.y) / 3.14);
                        if (chunkId.x > 0) //1 half
                        {

                        }
                        else //2 half
                        {
                            angle = 1 - angle;
                        }
                        angle -= 0.25;
                        angle %= 1;
                        if (angle < 0)
                        {
                            angle = 1 + angle;
                        }
                        col = float4(HUEtoRGB(angle), 1);
                        //col = float4(angle, 0, 0, 1);

                        float3 hsv = RGBtoHSV(col.xyz);

                        //randomized saturation per block
                        hsv.y *= lerp(0.4, 0.8, LinearCombineNoise2d(chunkId + 12, _ColorsSeed));

                        //randomized shading lines
                        float seed = _LinesSeed;
                        for (int i = 0; i < _LinesCount; i++)
                        {
                            float lineA = lerp(-7, 7, PseudoRand(seed));
                            seed += 1;
                            float lineB = lerp(-2, 2, PseudoRand(seed));
                            seed += 1;
                            //if under line then darken
                            if (transform.y > transform.x * lineA + lineB)
                            {
                                hsv.z *= _LinesDarken;
                            }
                        }

                        col = float4(HSVtoRGB(hsv), 1);
                    }
                    else //background
                    {
                        //return float4(0, 0, 0, 0);
                        col = float4(0, 0, 0, 0);
                    }
                }
                else
                {
                    //text background
                    float seed = _LinesSeed;
                    float lineNum = 0;
                    for (int i = 0; i < _LinesCount; i++)
                    {
                        float lineA = lerp(-_LineASpread.x, _LineASpread.y, PseudoRand(seed));
                        seed += 1;
                        //*
                        if (PseudoRand(seed) > 0.5)
                        {
                            lineA = -lineA;
                        }
                        //*/
                        seed += 1;
                        float lineB = lerp(_LineBSpread.x, _LineBSpread.y, PseudoRand(seed));
                        seed += 1;
                        //if under line then darken
                        if (lineA > 0)
                        {
                            if (transform.y < transform.x * lineA + lineB)
                            {
                                lineNum += 1;
                            }
                        }
                        else
                        {
                            if (transform.y > transform.x * lineA + lineB)
                            {
                                lineNum += 1;
                            }
                        }

                    }

                    col = float4(HUEtoRGB((lineNum / _LinesCount + 0.25) % 1), 1);

                    float3 hsv = RGBtoHSV(col.xyz);
                    //randomized saturation per chunk
                    hsv.y *= lerp(0.4, 0.8, PseudoRand(lineNum + _ColorsSeed));
                    //randomized brightness per chunk
                    hsv.z *= lerp(0.6, 0.9, PseudoRand(lineNum + _ColorsSeed + 24));

                    col = float4(HSVtoRGB(hsv), 1);
                }

                return col;
            }
            ENDCG
        }
    }
}
