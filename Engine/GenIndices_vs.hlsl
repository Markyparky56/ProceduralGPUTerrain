// input nonempty cell list

struct VertexInput
{
  uint z8y8x8case8 : TEXCOORD0;
};

struct VertexToGeoConnector
{
  uint z8y8x8case8 : TEXCOORD0;
};

VertexToGeoConnector main(VertexInput input)
{
  VertexToGeoConnector v2g;
  v2g.z8y8x8case8 = input.z8y8x8case8;
  return v2g;
}
