---
name: ue-material-creator
description: Use when analyzing Unreal material requirements, generating or editing `.materialdsl` files for MaterialSemanticBridge, validating reflected `MaterialExpression*` nodes, material outputs, and graph layout settings such as the result node position, and iterating material DSL until it is import-ready.
---

# UE Material Creator

Use this skill for `MaterialSemanticBridge` workflows in this repository: analyze the material request, generate or edit `.materialdsl`, place nodes and the material result node clearly, normalize it through `MaterialSemanticCommandlet`, repair until normalization succeeds, then import the normalized DSL into the mapped `/Game` material target.

## When To Use

- creating a new `.materialdsl` file
- editing an existing `.materialdsl` file
- converting material notes, shader graph descriptions, screenshots, or look-dev requirements into Material DSL
- checking whether a `MaterialExpression*` class, property, pin, material setting, or output is supported before generating DSL
- setting graph layout metadata such as `graph.result_pos` to keep the Material Result node from overlapping generated nodes
- repairing a DSL draft that is failing validation, import, export, or round-trip checks

Do not use this skill for:

- Niagara, Blueprint, UMG, Sequencer, MetaSound, or Data DSL
- HLSL authoring outside `MaterialExpressionCustom`
- runtime material instance parameter setting unrelated to `.materialdsl`
- general Unreal C++ work unrelated to Material DSL

## Workflow

Always follow this loop:

1. Analyze the material from a production technical-art perspective. Read [references/material-analysis.md](references/material-analysis.md).
2. Satisfy the requested visual read and production quality bar before simplifying the graph.
3. Generate or edit concise, parameterized DSL. Read [references/dsl-generation.md](references/dsl-generation.md).
4. Normalize, repair, and import the generated DSL. Read [references/dsl-validation.md](references/dsl-validation.md).

## Technical Art Quality Bar

Prioritize in this order:

1. Correct visual read.
2. Production reliability.
3. Art-directable controls.
4. Reasonable performance.
5. Graph simplicity.

Simplicity is a constraint, not the primary goal. Do not optimize for node count alone. If an effect needs extra structure for readability, falloff, contrast, masking, or art direction, add it and explain why.

A concise material is acceptable only when it still has:

- a clear first-read visual feature
- controlled contrast
- appropriate falloff or transition
- enough parameters for art direction
- no misleading renderer assumptions
- no flat placeholder look unless the user explicitly asks for one

Before generating DSL, decide where the material will be used, what must read first, what performance budget is appropriate, what Unreal rendering limitations affect the request, and what fallback gives the closest reliable result.

## Authoritative Sources

Use these local files as the source of truth:

- DSL syntax and canonical formatting: [references/spec.md](references/spec.md)
- supported material settings, outputs, class discovery, and reflection rules: [references/support-surface.md](references/support-surface.md)
- canonical examples: [references/examples.md](references/examples.md)
- project-specific naming and placement rules: [references/project-rules.md](references/project-rules.md)
- workflow guidance:
  - [references/material-analysis.md](references/material-analysis.md)
  - [references/dsl-generation.md](references/dsl-generation.md)
  - [references/dsl-validation.md](references/dsl-validation.md)

For repository-specific naming and output placement, `project-rules.md` overrides generic examples when they conflict.

If a local reference is still not enough to disambiguate an exact property, pin, or output target, inspect the plugin implementation and tests from the project plugin as the final fallback:

- `Plugins/MaterialSemanticBridge/Source/MaterialSemanticBridgeEditor/Private/MaterialSemanticMaterialGraphService.cpp`
- `Plugins/MaterialSemanticBridge/Source/MaterialSemanticBridgeEditor/Private/MaterialSemanticCommandlet.cpp`
- `Plugins/MaterialSemanticBridge/Source/MaterialSemanticBridgeEditor/Private/Tests/MaterialSemanticBridgeAutomationTests.cpp`

## Output Rules

- Use exact real UE class names as node types, such as `MaterialExpressionConstant3Vector`.
- Do not use short aliases such as `Constant3Vector`, `VectorParameter`, or `TextureObject`.
- Do not use full class paths unless editing an existing file that already uses them; short real class names are preferred.
- Do not emit `MaterialExpressionParameter`; use concrete subclasses such as `MaterialExpressionScalarParameter`, `MaterialExpressionVectorParameter`, or texture parameter classes.
- Use only properties and pins proven by `Mode=schema` or existing import/export behavior. For property-driven dynamic pins, `Mode=schema` only flags that pins are dynamic; use the relevant property values, a normalized/exported graph, or local tests for exact pin names.
- Prefer small import-safe graphs over speculative large graphs.
- Use `set graph.result_pos "X,Y"` when the Material Result node needs an explicit graph editor position, especially when generated nodes would otherwise overlap it.
- Omit defaults whenever possible so the file stays close to canonical export shape.
- If a requested feature is unsupported, asset-dependent, or context-dependent, say so explicitly and propose the nearest supported fallback.
