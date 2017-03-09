struct VertexToGeoConnector
{
  float4 position : POSITION;
  uint nInstanceID : TEXCOORD;
};

struct GeoToFragConnector
{
  float4 position : POSITION;
  uint RTIndex : SV_RenderTargetArrayIndex;
};

[maxvertexcount(3)]
void main(triangle VertexToGeoConnector input[3], inout TriangleStream<GeoToFragConnector> Stream)
{
  for (int i = 0; i < 3; i++)
  {
    GeoToFragConnector g2f;
    g2f.position = input[i].position;
    g2f.RTIndex = input[i].nInstanceID;
    Stream.Append(g2f);
  }
  Stream.RestartStrip();
}
