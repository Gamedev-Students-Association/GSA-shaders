//DISCLAIMER!!!!
//ten plik to automatyczny generator grafik
//w stylu loga kola GSA
//(generuje pattern na caly ekran, ktory mozna potem zewnetrznie wyciac)
//jest to shader robiony na Unity (built-in)
//wierze ze moi nastepcy w kole tworzenia gier
//beda umieli takie cos poprawnie otworzyc
//~Magiczna Matryca

Shader "Hidden/GSAConferenceTextbox"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _FirstColor("_FirstColor", Color) = (0, 0, 0, 0)
        _SecondColor("_SecondColor", Color) = (0, 0, 0, 0)

            //objectPlacement
            _ShapePosition("_ShapePosition", vector) = (0, 0, 0, 0)
            _ShapeRotation("_ShapeRotation", float) = 0
            _ShapeScale("_ShapeScale", vector) = (0, 0, 0, 0)

            _GridTranslation("_GridTranslation", vector) = (0, 0, 0, 0)
            _GridScale("_GridScale", vector) = (0, 0, 0, 0)
            _CubeSize("_CubeSize", vector) = (0, 0, 0, 0)
            _CubeCornerSize("_CubeCornerSize", float) = 0
            _HueShiftScale("_HueShiftScale", vector) = (0, 0, 0, 0)

            _StripesScale ("_StripesScale", vector) = (0, 0, 0, 0)
            _StripesNoiseScale ("_StripesNoiseScale", vector) = (0, 0, 0, 0)
        /*
        _HueShiftExponenta ("_HueShiftExponenta", vector) = (1, 1, 1, 1)
        _CenterCubesValue ("_CenterCubesValue", range(0, 1)) = 0
        _CubesSaturation ("_CubesSaturation", vector) = (0, 0, 0, 0)
        _CubesValue("_CubesValue", vector) = (0, 0, 0, 0)
        _SaturationSeed ("_SaturationSeed", float) = 0
        _ValueSeed ("_ValueSeed", float) = 0
        _GlowScale ("_GlowScale", vector) = (0, 0, 0, 0)
        _GlowThreshold ("_GlowThreshold", range(0, 1)) = 0
        _GlowSeed ("_GlowSeed", float) = 0
        _GlowMinSaturation ("_GlowMinSaturation", float) = 0
        _GlowMaxValue ("_GlowMaxValue", float) = 0

        _LinesCount ("_LinesCount", int) = 0
        _LinesDarken ("_LinesDarken", range(0, 1)) = 0
        _LinesSeed ("_LinesSeed", float) = 0
        _LineASpread ("_LineASpread", vector) = (0.5, 12, 0, 0)
        _LineBSpread ("_LineBSpread", vector) = (-6, 6, 0, 0)
        _CompoundLineRange("_CompoundLineRange", vector) = (1, 1, 0, 0)

        _GraphicStyle ("_Style", int) = 0 //0 = image pattern 1 = text pattern
        */
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

            uniform vector _FirstColor;
            uniform vector _SecondColor;

            uniform vector _ShapePosition;
            uniform float _ShapeRotation;
            uniform vector _ShapeScale;

            uniform vector _GridTranslation; //float2
            //uniform float _GridRotation;
            //uniform vector _GridTiltX;
            //uniform vector _GridTiltY;
            uniform vector _GridScale; //float2
            uniform vector _CubeSize; //float2
            uniform float _CubeCornerSize;
            uniform vector _HueShiftScale; //actually vect4, every one another direction
            
            uniform vector _StripesScale;
            uniform vector _StripesNoiseScale;
            
            
            
            uniform vector _HueShiftExponenta;
            uniform float _CenterCubesValue;
            uniform vector _CubesSaturation; //float2 (range)
            uniform vector _CubesValue; //float2 (range)
            uniform float _SaturationSeed;
            uniform float _ValueSeed;
            uniform vector _GlowScale; //float2
            uniform float _GlowThreshold;
            uniform float _GlowSeed;
            uniform float _GlowMinSaturation;
            uniform float _GlowMaxValue;

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
                float epsilon = 64;
                fixed4 col = tex2D(_MainTex, i.uv);
                float2 transform = i.uv - float2(0.5, 0.5);
                //apply aspect ratio so that square grid scale generates squares
                //must create another transform for grid to be pixel perfect-ish
                transform = float2(transform.x, transform.y / (_ScreenParams.x / _ScreenParams.y));
                float2 gridTransform = transform;
                gridTransform = transform - _ShapePosition.xy + _ShapeScale.xy;
                gridTransform.y = transform.y - _ShapePosition.y - _ShapeScale.y;

                //transform = rot2D(transform, _ShapeRotation);

                //only work if inside desired shape
                float3 shapeScalePercent = float3(_CubeSize.x * (1 - _CubeCornerSize), _CubeSize.y * (1 - _CubeCornerSize), min(_CubeSize.x, _CubeSize.y) * _CubeCornerSize);
                float shapeDist = CubeShape2D(transform - _ShapePosition, float3(_ShapeScale.x, _ShapeScale.y, _ShapeScale.z));
                if (shapeDist < 0)
                {
                    col = float4(0, 0, 0, 1);
                    //gridTransform = rot2D(gridTransform, 45);

                    //this weird way makes it that there is no center square
                    gridTransform -= _GridScale / 2;
                    float2 chunkId = round(gridTransform / _GridScale) * _GridScale;
                    chunkId += _GridScale / 2;
                    float2 chunkPos = (gridTransform + _GridScale / 2 - chunkId) / _GridScale * 2;

                    

                    //cube scale is a percentage
                    float3 cubeScale = float3(_CubeSize.x * (1 - _CubeCornerSize), _CubeSize.y * (1 - _CubeCornerSize), min(_CubeSize.x, _CubeSize.y) * _CubeCornerSize);
                    float cubeDist = CubeShape2D(chunkPos, cubeScale);

                    if (cubeDist < 0)
                    {
                        //float chunkBlend = (chunkId.x - (chunkId.x - _ShapePosition.x) - _ShapeScale.x) / ((chunkId.x - _ShapePosition.x) + _ShapeScale.x);
                        //float chunkBlend = lerp((transform.x - _ShapePosition.x) - _ShapeScale.x, (transform.x - _ShapePosition.x) + _ShapeScale.x, chunkId);

                        col = _FirstColor;
                        //+ abs(chunkId.y)
                        float chunkBlend = (abs(chunkId.x) + abs(chunkId.y)) / (_ShapeScale.x * 2 + _ShapeScale.y * 2);
                        //float chunkBlend = abs(gridTransform.y) / (_ShapeScale.y * 2);
                        
                        //col = float4(chunkBlend, chunkBlend, chunkBlend, 1);
                        col = ColorBlend(_FirstColor, float4(_SecondColor.xyz, chunkBlend));
                        /*
                        if (chunkBlend <= 0.02)
                        {
                            col = float4(1, 0, 0, 1);
                        }
                        else if (chunkBlend >= 0.98)
                        {
                            col = float4(1, 0, 0, 1);
                        }
                        */


                        /*
                        float3 hsv = RGBtoHSV(_FirstColor.xyz);
                        hsv.y = 1;
                        hsv.z = 1;
                        float2 chunkRand = WhiteNoise2d(chunkId + epsilon, 2);
                        float stripesIntensity = abs(chunkId.y) + (chunkRand.x * _StripesNoiseScale.x) * _GridScale.x;
                        stripesIntensity += cos(abs(chunkId.y - 0.5) * 4) / 4;
                        //hsv.y = abs(chunkId.y) + (chunkRand.x * _StripesNoiseScale.x) * _GridScale.x;
                        //hsv.y += cos(abs(chunkId.y - 0.5) * 4) / 4;

                        hsv.y = lerp(0.6, 0.0, 1 - stripesIntensity);
                        col = float4(HSVtoRGB(hsv), 1);

                        //col = _FirstColor;
                        //col = ColorBlend(col, float4(1, 1, 1, stripesIntensity));

                        //col = ColorBlend(col, float4(_FirstColor.x, _FirstColor.y, _FirstColor.z, abs(chunkId.y + chunkId.x) + (chunkRand.x * _StripesNoiseScale.x) * _GridScale));
                        col = _FirstColor;
                        float gridSpan = abs(chunkIndex.y + chunkIndex.x);
                        gridSpan = round(gridSpan / 2) * 2 * _GridScale;
                        //flochunkId = round(gridTransform / (_GridScale * 2)) * _GridScale * 2;
                        float mixVal = gridSpan + (chunkRand.x * _StripesNoiseScale.x) * _GridScale.x;
                        col = ColorBlend(col, float4(1, 1, 1, mixVal));
                        //col = ColorBlend(col, float4(1, 1, 1, 0));
                        */
                    }
                }
                //else copy whatever was already rendered by camera

                return col;
            }
            ENDCG
        }
    }
}
