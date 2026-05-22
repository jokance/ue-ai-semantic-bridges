# Material DSL Spec

This file is the syntax reference for this skill.
For support discovery and compatibility rules, see `support-surface.md`.

## Format

- file extension: `.materialdsl`
- schema line: `schema 2`
- asset type: `asset_type "material"`
- style: line-oriented DSL
- comments are not part of the canonical examples; avoid them in generated files

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
- named dynamic pins reported by `Mode=schema`

## Values

Examples:

```text
set scalar.R "0.5"
set color.Constant "(R=0.8,G=0.2,B=0.1,A=1)"
set tex.Texture "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
set param.ParameterName "Tint"
set time.bIgnorePause "True"
```

Use commandlet schema when unsure about enum strings, struct text format, object path format, or property names.
