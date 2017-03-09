// input vert list from stream output

#include "LodCB.hlsli"

struct VertexInput
{
  uint z8y8x8null4edgeNum4 : TEXCOORD0;
  uint nVertexID : SV_VERTEXID;
};

struct VertexToGeoConnector
{
  float4 projCoord : POSITION;
  uint2 vertexIDandSlice :TEXCOORD0;
};

VertexToGeoConnector main(VertexInput input)
{
  uint edgeNum = input.z8y8x8null4edgeNum4 & 0x0F;
  int3 xyz = (int3)((input.z8y8x8null4edgeNum4.xxx >> uint3(8, 16, 24)) & 0xFF);

  // Every vertex coming in here is on edge 3, 0 or 8 (lower left edges of the cells)
  xyz.x *= 3;
  if (edgeNum == 3)
  {
    xyz.x += 0;
  }
  if (edgeNum == 0)
  {
    xyz.x += 1;
  }
  if (edgeNum == 8)
  {
    xyz.x += 2;
  }

  float2 uv = (float2)xyz.xy;
  // Alignment fix (for nearest neighbour sampling
  uv.x += 0.5*InvVoxelDim.x / 3.0;
  uv.y += 0.5*InvVoxelDim.x / 1.0;

  VertexToGeoConnector v2g;
  v2g.projCoord.x = (uv.x*InvVoxelDim.x / 3.0) * 2 - 1; // -1..1 range
  v2g.projCoord.y = (uv.y*InvVoxelDim.x) * 2 - 1; // -1..1 range
  // Fix upside-down projection:
  v2g.projCoord.y *= -1;
  v2g.projCoord.z = 0;
  v2g.projCoord.w = 1;
  v2g.vertexIDandSlice.x = input.nVertexID;
  v2g.vertexIDandSlice.y = xyz.z;

  return v2g;
}
