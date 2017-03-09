#include "LodCB.hlsli"

struct VertexToGeoConnector
{
  uint z8y8x8case8 : TEXCOORD0;
};

struct GeoOutput
{
  uint index : TEXCOORD0;
};

cbuffer g_MCLUT
{
  uint caseToNumpolys[256];
  float3 edgeStart[12];
  float3 edgeDor[12];
  float3 edgeEnd[12];
  uint edgeAxis[12]; // 0 for x edges, 1 for y edges, 2 for z edges
};

cbuffer g_MCLUT2
{
  int4 triTable[1280]; // 256*5 = 1024 (256 cases, up to 15 (0/3/6/9/12/15) vers output for each)
};

Texture3D<uint> VertexIDVol;
SamplerState NearestClamp;

[maxvertexcount(15)]
void main(inout TriangleStream<GeoOutput> Stream, point VertexToGeoConnector input[1])
{
  uint cubeCase = (input[0].z8y8x8case8 & 0xFF);
  uint numPolys = caseToNumpolys[cubeCase];
  int3 xyz = (int3)((input[0].z8y8x8case8.xxx >> uint3(8, 16, 24)) & 0xFF);

  // Don't generate polys in the final layer (in XY / YZ / ZX) of phantom cells
  if (max(max(xyz.x, xyz.y), xyz.z) >= (uint)VoxelDimMinusOne.x)
  {
    numPolys = 0;
  }

  for (uint i = 0; i < numPolys; i++)
  {
    // range: 0-11
    int3 edgeNumsForTriangle = triTable[cubeCase * 5 + i].xyz;

    // Sample the 3D VertexIDVol texture to get the vertex IDs for those vertices

    int3 xyzEdge;
    int3 VertexID;

    xyzEdge = xyz + (int3)edgeStart[edgeNumsForTriangle.x].xyz;
    xyzEdge.x = xyzEdge.x * 3 + edgeAxis[edgeNumsForTriangle.x].x;
    VertexID.x = VertexIDVol.Load(int4(xyzEdge, 0)).x;

    xyzEdge = xyz + (int3)edgeStart[edgeNumsForTriangle.y].xyz;
    xyzEdge.x = xyzEdge.x * 3 + edgeAxis[edgeNumsForTriangle.y].x;
    VertexID.y = VertexIDVol.Load(int4(xyzEdge, 0)).x;

    xyzEdge = xyz + (int3)edgeStart[edgeNumsForTriangle.z].xyz;
    xyzEdge.x = xyzEdge.x * 3 + edgeAxis[edgeNumsForTriangle.z].x;
    VertexID.z = VertexIDVol.Load(int4(xyzEdge, 0)).x;

    // If none of the IDs are zero there were no invalid indices
    GeoOutput output;
    output.index = VertexID.x;
    Stream.Append(output);
    output.index = VertexID.y;
    Stream.Append(output);
    output.index = VertexID.z;
    Stream.Append(output);
    Stream.RestartStrip();
  }
}
