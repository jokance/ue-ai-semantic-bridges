# ue-material-creator 使用说明

[English](ue-material-creator.en.md) | 中文 | [日本語](ue-material-creator.ja.md) | [한국어](ue-material-creator.ko.md)

本文档介绍如何配合 `MaterialSemanticBridge` 插件使用 `ue-material-creator` skill，让 AI Agent 生成、校验、规范化、导入和导出 Unreal 材质 DSL。

## 这是什么

`ue-material-creator` 是一个给 AI Agent 使用的工作流 skill。

它本身不是 Unreal 运行时代码，也不是单独的插件。它的作用是指导 AI Agent：

- 分析材质需求
- 生成或编辑受支持的 `.materialdsl`
- 选择正确的材质实例 DSL 或材质图 DSL 形式
- 保持在已记录的 `MaterialExpression*`、属性、材质设置、图布局和材质输出支持面内
- 在导入前校验并规范化 DSL
- 将校验后的 DSL 导入为 `Material` 或 `MaterialInstanceConstant` 资源

## 与 MaterialSemanticBridge 的关系

这套方案由两部分组成：

- `MaterialSemanticBridge`：Unreal Editor 插件，负责校验、导入、导出和编辑器集成
- `ue-material-creator`：AI Agent skill，负责需求分析和 DSL 生成流程

插件负责执行，skill 负责指导 Agent 如何编写和修复 DSL。

## 对游戏开发提效的价值

在游戏项目里，材质通常会随着美术方向、关卡环境、性能预算和玩法反馈不断迭代。使用 `MaterialSemanticBridge` 插件配合 `ue-material-creator` 后，可以把“描述材质需求 -> 生成 DSL -> 校验 / 规范化 -> 导入 Unreal 资源”变成一条可重复执行的流程，减少手动搭节点、反复对参数和整理材质变体的时间。

它带来的直接收益通常包括：

- 更快做出材质原型，方便尽早验证地表、石头、金属、布料、特效底材等视觉方向
- look-dev 笔记、节点图描述或文字需求可以更快落成可导入的 `Material` / `MaterialInstanceConstant` 资源，减少从想法到编辑器资产之间的信息损耗
- 材质实例参数以 `.materialdsl` 文本表达后，AI 可以批量生成或调整颜色、粗糙度、贴图、静态开关等变体，适合快速铺开同一父材质下的多种资产风格
- 即使你不是 TA 人员，也可以利用该 skill 和插件制作出你想要的材质效果
- 批量导出已有材质或材质实例后，AI 可以基于当前项目真实资产继续修改，而不是从空白猜测材质结构
- 材质 DSL 适合进入版本管理和代码评审流程，让技术美术、程序和 AI Agent 围绕同一份可读文本协作
- 重复性的材质搭建、变体生成和同步工作交给插件与 skill 处理后，开发者可以把更多时间放在美术判断、性能取舍和运行时表现上

## 安装方式

### 1. 安装插件

`MaterialSemanticBridge` 会作为 Unreal Editor 插件分发。后续上架 Fab 后，可以通过 Fab 页面使用 `Install to Engine` 安装。

`MaterialSemanticBridge` 同时支持两种安装方式：

- 项目插件：`<Project>/Plugins/MaterialSemanticBridge`
- 引擎插件：`<Engine>/Plugins/.../MaterialSemanticBridge`

安装后需要在项目中启用该插件：在 Unreal Editor 中，进入 `Edit` -> `Plugins`，找到 `MaterialSemanticBridge` 并勾选启用。

### 2. 放置 skill

在 Unreal Editor 中打开 `AIBridge` -> `Material Semantic Bridge`，然后使用 `Agent Skill Setup` 将插件自带的 skill 拷贝到项目中。默认 `Destination Root` 是项目根目录，也可以点击 `Browse` 选择其它目录：

![](../assets/copy_skill.jpg)

根据你使用的 Agent 工具保留对应目标：

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode 以及其它兼容 `AGENTS.md` 的 Agent 工具：`.agents/skills/ue-material-creator/`
- Claude Code：`.claude/skills/ue-material-creator/`

