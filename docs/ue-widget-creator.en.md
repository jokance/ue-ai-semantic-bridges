# ue-widget-creator Guide

This document explains how to use the `ue-widget-creator` skill together with the `WidgetSemanticBridge` plugin so an AI Agent can generate static UI, widget animation DSL, validate it, preview it, and import it into UMG Widget Blueprints.

![Cover](../assets/cover_main.jpg)

## What It Is

`ue-widget-creator` is a workflow skill designed for AI Agents.

It is not Unreal runtime code, and it is not a standalone plugin. Its purpose is to guide an AI Agent to:

- analyze UI requirements
- convert those requirements into supported `.widgetdsl`
- keep generation within the set of widgets, properties, slots, and animation tracks supported by `WidgetSemanticBridge`
- generate or edit `animation` / `track` sections
- run validation and preview before import
- import validated DSL into real `WBP_*` assets in Unreal

## Relationship With WidgetSemanticBridge

This setup consists of two parts:

- `WidgetSemanticBridge`: the [Unreal Editor plugin](https://www.fab.com/listings/92270793-0b09-406a-81b9-d6f9f307044f) responsible for validation, preview, and import
- `ue-widget-creator`: the AI Agent skill responsible for requirement analysis and the DSL generation workflow

The plugin executes the work. The skill defines the workflow.

## How It Improves Game UI Development

In game projects, UI often needs repeated iteration as gameplay, balance, and visual design keep changing. By combining the `WidgetSemanticBridge` plugin with `ue-widget-creator`, you can turn “describe requirements -> generate DSL -> validate / preview -> import blueprint” into a repeatable workflow, reducing a large amount of manual UMG setup and editor clicking.

Common benefits include:

- faster UI prototyping for inventory, main menu, quest panels, popups, and similar screens
- design mockups, sketches, or written requirements can be turned into importable Widget Blueprints more quickly, reducing information loss during implementation
- because layout and part of the animation are expressed as `.widgetdsl` text, AI can understand, generate, and modify the UI description more easily, speeding up iteration on UI interaction, state changes, and flow adjustments
- generated and re-exported DSL can also drive AI-written UI logic: after WBP changes, export DSL again and let AI update the logic, often removing the need to hand-write UI code; this is especially suitable for scripting languages such as Lua, TypeScript, or Python, where AI iterates faster than with C++ or Blueprint
- validation and preview before import help catch unsupported widgets, properties, or layout issues earlier, reducing rework
- bulk generation and modification of `.widgetdsl` files fits team collaboration and automation workflows better, making UI assets easier to version-control
- with structural UI work handled by the plugin and skill, developers can spend more time on gameplay logic, interaction polish, and runtime behavior

## Installation

### 1. Install the Plugin

Plugin link: [WidgetSemanticBridge](https://www.fab.com/listings/92270793-0b09-406a-81b9-d6f9f307044f)

If the plugin comes from Fab, it is typically installed into the Unreal Engine directory via `Install to Engine`.


`WidgetSemanticBridge` supports both installation modes:

- project plugin: `<Project>/Plugins/WidgetSemanticBridge`
- engine plugin: `<Engine>/Plugins/.../WidgetSemanticBridge`

After installation, enable the plugin in your project: in Unreal Editor, go to `Edit` -> `Plugins`, find `WidgetSemanticBridge`, and enable it.

### 2. Place the Skill

Open `AIBridge` -> `Widget Semantic Bridge` in Unreal Editor, then use `Agent Skill Setup` to copy the bundled skill into your project. The default `Destination Root` is the project root, but you can click `Browse` to choose another folder:

![](../assets/copy_skill.jpg)

Keep the target that matches the Agent tool you use:

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode and other `AGENTS.md`-compatible Agent tools: `.agents/skills/ue-widget-creator/`
- Claude Code: `.claude/skills/ue-widget-creator/`

You can also download the ZIP file directly from GitHub, unzip it, and copy the `ue-widget-creator` directory into the corresponding `skills` directory:

![](../assets/github_skill.jpg)


It is recommended to keep it in the project repository so teammates and automation environments can share the same workflow instructions.

## Directory Structure

A typical layout looks like this:

```text
.agents/
  skills/
    ue-widget-creator/
      SKILL.md
      references/
      scripts/
```

## Suitable Use Cases

Good fits:

- generating UMG UI from text requirements, design mockups, or sketches
- writing `.widgetdsl` based on a design image or written specification
- modifying existing `.widgetdsl`
- generating or editing animation tracks for supported widgets
- checking whether a widget, property, or animation track is supported before import
- validating and importing DSL files in batch into Widget Blueprints

Not suitable for:

- Event Graph generation
- runtime bindings or delegates
- arbitrary custom widgets outside the current supported surface

## How an AI Agent Should Use This Skill

Whether you use `Claude Code`, `Codex`, or `Gemini CLI`, the core requirements are the same:

- the Agent can access the project repository
- the Agent can run local scripts or commandlets, though it may ask for permission to run commands

Recommended workflow:

1. Use the repository root as the Agent working directory
2. Explicitly tell the Agent to use the `ue-widget-creator` skill
3. Ask the Agent to generate or modify `.widgetdsl`
4. Ask the Agent to generate or modify widget animations
5. Ask the Agent to run validate / preview first
6. Ask the Agent to import the DSL and generate the Widget Blueprint

Based on my experience, GPT-5.4+ models generate better UI results than other models. If another model does not produce the result you want, try GPT-5.4+.

### Example

```shell
cd /path/to/your/project
codex
$ue-widget-creator Create a full-screen inventory widget with a 4x7 item slot grid on the left and an item details panel on the right.
```

If you use a different Agent tool, the same idea still applies: first state clearly that it should use `ue-widget-creator`, then provide the UI description, layout requirements, and whether animation or blueprint import is needed.

## Outputs

Common outputs include:

- DSL files: `.ue_dsl/WidgetDSL/.../WBP_*.widgetdsl`
- DSL files with animation: also stored in `.ue_dsl/WidgetDSL/.../WBP_*.widgetdsl`
- preview images: `Saved/WidgetDSLPreview/.../*.png`
- imported blueprints: `/Game/.../WBP_*` inside the project

## Editor Panel Guide

After enabling the plugin, you can open the main panel from:

- main menu: `AIBridge` -> `Widget Semantic Bridge`

If you only want to export a single existing Widget Blueprint to DSL, you can also right-click a Widget Blueprint in the Content Browser and use `Export To Widget DSL`.

![Widget Semantic Bridge Panel](../assets/widget_panel.jpg)

The panel is mainly divided into three parts:

### 1. Batch Export / Batch Import

The two buttons at the top are for project-wide batch operations:

- `Export All WBPs`: batch-export Widget Blueprints under `/Game` to `<Project>/.ue_dsl/WidgetDSL` while preserving the original `/Game` subfolder structure
- `Import New/Changed DSLs`: batch-import DSL files from `<Project>/.ue_dsl/WidgetDSL`, processing only new files or DSL files that are newer and different from the current blueprint export

This is useful for team workflows, batch synchronization, or when AI has already generated multiple `.widgetdsl` files.

### 2. Single-File Import: `Import DSL Into Widget Blueprint`

This imports a single `.widgetdsl` into a Widget Blueprint in Unreal.

- Select the target file in `DSL File`, and it is recommended to click `Validate` first
- `Target WBP` will automatically show the import target
- After confirming everything looks correct, click `Import DSL`

Note: the DSL file must be located under `<Project>/.ue_dsl/WidgetDSL`, otherwise the panel cannot auto-map the target blueprint path.

### 3. Single-File Export: `Export Widget Blueprint To DSL`

This exports an existing Widget Blueprint back to `.widgetdsl`.

- Select the target asset under `/Game` in `Widget Blueprint`
- `Output DSL File` will automatically show the output path
- Click `Export DSL` to perform the export

This is useful when you manually adjust the UI in UMG and want to sync the result back into DSL for further AI editing or version control.
