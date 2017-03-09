struct GeoToFragConnector
{
  float4 projCoord : POSITION;
  uint vertexID : TEXCOORD0;
};

uint main(GeoToFragConnector g2f) : SV_TARGET0
{
  return g2f.vertexID;
}