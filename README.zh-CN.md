# Custom-Shader

[English](README.md) · **中文**

一套面向 Unity **URP（通用渲染管线）** 的自定义 Shader、Shader Graph 与可复用 Sub Graph 合集，
主要用于角色、草地、地形与特效的**风格化 / 动漫（吉卜力风）**渲染。

## 目录

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
- [说明](#说明)

## 环境要求

- Unity 6.1（6000.1）或更高版本
- Universal Render Pipeline（URP）17.1+

## 内容一览

### 手写 Shader

| Shader | 路径 | 说明 |
| --- | --- | --- |
| `Custom/Anime` | `Anime.shader` | 完整的动漫角色 Shader：渐变 Ramp 漫反射、可调阈值与平滑度的多级阴影、三种高光形状（圆形 / 星形 / 十字 / 自定义）配合高光遮罩、边缘光、头发高光、环境光控制与 Alpha 裁剪；另外附带独立的描边 Pass 与阴影投射 Pass。 |
| `Custom/My_Toon` | `My_Toon.shader` | 精简的 URP 卡通 Shader，仅由一张 Ramp 渐变贴图驱动，适合作为自定义卡通效果的基础模板。 |
| `Custom/AnimeGrass` | `AnimeGrass_2.shader` | 二次元草地 Shader，Alpha 裁剪，通过插值系数混合两张渐变贴图。 |

### Shader Graph

| 图形 | 路径 | 说明 |
| --- | --- | --- |
| Toon | `_Toon.shadergraph` | 基于可复用 Sub Graph 搭建的卡通着色图。 |
| Cloudy | `Cloudy_ShaderGraph.shadergraph` | 风格化云层天空着色。 |
| Trail | `VFX/Trail.shadergraph` | 特效用的风格化拖尾。 |
| 草地 v0 | `Grass/First_GhibliStyle_Grass_ShaderGraph.shadergraph` | 吉卜力风格草地的第一个版本。 |
| 草地 v1 | `Grass/GhibliStyle_Grass_v1_ShaderGraph.shadergraph` | 吉卜力风格草地的第二个版本。 |
| 草地 LOD0 v2 | `Grass/GhibliStyleGrass_LOD0_v2_ShaderGraph.shadergraph` | 第三个版本，LOD0 优化变体。 |

### Sub Graph

`SubGraphs/` 中按用途划分的可复用节点：

- **着色** —— `Sub_BaseColor`、`Sub_HalfLambert`、`Sub_BlinnPhong`、`Sub_ToonRemapGradient`
- **广告牌** —— `Sub_Billboard`、`Sub_BillboardBase`
- **植被风动** —— `Sub_CalculateYWeightedOffset` 及其 `Quadratic`、`Sine`、`Smoothstep` 变体
- **地形混合** —— `Sub_CalculateTerrainUV`、`Sub_CalculateTerrainColor`
- **颜色校正** —— `Sub_ElevateBlack`

### HLSL 自定义节点

| 文件 | 节点 |
| --- | --- |
| `HLSL/ToolNode.hlsl` | `BillboardBase`、`Billboard`、`CalculateYWeightedOffset`（含 `Quadratic` / `Sine` / `Smoothstep`）、`CalculateTerrainUV`、`CalculateTerrainColor` |
| `HLSL/ColorCorrection.hlsl` | `ElevateBlack` —— 抬升并混合颜色的暗部 |

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

## 说明

- 仓库不跟踪 `.meta` 文件（`.gitignore` 中已忽略 `*.meta`）。Unity 会在导入时重新生成，
  因此资源 GUID 由各工程自行分配 —— 建议按需复制文件，而不是跨工程直接引用。