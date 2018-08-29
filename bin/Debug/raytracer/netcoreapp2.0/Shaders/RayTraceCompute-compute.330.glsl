#version 430

struct SamplerDummy { int _dummyValue; };
struct SamplerComparisonDummy { int _dummyValue; };

struct RayTracer_Sphere
{
    vec3 Center;
    float Radius;
};

struct RayTracer_Material
{
    vec3 Albedo;
    int Type;
    float FuzzOrRefIndex;
    float _padding0;
    float _padding1;
    float _padding2;
};

struct RayTracer_Camera
{
    vec3 Origin;
    float _padding0;
    vec3 LowerLeftCorner;
    float _padding1;
    vec3 Horizontal;
    float _padding2;
    vec3 Vertical;
    float _padding3;
    vec3 U;
    float LensRadius;
    vec3 V;
    float _padding4;
    vec3 W;
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
    vec3 Origin;
    float _padding0;
    vec3 Direction;
    float _padding1;
};

struct RayTracer_RayHit
{
    vec3 Position;
    float T;
    vec3 Normal;
};

layout(std430) readonly buffer Spheres
{
    RayTracer_Sphere field_Spheres[];
};
layout(std430) readonly buffer Materials
{
    RayTracer_Material field_Materials[];
};
layout(rgba32f) uniform image2D Output;

layout(std140) uniform Params
{
    RayTracer_SceneParams field_Params;
};

layout(std430)  buffer RayCount
{
    uint field_RayCount[];
};
uint RayTracer_RandUtil_XorShift(inout uint state)
{
    state ^= state << 13;
    state ^= state >> 17;
    state ^= state << 15;
    return state;
}


float RayTracer_RandUtil_RandomFloat(inout uint state)
{
    return RayTracer_RandUtil_XorShift(state) * (1.f / 4294967296.f);
}


vec3 RayTracer_RandUtil_RandomInUnitDisk(inout uint state)
{
    vec3 p;
    do {
{
    p = 2.f * vec3(RayTracer_RandUtil_RandomFloat(state), RayTracer_RandUtil_RandomFloat(state), 0) - vec3(1, 1, 0);
}

 } while (dot(p, p) >= 1.f);
    return p;
}


RayTracer_Ray RayTracer_Ray_Create( vec3 origin,  vec3 direction)
{
    RayTracer_Ray r;
    r.Origin = origin;
    r.Direction = direction;
    r._padding0 = 0;
    r._padding1 = 0;
    return r;
}


RayTracer_Ray RayTracer_Camera_GetRay( RayTracer_Camera cam,  float s,  float t, inout uint state)
{
    vec3 rd = cam.LensRadius * RayTracer_RandUtil_RandomInUnitDisk(state);
    vec3 offset = cam.U * rd.x + cam.V * rd.y;
    return RayTracer_Ray_Create(cam.Origin + offset, cam.LowerLeftCorner + s * cam.Horizontal + t * cam.Vertical - cam.Origin - offset);
}


vec3 RayTracer_Ray_PointAt( RayTracer_Ray ray,  float t)
{
    return ray.Origin + ray.Direction * t;
}


RayTracer_RayHit RayTracer_RayHit_Create( vec3 position,  float t,  vec3 normal)
{
    RayTracer_RayHit hit;
    hit.Position = position;
    hit.T = t;
    hit.Normal = normal;
    return hit;
}


bool RayTracer_Sphere_Hit( RayTracer_Sphere sphere,  RayTracer_Ray ray,  float tMin,  float tMax, out RayTracer_RayHit hit)
{
    vec3 center = sphere.Center;
    vec3 oc = ray.Origin - center;
    vec3 rayDir = ray.Direction;
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
    vec3 position = RayTracer_Ray_PointAt(ray, t);
    vec3 normal = (position - center) / radius;
    hit = RayTracer_RayHit_Create(RayTracer_Ray_PointAt(ray, t), t, normal);
    return true;
}



    t = (-b + tmp) / a;
    if (t < tMax && t > tMin)
{
    vec3 position = RayTracer_Ray_PointAt(ray, t);
    vec3 normal = (position - center) / radius;
    hit = RayTracer_RayHit_Create(position, t, normal);
    return true;
}



}



    hit.Position = vec3(0, 0, 0);
    hit.Normal = vec3(0, 0, 0);
    hit.T = 0;
    return false;
}


