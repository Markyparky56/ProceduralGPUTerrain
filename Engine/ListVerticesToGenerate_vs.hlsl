// Input nonempty cell list from the stream output

struct VertexInput
{
  uint z8y8x8case8 : TEXCOORD0;
};

struct VertexToGeoConnector
{
  uint z8y8x8null5edgeFlags3 : TEXCOORD0;
};

VertexToGeoConnector main(VertexInput input)
{
  int cubeCase = (int)(input.z8y8x8case8 & 0xFF);
  int bit0 = (cubeCase) & 1;
  int bit3 = (cubeCase >> 3) & 1;
  int bit1 = (cubeCase >> 1) & 1;
  int bit4 = (cubeCase >> 4) & 1;
  int3 buildVertOnEdge = abs(int3(bit3, bit1, bit4) - bit0.xxx);

  uint bits = input.z8y8x8case8 & 0xFFFFFF00; // Pack the position into the last 24 bits
  if (buildVertOnEdge.x != 0)
  {
    bits |= 1;
  }
  if (buildVertOnEdge.y != 0)
  {
    bits |= 2;
  }
  if (buildVertOnEdge.z != 0)
  {
    bits |= 4;
  }

  VertexToGeoConnector v2g;
  v2g.z8y8x8null5edgeFlags3 = bits;
  return v2g;
}
