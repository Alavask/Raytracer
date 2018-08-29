#include <metal_stdlib>
using namespace metal;
struct RayTracer_Shaders_FragmentInput
{
    float4 Position [[ position ]];
    float2 TexCoords [[ attribute(0) ]];
};

struct ShaderContainer {
thread texture2d<float> SourceTex;
thread sampler SourceSampler;
float3 RayTracer_Shaders_FramebufferBlitter_ToSrgb( float3 color)
{
    color = max(color, float3(0, 0, 0));
    return max(1.055f * pow(color, float3(0.41666667f, 0.41666667f, 0.41666667f)) - float3(0.055f, 0.055f, 0.055f), float3(0, 0, 0));
}



ShaderContainer(
thread texture2d<float> SourceTex_param, thread sampler SourceSampler_param
)
:
SourceTex(SourceTex_param), SourceSampler(SourceSampler_param)
{}
float4 FS( RayTracer_Shaders_FragmentInput input)
{
    float4 color = SourceTex.sample(SourceSampler, input.TexCoords);
    return float4(RayTracer_Shaders_FramebufferBlitter_ToSrgb(float4(color).xyz), 1.f);
}


};

fragment float4 FS(RayTracer_Shaders_FragmentInput input [[ stage_in ]], texture2d<float> SourceTex [[ texture(0) ]], sampler SourceSampler [[ sampler(0) ]])
{
return ShaderContainer(SourceTex, SourceSampler).FS(input);
}
