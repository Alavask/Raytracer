#version 450
#extension GL_ARB_separate_shader_objects : enable
#extension GL_ARB_shading_language_420pack : enable
struct RayTracer_Shaders_FragmentInput
{
    vec4 Position;
    vec2 TexCoords;
};

layout(set = 0, binding = 0) uniform texture2D SourceTex;
layout(set = 0, binding = 1) uniform sampler SourceSampler;
vec3 RayTracer_Shaders_FramebufferBlitter_ToSrgb( vec3 color)
{
    color = max(color, vec3(0, 0, 0));
    return max(1.055f * pow(color, vec3(0.41666667f, 0.41666667f, 0.41666667f)) - vec3(0.055f, 0.055f, 0.055f), vec3(0, 0, 0));
}



vec4 FS( RayTracer_Shaders_FragmentInput input_)
{
    vec4 color = texture(sampler2D(SourceTex, SourceSampler), input_.TexCoords);
    return vec4(RayTracer_Shaders_FramebufferBlitter_ToSrgb(color.xyz), 1.f);
}


layout(location = 0) in vec2 fsin_0;
layout(location = 0) out vec4 _outputColor_;

void main()
{
    RayTracer_Shaders_FragmentInput input_;
    input_.Position = gl_FragCoord;
    input_.TexCoords = fsin_0;
    vec4 output_ = FS(input_);
    _outputColor_ = output_;
}
