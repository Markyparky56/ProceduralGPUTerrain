// Input dummy cells

#include "Master.hlsli"

// Input around 63x63 points, one for each cell we'll run marching cubes on
// If the VoxelDim is 65 (65 corners, 64 cells) and the Margin is 4
// Then the points we actually get are [4..67]

struct VertexInput
{
  float2 uvWrite : POSITION; // 0..1 range
  float2 uvRead : POSITION2; // less - where to read the source texels - factors in margins
  uint nInstanceID : SV_InstanceID;
};

struct VertexToGeoConnector
{
  uint z8y8x8case8 : TEXCOORD0;
};

cbuffer ChunkCB
{
  float3 wsChunkPos = float3(0, 0, 0);
  float opacity = 1;
};

#include "LodCB.hlsli"

Texture3D densityVolume;
SamplerState LinearClamp;
SamplerState NearestClamp;

VertexToGeoConnector main(VertexInput input)
{
  int inst = input.nInstanceID;

  float3 chunkCoordRead = float3(input.uvRead.x, 
                                 input.uvRead.y, 
                                 (input.nInstanceID + Margin)*InvVoxelDimPlusMargins.x);
  float3 chunkCoordWrite = float3(input.uvWrite.x, input.uvWrite.y, input.nInstanceID*InvVoxelDim.x);
  float3 wsCoord = wsChunkPos + chunkCoordWrite*wsChunkSize; // Apparently this line needs fixed?

  float3 uvw = chunkCoordRead + InvVoxelDimPlusMarginsMinusOne.xxx * 0.125;
  uvw.xy *= ((VoxelDimPlusMargins.x - 1)*InvVoxelDimPlusMargins.x).xx;

  float4 field0123;
  float4 field4567;

  field0123.x = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.yyy, 0).x;
  field0123.y = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.yxy, 0).x;
  field0123.z = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.xxy, 0).x;
  field0123.w = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.xyy, 0).x;
  field4567.x = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.yyx, 0).x;
  field4567.y = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.yxx, 0).x;
  field4567.z = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.xxx, 0).x;
  field4567.w = densityVolume.SampleLevel(NearestClamp, uvw + InvVoxelDimPlusMarginsMinusOne.xyx, 0).x;

  uint4 i0123 = (uint4)saturate(field0123 * 99999);
  uint4 i4567 = (uint4)saturate(field4567 * 99999);
  int cubeCase = (i0123.x     ) | (i0123.y << 1) | (i0123.z << 2) | (i0123.w << 3) |
                 (i4567.x << 4) | (i4567.y << 5) | (i4567.z << 6) | (i4567.w << 7);

  VertexToGeoConnector v2g;
  uint3 uint3Coord = uint3(input.uvWrite.xy * VoxelDimMinusOne.xx, input.nInstanceID);

  v2g.z8y8x8case8 = (uint3Coord.z << 24) | (uint3Coord.y << 16) | (uint3Coord.x << 8) | cubeCase;
  return v2g;
}
