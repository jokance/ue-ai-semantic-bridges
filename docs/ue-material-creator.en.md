# ue-material-creator Guide

English | [中文](ue-material-creator.cn.md) | [日本語](ue-material-creator.ja.md) | [한국어](ue-material-creator.ko.md)

This document explains how to use the `ue-material-creator` skill together with the `MaterialSemanticBridge` plugin so an AI Agent can generate, validate, normalize, import, and export Unreal material DSL.

## What It Is

`ue-material-creator` is a workflow skill for AI Agents.

It is not Unreal runtime code, and it is not a standalone plugin. Its purpose is to guide an AI Agent to:

- analyze material requirements
- generate or edit supported `.materialdsl`
- choose the correct material-instance or material-graph DSL form
- stay inside the documented `MaterialExpression*`, property, material setting, graph layout, and material output support surface
- validate and normalize DSL before import
- import validated DSL into `Material` or `MaterialInstanceConstant` assets

## Relationship With MaterialSemanticBridge

This setup consists of two parts:

- `MaterialSemanticBridge`: the Unreal Editor plugin responsible for validation, import, export, and editor integration
- `ue-material-creator`: the AI Agent skill responsible for requirement analysis and DSL generation workflow

The plugin executes the work. The skill defines how the Agent should write and repair DSL.

## Value for Game Development Productivity

In game projects, materials usually iterate alongside art direction, level environments, performance budgets, and gameplay feedback. Using `MaterialSemanticBridge` together with `ue-material-creator` turns “describe the material need -> generate DSL -> validate / normalize -> import Unreal assets” into a repeatable workflow, reducing the time spent hand-building nodes, tuning parameters, and maintaining material variants.

Typical direct benefits include:

- Faster material prototyping for surfaces such as terrain, stone, metal, fabric, and VFX base materials
- Look-dev notes, shader graph descriptions, or plain-text requirements can become importable `Material` / `MaterialInstanceConstant` assets with less information loss between the idea and the editor asset
- Because material instance parameters are represented as `.materialdsl` text, AI can batch-generate or adjust variants for color, roughness, textures, static switches, and other supported overrides under the same parent material
- Even if you are not a technical artist, you can use this skill and plugin to create the material effect you want
- After batch-exporting existing materials or material instances, AI can continue from real project assets instead of guessing from a blank graph
- Material DSL works well with version control and code review, giving technical artists, programmers, and AI Agents a readable shared artifact
- Once repetitive graph setup, variant generation, and asset synchronization are handled by the plugin and skill, developers can spend more time on art judgment, performance tradeoffs, and runtime presentation

## Installation

### 1. Install the Plugin

`MaterialSemanticBridge` will be distributed as an Unreal Editor plugin. After it is published on Fab, install it from the Fab listing with `Install to Engine`.

`MaterialSemanticBridge` supports both installation modes:

- project plugin: `<Project>/Plugins/MaterialSemanticBridge`
- engine plugin: `<Engine>/Plugins/.../MaterialSemanticBridge`

After installation, enable the plugin in your project: in Unreal Editor, go to `Edit` -> `Plugins`, find `MaterialSemanticBridge`, and enable it.

### 2. Place the Skill

Open `AIBridge` -> `Material Semantic Bridge` in Unreal Editor, then use `Agent Skill Setup` to copy the bundled skill into your project. The default `Destination Root` is the project root, but you can click `Browse` to choose another folder:

![](../assets/copy_skill.jpg)

Keep the target that matches the Agent tool you use:

- Codex / Gemini CLI / Cursor / GitHub Copilot / OpenCode and other `AGENTS.md`-compatible Agent tools: `.agents/skills/ue-material-creator/`
- Claude Code: `.claude/skills/ue-material-creator/`

You can also download the ZIP file directly from GitHub after the public release, unzip it, and copy the `ue-material-creator` directory into the corresponding `skills` directory:

![](../assets/github_skill.jpg)

It is recommended to keep it in the project repository so teammates and automation environments can share the same workflow instructions.

## Directory Structure

A typical layout looks like this:

```text
.agents/
  skills/
    ue-material-creator/
      SKILL.md
      references/
```

## DSL Types

Material instance DSL is for `MaterialInstanceConstant` assets. It describes the parent material and supported parameter overrides:

```text
schema 1
material_instance "MI_Stone_Wet"
parent_material "/Game/Materials/M_Stone.M_Stone"

scalar_param Roughness "0.18"
vector_param Tint "(R=0.45,G=0.52,B=0.58,A=1)"
texture_param BaseColorTexture "/Game/Textures/T_Stone_D.T_Stone_D"
static_switch_param UseWetLayer "true"
```

Material graph DSL is for `Material` assets. It describes graph nodes, properties, connections, outputs, and graph layout:

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

Use `set graph.result_pos "X,Y"` when the Material Result node needs a clear editor position and should not overlap generated nodes.

## Suitable Use Cases

Good fits:

- creating new `.materialdsl`
- editing existing `.materialdsl`
- converting look-dev notes or shader graph descriptions into importable material DSL
- checking whether a node class, property, pin, setting, or output is supported
- validating, normalizing, and importing material DSL
- exporting existing supported materials or material instances back to DSL for AI editing

Not suitable for:

- runtime material instance parameter changes
- arbitrary HLSL outside supported `MaterialExpressionCustom` usage
- Niagara, UMG, Blueprint, Sequencer, or MetaSound DSL
- unrelated Unreal C++ changes

## How an AI Agent Should Use This Skill

Recommended workflow:

1. Use the repository root as the Agent working directory.
2. Explicitly tell the Agent to use the `ue-material-creator` skill.
3. Ask the Agent to generate or modify `.materialdsl`.
4. Ask the Agent to validate or normalize the DSL.
5. Ask the Agent to import the validated DSL into the mapped `/Game` asset.

Example:

```shell
cd /path/to/your/project
codex
$ue-material-creator Create a material graph DSL for a wet stone surface with a tinted base color and roughness output.
```

## Outputs

Common outputs include:

- DSL files: `.ue_dsl/MaterialDSL/.../*.materialdsl`
- imported materials: `/Game/.../M_*`
- imported material instances: `/Game/.../MI_*`
- validation or import reports when commandlet workflows are used

## Editor Panel Guide

After enabling the plugin, open the main panel from:

- main menu: `AIBridge` -> `Material Semantic Bridge`

The panel uses unified routing:

- `Export All DSLs`: exports `MaterialInstanceConstant` assets and supported `Material` graphs under `/Game`
- `Import New/Changed DSLs`: imports new or newer-changed DSL files and routes each file by DSL type
- `Import DSL`: validates and imports a single `.materialdsl` into its auto-mapped target asset
- `Export DSL`: exports a selected `Material` or `MaterialInstanceConstant` to its mapped `.materialdsl`

Single-file and batch workflows do not require the user to choose “material instance” or “material graph” manually. The plugin routes by DSL content or selected asset type.
