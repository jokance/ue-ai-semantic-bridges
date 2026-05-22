# Examples

Use these examples as canonical shapes.

## Simple Constant Surface

```text
schema 2
asset_type "material"
material "M_DebugRed"
set material.domain "surface"
set material.blend_mode "opaque"
set material.shading_model "default_lit"

node color MaterialExpressionConstant3Vector
set color.Constant "(R=0.8,G=0.05,B=0.02,A=1)"
set color.pos "0,0"

node rough MaterialExpressionConstant
set rough.R "0.45"
set rough.pos "0,180"

output BaseColor color.rgb
output Roughness rough.output0
```

## Parameterized Texture Surface

```text
schema 2
asset_type "material"
material "M_ParameterizedTexture"
set material.domain "surface"
set material.blend_mode "opaque"
set material.shading_model "default_lit"

node uv MaterialExpressionTextureCoordinate
set uv.UTiling "1.0"
set uv.VTiling "1.0"
set uv.pos "-600,0"

node tint MaterialExpressionVectorParameter
set tint.ParameterName "Tint"
set tint.DefaultValue "(R=1,G=1,B=1,A=1)"
set tint.pos "-300,-220"

node tex MaterialExpressionTextureSampleParameter2D
set tex.ParameterName "Albedo"
set tex.Texture "/Script/Engine.Texture2D'/Engine/EngineResources/WhiteSquareTexture.WhiteSquareTexture'"
set tex.pos "-300,0"

node mul MaterialExpressionMultiply
set mul.pos "0,0"

connect uv.output0 tex.coordinates
connect tint.rgb mul.input0
connect tex.rgb mul.input1

output BaseColor mul.output0
```

## Named Reroute Context

```text
schema 2
asset_type "material"
material "M_NamedRerouteExample"

node value MaterialExpressionConstant3Vector
set value.Constant "(R=0.2,G=0.4,B=0.8,A=1)"
set value.pos "-900,0"

node declaration MaterialExpressionNamedRerouteDeclaration
set declaration.Name "SharedColor"
set declaration.VariableGuid "0123456789ABCDEFFEDCBA9876543210"
set declaration.pos "-350,0"

node usage MaterialExpressionNamedRerouteUsage
set usage.DeclarationGuid "0123456789ABCDEFFEDCBA9876543210"
set usage.pos "180,0"

connect value.rgb declaration.input0

output BaseColor usage.output0
```

## Material Attributes Output

```text
schema 2
asset_type "material"
material "M_MaterialAttributes"

node attrs MaterialExpressionMakeMaterialAttributes
set attrs.BaseColor "(R=0.2,G=0.35,B=0.9,A=1)"
set attrs.Roughness "0.6"
set attrs.Metallic "0.0"
set attrs.pos "180,0"

output MaterialAttributes attrs.output0
```
