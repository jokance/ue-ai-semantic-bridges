# AI Agent Skills

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

Documentation:

- [Guide (English)](docs/ue-widget-creator.en.md)
- [Guide (中文)](docs/ue-widget-creator.cn.md)
