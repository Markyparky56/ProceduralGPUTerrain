#include "Master.hlsli"

struct VertexToFragConnector
{
  float4 position : POSITION;
  float4 wsCoordAmbo : TEXCOORD;
  float3 wsNormal : TEXCOORD1;
};

cbuffer ColourCB
{
  float3 colour = 1;
};

cbuffer ShaderCB
{
  float g_opacity = 1;
  float4 time;
  float3 worldEyePos;
};

cbuffer ChunkCB
{
  float3 wsChunkPos = float3(0, 0, 0); // wsCoord of lower-left corner
  float opacity = 1;
};

cbuffer SliderCB
{
  float bumpScale;
  float bumpFreq;
  float fogDensity;
  float diffuseLight;
  float specLight;
  float lightWrap;
  float ambientOcclusion;
  float colourSaturation;
};

Texture3D noiseVol0;
Texture3D noiseVol1;
Texture3D noiseVol2;
Texture3D noiseVol3;
Texture3D packedNoiseVol0;
Texture3D packedNoiseVol1;
Texture3D packedNoiseVol2;
Texture3D packedNoiseVol3;
Texture2D AltColourRamp;
SamplerState LinearClamp;
SamplerState LinearRepeat;
SamplerState NearestClamp;
SamplerState NearestRepeat;

#include "LodCB.hlsli"
#include "Density.hlsli"

float4 main(VertexToFragConnector v2f) : SV_TARGET
{
  float op = g_opacity*opacity;
  
  float4 wsCoordAmbo = v2f.wsCoordAmbo;
  float3 ws = wsCoordAmbo.xyz;
  float fog = saturate(length(worldEyePos.xyz - ws)*0.0033*fogDensity.x);
  fog = pow(fog, 1.1);

  float3 noiseCoord1 = mul(octaveMat1, ws).xyz;
  float3 noiseCoord2 = mul(octaveMat2, ws).xyz;
  float3 noiseCoord3 = ws;

  float3 N = normalize(v2f.wsNormal);

  // This ultra-ultra-low-frequency noise sample will guide
  // our texturing. It varies slowly over XZ, quickly over Y (up & down)
  // so that the texturing can drastically vary with altitude (even at the same XZ coords)
  float4 uulfRand = noiseVol2.Sample(LinearRepeat, noiseCoord3.xyz*0.00053*float3(1, 10, 1));

  // Noise
#define NOISE_FREQ 1.7*0.32*bumpFreq.x
  float3 s = 0;
  s += (noiseVol3.Sample(LinearRepeat, noiseCoord1*(NOISE_FREQ) * 1 * 0.97) * 2 - 1)*pow(0.75, 0);
  s += (noiseVol2.Sample(LinearRepeat, noiseCoord2*(NOISE_FREQ) * 2 * 1.03) * 2 - 1)*pow(0.75, 1);
  s += (noiseVol1.Sample(LinearRepeat, noiseCoord3*(NOISE_FREQ) * 4 * 0.99) * 2 - 1)*pow(0.75, 2);
  N = normalize(N + 0.25*s.xyz*0.5*bumpScale.x);

  float3 light;
  // light = 0.6 + 0.4*N; // Cheap green-red lighting
  // light = 0.6 * 0.4*saturate(N*0.6 + 0.4); // Cheap yellow lighting
  light = (saturate(0.05 + 0.95*dot(N, normalize(float3(0.7, 0.3, 0.7)))) * float3(1.05, 0.97, 0.5) + saturate(lightWrap.x + (1 - lightWrap.x)*dot(N, normalize(float3(-0.8, 0.8, -0.2)))) * float3(0.97, 1.0, 1.13));
  light *= diffuseLight.xxx;

  float3 surfaceColour;
  {
    // Striations 
    float u = uulfRand.x*1.2 - 0.1;
    float v = ws.y*0.03 + 0.5;
    float3 altColour = AltColourRamp.Sample(LinearRepeat, float2(saturate(u), v)).xyz;
    // Take another sample at higher frequency on Y
    // Blending them is like having a detail texture for the striations
    u += uulfRand.w * 0.2 - 0.1 + N.y*0.2;
    v *= -9.13;
    float3 altColour2 = AltColourRamp.Sample(LinearRepeat, float2(saturate(u), v)).xyz;
    altColour = lerp(altColour, altColour, 0.4);
    // Increase contrast
    altColour = lerp(0.7, altColour, 2.8*saturate(uulfRand.z * 2 - 0.4));
    surfaceColour = altColour;

    // GAMMA DE-CORRECT SURFACE COLOR PRIOR TO LIGHTING:
    // take sqrt here of any colors you sampled from color maps!
    // when an artist paints a color map or you take a photo, 
    // it is already gamma-adjusted to look good on
    // a very nonlinear monitor.  To do proper lighting, we
    // have to roughly take the square root of the color value first.
    // At the end of the lighting, we re-square it, so that the "real"
    // color looks good on the nonlinear monitor again.
    //surface_color = sqrt(surface_color);
  }

  float ambo = saturate(lerp(0.5, wsCoordAmbo.w, ambientOcclusion.x)*2.1 - 0.1);
  float3 litColour = light*ambo*surfaceColour;

  // Spec Light (faked)
  float3 E = normalize(worldEyePos.xyz - ws);
  float3 R = normalize(2 * N*dot(E, N) - E);
  float spec = saturate(R.y);
  litColour += pow(spec, 16) * 0.12 * float3(0.7, 0.8, 1.0) * saturate(ambo*1.5 - 0.5) * specLight.xxx;
  float3 foggedColour = lerp(litColour, float3(0.8, 0.8, 0.8), fog);

  // GAMMA RE-CORRECT PRIOR TO LIGHTING:
  // if you gamma-corrected the surface color @ top of shader,
  // then restore it here:
  //fogged_col *= fogged_col;

  return float4(foggedColour, op);
}