vec3 RayTracer_RandUtil_RandomInUnitSphere(inout uint state)
{
    vec3 ret;
    do {
{
    ret = 2.f * vec3(RayTracer_RandUtil_RandomFloat(state), RayTracer_RandUtil_RandomFloat(state), RayTracer_RandUtil_RandomFloat(state)) - vec3(1, 1, 1);
}

 } while (dot(ret, ret) >= 1.f);
    return ret;
}


bool RayTracer_RayTracingApplication_Scatter( RayTracer_Ray ray,  RayTracer_RayHit hit,  RayTracer_Material material, inout uint state, out vec3 attenuation, out RayTracer_Ray scattered)
{
    switch (material.Type)
{
case 0:

{
    vec3 target = hit.Position + hit.Normal + RayTracer_RandUtil_RandomInUnitSphere(state);
    scattered = RayTracer_Ray_Create(hit.Position, target - hit.Position);
    attenuation = material.Albedo;
    return true;
}

case 1:

{
    vec3 target = hit.Position + hit.Normal + RayTracer_RandUtil_RandomInUnitSphere(state);
    scattered = RayTracer_Ray_Create(hit.Position, target - hit.Position);
    attenuation = material.Albedo;
    return true;
}

case 2:

{
    vec3 target = hit.Position + hit.Normal + RayTracer_RandUtil_RandomInUnitSphere(state);
    scattered = RayTracer_Ray_Create(hit.Position, target - hit.Position);
    attenuation = material.Albedo;
    return true;
}

default:

attenuation = vec3(0, 0, 0);
scattered = RayTracer_Ray_Create(vec3(0, 0, 0), vec3(0, 0, 0));
return false;
}

}


vec4 RayTracer_Shaders_RayTraceCompute_Color( uint sphereCount, inout uint randState,  RayTracer_Ray ray, inout uint rayCount)
{
    vec3 color = vec3(0, 0, 0);
    vec3 currentAttenuation = vec3(1, 1, 1);
    for (int curDepth = 0; curDepth < 50; curDepth++)
{
    rayCount += 1;
    RayTracer_RayHit hit;
    hit.Position = vec3(0, 0, 0);
    hit.Normal = vec3(0, 0, 0);
    hit.T = 0;
    float closest = 9999999.f;
    bool hitAnything = false;
    uint hitID = 0;
    for (uint i = 0; i < sphereCount; i++)
{
    RayTracer_RayHit tempHit;
    if (RayTracer_Sphere_Hit(field_Spheres[i], ray, 0.001f, closest, tempHit))
{
    hitAnything = true;
    hit = tempHit;
    hitID = i;
    closest = hit.T;
}



}


    if (hitAnything)
{
    vec3 attenuation;
    RayTracer_Ray scattered;
    if (RayTracer_RayTracingApplication_Scatter(ray, hit, field_Materials[hitID], randState, attenuation, scattered))
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
    vec3 unitDir = normalize(ray.Direction);
    float t = 0.5f * (unitDir.y + 1.f);
    color += currentAttenuation * ((1.f - t) * vec3(1, 1, 1) + t * vec3(0.5f, 0.7f, 1.f));
    break;
}



}


    return vec4(color, 1.f);
}



layout(local_size_x = 16, local_size_y = 16, local_size_z = 1) in;
void CS()
{
    uvec3 dtid = gl_GlobalInvocationID;
    vec4 color = vec4(0, 0, 0, 0);
    uint randState = (dtid.x * 1973 + dtid.y * 9277 + field_Params.FrameCount * 26699) | 1;
    uint rayCount = 0;
    for (uint smp = 0; smp < 1; smp++)
{
    float u = (dtid.x + RayTracer_RandUtil_RandomFloat(randState)) / 800;
    float v = (dtid.y + RayTracer_RandUtil_RandomFloat(randState)) / 640;
    RayTracer_Ray ray = RayTracer_Camera_GetRay(field_Params.Camera, u, v, randState);
    color += RayTracer_Shaders_RayTraceCompute_Color(field_Params.SphereCount, randState, ray, rayCount);
}


    color /= 1;
    imageStore(Output, ivec2(uvec2(dtid.x, dtid.y)), color);
    atomicAdd(field_RayCount[0], rayCount);
}



void main()
{
    CS();
}
