# ue-material-creator 使用说明

[English](ue-material-creator.en.md) | 中文 | [日本語](ue-material-creator.ja.md) | [한국어](ue-material-creator.ko.md)

本文档介绍如何配合 `MaterialSemanticBridge` 插件使用 `ue-material-creator` skill，让 AI Agent 生成、校验、规范化、预览、修复、导入和导出 Unreal 材质 DSL。

## 这是什么

`ue-material-creator` 是一个给 AI Agent 使用的工作流 skill。

它本身不是 Unreal 运行时代码，也不是单独的插件。它的作用是指导 AI Agent：

- 分析材质视觉需求，并选择 `Material` 或 `MaterialInstanceConstant` 工作流
- 生成或编辑受支持的缩进式 `.materialdsl`
- 在已记录的 `MaterialExpression*`、属性、pin、材质设置、图布局和材质输出支持面内工作
- 在导入前校验并规范化 DSL
- 读取规范化流程生成的材质预览图和报告，让 AI Agent 视觉自评估效果并修复 `.materialdsl`
- 将稳定后的 DSL 导入为 `Material` 或 `MaterialInstanceConstant` 资源
- 将已有材质或材质实例导出回 DSL，继续交给 AI 迭代

## 与 MaterialSemanticBridge 的关系

这套方案由两部分组成：

- `MaterialSemanticBridge`：Unreal Editor 插件，负责校验、规范化、预览图与报告生成、导入、导出、schema 发现和编辑器集成
- `ue-material-creator`：AI Agent skill，负责需求分析、DSL 生成、预览评估和修复流程

插件负责执行 Unreal 侧工作，skill 负责指导 Agent 如何编写、检查、预览评估并修复 DSL。

## 对游戏开发提效的价值

在游戏项目里，材质通常会随着美术方向、关卡环境、性能预算和玩法反馈不断迭代。使用 `MaterialSemanticBridge` 插件配合 `ue-material-creator` 后，可以把“描述材质需求 -> 生成 DSL -> 校验 / 规范化 -> 生成预览图 -> AI 视觉评估并修复 -> 导入 Unreal 资源”变成一条可重复执行的流程，减少手动搭节点、反复调参数和整理材质变体的时间。

它带来的直接收益通常包括：

- 更快做出材质原型，方便尽早验证UI、地表、石头、金属、布料、特效底材等视觉方向
- 材质视觉笔记、节点图描述或文字需求可以更快落成可导入的 `Material` / `MaterialInstanceConstant` 资源，减少从想法到编辑器资产之间的信息损耗
- 材质实例参数以 `.materialdsl` 文本表达后，AI 可以批量生成或调整颜色、粗糙度、贴图、静态开关等变体，适合快速铺开同一父材质下的多种资产风格
- 规范化流程可以生成材质预览图；动态材质还可以输出多帧预览，便于 AI 检查运动、闪烁、平移或脉冲效果是否符合预期
- 即使你不是技术美术，也可以利用该 skill 和插件制作出更接近需求的材质效果
- 批量导出已有材质或材质实例后，AI 可以基于当前项目真实资产继续修改，而不是从空白猜测材质结构
- 材质 DSL 适合进入版本管理和代码评审流程，让技术美术、程序和 AI Agent 围绕同一份可读文本协作
- 重复性的材质搭建、变体生成和同步工作交给插件与 skill 处理后，开发者可以把更多时间放在美术判断、性能取舍和运行时表现上

## 安装方式

### 1. 安装插件

插件地址：`MaterialSemanticBridge`（Fab 上架后在这里补充插件页面链接）

如果插件来自 Fab，通常是通过 `Install to Engine` 安装到 Unreal 引擎目录。

`MaterialSemanticBridge` 同时支持两种安装方式：

- 项目插件：`<Project>/Plugins/MaterialSemanticBridge`
- 引擎插件：`<Engine>/Plugins/.../MaterialSemanticBridge`

安装后需要在项目中启用该插件：在 Unreal Editor 中，进入 `Edit` -> `Plugins`，找到 `MaterialSemanticBridge` 并勾选启用。

### 2. 放置 skill

在 Unreal Editor 中打开 `AIBridge` -> `Material Semantic Bridge`，然后使用 `Download Agent Skill` 将 skill 下载到项目中。默认 `Destination Root` 是项目根目录，也可以点击 `Browse` 选择其它目录：

