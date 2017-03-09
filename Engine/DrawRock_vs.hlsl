#include "Master.hlsli"

struct VertexInput
{
  uint index : TEXCOORD0;
  uint nVertexID : SV_VertexID;
};

struct VertexToFragConnector
{
  float4 position : POSITION;
  float4 wsCoordAmbo : TEXCOORD;
  float3 wsNormal : TEXCOORD1;
};

Buffer<float4> vbWorldCoordAmbo;
Buffer<float4> vbWorldNorm;

cbuffer ShaderCB
{
  float4x4 view;
  float4x4 viewProj;
  float4 worldEyePos = float4(0, 0, 0, 0);
  float4 time;
  float zBias;
  float3 padding;//?
};

VertexToFragConnector main(VertexInput input)
{
  float4 worldCoordAmbo = vbWorldCoordAmbo.Load(input.index);
  float3 worldNorm = vbWorldNorm.Load(input.index).xyz;

  float3 worldCoord = worldCoordAmbo.xyz;
  float3 worldCoordForProj = worldCoord;

  // Apply z bias to prioritise drawing of higher LODs
  // Can cause divide by zero for close polys
  float3 wsVecToPnt = normalize(worldCoord - worldEyePos.xyz);
  worldCoordForProj += wsVecToPnt * zBias * 3;

  float4 projCoord = mul(viewProj, float4(worldCoordForProj, 1));

  VertexToFragConnector v2f;
  v2f.position = projCoord;
  v2f.wsCoordAmbo = worldCoordAmbo;
  v2f.wsNormal = worldNorm;

  return v2f;
}
