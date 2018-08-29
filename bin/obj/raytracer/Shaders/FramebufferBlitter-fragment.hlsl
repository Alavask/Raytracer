struct RayTracer_Shaders_FragmentInput
{
    float4 Position : SV_Position;
    float2 TexCoords : TEXCOORD0;
};

Texture2D SourceTex : register(t0);

SamplerState SourceSampler : register(s0);

float3 RayTracer_Shaders_FramebufferBlitter_ToSrgb( float3 color)
{
    color = max(color, float3(0, 0, 0));
    return max(1.055f * pow(color, float3(0.41666667f, 0.41666667f, 0.41666667f)) - float3(0.055f, 0.055f, 0.055f), float3(0, 0, 0));
}



float4 FS( RayTracer_Shaders_FragmentInput input) : SV_Target
{
    float4 color = SourceTex.Sample(SourceSampler, input.TexCoords);
    return float4(RayTracer_Shaders_FramebufferBlitter_ToSrgb(color.xyz), 1.f);
}