![](../assets/ue-material-creator-download-skill.png)

根据你使用的 Agent 工具保留对应目标：

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode 以及其它兼容 `AGENTS.md` 的 Agent 工具：`.agents/skills/ue-material-creator/`
- Claude Code: `.claude/skills/ue-material-creator/`

你也可以直接在 [GitHub](https://github.com/jokance/ue-ai-semantic-bridges/tree/main) 上下载 ZIP 文件，解压后把 `skills/ue-material-creator` 目录拷贝到对应的 `skills` 目录下：

![](../assets/download-github-skill.png)

推荐优先放在项目仓库中，这样团队成员和自动化环境可以共享同一份工作流说明。

## 目录结构

典型结构如下：

```text
.agents/
  skills/
    ue-material-creator/
      agents/
      references/
      scripts/
      .version
      SKILL.md
```

## 适用场景

适合用于：

- 创建新的 `.materialdsl`
- 编辑已有 `.materialdsl`
- 将材质视觉笔记或 shader graph 描述转换成可导入的材质 DSL
- 检查某个节点类、属性、pin、材质设置或输出是否受支持
- 校验、规范化、生成预览图，并根据预览效果修复材质 DSL
- 将已有材质或材质实例导出回 DSL，继续交给 AI 修改
- 批量导出 `/Game` 下的材质 DSL，或只导入新建 / 更新过的 DSL 文件

不适合用于：

- 运行时材质实例参数修改
- 支持范围外的任意 HLSL；只有受支持的 `MaterialExpressionCustom` 用法适合进入 DSL
- Niagara、UMG、Blueprint、Sequencer 或 MetaSound DSL
- 无关的 Unreal C++ 修改

## AI Agent 应该怎么用这个 skill

推荐工作流：

1. 将仓库根目录作为 Agent 的工作目录。
2. 明确告诉 Agent 使用 `ue-material-creator` skill。
3. 让 Agent 生成或修改 `.materialdsl`。
4. 让 Agent 运行规范化流程；该流程会先校验 DSL，成功后生成规范化后的 DSL，并在渲染可用时输出材质预览图。
5. 让 Agent 读取预览图或多帧预览，对照需求自评估材质效果；如果视觉不符合预期，修复 DSL 后重新规范化。
6. 当 DSL 和预览效果都通过后，让 Agent 将稳定后的 DSL 导入到虚幻。

示例（Codex）：

1. 使用`$`符号选择`UE Material Creator`技能（确保Codex工作目录下正确放置了该技能），选中后回车：
![](../assets/codex-app-material-example.png)
2. 输入任何材质生成或修改需求：
![alt text](../assets/codex-app-material-example-2.png) 
3. 剩下工作的交给AI：  
![alt text](../assets/codex-app-material-example-3.png)

如果你使用的是其他 Agent 工具，也可以用同样的思路表达需求：先明确要求使用 `ue-material-creator`，再给出材质描述、是否要生成材质预览或导入dsl为虚幻资产。

## 输出结果

常见输出包括：

- DSL 文件：`.ue_dsl/MaterialDSL/.../*.materialdsl`
- 导入后的材质：`/Game/.../M_*`
- 导入后的材质实例：`/Game/.../MI_*`
- 规范化、校验、导入或导出报告
- 材质预览 PNG：`Saved/MaterialSemanticBridge/MaterialDSLPreview/...`

静态材质通常输出一张预览图；包含时间驱动表达式的动态材质可能输出多帧预览。

## 编辑器面板使用说明

启用插件后，可以通过以下入口打开主面板：

- 主菜单：`AIBridge` -> `Material Semantic Bridge`

面板使用统一路由：

- `Export All DSLs`：导出 `/Game` 下的 `MaterialInstanceConstant` 和受支持的 `Material` 图，并保留 `/Game` 子目录结构
- `Import New/Changed DSLs`：导入新建或更新过的 DSL 文件，并按 DSL 类型分发到对应目标资源
- `Import DSL`：校验并导入单个 `.materialdsl` 到自动映射的目标资源
- `Export DSL`：将选中的 `Material` 或 `MaterialInstanceConstant` 导出到映射的 `.materialdsl`

单文件和批量流程都不需要用户手动选择“材质实例”或“材质图”。插件会根据 DSL 内容或所选资源类型自动分支。
