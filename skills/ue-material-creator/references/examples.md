# Examples

Use these examples as canonical shapes.

## Simple Constant Surface

```text
material "M_DebugRed"
  settings
    domain "surface"
    blend_mode "opaque"
    shading_model "default_lit"

  node color MaterialExpressionConstant3Vector
    Constant "(R=0.8,G=0.05,B=0.02,A=1)"
    pos "0,0"

  node rough MaterialExpressionConstant
    R "0.45"
    pos "0,180"

  outputs
    BaseColor color.rgb
    Roughness rough.output0
```

## Parameterized Texture Surface

```text
material "M_ParameterizedTexture"
  settings
    domain "surface"
    blend_mode "opaque"
    shading_model "default_lit"

  node uv MaterialExpressionTextureCoordinate
    UTiling "1.0"
    VTiling "1.0"
    pos "-600,0"

  node tint MaterialExpressionVectorParameter
    ParameterName "Tint"
    DefaultValue "(R=1,G=1,B=1,A=1)"
    pos "-300,-220"

  node tex MaterialExpressionTextureSampleParameter2D
    ParameterName "Albedo"
    Texture "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
    pos "-300,0"

  node mul MaterialExpressionMultiply
    pos "0,0"

  connections
    uv.output0 -> tex.coordinates
    tint.rgb -> mul.input0
    tex.rgb -> mul.input1

  outputs
    BaseColor mul.output0
```

## Named Reroute Context

```text
material "M_NamedRerouteExample"
  node value MaterialExpressionConstant3Vector
    Constant "(R=0.2,G=0.4,B=0.8,A=1)"
    pos "-900,0"

  node declaration MaterialExpressionNamedRerouteDeclaration
    Name "SharedColor"
    VariableGuid "0123456789ABCDEFFEDCBA9876543210"
    pos "-350,0"

  node usage MaterialExpressionNamedRerouteUsage
    DeclarationGuid "0123456789ABCDEFFEDCBA9876543210"
    pos "180,0"

  connections
    value.rgb -> declaration.input0

  outputs
    BaseColor usage.output0
```

## Material Attributes Output

```text
material "M_MaterialAttributes"
  node base MaterialExpressionConstant3Vector
    Constant "(R=0.2,G=0.35,B=0.9,A=1)"
    pos "-420,-180"

  node rough MaterialExpressionConstant
    R "0.6"
    pos "-420,0"

  node metal MaterialExpressionConstant
    R "0.0"
    pos "-420,180"

  node attrs MaterialExpressionMakeMaterialAttributes
    pos "180,0"

  connections
    base.rgb -> attrs.base_color
    rough.output0 -> attrs.roughness
    metal.output0 -> attrs.metallic

  outputs
    MaterialAttributes attrs.output0
```

## Material Instance

```text
material_instance "MI_StylizedWater_Wet"
  parent_material "/Game/Materials/Water/M_StylizedWater.M_StylizedWater"

  params
    scalar Roughness "0.18"
    vector Tint "0.2,0.55,0.85,1"
    texture AlbedoTex "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
    static_switch USE_DETAIL "true"
```
