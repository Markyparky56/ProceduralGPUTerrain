// Stream out

struct VertexToGeoConnector
{
  float4 wsCoordAmbo : TEXCOORD0;
  float3 wsNormal : NORMAL0;
};

struct GeoOutput
{
  float4 worldCoordAmbo : POSITION; // .w = occlusion
  float4 worldNormal : NORMAL;
};

[maxvertexcount(1)]
void main(inout PointStream<GeoOutput> Stream, point VertexToGeoConnector input[1])
{
  GeoOutput output;
  output.worldCoordAmbo = input[0].wsCoordAmbo;
  output.worldNormal = float4(input[0].wsNormal, 0);
  Stream.Append(output);
}