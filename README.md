# Custom-Shader

**English** · [中文](README.zh-CN.md)

A collection of custom shaders, Shader Graphs and reusable Sub Graphs for Unity's
Universal Render Pipeline (URP), aimed at a stylized / anime (Ghibli-like) look for
characters, grass, flowers, terrain and VFX.

## Demo

Ghibli-style grass field rendered entirely with the shaders in this repository
(Unity 6 + URP).

https://github.com/user-attachments/assets/04ca7c45-6870-478f-b2e2-1bb0944da2bc

## Table of Contents

- [Demo](#demo)
- [Requirements](#requirements)
- [Contents](#contents)
  - [Hand-written Shaders](#hand-written-shaders)
  - [Shader Graphs](#shader-graphs)
  - [Sub Graphs](#sub-graphs)
  - [HLSL Custom Nodes](#hlsl-custom-nodes)
  - [Third-party](#third-party)
    - [URP ShaderGraph Custom Lighting](#urp-shadergraph-custom-lighting)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Notes](#notes)

## Requirements

- Unity 6.1 (6000.1) or newer
- Universal Render Pipeline (URP) 17.1+

## Contents

### Hand-written Shaders

| Shader | Path | Description |
| --- | --- | --- |
| `Custom/Anime` | `Anime.shader` | Full anime character shader: gradient ramp diffuse, multi-step shadow with adjustable threshold and smoothness, three specular shapes (circle / star / cross / custom) with a specular mask, rim light, hair highlight, ambient control and alpha cutout. Ships with a dedicated outline pass and a shadow caster pass. |
| `Custom/My_Toon` | `My_Toon.shader` | Compact URP toon shader driven by a single ramp texture. A good starting point for a custom toon look. |
| `Custom/AnimeGrass` | `AnimeGrass_2.shader` | Alpha cutout anime grass shader with two gradient maps blended by a lerp factor. |

### Shader Graphs

| Graph | Path | Description |
| --- | --- | --- |
| Toon | `_Toon.shadergraph` | Toon shading graph built on top of the reusable sub graphs. |
| Cloudy | `Cloudy_ShaderGraph.shadergraph` | Stylized cloudy sky shading. |
| Trail | `VFX/Trail.shadergraph` | Stylized trail effect for VFX. |
| Grass v0 | `Grass/First_GhibliStyle_Grass_ShaderGraph.shadergraph` | First Ghibli style grass iteration. |
| Grass v1 | `Grass/GhibliStyle_Grass_v1_ShaderGraph.shadergraph` | Second Ghibli style grass iteration. |
| Grass LOD0 v2 | `Grass/GhibliStyleGrass_v2_LOD0_ShaderGraph.shadergraph` | Third iteration, optimized LOD0 variant. |
| Flower LOD0 | `Flower/GhibliStyleFlower_LOD0_ShaderGraph.shadergraph` | Ghibli style flower, optimized LOD0 variant. |

### Sub Graphs

Reusable nodes in `SubGraphs/`, grouped by purpose:

- **Shading** — `Sub_BaseColor`, `Sub_HalfLambert`, `Sub_BlinnPhong`, `Sub_ToonRemapGradient`
- **Billboard** — `Sub_Billboard`, `Sub_BillboardBase`
- **Vegetation wind** — `Sub_CalculateYWeightedOffset` with `Quadratic`, `Sine` and `Smoothstep` variants
- **Terrain blending** — `Sub_CalculateTerrainUV`, `Sub_CalculateTerrainColor`
- **Root shadow** — `Sub_RootShadowOS`, object-space root shadow mask for meshes whose UVs do not expand along the height axis
- **Color correction** — `Sub_ElevateBlack`

### HLSL Custom Nodes

| File | Nodes |
| --- | --- |
| `HLSL/ToolNode.hlsl` | `BillboardBase`, `Billboard`, `CalculateYWeightedOffset` (plus `Quadratic` / `Sine` / `Smoothstep`), `CalculateTerrainUV`, `CalculateTerrainColor`, `RootShadowOS` |
| `HLSL/ColorCorrection.hlsl` | `ElevateBlack` — lifts and blends the dark parts of a color |

### Third-party

#### URP ShaderGraph Custom Lighting

- **Download**: <https://github.com/Cyanilux/URP_ShaderGraphCustomLighting>
- **Install via Git URL**: `https://github.com/Cyanilux/URP_ShaderGraphCustomLighting.git`
- **Author**: Cyanilux — <https://www.cyanilux.com/>
- **Package**: `com.cyanilux.shadergraph-customlighting` v17.1.0 (URP 17.1+ / Unity 6000.1+)
- **Local copy**: `ThirdParty/URP_ShaderGraphCustomLighting-6000.1` — custom lighting sub graphs for main light, additional lights, shadows, cookie, fog, shadowmask and subtractive GI, plus toon and shadow receiver examples
- **License**: MIT, see the `LICENSE` file inside the folder

## Usage

1. Copy the folders you need into your project's `Assets/` directory.
2. Make sure the Universal Render Pipeline is active and the render pipeline asset is assigned in `Project Settings → Graphics`.
3. The HLSL files are meant to be used through Shader Graph's `Custom Function` node with `Source` set to `HLSL File`, so the file must live inside the project.
4. When using the third-party lighting sub graphs, follow the setup notes in `ThirdParty/URP_ShaderGraphCustomLighting-6000.1/README.md`.

## Contributing

Bug reports, feature requests and pull requests are all welcome. See
[CONTRIBUTING.md](CONTRIBUTING.md) for the commit message format, branch naming
and the Shader Graph ground rules.

If you are not sure whether something belongs here, open an issue and ask — a
question is cheaper than a rejected pull request.

## License

MIT — see [LICENSE](LICENSE). You are free to use, modify and redistribute
these shaders, including commercially, as long as the copyright notice is kept.

## Notes

- `.meta` files are not tracked in this repository (`*.meta` in `.gitignore`). Unity regenerates them on import, so asset GUIDs are assigned per project — copy the files you need rather than referencing them across projects.