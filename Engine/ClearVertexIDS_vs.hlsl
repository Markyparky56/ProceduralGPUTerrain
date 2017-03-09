struct VertexInput
{
  float3 objCoord : POSITION;
  float2 tex : TEXCOORD;
  uint nInstanceID : SV_InstanceID;
};

struct VertexToGeoConnector
{
  float4 position : POSITION;
  uint nInstanceID : TEXCOORD;
};

VertexToGeoConnector main(VertexInput input)
{
  VertexToGeoConnector output;
  float4 projCoord = float4(input.objCoord.xyz, 1);
  projCoord.y *= -1;

  output.position = projCoord;
  output.nInstanceID = input.nInstanceID;
  return output;
}