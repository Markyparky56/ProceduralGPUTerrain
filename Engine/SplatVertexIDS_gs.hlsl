// VS can't specify SV_RenderTargetArrayIndex so we pass through the geometry shader to set it

struct VertexToGeoConnector
{
  float4 projCoord : POSITION;
  uint2 vertexIDandSlice : TEXCOORD0;
};

struct GeoToFragConnector
{
  float4 projCoord : POSITION;
  uint vertexID : TEXCOORD0;
  uint RTIndex : SV_RenderTargetArrayIndex;
};

[maxvertexcount(1)]
void main(point VertexToGeoConnector input[1], inout PointStream<GeoToFragConnector> Stream)
{
  GeoToFragConnector g2f;
  g2f.projCoord = input[0].projCoord;
  g2f.vertexID = input[0].vertexIDandSlice.x;
  g2f.RTIndex = input[0].vertexIDandSlice.y;
  Stream.Append(g2f);
}