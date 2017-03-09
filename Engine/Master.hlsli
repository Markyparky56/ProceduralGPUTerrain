#define MAX_INSTANCES       256
#define NOISE_LATTICE_SIZE  16

#define FOG_COLOUR float3(0.161, 0.322, 0.588);

#define INV_LATTICE_SIZE (1.0/(float)(NOISE_LATTICE_SIZE))

#define AMBO_RAYS 32

#define MAX_AMBO_RAY_DIST_CELLS 24

cbuffer g_GlobalRockCB
{
  float4x4 octaveMat0;
  float4x4 octaveMat1;
  float4x4 octaveMat2;
  float4x4 octaveMat3;
  float4x4 octaveMat4;
  float4x4 octaveMat5;
  float4x4 octaveMat6;
  float4x4 octaveMat7;

  float4 timeValues;
  float3 wsEyePos;
  float3 wsEyeLookAt;
};

float3 vecMul(float4x4 m, float3 v)
{
  return float3(dot(m._11_12_13, v), dot(m._21_22_23, v), dot(m._31_32_33, v));
}
float  smoothy(float  t) { return t*t*(3 - 2 * t); }
float2 smoothy(float2 t) { return t*t*(3 - 2 * t); }
float3 smoothy(float3 t) { return t*t*(3 - 2 * t); }
float4 smoothy(float4 t) { return t*t*(3 - 2 * t); }
