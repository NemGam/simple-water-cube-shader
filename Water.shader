Shader "Custom/Water"
{
	Properties
	{
		_Color ("Main Color (RGBA)", Color) = (1,1,1,1) //Color and transparency of the water (RGBA)
		
		//Reference value for stencil masks (Delete if don't need Stencil functionality)
		[IntRange] _StencilRef ("Stencil Reference Value", Range(0,255)) = 0 
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest("ZTest", Float) = 3 // Compare modes selection.
		_Amplitude ("Amplitude", Float) = 0.0 //Amplitude of waves
		_Speed ("Speed", Float) = 1.0 //How fast vertices move UP and DOWN
		
		//At what height (From bottom) shader should start manipulate vertices (0 - center of the mesh, -0.5 - bottom and 0.5 - top)
		_TransformHeight ("Transform Height", Range(-0.5, 0.5)) = 0.0
	}
	
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200 //Default value for diffuse shader. For more info: https://docs.unity3d.com/Manual/SL-ShaderLOD.html
		
		ZWrite off
		Blend SrcAlpha OneMinusSrcAlpha
		Cull off

		Stencil
		{
			Ref [_StencilRef]
			Comp [_ZTest]
			Pass keep
		}
		Pass{
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"
			
			fixed4 _Color; 
			fixed _Transparency; 
			fixed4 _MainTex_ST; 
	        float _Amplitude;
	        float _Speed;
			fixed _TransformHeight;

			//Noise functions from ShaderGraph
	        float2 unity_gradientNoise_dir(float2 p)
	        {
	            p = p % 289;
	            float x = (34 * p.x + 1) * p.x % 289 + p.y;
	            x = (34 * x + 1) * x % 289;
	            x = frac(x / 41) * 2 - 1;
	            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
	        }

	        float unity_gradientNoise(float2 p)
	        {
	            const float2 ip = floor(p);
	            float2 fp = frac(p);
	            const float d00 = dot(unity_gradientNoise_dir(ip), fp);
	            const float d01 = dot(unity_gradientNoise_dir(ip + float2(0, 1)), fp - float2(0, 1));
	            const float d10 = dot(unity_gradientNoise_dir(ip + float2(1, 0)), fp - float2(1, 0));
	            const float d11 = dot(unity_gradientNoise_dir(ip + float2(1, 1)), fp - float2(1, 1));
	            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
	            return lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x);
	        }

			float Unity_GradientNoise_float(float x)
	        {
	            return unity_gradientNoise(x) + 0.5;
	        }
			
			struct Input
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
			};
			
			v2f vert (Input In)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(In.vertex);
				if (In.vertex.y >= _TransformHeight)
					o.vertex.y += Unity_GradientNoise_float(In.vertex.x * In.vertex.z + _Time * _Speed) * _Amplitude;
				return o;
			}

			fixed4 frag () : SV_Target
			{
				fixed4 col = _Color;
				col.a = _Color.a;
				return col;
			}
			ENDCG
		}
	}

	Fallback "Internal"
}
