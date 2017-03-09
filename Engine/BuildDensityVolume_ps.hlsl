#include "Master.hlsli"

struct GeoToFragConnector
{
  float4 projCoord : POSITION;
  float3 wsCoord : TEXCOORD;
  float3 chunkCoord : TEXCOORD1; // Not used?
  uint RTIndex : SV_RenderTargetarrayIndex;
};

Texture3D noiseVol0;
Texture3D noiseVol1;
Texture3D noiseVol2;
Texture3D noiseVol3;
Texture3D packedNoiseVol0;
Texture3D packedNoiseVol1;
Texture3D packedNoiseVol2;
Texture3D packedNoiseVol3;
SamplerState LinearRepeat;
SamplerState NearestClamp;
SamplerState NearestRepeat;
SamplerState LinearClamp;

#include "LodCB.hlsli"
#include "Density.hlsli"

float main(GeoToFragConnector g2f) : SV_TARGET0
{
  float ret = Density(g2f.wsCoord.xyz);
  return ret;
}
