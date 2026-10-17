# Custom-Shader

**English** · [中文](README.zh-CN.md)

A collection of custom shaders, Shader Graphs and reusable Sub Graphs for Unity's
Universal Render Pipeline (URP), aimed at a stylized / anime (Ghibli-like) look for
characters, grass, flowers, terrain, VFX and full-screen volumetric fog.

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
| `Custom/AnimeGrass` | `AnimeGrass_2.shader` | Alpha cutout anime grass shader with two gradient maps blended by a lerp factor. |
| `Custom/VolumeFog` | `FullScreen/VolumeFog.shader` | Full-screen pass scaffold: fullscreen-triangle vertex stage, `ZTest Always` / `ZWrite Off`, URP `Opaque` render type. The fragment currently outputs UV only, so the fog logic is not hooked up yet — see the Fog graph and `HLSL/VolumetricScattering.hlsl`. |

### Shader Graphs

| Graph | Path | Description |
| --- | --- | --- |
| Toon | `_Toon.shadergraph` | Toon shading graph built on top of the reusable sub graphs. |
| Cloudy | `Cloudy_ShaderGraph.shadergraph` | Stylized cloudy sky shading. |
| Trail | `VFX/FX_Trail.shadergraph` | Stylized trail effect for VFX. |
| Clash | `VFX/FX_Clash.shadergraph` | Clash impact effect: noise-jittered UV distortion with alpha clip. |
| Full-screen Fog | `FullScreen/Fog_ShaderGraph.shadergraph` | Full-screen volumetric fog, assembled from `Sub_Fog`, `Sub_HeightVolumeFog` and `Sub_ReconstructWorldPosition` (309 nodes). |
| Cloudy v2 | `Cloudy_v2_ShaderGraph.shadergraph` | Cloudy sky rebuilt on layered Voronoi noise with dual scale and smoothness controls. |
| Cloudy v3 | `Cloudy_v3_ShaderGraph.shadergraph` | Third cloudy sky iteration, layered with `Sub_Move`, `Sub_ConstructNormal`, `Sub_ElevateBlack` and `Main Light`. |
| Grass v0 | `Grass/First_GhibliStyle_Grass_ShaderGraph.shadergraph` | First Ghibli style grass iteration. |
| Grass v1 | `Grass/GhibliStyleGrass_v1__ShaderGraph.shadergraph` | Second Ghibli style grass iteration. |
| Grass LOD0 v2 | `Grass/GhibliStyleGrass_v2_LOD0_ShaderGraph.shadergraph` | Third iteration, optimized LOD0 variant. |
| Flower LOD0 | `Flower/GhibliStyleFlower_LOD0_ShaderGraph.shadergraph` | Ghibli style flower, optimized LOD0 variant. |
| Tree LOD0 | `Tree/Tree_LOD0_ShaderGraph.shadergraph` | LOD0 tree graph assembled from the half lambert and object-space root shadow sub graphs. |
| Leaves LOD0 | `Tree/Leaves_LOD0_ShaderGraph.shadergraph` | LOD0 foliage graph for tree canopies. |

### Sub Graphs

Reusable nodes in `SubGraphs/`, grouped by purpose:

- **Shading** — `Sub_BaseColor`, `Sub_HalfLambert`, `Sub_HalfLambertBoth`, `Sub_BlinnPhong`, `Sub_ToonRemapGradient`, and `Sub_DirectLightingStylized` (stylized direct light with specular colour / normal / smoothness and shadowmask sampling)
- **Billboard** — `Sub_Billboard`, `Sub_BillboardBase`
- **Vegetation wind** — `Sub_CalculateYWeightedOffset` with `Quadratic`, `Sine` and `Smoothstep` variants
- **Motion** — `Sub_Move`, offset driven by `_Direction` and `_Speed`
- **Terrain blending** — `Sub_CalculateTerrainUV`, `Sub_CalculateTerrainColor`
- **Root shadow** — `Sub_RootShadowOS`, object-space root shadow mask for meshes whose UVs do not expand along the height axis
- **Volumetric fog** — `Sub_Fog` (box-bounded ray march over `_boxCenter` / `_boxSize` with `_stepCount`, `_density`, `_noiseScale`), `Sub_HeightVolumeFog` (`_fogHeight` / `_fogHeightRange` / `_density`), `Sub_ValueNoise3D` (3D value noise)
- **Space reconstruction** — `Sub_ReconstructWorldPosition` (world position from `uv` + depth via `UNITY_MATRIX_I_VP`), `Sub_ConstructNormal` (normal from three height samples via finite differences)
- **Color correction** — `Sub_ElevateBlack`
- **Color quantization** — `Sub_Posterize`

### HLSL Custom Nodes

| File | Nodes |
| --- | --- |
| `HLSL/ToolNode.hlsl` | `BillboardBase`, `Billboard`, `CalculateYWeightedOffset` (plus `Quadratic` / `Sine` / `Smoothstep`), `CalculateTerrainUV`, `CalculateTerrainColor`, `RootShadowOS`, `ReconstructWorldPosition`, `ConstructNormal` |
| `HLSL/ColorCorrection.hlsl` | `ElevateBlack` — lifts and blends the dark parts of a color; `Posterize` — colour quantization |
| `HLSL/VolumetricScattering.hlsl` | `Fog`, `HeightVolumeFog`, `ValueNoise3D`, `RayBoxIntersection`, `RaySphereIntersect`, `BoundaryAttenuation`, `Hash31` — standalone ray-marching helpers for volumetric fog; not referenced by any graph yet |

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

- `.meta` files are not tracked in this repository (`*.meta` in `.gitignore`). Unity regenerates them on import, so asset GUIDs are assigned per project — copy the files you need rather than referencing them across projects. Shader Graph references to Sub Graphs are resolved by GUID, so after importing you may need to re-pick the Sub Graph asset on any node that shows as missing.
