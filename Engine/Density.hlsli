#include "SampleNoise.hlsli"

float3 rot(float3 coord, float4x4 mat)
{
  return float3(dot(mat._11_12_13, coord),
                dot(mat._21_22_23, coord),
                dot(mat._31_32_33, coord));
}

float smoothSnap(float t, float m)
{
  // input t in [0..1]
  // maps input to an output that goes from 0..1,
  // but spends most of its time at 0 or 1, except for
  // a quick, smooth ump from 0 to 1 around input values of 0.5.
  // the slope of the jump is roughly determined by 'm'
  // note: 'm' shouldn't shouldn't go over ~16 or so because percision breaks down

  float c = (t > 0.5) ? 1 : 0;
  float s = 1 - c * 2;
  return c + s*pow((c + s*t) * 2, m)*0.5;
}

float Density(float3 ws)
{
  // This function determines the shape of the terrain

  float3 wsOrig = ws;

  // Start at 0
  // Pisition values are inside the terrain, negative are outside (air)
  float density = 0;

  // Sample ultra-ultra-low-frequency noise to vary high-level terrain features
  float4 uulfRand = saturate(NMQu(ws*0.000718, noiseVol0) * 2 - 0.5);
  float4 uulfRand2 = NMQu(ws*0.000632, noiseVol1);
  float3 uulfRand3 = NMQu(ws*0.000695, noiseVol2);

  // Pre-Warp the world-space cooridnate
  const float prewarpStrength = 25; // recommended range 5..25
  float3 ulfRand = 0;
  ulfRand.x = NHQs(ws*0.0041*0.971, packedNoiseVol2, 1)*0.64 + NHQs(ws*0.0041*0.461, packedNoiseVol3, 1)*0.32;
  ulfRand.y = NHQs(ws*0.0041*0.997, packedNoiseVol1, 1)*0.64 + NHQs(ws*0.0041*0.453, packedNoiseVol0, 1)*0.32;
  ulfRand.z = NHQs(ws*0.0041*1.032, packedNoiseVol3, 1)*0.64 + NHQs(ws*0.0041*0.511, packedNoiseVol2, 1)*0.32;
  ws += ulfRand.xyz * prewarpStrength * saturate(uulfRand3.x*1.4f - 0.3);

  // Compute 8 randomly rotated versions of 'ws'
  float3 c0 = rot(ws, octaveMat0);
  float3 c1 = rot(ws, octaveMat1);
  float3 c2 = rot(ws, octaveMat2);
  float3 c3 = rot(ws, octaveMat3);
  float3 c4 = rot(ws, octaveMat4);
  float3 c5 = rot(ws, octaveMat5);
  float3 c6 = rot(ws, octaveMat6);
  float3 c7 = rot(ws, octaveMat7);

  // Main shape
  density = -ws.y;
  density += saturate((-4 - wsOrig.y*0.3)*3.0) * 40 * uulfRand2.z;

#ifdef EVAL_CHEAP
  float HFM = 0;
#else
  float HFM = 1;
#endif

  density += (
              0
              + NLQs(ws*0.1600*1.021, noiseVol1).x*0.32*1.16 * HFM
              + NLQs(ws*0.0800*0.985, noiseVol2).x*0.64*0.12 * HFM
              + NLQs(ws*0.0400*1.051, noiseVol0).x*1.28*1.08 * HFM
              + NLQs(ws*0.0200*1.020, noiseVol1).x*2.56*1.04
              + NLQs(ws*0.0100*0.968, noiseVol3).x*5
              + NMQs(ws*0.0050*0.994, noiseVol0).x*10*1.0 // MQ
              + NMQs(c6*0.0025*1.045, noiseVol2).x*20*0.9 // MQ
              + NHQs(c7*0.0012*0.972, packedNoiseVol3).x*40*0.8 // HQ and rotated
             );

  // LOD Density Bias
  // Shrink the lo and med res chunks a bit
  density -= wsChunkSize.x*0.009;

  return density;
}
