#ifndef SAMPLE_NOISE
#define SAMPLE_NOISE 1

// Helper functions for sampling noise volumes
// NLQu   Sample Noise, Low Quality, unsigned
// NLQs   Sample Noise, Low Quality, signed
// NMQu   Sample Noise, Medium Quality, unsigned
// NMQs   Sample Noise, Medium Quality, signed
// NHQu   Sample Noise, High Quality, unsigned
// NHQs   Sample Noise, High Quality, signed

float4 NLQu(float3 uvw, Texture3D noiseTex)
{
  return noiseTex.SampleLevel(LinearRepeat, uvw, 0);
}

float4 NLQs(float3 uvw, Texture3D noiseTex)
{
  return NLQu(uvw, noiseTex) * 2 - 1;
}

float4 NMQu(float3 uvw, Texture3D noiseTex)
{
  // Smooth the input coord
  float3 t = frac(uvw * NOISE_LATTICE_SIZE + 0.5);
  float3 t2 = (3 - 2 * t)*t*t;
  float3 uvw2 = uvw + (t2 - 2) / (float)(NOISE_LATTICE_SIZE);
  return NLQu(uvw2, noiseTex);
}

float4 NMQs(float3 uvw, Texture3D noiseTex)
{
  // Smooth the input coord
  float3 t = frac(uvw * NOISE_LATTICE_SIZE + 0.5);
  float3 t2 = (3 - 2 * t)*t*t;
  float3 uvw2 = uvw + (t2 - 2) / (float)(NOISE_LATTICE_SIZE);
  return NLQs(uvw2, noiseTex);
}

float NHQu(float3 uvw, Texture3D tex, float smooth = 1)
{
  float3 uvw2 = floor(uvw * NOISE_LATTICE_SIZE) * INV_LATTICE_SIZE;
  float3 t = (uvw - uvw2) * NOISE_LATTICE_SIZE;
  t = lerp(t, t*t*(3 - 2 * t), smooth);

  float2 d = float2(INV_LATTICE_SIZE, 0);

  float4 f1 = tex.SampleLevel(NearestRepeat, uvw2, 0).zxyw; // <+0 +y +z +yz>
  float4 f2 = tex.SampleLevel(NearestRepeat, uvw2 + d.xyy, 0); // <+x +xy +xz +xyz>
  float4 f3 = lerp(f1, f2, t.xxxx); // f3 = <+0 +y +z +yz>
  float2 f4 = lerp(f3.xy, f3.zw, t.yy); // f4 = <+0 +z>
  float f5 = lerp(f4.x, f4.y, t.z);

  return f5;
}

float NHQs(float3 uvw, Texture3D tex, float smooth = 1)
{
  return NHQu(uvw, tex, smooth) * 2 - 1;
}

#endif