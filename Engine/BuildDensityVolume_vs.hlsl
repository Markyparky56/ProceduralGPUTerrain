#include "Master.hlsli"

struct VertexInput
{
  float3 objCoord : POSITION;
  float2 tex      : TEXCOORD;
  uint nInstanceID : SV_InstanceID;
};

struct VertexToGeoConnector
{
  float4 projCoord : POSITON;
  float4 wsCoord : TEXCOORD;
  float3 chunkCoord : TEXCOORD1;
  uint nInstanceID : TEXCOORD2;
};

cbuffer ChunkCB
{
  float3 wsChunkPos = float3(0, 0, 0);
  float opacity = 1;
};

float3 rot(float3 coord, float4x4 mat)
{
  return float3(dot(mat._11_12_13, coord),
                dot(mat._21_22_23, coord),
                dot(mat._31_32_33, coord));
}

#include "LodCB.hlsli"

VertexToGeoConnector main(VertexInput input)
{
  VertexToGeoConnector output;
  float4 projCoord = float4(input.objCoord.xy, 0.5, 1);
  projCoord.y *= -1; // Flip Y coord

  // chunkCoord is in [0..1] range
  float3 chunkCoord = float3(input.tex.xy, input.nInstanceID * InvVoxelDimPlusMargins.x);

  // Multiply by 65/64?
  chunkCoord.xyz *= VoxelDim.x*InvVoxelDimMinusOne.x;

  // extChunkCoord goes outside that range so we also compute some voxels outside of the chunk
  float3 extChunkCoord = (chunkCoord*VoxelDimPlusMargins.x - Margin)*InvVoxelDim.x;

  float3 ws = wsChunkPos + extChunkCoord*wsChunkSize;
  output.projCoord = projCoord;
  output.wsCoord = float4(ws, 1);
  output.nInstanceID = input.nInstanceID;
  output.chunkCoord = chunkCoord;

  return output;
}
