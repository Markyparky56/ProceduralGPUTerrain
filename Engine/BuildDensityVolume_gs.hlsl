// The VS Can't specify SV_RenderTargetArrayIndex, so we have to do it here

struct VertexToGeoConnector
{
  float4 projCoord : POSITON;
  float4 wsCoord : TEXCOORD;
  float3 chunkCoord : TEXCOORD1;
  uint nInstanceID : TEXCOORD2;
};

struct GeoToFragConnector
{
  float4 projCoord : POSITION;
  float3 wsCoord : TEXCOORD;
  float3 chunkCoord : TEXCOORD1;
  uint RTIndex : SV_RenderTargetarrayIndex;
};

[maxvertexcount(3)]
void main(triangle VertexToGeoConnector input[3], inout TriangleStream<GeoToFragConnector> Stream)
{
  for (int v = 0; v < 3; v++)
  {
    GeoToFragConnector g2f;
    g2f.projCoord = input[v].projCoord;
    g2f.wsCoord = input[v].wsCoord;
    g2f.RTIndex = input[v].nInstanceID;
    g2f.chunkCoord = input[v].chunkCoord;
    Stream.Append(g2f);
  }
  Stream.RestartStrip();
}
