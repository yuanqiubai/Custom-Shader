# Custom-Shader

[English](README.md) · **中文**

一套面向 Unity **URP（通用渲染管线）** 的自定义 Shader、Shader Graph 与可复用 Sub Graph 合集，
主要用于角色、草地、花卉、地形、特效与**全屏体积雾**的**风格化 / 动漫（吉卜力风）**渲染。

## 效果展示

完全使用本仓库 Shader 渲染的吉卜力风格草地（Unity 6 + URP）。

https://github.com/user-attachments/assets/04ca7c45-6870-478f-b2e2-1bb0944da2bc

## 目录

- [效果展示](#效果展示)
- [环境要求](#环境要求)
- [内容一览](#内容一览)
  - [手写 Shader](#手写-shader)
  - [Shader Graph](#shader-graph)
  - [Sub Graph](#sub-graph)
  - [HLSL 自定义节点](#hlsl-自定义节点)
  - [第三方资源](#第三方资源)
    - [URP ShaderGraph Custom Lighting](#urp-shadergraph-custom-lighting)
- [使用方式](#使用方式)
- [参与贡献](#参与贡献)
- [授权协议](#授权协议)
- [说明](#说明)

## 环境要求

- Unity 6.1（6000.1）或更高版本
- Universal Render Pipeline（URP）17.1+

## 内容一览

### 手写 Shader

| Shader | 路径 | 说明 |
| --- | --- | --- |
| `Custom/Anime` | `Anime.shader` | 完整的动漫角色 Shader：渐变 Ramp 漫反射、可调阈值与平滑度的多级阴影、三种高光形状（圆形 / 星形 / 十字 / 自定义）配合高光遮罩、边缘光、头发高光、环境光控制与 Alpha 裁剪；另外附带独立的描边 Pass 与阴影投射 Pass。 |
| `Custom/AnimeGrass` | `AnimeGrass_2.shader` | 二次元草地 Shader，Alpha 裁剪，通过插值系数混合两张渐变贴图。 |
| `Custom/VolumeFog` | `FullScreen/VolumeFog.shader` | 全屏 Pass 脚手架：全屏三角形顶点阶段，`ZTest Always` / `ZWrite Off`，URP `Opaque` 渲染类型。`frag` 目前只输出 UV，雾的逻辑尚未接入 —— 实际实现见 Fog 图与 `HLSL/VolumetricScattering.hlsl`。 |

### Shader Graph

| 图形 | 路径 | 说明 |
| --- | --- | --- |
| Toon | `_Toon.shadergraph` | 基于可复用 Sub Graph 搭建的卡通着色图。 |
| Cloudy | `Cloudy_ShaderGraph.shadergraph` | 风格化云层天空着色。 |
| Trail | `VFX/FX_Trail.shadergraph` | 特效用的风格化拖尾。 |
| Clash | `VFX/FX_Clash.shadergraph` | 撞击特效：噪声抖动 UV 扭曲配合 Alpha 裁剪。 |
| 全屏雾 | `FullScreen/Fog_ShaderGraph.shadergraph` | 全屏体积雾，由 `Sub_Fog`、`Sub_HeightVolumeFog`、`Sub_ReconstructWorldPosition` 组合而成（309 节点）。 |
| 云层 v2 | `Cloudy_v2_ShaderGraph.shadergraph` | 基于多层 Voronoi 噪声重建的云层天空，带双重视图缩放与平滑度控制。 |
| 云层 v3 | `Cloudy_v3_ShaderGraph.shadergraph` | 云层天空的第三版，`Sub_Move`、`Sub_ConstructNormal`、`Sub_ElevateBlack` 与第三方 `Main Light` 叠加而成。 |
| 草地 v0 | `Grass/First_GhibliStyle_Grass_ShaderGraph.shadergraph` | 吉卜力风格草地的第一个版本。 |
| 草地 v1 | `Grass/GhibliStyleGrass_v1__ShaderGraph.shadergraph` | 吉卜力风格草地的第二个版本。 |
| 草地 LOD0 v2 | `Grass/GhibliStyleGrass_v2_LOD0_ShaderGraph.shadergraph` | 第三个版本，LOD0 优化变体。 |
| 花卉 LOD0 | `Flower/GhibliStyleFlower_LOD0_ShaderGraph.shadergraph` | 吉卜力风格花卉，LOD0 优化变体。 |
| 树木 LOD0 | `Tree/Tree_LOD0_ShaderGraph.shadergraph` | LOD0 树木图，由半兰伯特与物体空间根部阴影 Sub Graph 组合而成。 |
| 树叶 LOD0 | `Tree/Leaves_LOD0_ShaderGraph.shadergraph` | 树冠使用的 LOD0 树叶图。 |

### Sub Graph

`SubGraphs/` 中按用途划分的可复用节点：

- **着色** —— `Sub_BaseColor`、`Sub_HalfLambert`、`Sub_HalfLambertBoth`、`Sub_BlinnPhong`、`Sub_ToonRemapGradient`，以及 `Sub_DirectLightingStylized`（风格化直接光，带高光颜色 / 法线 / 平滑度与 Shadowmask 采样）
- **广告牌** —— `Sub_Billboard`、`Sub_BillboardBase`
- **植被风动** —— `Sub_CalculateYWeightedOffset` 及其 `Quadratic`、`Sine`、`Smoothstep` 变体
- **位移** —— `Sub_Move`，由 `_Direction` 与 `_Speed` 驱动的偏移
- **地形混合** —— `Sub_CalculateTerrainUV`、`Sub_CalculateTerrainColor`
- **根部阴影** —— `Sub_RootShadowOS`，适用于 UV 不沿高度轴展开的模型的物体空间根部阴影遮罩
- **体积雾** —— `Sub_Fog`（围绕 `_boxCenter` / `_boxSize` 的包围盒光线步进，可调 `_stepCount`、`_density`、`_noiseScale`）、`Sub_HeightVolumeFog`（`_fogHeight` / `_fogHeightRange` / `_density`）、`Sub_ValueNoise3D`（3D 值噪声）
- **空间重建** —— `Sub_ReconstructWorldPosition`（由 `uv` + 深度经 `UNITY_MATRIX_I_VP` 还原世界坐标）、`Sub_ConstructNormal`（由三次高度采样做有限差分求法线）
- **颜色校正** —— `Sub_ElevateBlack`
- **颜色量化** —— `Sub_Posterize`

### HLSL 自定义节点

| 文件 | 节点 |
| --- | --- |
| `HLSL/ToolNode.hlsl` | `BillboardBase`、`Billboard`、`CalculateYWeightedOffset`（含 `Quadratic` / `Sine` / `Smoothstep`）、`CalculateTerrainUV`、`CalculateTerrainColor`、`RootShadowOS`、`ReconstructWorldPosition`、`ConstructNormal` |
| `HLSL/ColorCorrection.hlsl` | `ElevateBlack` —— 抬升并混合颜色的暗部；`Posterize` —— 颜色量化 |
| `HLSL/VolumetricScattering.hlsl` | `Fog`、`HeightVolumeFog`、`ValueNoise3D`、`RayBoxIntersection`、`RaySphereIntersect`、`BoundaryAttenuation`、`Hash31` —— 体积雾用的独立光线步进辅助函数，目前尚未被任何图引用 |

### 第三方资源

#### URP ShaderGraph Custom Lighting

- **下载地址**：<https://github.com/Cyanilux/URP_ShaderGraphCustomLighting>
- **Git URL 安装**：`https://github.com/Cyanilux/URP_ShaderGraphCustomLighting.git`
- **作者**：Cyanilux —— <https://www.cyanilux.com/>
- **包名**：`com.cyanilux.shadergraph-customlighting` v17.1.0（URP 17.1+ / Unity 6000.1+）
- **本地副本**：`ThirdParty/URP_ShaderGraphCustomLighting-6000.1` —— 提供主光、附加光、阴影、Cookie、雾、Shadowmask、Subtractive GI 等自定义光照 Sub Graph，以及 Toon 与 Shadow Receiver 示例
- **协议**：MIT，详见该目录内的 `LICENSE` 文件

## 使用方式

1. 把需要的文件夹复制到工程的 `Assets/` 目录下。
2. 确认工程已启用 URP，并在 `Project Settings → Graphics` 中指定渲染管线资源。
3. HLSL 文件需配合 Shader Graph 的 `Custom Function` 节点使用，把 `Source` 设为 `HLSL File`，因此文件必须放在工程内。
4. 使用第三方光照 Sub Graph 时，请参考 `ThirdParty/URP_ShaderGraphCustomLighting-6000.1/README.md` 中的安装说明与已知问题。

## 参与贡献

欢迎提交 Bug 报告、功能建议与 Pull Request。Commit 信息规范、分支命名以及 Shader Graph
的注意事项都写在 [CONTRIBUTING.zh-CN.md](CONTRIBUTING.zh-CN.md) 里。

不确定某个东西是否适合放进这个仓库？直接开个 issue 问就好 —— 提问的成本比 PR 被打回低得多。

## 授权协议

MIT —— 详见 [LICENSE](LICENSE)。你可以自由使用、修改与再分发这些 Shader（含商业用途），
只要保留版权声明即可。

## 说明

- 仓库不跟踪 `.meta` 文件（`.gitignore` 中已忽略 `*.meta`）。Unity 会在导入时重新生成，
  因此资源 GUID 由各工程自行分配 —— 建议按需复制文件，而不是跨工程直接引用。
  Shader Graph 对 Sub Graph 的引用是按 GUID 解析的，导入后若有节点显示为缺失，需要重新指定对应的 Sub Graph 资源。
