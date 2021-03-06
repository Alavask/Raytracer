#include <metal_stdlib>
using namespace metal;
struct RayTracer_Sphere
{
    packed_float3 Center;
    float Radius;
};

struct RayTracer_Material
{
    packed_float3 Albedo;
    int Type;
    float FuzzOrRefIndex;
    float _padding0;
    float _padding1;
    float _padding2;
};

struct RayTracer_Camera
{
    packed_float3 Origin;
    float _padding0;
    packed_float3 LowerLeftCorner;
    float _padding1;
    packed_float3 Horizontal;
    float _padding2;
    packed_float3 Vertical;
    float _padding3;
    packed_float3 U;
    float LensRadius;
    packed_float3 V;
    float _padding4;
    packed_float3 W;
    float _padding5;
};

struct RayTracer_SceneParams
{
    RayTracer_Camera Camera;
    uint SphereCount;
    uint FrameCount;
    uint _padding0;
    uint _padding1;
};

struct RayTracer_Ray
{
    packed_float3 Origin;
    float _padding0;
    packed_float3 Direction;
    float _padding1;
};

struct RayTracer_RayHit
{
    packed_float3 Position;
    float T;
    packed_float3 Normal;
};

struct ShaderContainer {
constant RayTracer_Sphere* Spheres;
constant RayTracer_Material* Materials;
constant RayTracer_SceneParams& Params;
texture2d<float, access::read_write> Output;
device atomic_uint* RayCount;
uint RayTracer_RandUtil_XorShift(thread uint &state)
{
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 15;
    return state;
}


float RayTracer_RandUtil_RandomFloat(thread uint &state)
{
    return RayTracer_RandUtil_XorShift(state) * (1.f / 4294967296.f);
}


float3 RayTracer_RandUtil_RandomInUnitDisk(thread uint &state)
{
    float3 p;
    do {
{
    p = 2.f * float3(RayTracer_RandUtil_RandomFloat(state), RayTracer_RandUtil_RandomFloat(state), 0) - float3(1, 1, 0);
}

 } while (dot(p, p) >= 1.f);
    return p;
}


RayTracer_Ray RayTracer_Ray_Create( float3 origin,  float3 direction)
{
    RayTracer_Ray r;
    r.Origin = origin;
    r.Direction = direction;
    r._padding0 = 0;
    r._padding1 = 0;
    return r;
}


RayTracer_Ray RayTracer_Camera_GetRay( RayTracer_Camera cam,  float s,  float t, thread uint &state)
{
    float3 rd = cam.LensRadius * RayTracer_RandUtil_RandomInUnitDisk(state);
    float3 offset = cam.U * rd[0] + cam.V * rd[1];
    return RayTracer_Ray_Create(cam.Origin + offset, cam.LowerLeftCorner + s * cam.Horizontal + t * cam.Vertical - cam.Origin - offset);
}


float3 RayTracer_Ray_PointAt( RayTracer_Ray ray,  float t)
{
    return ray.Origin + ray.Direction * t;
}


RayTracer_RayHit RayTracer_RayHit_Create( float3 position,  float t,  float3 normal)
{
    RayTracer_RayHit hit;
    hit.Position = position;
    hit.T = t;
    hit.Normal = normal;
    return hit;
}


bool RayTracer_Sphere_Hit( RayTracer_Sphere sphere,  RayTracer_Ray ray,  float tMin,  float tMax, thread RayTracer_RayHit &hit)
{
    float3 center = sphere.Center;
    float3 oc = ray.Origin - center;
    float3 rayDir = ray.Direction;
    float a = dot(rayDir, rayDir);
    float b = dot(oc, rayDir);
    float radius = sphere.Radius;
    float c = dot(oc, oc) - radius * radius;
    float discriminant = b * b - a * c;
    if (discriminant > 0)
{
    float tmp = sqrt(b * b - a * c);
    float t = (-b - tmp) / a;
    if (t < tMax && t > tMin)
{
    float3 position = RayTracer_Ray_PointAt(ray, t);
    float3 normal = (position - center) / radius;
    hit = RayTracer_RayHit_Create(RayTracer_Ray_PointAt(ray, t), t, normal);
    return true;
}



    t = (-b + tmp) / a;
    if (t < tMax && t > tMin)
{
    float3 position = RayTracer_Ray_PointAt(ray, t);
    float3 normal = (position - center) / radius;
    hit = RayTracer_RayHit_Create(position, t, normal);
    return true;
}



}



    hit.Position = float3(0, 0, 0);
    hit.Normal = float3(0, 0, 0);
    hit.T = 0;
    return false;
}


float3 RayTracer_RandUtil_RandomInUnitSphere(thread uint &state)
{
    float3 ret;
    do {
{
    ret = 2.f * float3(RayTracer_RandUtil_RandomFloat(state), RayTracer_RandUtil_RandomFloat(state), RayTracer_RandUtil_RandomFloat(state)) - float3(1, 1, 1);
}

 } while (dot(ret, ret) >= 1.f);
    return ret;
}


bool RayTracer_RayTracingApplication_Scatter( RayTracer_Ray ray,  RayTracer_RayHit hit,  RayTracer_Material material, thread uint &state, thread float3 &attenuation, thread RayTracer_Ray &scattered)
{
    switch (material.Type)
{
case 0:

{
    float3 target = hit.Position + hit.Normal + RayTracer_RandUtil_RandomInUnitSphere(state);
    scattered = RayTracer_Ray_Create(hit.Position, target - hit.Position);
    attenuation = material.Albedo;
    return true;
}

case 1:

{
    float3 target = hit.Position + hit.Normal + RayTracer_RandUtil_RandomInUnitSphere(state);
    scattered = RayTracer_Ray_Create(hit.Position, target - hit.Position);
    attenuation = material.Albedo;
    return true;
}

case 2:

{
    float3 target = hit.Position + hit.Normal + RayTracer_RandUtil_RandomInUnitSphere(state);
    scattered = RayTracer_Ray_Create(hit.Position, target - hit.Position);
    attenuation = material.Albedo;
    return true;
}

default:

attenuation = float3(0, 0, 0);
scattered = RayTracer_Ray_Create(float3(0, 0, 0), float3(0, 0, 0));
return false;
}

}


float4 RayTracer_Shaders_RayTraceCompute_Color( uint sphereCount, thread uint &randState,  RayTracer_Ray ray, thread uint &rayCount)
{
    float3 color = float3(0, 0, 0);
    float3 currentAttenuation = float3(1, 1, 1);
    for (int curDepth = 0; curDepth < 50; curDepth++)
{
    rayCount += 1;
    RayTracer_RayHit hit;
    hit.Position = float3(0, 0, 0);
    hit.Normal = float3(0, 0, 0);
    hit.T = 0;
    float closest = 9999999.f;
    bool hitAnything = false;
    uint hitID = 0;
    for (uint i = 0; i < sphereCount; i++)
{
    RayTracer_RayHit tempHit;
    if (RayTracer_Sphere_Hit(Spheres[i], ray, 0.001f, closest, tempHit))
{
    hitAnything = true;
    hit = tempHit;
    hitID = i;
    closest = hit.T;
}



}


    if (hitAnything)
{
    float3 attenuation;
    RayTracer_Ray scattered;
    if (RayTracer_RayTracingApplication_Scatter(ray, hit, Materials[hitID], randState, attenuation, scattered))
{
    currentAttenuation *= attenuation;
    ray = scattered;
}

else
{
    color += currentAttenuation;
    break;
}



}

else
{
    float3 unitDir = normalize(ray.Direction);
    float t = 0.5f * (unitDir[1] + 1.f);
    color += currentAttenuation * ((1.f - t) * float3(1, 1, 1) + t * float3(0.5f, 0.7f, 1.f));
    break;
}



}


    return float4(color, 1.f);
}



ShaderContainer(
constant RayTracer_Sphere* Spheres_param, constant RayTracer_Material* Materials_param, constant RayTracer_SceneParams& Params_param, texture2d<float, access::read_write> Output_param, device atomic_uint* RayCount_param
)
:
Spheres(Spheres_param), Materials(Materials_param), Params(Params_param), Output(Output_param), RayCount(RayCount_param)
{}

void CS(uint3 _builtins_DispatchThreadID)
{
    uint3 dtid = _builtins_DispatchThreadID;
    float4 color = float4(0, 0, 0, 0);
    uint randState = (dtid[0] * 1973 + dtid[1] * 9277 + Params.FrameCount * 26699) | 1;
    uint rayCount = 0;
    for (uint smp = 0; smp < 1; smp++)
{
    float u = (dtid[0] + RayTracer_RandUtil_RandomFloat(randState)) / 800;
    float v = (dtid[1] + RayTracer_RandUtil_RandomFloat(randState)) / 640;
    RayTracer_Ray ray = RayTracer_Camera_GetRay(Params.Camera, u, v, randState);
    color += RayTracer_Shaders_RayTraceCompute_Color(Params.SphereCount, randState, ray, rayCount);
}


    color /= 1;
    Output.write(color, uint2(dtid[0], dtid[1]));
    atomic_fetch_add_explicit(&RayCount[0], rayCount, memory_order_relaxed);
}


};

kernel void CS(constant RayTracer_Sphere *Spheres [[ buffer(0) ]], constant RayTracer_Material *Materials [[ buffer(1) ]], texture2d<float, access::read_write> Output [[ texture(0) ]], constant RayTracer_SceneParams &Params [[ buffer(2) ]], device atomic_uint *RayCount [[ buffer(3) ]], uint3 _builtins_DispatchThreadID [[ thread_position_in_grid ]])
{
return ShaderContainer(Spheres, Materials, Params, Output, RayCount).CS(_builtins_DispatchThreadID);
}
