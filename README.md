# AI Agent Skills

English | [中文](docs/README.cn.md) | [日本語](docs/README.ja.md) | [한국어](docs/README.ko.md)

This directory contains repository-local AI agent skills used together with project tooling and workflows.

## Available Skills

### `ue-widget-creator` (WidgetSemanticBridge)

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

### `ue-material-creator` (MaterialSemanticBridge)

`ue-material-creator` is the skill workflow for `MaterialSemanticBridge`.

It is used to help an AI agent:

- analyze material look-dev requirements and choose the right `Material` or `MaterialInstanceConstant` workflow
- generate and edit supported `.materialdsl` for material graphs and material instances
- validate and normalize DSL before it is imported into Unreal Engine
- generate material preview images and reports so AI agents can visually self-evaluate the result and repair the `.materialdsl` before final import
- import and export single assets between `.materialdsl` and Unreal `Material` / `MaterialInstanceConstant` assets
- batch export `/Game` materials to DSL and import new or changed DSL files back into matching `/Game` folders
- query supported material settings, outputs, and `MaterialExpression*` schemas for safer agent generation

This skill is meant for editor production workflows, not runtime material instance parameter changes or unrelated Unreal C++ work.

- [Showcase](https://youtu.be/yN9iPlmiWok)
- [Guide](docs/ue-material-creator.en.md)

## Community

- [Discord](https://discord.gg/gbbPGeVXw9)
