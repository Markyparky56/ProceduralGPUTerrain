// input vert list from stream output

struct VertexInput
{
  uint z8y8x8null4edgeNum4 : TEXCOORD0;
};

struct VertexToGeoConnector
{
  float4 wsCoordAmbo : TEXCOORD0;
  float3 wsNormal : NORMAL0;
};

cbuffer ChunkCB
{
  float3 wsChunkPos = float3(0, 0, 0);
  float opacity = 1;
};

Texture3D densityVolume;
Texture3D noiseVol0;
Texture3D noiseVol1;
Texture3D noiseVol2;
Texture3D noiseVol3;
Texture3D packedNoiseVol0;
Texture3D packedNoiseVol1;
Texture3D packedNoiseVol2;
Texture3D packedNoiseVol3;
SamplerState LinearClamp;
SamplerState NearestClamp;
SamplerState LinearRepeat;
SamplerState NearestRepeat;

#include "Master.hlsli"
#include "LodCB.hlsli"
#define EVAL_CHEAP 1
#include "Density.hlsli"

cbuffer g_MCLUT
{
  uint caseToNumpolys[256];
  float3 edgeStart[12];
  float3 edgeDir[12];
  float3 edgeEnd[12];
  uint edgeAxis[12]; // 0 for x edges, 1 for y edges, 2 for z edges
};

#define AMBO_STEPS 16
cbuffer g_AMBOLUT
{
  float amboDist[16];
  float4 occlusionAmt[16];
  float3 rayDirs32[32];
  float3 rayDirs64[64];
  float3 rayDirs256[256];
};

#if (AMBO_RAYS==32)
#define rayDirs rayDirs32
#elif(AMBO_RAYS==64)
#define rayDirs rayDirs64
#elif(AMBO_RAYS==256)
#define rayDirs rayDirs256
#else
  ERROR // ruh-roh
#endif

struct vertex
{
  float4 worldCoordAmbo : POSITION; // .w occlusion
  float3 worldNormalMisc : NORMAL;
};

