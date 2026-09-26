# Contributing to Custom-Shader

**English** · [中文](CONTRIBUTING.zh-CN.md)

Thanks for wanting to help out! This is a small personal shader collection, so
contributions of any size are welcome — fixing a typo, improving a ramp, or
adding a whole new shader.

## Table of Contents

- [Ways to contribute](#ways-to-contribute)
- [Before you start](#before-you-start)
- [Reporting a bug](#reporting-a-bug)
- [Suggesting a feature](#suggesting-a-feature)
- [Submitting a change](#submitting-a-change)
- [Commit message format](#commit-message-format)
- [Branch naming](#branch-naming)
- [Shader Graph tips](#shader-graph-tips)
- [Third-party code](#third-party-code)

## Ways to contribute

| I want to... | Do this |
| --- | --- |
| Report something that renders wrong | Open a [Bug report](https://github.com/yuanqiubai/Custom-Shader/issues/new?template=bug_report.yml) |
| Ask for a new shader or node | Open a [Feature request](https://github.com/yuanqiubai/Custom-Shader/issues/new?template=feature_request.yml) |
| Fix or improve something yourself | Fork, then open a pull request |
| Show what you built with it | Open an issue with screenshots — it is genuinely motivating |

## Before you start

This repository targets **Unity 6.1 (6000.1)+** and **URP 17.1+**. Please check
the [README](README.md) for setup steps first, and confirm the problem still
happens on a clean project with only the files you need copied in.

## Reporting a bug

Use the Bug report template — it asks for the Unity version, URP version,
platform, graphics API and a screenshot, which are almost always required to
reproduce a rendering issue.

A bug report without a screenshot or video is very hard to act on: shader
problems are visual, and "the lighting looks wrong" cannot be diagnosed.

## Suggesting a feature

Describe the **use case**, not just the asset you want. "I need grass that
flattens when a character walks through it, for a 2.5D platformer" is far more
useful than "add a grass shader", because it tells me what the shader actually
has to do.

If the feature only makes sense for your project, that is fine — say so, and I
will tell you whether it belongs here or in your own fork.

## Submitting a change

### 1. Fork and branch

Fork the repository, then create a branch off `main` using the naming rules
below. Do not commit directly to `main` on your own fork if you plan to open a
pull request — a topic branch keeps the history reviewable.

### 2. Work on the change

- Keep changes focused. One shader or one fix per pull request is much easier
  to review than ten unrelated edits.
- Match the existing code style: 4 spaces, Allman braces for hand-written
  shaders, `_PascalCase` for shader properties, English comments.
- If you add a Sub Graph, keep it under `SubGraphs/` and name it `Sub_<Purpose>`.
- Pull the latest `main` before you start, especially for Shader Graph changes.

### 3. Commit

Follow the [commit message format](#commit-message-format) below. Commits like
`update` or `fix stuff` will be asked to be reworded.

### 4. Open a pull request

A good pull request includes:

- **What changed** and **why**.
- **Before / after screenshots or a short video** for anything visual. This is
  the single most important part of a shader pull request.
- The **Unity and URP versions** you tested with.
- Any **breaking change** (renamed properties, moved files, changed defaults).

Small pull requests get merged quickly. Large ones that mix refactoring with new
features tend to stall.

By opening a pull request you agree that your contribution is licensed under the
repository's [MIT license](LICENSE), same as the rest of the project.

## Commit message format

```
<BranchType>/<FeatureName> (#IssueID)
```

The issue ID is optional — omit the `(#ID)` part when there is no issue.

Then group the changes into the sections that apply:

| Section | Used for |
| --- | --- |
| `Added Prefabs:` | New prefabs |
| `Added Scripts:` | New C# scripts |
| `Fixed Prefabs:` | Prefab fixes |
| `Fixed Scripts:` | Script fixes |
| `Renamed Assets:` | Renames |
| `File Movement:` | Moved / reorganized files |
| `Namespace Refactor:` | Namespace changes |
| `Added Textures:` | New textures, ramps, gradients |
| `Material Changes:` | Material adjustments |
| `Shader Changes:` | Shader and Shader Graph changes |
| `Scene Changes:` | Scene changes |
| `Deleted Files:` | Removals |

Use Unity-style forward-slash asset paths, with a short `[description]` when the
purpose of a file is not obvious:

```
Feature/AnimeRimLight [Rim Light Rework] (#7)

Shader Changes:
Anime.shader [Reworked rim light, added _RimStrength]

Added Textures:
Textures/Ramps/Ramp_Anime_Cool.png

Material Changes:
Materials/Anime_Character.mat [_RimColor tuned]
```

Prefix entries that only exist to support a change with `[Temporary]` so
reviewers know they can be dropped later.

## Branch naming

| Type | Naming | Purpose |
| --- | --- | --- |
| Feature | `feature/<name>` | New shaders, nodes, visual effects |
| Fix | `fix/<bug-name>` | Non-critical bug fixes |
| Hotfix | `hotfix/<issue>` | Urgent fixes for something already released |
| Chore | `chore/<topic>` | Documentation, tooling, cleanup |

Branch off `main` and target `main` in the pull request. This repository does not
currently maintain a `develop` branch.

## Shader Graph tips

Shader Graph files change easily and conflict badly, so a few ground rules:

- **Do not rename or move** existing `.shadergraph` / `.shadersubgraph` files.
  Every reference to them breaks, and the diff becomes unreviewable.
- **Pull before you edit.** Two people editing the same graph on different
  branches will produce a conflict that is effectively impossible to merge by
  hand.
- **Keep property names stable.** Renaming a property silently resets it to its
  default on every existing material.
- **Add `.meta` files?** No — this repository deliberately ignores `*.meta`
  (see [Notes](README.md#notes)). Do not commit them.

## Third-party code

`ThirdParty/URP_ShaderGraphCustomLighting-6000.1` is an unmodified copy of
[Cyanilux's package](https://github.com/Cyanilux/URP_ShaderGraphCustomLighting).
Please:

- **Do not patch the files in that folder.** Fixes there belong upstream, and
  patches would be lost the next time the package is updated.
- Report issues caused by that package to the
  [upstream repository](https://github.com/Cyanilux/URP_ShaderGraphCustomLighting/issues).
- When adding new third-party assets, state the **source URL** and the
  **license** in your pull request, and keep the original license file intact.
