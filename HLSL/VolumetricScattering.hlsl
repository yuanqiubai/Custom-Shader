#ifndef VOLUMETRIC_SCATTERING_HLSL
#define VOLUMETRIC_SCATTERING_HLSL

// ================================ (内部函数) ================================

// ========= 3D 噪声计算 =========
float Hash31(float3 p)
{
    p = frac(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return frac((p.x + p.y) * p.z);
}

half Hash31(half3 p)
{
    p = frac(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return frac((p.x + p.y) * p.z);
}

float ValueNoise3D(float3 position)
{
    float3 i = floor(position); // 取最小整数
    float3 f = frac(position); // 取小数

    // 平滑插值
    float3 u = f * f * (3.0 - 2.0 * f);

    float n000 = Hash31(i + float3(0, 0, 0));
    float n100 = Hash31(i + float3(1, 0, 0));
    float n010 = Hash31(i + float3(0, 1, 0));
    float n110 = Hash31(i + float3(1, 1, 0));

    float n001 = Hash31(i + float3(0, 0, 1));
    float n101 = Hash31(i + float3(1, 0, 1));
    float n011 = Hash31(i + float3(0, 1, 1));
    float n111 = Hash31(i + float3(1, 1, 1));

    float x00 = lerp(n000, n100, u.x);
    float x10 = lerp(n010, n110, u.x);
    float x01 = lerp(n001, n101, u.x);
    float x11 = lerp(n011, n111, u.x);

    float y0 = lerp(x00, x10, u.y);
    float y1 = lerp(x01, x11, u.y);

    return lerp(y0, y1, u.z);
}

half ValueNoise3D(half3 position)
{
    half3 i = floor(position); // 取最小整数
    half3 f = frac(position); // 取小数

    // 平滑插值
    half3 u = f * f * (3.0 - 2.0 * f);

    half n000 = Hash31(i + half3(0, 0, 0));
    half n100 = Hash31(i + half3(1, 0, 0));
    half n010 = Hash31(i + half3(0, 1, 0));
    half n110 = Hash31(i + half3(1, 1, 0));

    half n001 = Hash31(i + half3(0, 0, 1));
    half n101 = Hash31(i + half3(1, 0, 1));
    half n011 = Hash31(i + half3(0, 1, 1));
    half n111 = Hash31(i + half3(1, 1, 1));

    half x00 = lerp(n000, n100, u.x);
    half x10 = lerp(n010, n110, u.x);
    half x01 = lerp(n001, n101, u.x);
    half x11 = lerp(n011, n111, u.x);

    half y0 = lerp(x00, x10, u.y);
    half y1 = lerp(x01, x11, u.y);

    return lerp(y0, y1, u.z);
}

float2 RaySphereIntersect(float3 rayOrigin, float3 rayDir, float3 sphereCenter, float sphereRadius)
{
    float3 oc = rayOrigin - sphereCenter;   // 光线起点到球心的向量
    float b = dot(oc, rayDir);              // 光线起点到球心的投影长度
    float c = dot(oc, oc) - sphereRadius * sphereRadius; // 光线起点到球心的距离平方减去球半径平方
    float h = b * b - c;
    
    // 无交点
    if (h < 0.0) return float2(1.0, -1.0);
    
    h = sqrt(h);
    return float2(-b - h, -b + h);
}

// ========= Slab Method 光线与盒子的交点计算【对角线版本】=========
float2 RayBoxIntersection_f(float3 rayOrigin, float3 rayDir, float3 boxCenter, float3 boxMinPos, float3 boxMaxPos)
{
    float3 boxMin = boxMinPos;
    float3 boxMax = boxMaxPos;

    float3 invDir = 1.0 / rayDir;

    float3 t0 = (boxMin - rayOrigin) * invDir;    // t_0 * rayDir = boxMin - rayOrigin 光经过一定时间后到达boxMin的位置
    float3 t1 = (boxMax - rayOrigin) * invDir;    // t_1 * rayDir = boxMax - rayOrigin 光经过一定时间后离开boxMax的位置

    float3 tEnter = min(t0, t1);    // 光线进入盒子的时间
    float3 tExit = max(t0, t1);     // 光线离开盒子的时间

    float tMin = max(max(tEnter.x, tEnter.y), tEnter.z); // 光线进入盒子的最大时间，三轴全部进入盒子取决于最后进入的轴
    float tMax = min(min(tExit.x, tExit.y), tExit.z);    // 光线离开盒子的最小时间，三轴全部离开盒子取决于最早离开的轴

    return float2(tMin, tMax); // 返回光线进入和离开盒子的时间
}

half2 RayBoxIntersection_h(half3 rayOrigin, half3 rayDir, half3 boxCenter, half3 boxMinPos, half3 boxMaxPos)
{
    half3 boxMin = boxMinPos;
    half3 boxMax = boxMaxPos;

    half3 invDir = 1.0 / rayDir;

    half3 t0 = (boxMin - rayOrigin) * invDir;    // t_0 * rayDir = boxMin - rayOrigin 光经过一定时间后到达boxMin的位置
    half3 t1 = (boxMax - rayOrigin) * invDir;    // t_1 * rayDir = boxMax - rayOrigin 光经过一定时间后离开boxMax的位置

    half3 tEnter = min(t0, t1);    // 光线进入盒子的时间
    half3 tExit = max(t0, t1);     // 光线离开盒子的时间

    half tMin = max(max(tEnter.x, tEnter.y), tEnter.z); // 光线进入盒子的最大时间，三轴全部进入盒子取决于最后进入的轴
    half tMax = min(min(tExit.x, tExit.y), tExit.z);    // 光线离开盒子的最小时间，三轴全部离开盒子取决于最早离开的轴

    return half2(tMin, tMax); // 返回光线进入和离开盒子的时间
}

//========= Slab Method 光线与盒子的交点计算【尺寸版本】=========
float2 RayBoxIntersection_f(float3 rayOrigin, float3 rayDir, float3 boxCenter, float3 boxSize)
{
    float3 boxMin = boxCenter - boxSize * 0.5;
    float3 boxMax = boxCenter + boxSize * 0.5;

    float3 invDir = 1.0 / rayDir;

    float3 t0 = (boxMin - rayOrigin) * invDir;    // t_0 * rayDir = boxMin - rayOrigin 光经过一定时间后到达boxMin的位置
    float3 t1 = (boxMax - rayOrigin) * invDir;    // t_1 * rayDir = boxMax - rayOrigin 光经过一定时间后离开boxMax的位置

    float3 tEnter = min(t0, t1);    // 光线进入盒子的时间
    float3 tExit = max(t0, t1);     // 光线离开盒子的时间

    float tMin = max(max(tEnter.x, tEnter.y), tEnter.z); // 光线进入盒子的最大时间，三轴全部进入盒子取决于最后进入的轴
    float tMax = min(min(tExit.x, tExit.y), tExit.z);    // 光线离开盒子的最小时间，三轴全部离开盒子取决于最早离开的轴

    return float2(tMin, tMax); // 返回光线进入和离开盒子的时间
}

half2 RayBoxIntersection_h(half3 rayOrigin, half3 rayDir, half3 boxCenter, half3 boxSize)
{
    half3 boxMin = boxCenter - boxSize * 0.5;
    half3 boxMax = boxCenter + boxSize * 0.5;

    half3 invDir = 1.0 / rayDir;

    half3 t0 = (boxMin - rayOrigin) * invDir;    // t_0 * rayDir = boxMin - rayOrigin 光经过一定时间后到达boxMin的位置
    half3 t1 = (boxMax - rayOrigin) * invDir;    // t_1 * rayDir = boxMax - rayOrigin 光经过一定时间后离开boxMax的位置

    half3 tEnter = min(t0, t1);    // 光线进入盒子的时间
    half3 tExit = max(t0, t1);     // 光线离开盒子的时间

    half tMin = max(max(tEnter.x, tEnter.y), tEnter.z); // 光线进入盒子的最大时间，三轴全部进入盒子取决于最后进入的轴
    half tMax = min(min(tExit.x, tExit.y), tExit.z);    // 光线离开盒子的最小时间，三轴全部离开盒子取决于最早离开的轴

    return half2(tMin, tMax); // 返回光线进入和离开盒子的时间
}

// ========== 边界衰减函数【对角线版本】==========
float BoundaryAttenuation_f(float3 samplePosWS, float3 boxCenter, float3 boxMinPos, float3 boxMaxPos, float falloffWidth)
{
    float3 boxMin = boxMinPos;
    float3 boxMax = boxMaxPos;

    // 1. 计算采样点到边界的距离
    float3 distanceToBoxMin = samplePosWS - boxMin;
    float3 distanceToBoxMax = boxMax - samplePosWS;

    // 2. 计算距离边界的最小距离
    float3 distanceToBoundary = min(distanceToBoxMin, distanceToBoxMax);
    float minDistanceToBoundary = min(min(distanceToBoundary.x, distanceToBoundary.y), distanceToBoundary.z);

    // 3. 计算边界衰减因子
    return smoothstep(0.0, falloffWidth, minDistanceToBoundary);
}

half BoundaryAttenuation_h(half3 samplePosWS, half3 boxCenter, half3 boxMinPos, half3 boxMaxPos, half falloffWidth)
{
    half3 boxMin = boxMinPos;
    half3 boxMax = boxMaxPos;

    // 1. 计算采样点到边界的距离
    half3 distanceToBoxMin = samplePosWS - boxMin;
    half3 distanceToBoxMax = boxMax - samplePosWS;

    // 2. 计算距离边界的最小距离
    half3 distanceToBoundary = min(distanceToBoxMin, distanceToBoxMax);
    half minDistanceToBoundary = min(min(distanceToBoundary.x, distanceToBoundary.y), distanceToBoundary.z);

    // 3. 计算边界衰减因子
    return smoothstep(0.0, falloffWidth, minDistanceToBoundary);
}

// ========== 边界衰减函数【尺寸版本】==========
float BoundaryAttenuation_f(float3 samplePosWS, float3 boxCenter, float3 boxSize, float falloffWidth)
{
    float3 boxMin = boxCenter - boxSize * 0.5;
    float3 boxMax = boxCenter + boxSize * 0.5;

    // 1. 计算采样点到边界的距离
    float3 distanceToBoxMin = samplePosWS - boxMin;
    float3 distanceToBoxMax = boxMax - samplePosWS;

    // 2. 计算距离边界的最小距离
    float3 distanceToBoundary = min(distanceToBoxMin, distanceToBoxMax);
    float minDistanceToBoundary = min(min(distanceToBoundary.x, distanceToBoundary.y), distanceToBoundary.z);

    // 3. 计算边界衰减因子
    return smoothstep(0.0, falloffWidth, minDistanceToBoundary);
}

half BoundaryAttenuation_h(half3 samplePosWS, half3 boxCenter, half3 boxSize, half falloffWidth)
{
    half3 boxMin = boxCenter - boxSize * 0.5;
    half3 boxMax = boxCenter + boxSize * 0.5;

    // 1. 计算采样点到边界的距离
    half3 distanceToBoxMin = samplePosWS - boxMin;
    half3 distanceToBoxMax = boxMax - samplePosWS;

    // 2. 计算距离边界的最小距离
    half3 distanceToBoundary = min(distanceToBoxMin, distanceToBoxMax);
    half minDistanceToBoundary = min(min(distanceToBoundary.x, distanceToBoundary.y), distanceToBoundary.z);

    // 3. 计算边界衰减因子
    return smoothstep(0.0, falloffWidth, minDistanceToBoundary);
}

// ================================ 光线与盒子的交点计算 (节点自定义函数) ================================

void RayBoxIntersection_float(float3 rayOrigin, float3 rayDir, float3 boxCenter, float3 boxSize, out float2 result)
{
    // 计算盒子最小和最大坐标
    float3 boxMin = boxCenter - boxSize * 0.5;
    float3 boxMax = boxCenter + boxSize * 0.5;

    float3 invDir = 1.0 / rayDir;

    float3 t0 = (boxMin - rayOrigin) * invDir;    
    float3 t1 = (boxMax - rayOrigin) * invDir;    

    float3 tEnter = min(t0, t1);   
    float3 tExit = max(t0, t1);    

    float tMin = max(max(tEnter.x, tEnter.y), tEnter.z); 
    float tMax = min(min(tExit.x, tExit.y), tExit.z);    

    result = float2(tMin, tMax); 
}

void RayBoxIntersection_half(half3 rayOrigin, half3 rayDir, half3 boxCenter, half3 boxSize, out half2 result)
{
    half3 boxMin = boxCenter - boxSize * 0.5;
    half3 boxMax = boxCenter + boxSize * 0.5;

    half3 invDir = 1.0 / rayDir;

    half3 t0 = (boxMin - rayOrigin) * invDir;    
    half3 t1 = (boxMax - rayOrigin) * invDir;    

    half3 tEnter = min(t0, t1);    
    half3 tExit = max(t0, t1);     

    half tMin = max(max(tEnter.x, tEnter.y), tEnter.z); 
    half tMax = min(min(tExit.x, tExit.y), tExit.z);    

    result = half2(tMin, tMax); 
}




// ========== 3D 程序噪声 ==========
/*
noise : 根据着色器阶段返回顶点坐标或片元
*/
void ValueNoise3D_float(float3 position, float scale, out float noise)
{
    float3 i = floor(position); // 取最小整数
    float3 f = frac(position);  // 取小数

    // 平滑插值
    float3 u = f * f * (3.0 - 2.0 * f);

    float n000 = Hash31(i + float3(0, 0, 0));
    float n100 = Hash31(i + float3(1, 0, 0));
    float n010 = Hash31(i + float3(0, 1, 0));
    float n110 = Hash31(i + float3(1, 1, 0));

    float n001 = Hash31(i + float3(0, 0, 1));
    float n101 = Hash31(i + float3(1, 0, 1));
    float n011 = Hash31(i + float3(0, 1, 1));
    float n111 = Hash31(i + float3(1, 1, 1));

    float x00 = lerp(n000, n100, u.x);
    float x10 = lerp(n010, n110, u.x);
    float x01 = lerp(n001, n101, u.x);
    float x11 = lerp(n011, n111, u.x);

    float y0 = lerp(x00, x10, u.y);
    float y1 = lerp(x01, x11, u.y);

    noise = lerp(y0, y1, u.z) * scale;
}

void ValueNoise3D_half(half3 position, half scale, out half noise)
{
    half3 i = floor(position); // 取最小整数
    half3 f = frac(position);  // 取小数

    // 平滑插值
    half3 u = f * f * (3.0 - 2.0 * f);

    half n000 = Hash31(i + half3(0, 0, 0));
    half n100 = Hash31(i + half3(1, 0, 0));
    half n010 = Hash31(i + half3(0, 1, 0));
    half n110 = Hash31(i + half3(1, 1, 0));

    half n001 = Hash31(i + half3(0, 0, 1));
    half n101 = Hash31(i + half3(1, 0, 1));
    half n011 = Hash31(i + half3(0, 1, 1));
    half n111 = Hash31(i + half3(1, 1, 1));

    half x00 = lerp(n000, n100, u.x);
    half x10 = lerp(n010, n110, u.x);
    half x01 = lerp(n001, n101, u.x);
    half x11 = lerp(n011, n111, u.x);

    half y0 = lerp(x00, x10, u.y);
    half y1 = lerp(x01, x11, u.y);

    noise = lerp(y0, y1, u.z) * scale;
}

// ================================ 雾【对角线版本】================================
void Fog_float(
    float3 n2wPos,        // 当前像素世界坐标
    float3 rayOrigin,     // 相机世界位置
    int    stepCount,     // 步进数
    float  density,       // 基础密度
    float4 fogColor,      // 雾颜色 + 散射强度
    float3 boxCenter,     // 盒子中心
    float3 boxMinPos,     // 盒子最小位置
    float3 boxMaxPos,     // 盒子最大位置
    float  falloffWidth,  // 边缘衰减宽度
    float3 noisePosition, // 噪声位置
    float  noiseScale,    // 噪声大小
    out float4 result)    // 输出雾
{
    // 默认无雾
    result = float4(0, 0, 0, 0);

    // 光
    float3 ray             = n2wPos - rayOrigin;
    float  rayLength       = length(ray);

    if (rayLength < 1e-5 || stepCount == 0) return;

    float3 rayDir          = ray / rayLength;

    float2 boxIntersection = RayBoxIntersection_f(rayOrigin, rayDir, boxCenter, boxMinPos, boxMaxPos);
    float  marchStart      = max(boxIntersection.x, 0.0);
    float  marchEnd        = min(boxIntersection.y, rayLength);

    if(marchEnd <= marchStart) return;

    float  marchLength     = marchEnd - marchStart;     // 穿过正方体的总时间
    float  stepSize        = marchLength / stepCount;   // 时间步长

    float  opticalDepth    = 0.0;

    for (uint i = 0; i < stepCount; i++)
    {
        float distanceAlongRay = marchStart + (i + 0.5) * stepSize;     // 沿光线射入体积后的路程
        float3 samplePosWS     = rayOrigin + rayDir * distanceAlongRay; // 沿光线路程采样

        // 高度因子
        float heightFactor = exp(-(samplePosWS.y - boxMinPos.y));
        
        // 噪声因子
        float noiseFactor = ValueNoise3D(samplePosWS * noiseScale + noisePosition);

        // 边界衰减因子
        float boundaryAttenuationFactor = BoundaryAttenuation_f(samplePosWS, boxCenter, boxMinPos, boxMaxPos, falloffWidth);

        opticalDepth += stepSize * density * heightFactor * boundaryAttenuationFactor * noiseFactor;
    }

    float transmittance = exp(-opticalDepth);      // 透射率
    float fogAmount     = 1.0 - transmittance;     // 雾的总量
    
    result = float4(fogAmount, fogAmount, fogAmount, 1) * fogColor;
}

void Fog_half(
    half3 n2wPos,        // 当前像素世界坐标
    half3 rayOrigin,     // 相机世界位置
    int   stepCount,     // 步进数
    half  density,       // 基础密度
    half4 fogColor,      // 雾颜色 + 散射强度
    half3 boxCenter,     // 盒子中心
    half3 boxMinPos,     // 盒子最小位置
    half3 boxMaxPos,     // 盒子最大位置
    half  falloffWidth,  // 边缘衰减宽度
    half3 noisePosition, // 噪声位置
    half  noiseScale,    // 噪声大小
    out half4 result)    // 输出雾
{
    // 默认无雾
    result = half4(0, 0, 0, 0);

    // 光
    half3 ray             = n2wPos - rayOrigin;
    half  rayLength       = length(ray);

    if (rayLength < 1e-5 || stepCount == 0) return;

    half3 rayDir          = ray / rayLength;

    half2 boxIntersection = RayBoxIntersection_h(rayOrigin, rayDir, boxCenter, boxMinPos, boxMaxPos);
    half  marchStart      = max(boxIntersection.x, 0.0);
    half  marchEnd        = min(boxIntersection.y, rayLength);

    if(marchEnd <= marchStart) return;

    half  marchLength     = marchEnd - marchStart;
    half  stepSize        = marchLength / stepCount;

    half  opticalDepth    = 0.0;
    
    for (uint i = 0; i < stepCount; i++)
    {
        half distanceAlongRay = marchStart + (i + 0.5) * stepSize; // 沿射线距离
        half3 samplePosWS     = rayOrigin + rayDir * distanceAlongRay;

        // 高度因子
        half heightFactor = exp(-(samplePosWS.y - boxMinPos.y));

        // 噪声因子
        float noiseFactor = ValueNoise3D(samplePosWS * noiseScale + noisePosition);

        // 计算边界衰减因子
        half boundaryAttenuationFactor = BoundaryAttenuation_h(samplePosWS, boxCenter, boxMinPos, boxMaxPos, falloffWidth);

        opticalDepth += stepSize * density * heightFactor * boundaryAttenuationFactor * noiseFactor;
    }

    half transmittance = exp(-opticalDepth);      // 透射率
    half fogAmount     = 1.0 - transmittance;     // 雾的总量
    
    result = half4(fogAmount, fogAmount, fogAmount, 1) * fogColor;
}

// ================================ 雾【尺寸版本】================================
void Fog_float(
    float3 n2wPos,        // 当前像素世界坐标
    float3 rayOrigin,     // 相机世界位置
    int    stepCount,     // 步进数
    float  density,       // 基础密度
    float4 fogColor,      // 雾颜色
    float3 boxCenter,     // 盒子中心
    float3 boxSize,       // 盒子尺寸
    float  falloffWidth,  // 边缘衰减宽度
    float3 noisePosition, // 噪声位置
    float  noiseScale,    // 噪声大小
    out float4 result)    // 输出雾
{

    float3 boxMinPos = boxCenter - boxSize * 0.5;
    float3 boxMaxPos = boxCenter + boxSize * 0.5;

    Fog_float(n2wPos, rayOrigin, stepCount, density, fogColor,
              boxCenter, boxMinPos, boxMaxPos, falloffWidth, noisePosition, noiseScale, result);
}

void Fog_half(
    half3 n2wPos,        // 当前像素世界坐标
    half3 rayOrigin,     // 相机世界位置
    int   stepCount,     // 步进数
    half  density,       // 基础密度
    half4 fogColor,      // 雾颜色
    half3 boxCenter,     // 盒子中心
    half3 boxSize,       // 盒子尺寸
    half  falloffWidth,  // 边缘衰减宽度
    half3 noisePosition, // 噪声位置
    half  noiseScale,    // 噪声大小
    out half4 result)    // 输出雾
{
    half3 boxMinPos = boxCenter - boxSize * 0.5;
    half3 boxMaxPos = boxCenter + boxSize * 0.5;

    Fog_half(n2wPos, rayOrigin, stepCount, density, fogColor,
             boxCenter, boxMinPos, boxMaxPos, falloffWidth, noisePosition, noiseScale, result);
}

/*
高度体积雾:
n2wPos: 体积雾位置(世界空间)
cameraPosWS: 摄像机位置(世界空间)
stepCount: 采样步数
density: 雾的密度
height: 雾的高度 —— 通常传入噪声处理高度
fogColor: 雾的颜色
*/
void HeightVolumeFog_float(float3 n2wPos, float3 cameraPosWS, int stepCount, float density, float fogHeight, float fogHeightRange,float4 fogColor, out float4 result)
{
    float3 ray = n2wPos - cameraPosWS;              // 计算从摄像机到体积雾位置的方向(光线)
    float rayLength = length(ray);                  // 计算从摄像机到体积雾位置的距离
    float3 rayDir = normalize(ray);                 // 光向

    float stepSize = rayLength / stepCount;         // 每一段"光进"的长度

    float opticalDepth  = 0.0;                      // 光学厚度
    float transmittance = exp(-opticalDepth);       // 光透射率(如果透射率 = 100%, 则没有雾)
    
    float fogAmount     = 1.0 - transmittance;      // 雾的总量

    // 逐步采样体积雾
    for(uint i = 0; i < stepCount; i++)
    {
        float distanceAlongRay = stepSize * (i + 0.5);                 // 沿射线距离
        float3 samplePosWS = cameraPosWS + rayDir * distanceAlongRay;  // 采样位置(光线步进的坐标)(每一段的中间位置)
    
        float heightFactor = 1.0 - smoothstep(
            fogHeight - fogHeightRange,
            fogHeight,
            samplePosWS.y
        );

        float sampleDensity = density * heightFactor;

        opticalDepth += sampleDensity * stepSize;
    }

    transmittance = exp(-opticalDepth);      // 透射率
    fogAmount = 1 - transmittance;
    result = float4(fogAmount, fogAmount, fogAmount, 1) * fogColor;
}

void HeightVolumeFog_half(half3 n2wPos, half3 cameraPosWS, int stepCount, half density, half fogHeight, half fogHeightRange, half4 fogColor, out half4 result)
{
    half3 ray = n2wPos - cameraPosWS;              // 计算从摄像机到体积雾位置的方向(光线)
    half rayLength = length(ray);                  // 计算从摄像机到体积雾位置的距离
    half3 rayDir = normalize(ray);                 // 光向

    half stepSize = rayLength / stepCount;         // 每一段"光进"的长度

    half opticalDepth  = 0.0;                      // 光学厚度
    half transmittance = exp(-opticalDepth);       // 光透射率

    half fogAmount     = 1.0 - transmittance;

    // 逐步采样体积雾
    for(uint i = 0; i < stepCount; i++)
    {
        half distanceAlongRay = stepSize * (i + 0.5);                // 沿射线距离
        half3 samplePosWS = cameraPosWS + rayDir * distanceAlongRay; // 采样位置(光线步进的坐标)(每一段的中间位置)

        half heightFactor = 1.0 - smoothstep(
            fogHeight - fogHeightRange,
            fogHeight,
            samplePosWS.y
        );
        half sampleDensity = density * heightFactor;

        opticalDepth += sampleDensity * stepSize;
    }

    transmittance = exp(-opticalDepth);      // 透射率
    fogAmount = 1 - transmittance;
    result = half4(fogAmount, fogAmount, fogAmount, 1) * fogColor;
}


#endif