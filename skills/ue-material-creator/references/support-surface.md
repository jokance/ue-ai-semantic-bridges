# Support Surface

MaterialSemanticBridge is reflection-first. The supported surface is the set of safe, resolvable, non-deprecated `UMaterialExpression` classes reported by commandlet schema discovery.

## Current Naming Contract

- Use exact real UE expression class names as DSL node types.
- Preferred form: `MaterialExpressionConstant3Vector`.
- Full class paths are accepted by the implementation but should not be generated unless preserving an existing file.
- Short aliases such as `Constant3Vector`, `VectorParameter`, or `TextureSample` are not supported.
- `MaterialExpressionParameter` is excluded because it is a base class; use concrete subclasses.

## Known Compatibility Baseline

The latest local compatibility smoke for safe reflected expression classes reported:

```text
class_count: 339
compatible_count: 339
incompatible_count: 0
minimal_import_succeeded_count: 339
minimal_import_failed_count: 0
minimal_output_connected_count: 318
compatibility_percent: 100
```

Treat commandlet output from the current worktree as more authoritative than this snapshot.

## Discovery

Use commandlet discovery instead of guessing:

- `Mode=schema-list`: supported expression classes
- `Mode=schema -Class=<MaterialExpressionClassName>`: properties, input pins, output pins, dynamic pin notes
- `Mode=material-schema`: material settings and material outputs
- `Mode=compatibility -ConnectSubjectOutput=true`: broad import smoke

## Common Safe Classes

These are common, but still prefer schema checks for exact properties and pins:

- constants and parameters:
  - `MaterialExpressionConstant`
  - `MaterialExpressionConstant2Vector`
  - `MaterialExpressionConstant3Vector`
  - `MaterialExpressionConstant4Vector`
  - `MaterialExpressionScalarParameter`
  - `MaterialExpressionVectorParameter`
- texture and coordinates:
  - `MaterialExpressionTextureCoordinate`
  - `MaterialExpressionTextureObject`
  - `MaterialExpressionTextureObjectParameter`
  - `MaterialExpressionTextureSample`
  - `MaterialExpressionTextureSampleParameter2D`
  - `MaterialExpressionTextureSampleParameterCube`
  - `MaterialExpressionTextureSampleParameterVolume`
- math and channel flow:
  - `MaterialExpressionAdd`
  - `MaterialExpressionSubtract`
  - `MaterialExpressionMultiply`
  - `MaterialExpressionDivide`
  - `MaterialExpressionLinearInterpolate`
  - `MaterialExpressionClamp`
  - `MaterialExpressionOneMinus`
  - `MaterialExpressionComponentMask`
  - `MaterialExpressionAppendVector`
- coordinates and view:
  - `MaterialExpressionWorldPosition`
  - `MaterialExpressionCameraVectorWS`
  - `MaterialExpressionPixelNormalWS`
  - `MaterialExpressionVertexNormalWS`
  - `MaterialExpressionReflectionVectorWS`
- material attributes and graph helpers:
  - `MaterialExpressionMakeMaterialAttributes`
  - `MaterialExpressionBreakMaterialAttributes`
  - `MaterialExpressionSetMaterialAttributes`
  - `MaterialExpressionGetMaterialAttributes`
  - `MaterialExpressionNamedRerouteDeclaration`
  - `MaterialExpressionNamedRerouteUsage`
  - `MaterialExpressionMaterialFunctionCall`
  - `MaterialExpressionCustom`

## Material Settings

Use `Mode=material-schema` for exact values. Common settings include:

- `material.domain`
- `material.blend_mode`
- `material.shading_model`
- `material.two_sided`
- `material.opacity_mask_clip_value`
- `graph.result_pos`

## Material Outputs

Use `Mode=material-schema` for the full list. Common outputs include:

- `BaseColor`
- `Metallic`
- `Specular`
- `Roughness`
- `EmissiveColor`
- `Opacity`
- `OpacityMask`
- `Normal`
- `AmbientOcclusion`
- `WorldPositionOffset`
- `MaterialAttributes`

## Context-Dependent Nodes

- `MaterialExpressionNamedRerouteUsage` needs a matching `MaterialExpressionNamedRerouteDeclaration` with the same `DeclarationGuid`/`VariableGuid`.
- `MaterialExpressionMaterialFunctionCall` usually needs `MaterialFunction` set to a valid function asset.
- Texture, collection, font, sparse volume texture, runtime virtual texture, and material function properties need valid asset paths.
- Dynamic pin classes such as custom, switch, convert, function call, material attributes, and custom output classes should be checked with `Mode=schema` after setting dynamic properties.
