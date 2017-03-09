struct VertexToGeoConnector
{
  uint z8y8x8case8 : TEXCOORD0;
};

struct GeoOutput
{
  uint z8y8x8case8 : TEXCOORD0;
};

[maxvertexcount(1)]
void main(inout PointStream<GeoOutput> Stream, point VertexToGeoConnector input[1])
{
  uint cubeCase = (input[0].z8y8x8case8 & 0xFF);
  if (cubeCase * (255 - cubeCase) > 0)
  {
    GeoOutput output;
    output.z8y8x8case8 = input[0].z8y8x8case8;
    Stream.Append(output);
  }
}