vertex PlaceVertOnEdge(float3 wsCoord_LL, float3 uvw_LL, int edgeNum)
{
  vertex output;

  // Get the density values at the two ends of this edge of the cell,
  // then interpolate to find the point (t in 0..1) along the edge
  // where the density value hits zero
  float str0 = densityVolume.SampleLevel(NearestClamp, uvw_LL + InvVoxelDimPlusMarginsMinusOne.xxx*edgeStart[edgeNum], 0).x;
  float str1 = densityVolume.SampleLevel(NearestClamp, uvw_LL + InvVoxelDimPlusMarginsMinusOne.xxx*edgeEnd[edgeNum], 0).x;
  float t = saturate(str0 / (str0 - str1)); // Saturate keeps occasional stray triangle appearing @ edges

  // Reconstruct the interpolate point & place a vertex there
  float3 posWithinCell = edgeStart[edgeNum] + t.xxx * edgeDir[edgeNum]; // 0..1
  float3 wsCoord = wsCoord_LL + posWithinCell*wsVoxelSize.xxx;
  float3 uvw = uvw_LL + posWithinCell*InvVoxelDimPlusMarginsMinusOne.xxx;

  output.worldCoordAmbo.xyz = wsCoord.xyz;

  // Generate ambient occlusion for this vertex
  float ambo;
  {
    const float cellsToSkipAtRayStart = 1.25;
    float AMBO_RAY_DIST_CELLS = VoxelDimPlusMargins * 0.25;

    // So that ambo looks the same if we change the voxel dim
    float3 invVoxelDimTweaked = InvVoxelDimPlusMargins.xxx * VoxelDimPlusMargins / 160.0;

    for (int i = 0; i < AMBO_RAYS; i++)
    {
      float3 rayDir = rayDirs[i];
      float3 rayStart = uvw;
      float3 rayNow = rayStart + rayDir*InvVoxelDimPlusMargins.xxx*cellsToSkipAtRayStart; // Start a little out along the ray
      float3 rayDelta = rayDir*invVoxelDimTweaked*AMBO_RAY_DIST_CELLS.xxx;

      float amboThis = 1;

      // Short Range:
      // - step along the ray at AMBO_STEPS points, sampling the density volume texture
      // - occlusionAmt[] LUT makes closer occlusions have more weight than far ones
      // - start sampling a few cells away from the vertex to reduce noise
      rayDelta *= (1.0 / (AMBO_STEPS));
      for (int j = 0; j < AMBO_STEPS; j++)
      {
        rayNow += rayDelta;
        float t = densityVolume.SampleLevel(LinearClamp, rayNow, 0);
        amboThis = lerp(amboThis, 0, saturate(t * 6)*occlusionAmt[j].z);
      }

      // Long Range
      // - Also take a few samples far away, using the density function (not volume)
      for (int k = 0; k < 5; k++)
      {
        // Be sure to start some distance away, 
        // otherwise same vertex in different LODs might have different brightness
        // due to density function LOD bias
        float distance = (k + 2) / 5.0;
        distance = pow(distance, 1.8);
        distance *= 40;
        float t = Density(wsCoord + rayDir*distance);
        const float shadowHardness = 0.5;
        amboThis *= 0.1 + 0.9*saturate(-t*shadowHardness + 0.3);
      }

      amboThis *= 1.4;

      ambo += amboThis;
    }
    ambo *= (1.0 / AMBO_RAYS);
  }
  output.worldCoordAmbo.w = ambo;

  // Figure out the normal vector for this vertex
  float3 grad;
  grad.x =  densityVolume.SampleLevel(LinearClamp, uvw + InvVoxelDimPlusMargins.xyy, 0)
          - densityVolume.SampleLevel(LinearClamp, uvw - InvVoxelDimPlusMargins.xyy, 0);
  grad.y =  densityVolume.SampleLevel(LinearClamp, uvw + InvVoxelDimPlusMargins.yxy, 0)
          - densityVolume.SampleLevel(LinearClamp, uvw - InvVoxelDimPlusMargins.yxy, 0);
  grad.z =  densityVolume.SampleLevel(LinearClamp, uvw + InvVoxelDimPlusMargins.yyx, 0)
          - densityVolume.SampleLevel(LinearClamp, uvw - InvVoxelDimPlusMargins.yyx, 0);
  output.worldNormalMisc.xyz = -normalize(grad);

  return output;
}

VertexToGeoConnector main(VertexInput input)
{
  uint3 unpackedCoord;
  unpackedCoord.x = (input.z8y8x8null4edgeNum4 >> 8) & 0xFF;
  unpackedCoord.y = (input.z8y8x8null4edgeNum4 >> 16) & 0xFF;
  unpackedCoord.z = (input.z8y8x8null4edgeNum4 >> 24) & 0xFF;
  float3 chunkCoordWrite = (float3)unpackedCoord * InvVoxelDimMinusOne.xxx;
  float3 chunkCoordRead = (Margin + VoxelDimMinusOne*chunkCoordWrite)*InvVoxelDimPlusMarginsMinusOne.xxx;

  float3 wsCoord = wsChunkPos + chunkCoordWrite*wsChunkSize;

  float3 uvw = chunkCoordRead + InvVoxelDimPlusMarginsMinusOne.xxx*0.25;
  uvw.xyz *= (VoxelDimPlusMargins.x - 1)*InvVoxelDimPlusMargins.x;

  // Generate a vertex along this edge
  int edgeNum = (input.z8y8x8null4edgeNum4 & 0x0F);
  vertex v = PlaceVertOnEdge(wsCoord, uvw, edgeNum);

  VertexToGeoConnector v2g;
  v2g.wsCoordAmbo = v.worldCoordAmbo;
  v2g.wsNormal = v.worldNormalMisc;
  return v2g;
}
