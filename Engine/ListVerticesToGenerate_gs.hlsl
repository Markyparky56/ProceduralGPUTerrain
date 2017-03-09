struct VertexToGeoConnector
{
  uint z8y8x8null5edgeFlags3 : TEXCOORD0;
};

struct GeoOutput
{
  uint z8y8x8null4edgeNum4 : TEXCOORD0;
};

[maxvertexcount(3)]
void main(inout PointStream<GeoOutput> Stream, point VertexToGeoConnector input[1])
{
  GeoOutput output;

  uint z8y8x8null8 = input[0].z8y8x8null5edgeFlags3 & 0xFFFFFF00;
  if (input[0].z8y8x8null5edgeFlags3 & 1)
  {
    output.z8y8x8null4edgeNum4 = z8y8x8null8 | 3;
    Stream.Append(output);
  }
  if (input[0].z8y8x8null5edgeFlags3 & 2)
  {
    output.z8y8x8null4edgeNum4 = z8y8x8null8 | 0;
    Stream.Append(output);
  }
  if (input[0].z8y8x8null5edgeFlags3 & 4)
  {
    output.z8y8x8null4edgeNum4 = z8y8x8null8 | 8;
    Stream.Append(output);
  }
  
}