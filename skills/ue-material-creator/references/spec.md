# Material DSL Spec

This file is the syntax reference for this skill.
For support discovery and compatibility rules, see `support-surface.md`.

## Format

- file extension: `.materialdsl`
- style: indentation-based DSL
- indentation: two spaces per level
- top-level document type: `material` or `material_instance`
- schema declarations are not used
- `asset_type` is not used
- comments are accepted by the parser when a trimmed line starts with `#`, but avoid them in generated canonical examples

## Material Graph

Material declaration:

```text
material "M_Name"
```

Material settings:

```text
  settings
    domain "surface"
    blend_mode "opaque"
    shading_model "default_lit"
    two_sided "false"
    translucency_lighting_mode "surface_per_pixel_lighting"
```

Graph layout settings:

```text
  graph
    result_pos "360,0"
```

Node declaration and properties:

```text
  node <id> <MaterialExpressionClassName>
    <PropertyName> "<value>"
    pos "X,Y"
```

Connections:

```text
  connections
    <sourceNode>.<sourcePin> -> <targetNode>.<targetPin>
```

Material outputs:

```text
  outputs
    <MaterialOutputName> <sourceNode>.<sourcePin>
```

`Mode=material-schema` reports supported output names in `outputs[].name`; use those names in the `outputs` block.

## Material Instance

Material instance declaration:

```text
material_instance "MI_Name"
  parent_material "/Game/Path/M_Parent.M_Parent"
```

Supported parameter overrides:

```text
  params
    scalar Roughness "0.25"
    vector Tint "1,0.4,0.2,1"
    texture AlbedoTex "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
    static_switch USE_DETAIL "true"
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
  node scalar MaterialExpressionConstant
    R "0.5"

  node color MaterialExpressionConstant3Vector
    Constant "(R=0.8,G=0.2,B=0.1,A=1)"

  node tex MaterialExpressionTextureSampleParameter2D
    Texture "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"

  node param MaterialExpressionVectorParameter
    ParameterName "Tint"

  node time MaterialExpressionTime
    bIgnorePause "True"
```

Use commandlet schema when unsure about enum strings, struct text format, object path format, or property names.
