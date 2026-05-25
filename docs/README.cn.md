# AI Agent Skills

[English](../README.md) | 中文 | [日本語](README.ja.md) | [한국어](README.ko.md)

这个目录包含仓库本地的 AI Agent skills，用于配合项目工具链和工作流。

## 可用 Skills

### `ue-widget-creator`

`ue-widget-creator` 是 `WidgetSemanticBridge` 的 skill 工作流。

它用于帮助 AI Agent：

- 分析 UMG UI 需求
- 将需求转换为受支持的 `.widgetdsl`
- 保持在已记录的控件和属性支持面内
- 在导入前校验生成的 DSL
- 将校验后的 DSL 导入为 Unreal Widget Blueprints

该 skill 面向编辑器生产工作流，不用于运行时逻辑生成。

展示：

- [YouTube Video](https://www.youtube.com/watch?v=OsDRfoziQg8)

文档：

- [Guide (中文)](ue-widget-creator.cn.md)

### `ue-material-creator`

`ue-material-creator` 是 `MaterialSemanticBridge` 的 skill 工作流。

它用于帮助 AI Agent：

- 分析 Unreal 材质需求
- 生成或编辑受支持的 `.materialdsl`
- 根据 DSL 内容和目标资源类型区分材质实例 DSL 与材质图 DSL
- 保持在已记录的 `MaterialExpression*`、属性、材质设置、图布局和输出支持面内
- 清晰放置材质图节点，包括使用 `set graph.result_pos "X,Y"` 设置 Material Result 节点位置
- 在导入前校验生成的 DSL
- 将校验后的 DSL 导入为 Unreal `Material` 或 `MaterialInstanceConstant` 资源

该 skill 面向编辑器生产工作流，不用于运行时材质实例参数修改或无关的 Unreal C++ 工作。

文档：

- [Guide (中文)](ue-material-creator.cn.md)
