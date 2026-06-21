---
name: ue-widget-creator
description: Use when analyzing Unreal UMG UI requirements, generating or editing `.widgetdsl` files for WidgetSemanticBridge, validating whether requested widgets, properties, and animation tracks are supported, and iterating unsupported designs into import-ready DSL.
---

# UE Widget Creator

Use this skill for `WidgetSemanticBridge` workflows in this repository: analyze the UI request, generate or edit `.widgetdsl`, validate it through the repository wrapper, then import the stabilized DSL into the mapped `/Game` Widget Blueprint target.

## When To Use

- creating a new `.widgetdsl` file
- editing an existing `.widgetdsl` file
- converting UMG design notes, screenshots, or widget requirements into Widget DSL
- checking whether a widget property or animation track is supported before generating DSL
- repairing a DSL draft that is failing import, export, or round-trip validation

Do not use this skill for:

- Event Graph logic, bindings, or delegates
- runtime list item data
- widgets outside the current `WidgetSemanticBridge` scope
- general Unreal C++ work unrelated to Widget DSL

## Workflow

Always follow this loop:

1. Analyze the design. Read [references/design-analysis.md](references/design-analysis.md).
2. Generate or edit DSL. Read [references/dsl-generation.md](references/dsl-generation.md).
3. Pass that generated DSL file into validation. Read [references/dsl-validation.md](references/dsl-validation.md).

## Authoritative Sources

Use these local files as the source of truth:

- DSL syntax and canonical formatting: [references/spec.md](references/spec.md)
- supported widgets, properties, slot families, and animation families: [references/support-surface.md](references/support-surface.md)
- canonical examples: [references/examples.md](references/examples.md)
- project-specific naming and placement rules: [references/project-rules.md](references/project-rules.md)
- workflow guidance:
  - [references/design-analysis.md](references/design-analysis.md)
  - [references/dsl-generation.md](references/dsl-generation.md)
  - [references/dsl-validation.md](references/dsl-validation.md)

For repository-specific naming, animation naming, and output placement, `project-rules.md` overrides generic examples when they conflict.

This workflow supports both installation modes for `WidgetSemanticBridge`:

- project plugin: `<Project>/Plugins/WidgetSemanticBridge`
- engine plugin: `<Engine>/Plugins/.../WidgetSemanticBridge`

The validation/import workflow should work in either case as long as the project has the plugin enabled.

If a local reference is still not enough to disambiguate an exact DSL key, slot key, or animation path, inspect the plugin implementation and tests from the plugin's actual installed location as the final fallback. If the project contains a local plugin copy, use that first; otherwise inspect the corresponding engine plugin directory:

- `Plugins/WidgetSemanticBridge/Source/WidgetSemanticBridgeEditor/Private/WidgetSemanticWidgetSerialization.cpp`
- `Plugins/WidgetSemanticBridge/Source/WidgetSemanticBridgeEditor/Private/WidgetSemanticSlotSerialization.cpp`
- `Plugins/WidgetSemanticBridge/Source/WidgetSemanticBridgeEditor/Private/WidgetSemanticAnimationSerialization.cpp`
- `Plugins/WidgetSemanticBridge/Source/WidgetSemanticBridgeEditor/Private/Tests/WidgetSemanticBridgeAutomationTests.cpp`

## Output Rules

- Stay inside the frozen widget scope.
- Use only supported properties and animation tracks.
- Prefer the simplest import-safe widget tree that satisfies the request, but keep it structurally maintainable.
- For full-screen page widgets, design against the UMG Designer `Fill Screen` model: keep `CvsRoot` as the viewport-sized root, anchor first-level background or main-frame children to fill the screen with zero offsets unless the request explicitly needs a fixed custom designer size, and control margins inside those groups.
- Group widgets by semantic UI regions and functions. Do not flatten most controls directly under `CvsRoot` or one large catch-all panel.
- Keep grouping proportional. Do not add deep wrapper chains or single-child containers unless they provide layout, sizing, clipping, visual background, slot behavior, or a reusable semantic boundary.
- Use named containers for major areas and real functional groups such as background, header, content columns, preview, navigation, parameter groups, repeated rows, footer actions, and modal sections before placing leaf controls.
- Choose container widgets by responsibility. Prefer layout panels (`VerticalBox`, `HorizontalBox`, `Overlay`, `CanvasPanel`, `SizeBox`) for structure; use `Border` only when the container needs a visible brush/background, padding owned by the visual skin, alignment around one child, or a deliberate frame.
- Do not compensate for full-screen layout problems by changing whole-page `render_scale`, `render_transform.pivot`, or root-level offsets. Fix the anchors, fill behavior, padding, and internal container sizing instead.
- Do not invent syntax, keys, enum values, or animation paths.
- Omit defaults whenever possible so the file stays close to canonical export shape.
- If a requested feature is unsupported, blocked, or excluded, say so explicitly and propose the nearest supported fallback.
