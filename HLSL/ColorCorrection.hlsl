#ifndef COLOR_CORRECTION_HLSH
#define COLOR_CORRECTION_HLSH

// 暗部抬升
// Color: 输入颜色
// BlackCompression: 黑色压缩参数，范围为0到1，值越大表示抬升越明显
void ElevateBlack_float(float3 Color, float BlackCompression, out float3 Out)
{
    float3 newColor = Color * BlackCompression + (1.0 - BlackCompression);
    Out = newColor;
}

void ElevateBlack_half(half3 Color, half BlackCompression, out half3 Out)
{
    half3 newColor = Color * BlackCompression + (1.0 - BlackCompression);
    Out = newColor;
}

// 色阶(硬二分化)
void Posterize_float(float gray, float levels, out float outPosterize)
{
    float steps = levels - 1.0;
    // 向下取整 / 步长
    outPosterize = floor(gray * steps + 0.5) / steps;
}

void Posterize_half(half gray, half levels, out half outPosterize)
{
    half steps = levels - 1.0;
    outPosterize = floor(gray * steps + 0.5) / steps;
}

#endif