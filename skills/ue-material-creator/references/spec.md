# Material DSL Spec

This file is the syntax reference for this skill.
For support discovery and compatibility rules, see `support-surface.md`.

## Format

- file extension: `.materialdsl`
- material graph schema line: `schema 2`
- material graph asset type: `asset_type "material"`
- style: line-oriented DSL
- comments are not part of the canonical examples; avoid them in generated files

## Schema Versions

- `schema 2` is the current material graph DSL. Use it for generated materials with `asset_type "material"`, node declarations, node properties, graph connections, and material outputs.
- `schema 1` is the material instance DSL. Use it only for `material_instance` documents that point at a parent material and override exposed parameters. It does not support `asset_type`, `material`, `node`, `set`, `connect`, or `output` graph lines.

## Core Lines

Material declaration:

```text
material "M_Name"
```

Material setting:

```text
set material.domain "surface"
set material.blend_mode "opaque"
set material.shading_model "default_lit"
set material.two_sided "false"
set material.translucency_lighting_mode "surface_per_pixel_lighting"
```

Graph layout setting:

```text
set graph.result_pos "360,0"
```

Node declaration:

```text
node <id> <MaterialExpressionClassName>
```

Node property:

```text
set <id>.<PropertyName> "<value>"
```

Connection:

```text
connect <sourceNode>.<sourcePin> <targetNode>.<targetPin>
```

Material output:

```text
output <MaterialOutputName> <sourceNode>.<sourcePin>
```

This is the canonical parser/export form. `Mode=material-schema` reports supported output names in `outputs[].name`; use those names here and do not generate arrow-style output statements.

## Schema 1 Material Instance Lines

Material instance declaration:

```text
schema 1
material_instance "MI_Name"
parent_material "/Game/Path/M_Parent.M_Parent"
```

Supported parameter override lines:

```text
scalar_param Roughness "0.25"
vector_param Tint "1,0.4,0.2,1"
texture_param AlbedoTex "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
static_switch_param USE_DETAIL "true"
```

Parameter names are unquoted tokens. Parameter values are quoted strings and must correspond to global parameters exposed by the parent material.

## Node Types

Use exact UE class names:

```text
node c MaterialExpressionConstant3Vector
node add MaterialExpressionAdd
node tex MaterialExpressionTextureSampleParameter2D
```

Do not use:

```text
node c Constant3Vector
node add Add
node p MaterialExpressionParameter
```

## Pins

Common source pins:

- `output0`
- `r`, `g`, `b`, `a`
- `rg`, `rgb`, `rgba`
- named output pins reported by `Mode=schema`

Common target pins:

- reflected input names, such as `input0`, `input1`, `coordinates`, `texture_object`, `normal`
- named dynamic pins from property values or a normalized/exported graph. `Mode=schema` reports default pins and whether the class is property-driven; it does not apply per-node dynamic properties.

## Values

Examples:

```text
set scalar.R "0.5"
set color.Constant "(R=0.8,G=0.2,B=0.1,A=1)"
set tex.Texture "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
set param.ParameterName "Tint"
set time.bIgnorePause "True"
```

Use commandlet schema when unsure about enum strings, struct text format, object path format, or property names. For material outputs, use `Mode=material-schema` for target names and keep the canonical `output <MaterialOutputName> <sourceNode>.<sourcePin>` syntax.
