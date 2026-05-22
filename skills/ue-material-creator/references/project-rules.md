# Project Rules

## Files

- DSL file names should start with `M_` for materials.
  Example: `M_StylizedWater.materialdsl`
- Place all AI-generated material DSL files under `.ue_dsl/MaterialDSL/Materials/<feature-or-folder>/`.
- Use an existing subdirectory when it clearly matches the material's area or feature.
- The plugin root remains `.ue_dsl/MaterialDSL/`, and DSL files may also exist directly under that root or other subdirectories.
- The mapped Unreal object path mirrors the DSL path relative to `.ue_dsl/MaterialDSL/`.
  Example: `.ue_dsl/MaterialDSL/Materials/Environment/M_Water.materialdsl` maps to `/Game/Materials/Environment/M_Water`.
- When editing an existing DSL file, preserve its path and material name unless the user asks for a rename.

## Naming

- Material asset names should use English PascalCase after the `M_` prefix.
- Node ids should be short, stable, and readable.
  Examples: `baseColor`, `roughness`, `normalTex`, `mulTint`
- Parameter names should be user-facing PascalCase.
  Examples: `Tint`, `RoughnessScale`, `NormalStrength`, `Albedo`
- Avoid Chinese, pinyin, spaces, and mixed-language ids in generated DSL.

## Compatibility

- Prefer engine built-in fallback assets only when a texture asset is required and the user did not provide one.
- Keep generated graphs deterministic: stable node ids, stable parameter names, and no random GUIDs unless a node requires a GUID relation such as named reroute declaration/usage.
- Keep generated graph layouts deterministic: every graph node must have a `pos`, nodes should be layered left-to-right by data flow, common inputs should be leftmost, output-near nodes should be rightmost, and same-column nodes should use at least `180` vertical spacing.
- For `ExpressionGUID`, preserve existing values during edits. For new parameter nodes, omit it unless import validation requires one.
