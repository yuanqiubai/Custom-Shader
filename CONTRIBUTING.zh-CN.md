# 参与贡献 Custom-Shader

[English](CONTRIBUTING.md) · **中文**

感谢你愿意搭把手！这是一个体量不大的个人 Shader 合集，所以任何规模的贡献都欢迎
—— 改个错别字、调一版渐变图、甚至丢一整个新 Shader 进来都行。

## 目录

- [贡献方式](#贡献方式)
- [开始之前](#开始之前)
- [报告 Bug](#报告-bug)
- [提出功能建议](#提出功能建议)
- [提交改动](#提交改动)
- [Commit 信息规范](#commit-信息规范)
- [分支命名](#分支命名)
- [Shader Graph 注意事项](#shader-graph-注意事项)
- [第三方资源](#第三方资源)

## 贡献方式

| 我想…… | 这么做 |
| --- | --- |
| 反馈渲染错误 | 提交 [Bug 报告](https://github.com/yuanqiubai/Custom-Shader/issues/new?template=bug_report.yml) |
| 想要新 Shader 或新节点 | 提交 [功能建议](https://github.com/yuanqiubai/Custom-Shader/issues/new?template=feature_request.yml) |
| 自己动手修 / 改进 | Fork 之后提 Pull Request |
| 展示用它做出来的效果 | 开个 issue 贴截图 —— 真的很有激励作用 |

## 开始之前

本仓库面向 **Unity 6.1 (6000.1) 及以上** 与 **URP 17.1 及以上**。请先读
[README](README.zh-CN.md) 里的环境要求与用法，并确认在一个干净工程（只拷入需要的那几个文件）
里问题依然存在。

## 报告 Bug

请使用 Bug 报告模板，它会询问 Unity 版本、URP 版本、平台、图形 API 和截图 —— 这几个信息
基本是复现渲染问题的必需品。

**没有截图或视频的 Bug 报告很难处理。** Shader 问题本质上是视觉问题，"光照看起来不对"
这种描述没法定位。

## 提出功能建议

请说明**使用场景**，而不只是"我想要一个 X 资源"。
"我在做一个 2.5D 平台跳跃游戏，需要角色走过时草会被压平的草地" —— 这比"加个草地 Shader"
有用得多，因为它说明了 Shader 到底要做什么事。

如果这个功能只对你自己项目有意义，也完全可以直说，我会告诉你它该放在这里，还是放在你自己的
fork 里更合适。

## 提交改动

### 1. Fork 并建分支

Fork 本仓库，然后按下面的命名规则从 `main` 切出一个分支。如果打算提 PR，请不要直接在自己
fork 的 `main` 上改动 —— 用主题分支能让历史记录清晰可读。

### 2. 动手改

- **保持改动聚焦。** 一个 PR 只做一件事（一个 Shader / 一个修复），比塞十件不相干的事好审
  太多。
- **贴合现有风格**：4 空格缩进，手写 Shader 用 Allman 大括号，属性用 `_PascalCase`，注释写
  英文。
- 新增 Sub Graph 请放在 `SubGraphs/` 下，命名为 `Sub_<用途>`。
- 开工前先拉最新 `main`，改 Shader Graph 时尤其重要。

### 3. 提交

请遵循下面的 [Commit 信息规范](#commit-信息规范)。`update`、`fix stuff` 这类提交信息会被
要求改写。

### 4. 提 Pull Request

请填写 PR 模板。一份好的 PR 包含：

- **改了什么** 以及 **为什么改**；
- **改动前后的截图或短视频** —— 这是 Shader PR 里最重要的一环；
- 你测试所用的 **Unity 与 URP 版本**；
- 任何 **破坏性变更**（属性改名、文件移动、默认值变化）。

小而聚焦的 PR 合并得很快；把重构和新功能混在一起的大 PR 往往就烂在那儿了。

提交 PR 即表示你同意：你的贡献与仓库其余部分一样，按 [MIT 协议](LICENSE) 授权。

## Commit 信息规范

```
<BranchType>/<FeatureName> (#IssueID)
```

Issue 编号可选 —— 没有 issue 就省略 `(#ID)` 部分。

然后把改动归类到下面适用的段落里：

| 段落 | 用途 |
| --- | --- |
| `Added Prefabs:` | 新增 Prefab |
| `Added Scripts:` | 新增 C# 脚本 |
| `Fixed Prefabs:` | Prefab 修复 |
| `Fixed Scripts:` | 脚本修复 |
| `Renamed Assets:` | 资源改名 |
| `File Movement:` | 文件移动 / 整理 |
| `Namespace Refactor:` | 命名空间调整 |
| `Added Textures:` | 新增贴图、渐变图 |
| `Material Changes:` | 材质调整 |
| `Shader Changes:` | Shader 与 Shader Graph 改动 |
| `Scene Changes:` | 场景改动 |
| `Deleted Files:` | 删除文件 |

资源路径用 Unity 风格的正斜杠写法，用途不直观时在同行的 `[描述]` 里补一句：

```
Feature/AnimeRimLight [Rim Light Rework] (#7)

Shader Changes:
Anime.shader [重做边缘光，新增 _RimStrength]

Added Textures:
Textures/Ramps/Ramp_Anime_Cool.png

Material Changes:
Materials/Anime_Character.mat [_RimColor 调整]
```

仅为配合改动而临时加的东西，标注 `[Temporary]`，让审查者知道它之后可以删掉。

## 分支命名

| 类型 | 命名 | 用途 |
| --- | --- | --- |
| 功能 | `feature/<name>` | 新 Shader、新节点、新效果 |
| 修复 | `fix/<bug-name>` | 非紧急的 Bug 修复 |
| 热修 | `hotfix/<issue>` | 已发布内容的紧急修复 |
| 杂务 | `chore/<topic>` | 文档、工具、清理 |

从 `main` 切出，PR 目标也是 `main`。本仓库目前不维护 `develop` 分支。

## Shader Graph 注意事项

Shader Graph 文件极易改动、也极易冲突，所以有几条底线：

- **不要重命名或移动**已有的 `.shadergraph` / `.shadersubgraph` 文件。所有引用都会断，
  diff 也会变得没法审。
- **改动前先 pull。** 两个人在不同分支改同一个 Graph，产生的冲突基本无法手工合并。
- **保持属性名稳定。** 改属性名会让所有现有材质上的该属性静默重置为默认值。
- **不要提交 `.meta`。** 本仓库刻意忽略 `*.meta`（见 [说明](README.zh-CN.md#说明)）。

## 第三方资源

`ThirdParty/URP_ShaderGraphCustomLighting-6000.1` 是
[Cyanilux 的包](https://github.com/Cyanilux/URP_ShaderGraphCustomLighting) 的原样拷贝，请注意：

- **不要直接改那个文件夹里的文件。** 那里的修复应该提到上游，而且你改的内容会在下次更新
  资源包时被覆盖丢失。
- 由该资源包引起的问题，请提到
  [上游仓库](https://github.com/Cyanilux/URP_ShaderGraphCustomLighting/issues)。
- 新增第三方资源时，请在 PR 里写明 **来源链接** 和 **License**，并保留原始的 License 文件。
