# AI Agent Skills

English | [中文](docs/README.cn.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md)

This directory contains repository-local AI agent skills used together with project tooling and workflows.

## Available Skills

### `ue-widget-creator`

`ue-widget-creator` is the skill workflow for `WidgetSemanticBridge`.

It is used to help an AI agent:

- analyze UMG UI requirements
- convert requests into supported `.widgetdsl`
- stay inside the documented widget and property support surface
- validate generated DSL before import
- import validated DSL into Unreal Widget Blueprints

This skill is meant for editor production workflows, not runtime logic generation.

- [Showcase](https://www.youtube.com/watch?v=OsDRfoziQg8)
- [Guide](docs/ue-widget-creator.en.md)

### `ue-material-creator` (Coming soon)

`ue-material-creator` is the skill workflow for `MaterialSemanticBridge`.

It is used to help an AI agent:

- analyze Unreal material requirements
- generate or edit supported `.materialdsl`
- distinguish material-instance DSL from material-graph DSL by DSL content and target asset type
- stay inside the documented `MaterialExpression*`, property, material setting, graph layout, and output support surface
- place material graph nodes clearly, including the Material Result node with `set graph.result_pos "X,Y"`
- validate generated DSL before import
- import validated DSL into Unreal `Material` or `MaterialInstanceConstant` assets

This skill is meant for editor production workflows, not runtime material instance parameter changes or unrelated Unreal C++ work.

- [Guide](docs/ue-material-creator.en.md)

## Community

- [Discord](https://discord.gg/gbbPGeVXw9)
