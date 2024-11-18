//DISCLAIMER!!!!
//ten plik to automatyczny generator grafik
//w stylu loga kola GSA
//(generuje pattern na caly ekran, ktory mozna potem zewnetrznie wyciac)
//jest to shader robiony na Unity (built-in)
//wierze ze moi nastepcy w kole tworzenia gier
//beda umieli takie cos poprawnie otworzyc
//~Magiczna Matryca

Shader "Hidden/GSAConferenceShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BackgroundColor ("_BackgroundColor", Color) = (0, 0, 0, 0)
        _Epsilon ("_Epsilon", float) = 64
        _GridTranslation ("_GridTranslation", vector) = (0, 0, 0, 0)
        _GridRotation ("_GridRotation", float) = 0
        _GridTiltX ("_GridTiltX", vector) = (0, 0, 0, 0)
        _GridTiltY ("_GridTiltY", vector) = (0, 0, 0, 0)
        _GridScale ("_GridScale", vector) = (0, 0, 0, 0)
        _CubeSize ("_CubeSize", vector) = (0, 0, 0, 0)
        _CubeCornerSize ("_CubeCornerSize", float) = 0
        _HueShift ("_HueShift", float) = 0
        _HueStatic ("_HueStatic", float) = -1
        _HueSign ("_HueSign",  vector) = (1, 1, -1, -1)
        _HueScale ("_HueScale", vector) = (0, 0, 0, 0)
        _HueExponenta ("_HueExponenta", vector) = (1, 1, 1, 1)
        _CenterCubesValue ("_CenterCubesValue", range(0, 1)) = 0
        _CubesSaturation ("_CubesSaturation", vector) = (0, 0, 0, 0)
        _CubesValue("_CubesValue", vector) = (0, 0, 0, 0)
        _SaturationSeed ("_SaturationSeed", float) = 0
        _ValueSeed ("_ValueSeed", float) = 0
        _GlowThreshold ("_GlowThreshold", range(0, 1)) = 0
        _GlowSeed ("_GlowSeed", float) = 0
        _GlowMinSaturation ("_GlowMinSaturation", float) = 0
        _GlowMaxValue ("_GlowMaxValue", float) = 0
        _FadeIntensity ("_FadeIntensity", float) = 0
        _FadeSmoothness ("_FadeSmoothness", float) = 1

        //_LinesCenterPos ("_LinesCenterPos", vector) = ()
        _LinesCount ("_LinesCount", int) = 0
        _LinesDarken ("_LinesDarken", range(0, 1)) = 0
        _LinesSeed ("_LinesSeed", float) = 0
        _LineASpread ("_LineASpread", vector) = (0.5, 12, 0, 0)
        _LineBSpread ("_LineBSpread", vector) = (-6, 6, 0, 0)
        _CompoundLineRange("_CompoundLineRange", vector) = (1, 1, 0, 0)

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
                float4 screenPos : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.screenPos = ComputeScreenPos(o.vertex);
                o.uv = v.uv;
                return o;
            }


            float4 ColorBlend(float4 bgCol, float4 adCol)
            {
                float4 result = float4(1, 1, 1, 1);
                result.a = 1 - (1 - adCol.a) * (1 - bgCol.a);
                result.rgb = adCol.rgb * adCol.a / result.a + bgCol.rgb * bgCol.a * (1 - adCol.a) / result.a;

                return result;
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

            //2d rotation (in angles)
            float2 rot2D(float2 pos, float rot)
            {
                rot = rot * 3.14 / 180;
                float cs = cos(rot);
                float sn = sin(rot);
                float2x2 rotMatrix = float2x2(cs, sn, -sn, cs);
                return mul(rotMatrix, pos);
            }

            //cube generation
            float CubeShape2D(float2 p, float3 s)
            {
                p = abs(p);

                //p /= s.xy;

                float result = length(float2(max(0, p.x - s.x), max(0, p.y - s.y)));
                if (p.x < s.x && p.y < s.y)
                {
                    result = max(p.x - s.x, p.y - s.y);
                }

                return result - s.z;
            }

            //noises
            float PseudoRand(float data, float seed)
            {
                return frac(sin(dot(float2(data, seed), float2(12.9898, 78.233))) * 43758.5453);
            }

            float2 WhiteNoise2d(float2 data, float2 seed)
            {
                return float2(PseudoRand(data.x, seed.x), PseudoRand(data.y, seed.y));
            }

            float2 LinearCombineNoise2d(float2 pos, float2 seed)
            {
                return WhiteNoise2d(float2((pos.x * pos.y) * pos.y, (pos.x * pos.y) * pos.x), seed);
            }

            sampler2D _MainTex;
            uniform vector _BackgroundColor;
            uniform float _Epsilon;

            uniform vector _GridTranslation; //float2
            uniform float _GridRotation;
            uniform vector _GridTiltX;
            uniform vector _GridTiltY;
            uniform vector _GridScale; //float2
            uniform vector _CubeSize; //float2
            uniform float _CubeCornerSize;
            uniform float _HueShift;
            uniform float _HueStatic;
            uniform vector _HueSign;
            uniform vector _HueScale; //actually vect4, every one another direction
            uniform vector _HueExponenta;
            uniform float _CenterCubesValue;
            uniform vector _CubesSaturation; //float2 (range)
            uniform vector _CubesValue; //float2 (range)
            uniform float _SaturationSeed;
            uniform float _ValueSeed;
            uniform float _GlowThreshold;
            uniform float _GlowSeed;
            uniform float _GlowMinSaturation;
            uniform float _GlowMaxValue;
            uniform float _FadeIntensity;
            uniform float _FadeSmoothness;

            uniform uint _LinesCount;
            uniform float _LinesDarken;
            uniform float _LinesSeed;

            uniform vector _LineASpread;
            uniform vector _LineBSpread;

            uniform vector _CompoundLineRange;

            uniform uint _GraphicStyle;

            fixed4 frag(v2f i) : SV_Target
            {
                //used for better random generation
                float epsilon = _Epsilon;
                //i.uv = i.screenPos.xy / i.screenPos.w;
                fixed4 col = tex2D(_MainTex, i.uv);
                //center transform
                float2 transform = i.uv - float2(0.5, 0.5);
                //apply aspect ratio so that square grid scale generates squares
                transform = float2(transform.x, transform.y / (_ScreenParams.x / _ScreenParams.y));

                //will be useful later when no tilting is required
                float2 orgTransform = transform;

                //apply tilting (it's actually a rotation)
                transform = rot2D(transform, _GridRotation);

                //translation in local space (regarding tilt)
                transform = transform - _GridTranslation;

                //wavy tilt
                transform.x += sin((transform.y + _GridTiltX.x) * _GridTiltX.z) * _GridTiltX.y;
                transform.y += sin((transform.x + _GridTiltY.x) * _GridTiltY.z) * _GridTiltY.y;

                if (_GraphicStyle == 0)
                {
                    //this weird way makes it that there is no center square
                    transform -= _GridScale / 2;
                    float2 chunkId = round(transform / _GridScale) * _GridScale;
                    chunkId += _GridScale / 2;
                    float2 chunkPos = (transform + _GridScale / 2 - chunkId) / _GridScale * 2;

                    //cube scale is a percentage
                    float3 cubeScale = float3(_CubeSize.x * (1 - _CubeCornerSize), _CubeSize.y * (1 - _CubeCornerSize), min(_CubeSize.x, _CubeSize.y) * _CubeCornerSize);
                    float cubeDist = CubeShape2D(chunkPos, cubeScale);

                    
                    if (cubeDist < 0)
                    {
                        float2 removalChunkId = chunkId - _GridScale * sign(chunkId);

                        //+ hue by x and -hue by y
                        float hue = 0;
                        //0 distance isn't at center, it is around center squares
                        //this part of the code does it's job incorrectly, but the effect is desirable so it stays
                        float2 chunkDistShift = CubeShape2D(chunkId, float3(_GridScale.x, _GridScale.y, 0)) * sign(chunkId);
                        chunkId -= chunkDistShift;

                        float2 hueChunkId = chunkId;
                        hueChunkId *= _HueScale.xy;
                        
                        if (abs(hueChunkId.x) < abs(hueChunkId.y))
                        {
                            hueChunkId.y /= (1 + length(hueChunkId));
                        }
                        else
                        {
                            hueChunkId.x /= (1 + length(hueChunkId));
                        }

                        if (hueChunkId.x < 0)
                        {
                            hue += log(1 + abs(hueChunkId.x) * _HueExponenta.w) * sign(_HueSign.x);
                        }
                        else
                        {
                            hue += log(1 + abs(hueChunkId.x) * _HueExponenta.y) * sign(_HueSign.y);
                        }

                        if (hueChunkId.y < 0)
                        {
                            hue += log(1 + abs(hueChunkId.y) * _HueExponenta.z) * sign(_HueSign.z);
                        }
                        else
                        {
                            hue += log(1 + abs(hueChunkId.y) * _HueExponenta.x) * sign(_HueSign.w);
                        }

                        chunkId += chunkDistShift;

                        hue += _HueShift;
                        if (_HueStatic >= 0)
                        {
                            hue = _HueStatic;
                        }

                        hue %= 1;
                        if (hue < 0)
                        {
                            hue = 1 + hue;
                        }

                        col = float4(HUEtoRGB(hue), 1);
                        float3 hsv = RGBtoHSV(col.xyz);
                        
                        //randomized saturation per block
                        float cubeSaturation = lerp(_CubesSaturation.x, _CubesSaturation.y, LinearCombineNoise2d(chunkId + epsilon, _SaturationSeed).x);;
                        float cubeValue = lerp(_CubesValue.x, _CubesValue.y, LinearCombineNoise2d(chunkId + epsilon, _ValueSeed).x);
                        //----------------------------------------
                        //glow effect
                        float2 glowNoise = LinearCombineNoise2d(chunkId + epsilon, _GlowSeed);
                        if (glowNoise.x < _GlowThreshold && glowNoise.y < _GlowThreshold)
                        {
                            float glowLerp = min(1, -cubeDist / cubeScale.z);
                            hsv.z *= lerp(_GlowMaxValue, cubeValue, glowLerp);
                            hsv.y *= lerp(_GlowMinSaturation, cubeSaturation, abs(glowLerp - 0.5) * 2);
                        }
                        else
                        {
                            hsv.y *= cubeSaturation;
                            hsv.z *= cubeValue;
                        }

                        //most center squares have no saturation and no random value
                        if (abs(chunkId.x) < _GridScale.x && abs(chunkId.y) < _GridScale.y)
                        {
                            hsv.y = 0;
                            hsv.z = _CenterCubesValue;
                        }


                        //randomized shading lines
                        
                        float seed = _LinesSeed;
                        float linesHitThreshold = round(lerp(_CompoundLineRange.x, _CompoundLineRange.y, PseudoRand(seed, 0)));
                        float linesHitRatio = 0;
                        for (int i = 0; i < _LinesCount; i++)
                        {
                            float lineA = lerp(-7, 7, PseudoRand(seed, 0.0));
                            seed += 1;
                            float lineB = lerp(-2, 2, PseudoRand(seed, 0));
                            seed += 1;
                            //if under line then hit
                            //if line under 0 point, then check up and vice versa
                            if (lineB < 0)
                            {
                                if (orgTransform.y > orgTransform.x * lineA + lineB)
                                {
                                    linesHitRatio += 1;
                                }
                            }
                            else
                            {
                                if (orgTransform.y < orgTransform.x * lineA + lineB)
                                {
                                    linesHitRatio += 1;
                                }
                            }
                            
                            //if under consequtive lines then darken
                            if (linesHitRatio >= linesHitThreshold)
                            {
                                hsv.z *= _LinesDarken;
                                linesHitRatio = 0;
                                linesHitThreshold = round(lerp(_CompoundLineRange.x, _CompoundLineRange.y, PseudoRand(seed, 0)));
                            }
                        }

                        //removes cubes based on distance
                        float removalDist = length(removalChunkId);
                        float2 normId = chunkId / length(chunkId);
                        float angle = abs(atan2(normId.x, normId.y) / 3.14);
                        if (chunkId.x > 0) //1 half
                        {
                            angle *= 0.5;
                        }
                        else //2 half
                        {
                            angle = 0.5 + (1 - angle) / 2;
                        }
                        
                        float distRand = PseudoRand(angle, 2);
                        removalDist *= _FadeIntensity;
                        if (removalDist > distRand)
                        {
                            float removalValue = pow((1 - (removalDist - distRand)), _FadeSmoothness);
                            hsv.z *= removalValue;
                            col = float4(HSVtoRGB(hsv), removalValue);
                        }
                        else
                        {
                            col = float4(HSVtoRGB(hsv), 1);
                        }
                        
                        
                    }
                    else //background
                    {
                        col = _BackgroundColor;
                    }
                }

                return col;
            }
            ENDCG
        }
    }
}