公开发布后，你也可以直接从 GitHub 下载 ZIP 文件，解压后把 `ue-material-creator` 目录拷贝到对应的 `skills` 目录下：

![](../assets/github_skill.jpg)

推荐优先放在项目仓库中，这样团队成员和自动化环境可以共享同一份工作流说明。

## 目录结构

典型结构如下：

```text
.agents/
  skills/
    ue-material-creator/
      SKILL.md
      references/
```

## DSL 类型

材质实例 DSL 用于 `MaterialInstanceConstant` 资源，描述父材质和受支持的参数覆盖：

```text
schema 1
material_instance "MI_Stone_Wet"
parent_material "/Game/Materials/M_Stone.M_Stone"

scalar_param Roughness "0.18"
vector_param Tint "(R=0.45,G=0.52,B=0.58,A=1)"
texture_param BaseColorTexture "/Game/Textures/T_Stone_D.T_Stone_D"
static_switch_param UseWetLayer "true"
```

材质图 DSL 用于 `Material` 资源，描述图节点、属性、连接、输出和图布局：

```text
schema 2
asset_type "material"
material "M_SimpleRed"

set graph.result_pos "420,0"

node color MaterialExpressionConstant3Vector pos="-300,0"
set color.Constant "(R=1,G=0.05,B=0.02,A=1)"

node rough MaterialExpressionConstant pos="-300,180"
set rough.R "0.35"

output BaseColor color.rgb
output Roughness rough.r
```

当 Material Result 节点需要明确的编辑器位置、避免和生成节点重叠时，使用 `set graph.result_pos "X,Y"`。

## 适用场景

适合用于：

- 创建新的 `.materialdsl`
- 编辑已有 `.materialdsl`
- 将 look-dev 笔记或 shader graph 描述转换成可导入的材质 DSL
- 检查某个节点类、属性、pin、材质设置或输出是否受支持
- 校验、规范化并导入材质 DSL
- 将已有受支持的材质或材质实例导出回 DSL，继续交给 AI 修改

不适合用于：

- 运行时材质实例参数修改
- 支持范围外的任意 HLSL
- Niagara、UMG、Blueprint、Sequencer 或 MetaSound DSL
- 无关的 Unreal C++ 修改

## AI Agent 应该怎么用这个 skill

推荐工作流：

1. 将仓库根目录作为 Agent 的工作目录。
2. 明确告诉 Agent 使用 `ue-material-creator` skill。
3. 让 Agent 生成或修改 `.materialdsl`。
4. 让 Agent 校验或规范化 DSL。
5. 让 Agent 将校验后的 DSL 导入到映射的 `/Game` 资源。

示例：

```shell
cd /path/to/your/project
codex
$ue-material-creator Create a material graph DSL for a wet stone surface with a tinted base color and roughness output.
```

## 输出结果

常见输出包括：

- DSL 文件：`.ue_dsl/MaterialDSL/.../*.materialdsl`
- 导入后的材质：`/Game/.../M_*`
- 导入后的材质实例：`/Game/.../MI_*`
- 使用 commandlet 工作流时生成的校验或导入报告

## 编辑器面板使用说明

启用插件后，可以通过以下入口打开主面板：

- 主菜单：`AIBridge` -> `Material Semantic Bridge`

面板使用统一路由：

- `Export All DSLs`：导出 `/Game` 下的 `MaterialInstanceConstant` 和受支持的 `Material` 图
- `Import New/Changed DSLs`：导入新建或更新过的 DSL 文件，并按 DSL 类型分发
- `Import DSL`：校验并导入单个 `.materialdsl` 到自动映射的目标资源
- `Export DSL`：将选中的 `Material` 或 `MaterialInstanceConstant` 导出到映射的 `.materialdsl`

单文件和批量流程都不需要用户手动选择“材质实例”或“材质图”。插件会根据 DSL 内容或所选资源类型自动分支。
