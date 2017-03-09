cbuffer LodCB
{
  float VoxelDim = 65; // number of cell corners
  float VoxelDimMinusOne = 64; // number of cells
  float2 wsVoxelSize = float2(1.0 / 64.0, 0); 
  float wsChunkSize = 4.0; // 1.0, 2.0, or 4.0 depending on LOD
  float2 InvVoxelDim = float2(1.0 / 65.0, 0);
  float2 InvVoxelDimMinusOne = float2(1.0 / 64.0, 0);
  float Margin = 4; 
  float VoxelDimPlusMargins = 73; // 4 + 65 + 4
  float VoxelDimPlusMarginsMinusOne = 72; // 4 + 64 + 4
  float2 InvVoxelDimPlusMargins = float2(1.0 / 73.0, 0);
  float2 InvVoxelDimPlusMarginsMinusOne = float2(1.0 / 72.0, 0);
};

float3 ChunkCoordToExtChunkCoord(float3 chunkCoord)
{
  // If VoxelDim is 65 then chunkCoord should be in [0..64/65]
  // and extChunkCoord will be outside that range
  return (chunkCoord*VoxelDimPlusMargins.xxx - Margin.xxx)*InvVoxelDim.xxx;
}

float3 ExtChunkCoordToChunkCoord(float3 extChunkCoord)
{
  return (extChunkCoord*VoxelDim.xxx + Margin.xxx)*InvVoxelDimPlusMargins.xxx;
}