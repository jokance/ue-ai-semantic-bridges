# DSL Generation

Use this step to create or edit a `.widgetdsl` draft.

## Goal

Turn the analyzed design brief into the smallest import-safe DSL draft that stays inside the current support surface and follows `project-rules.md`.

## Inputs

- the design brief from `design-analysis`
- the current `.widgetdsl` file, if this is an edit
- `spec.md`
- `support-surface.md`
- `project-rules.md`
- `examples.md`, when shape or naming is unclear

## Flow

1. Start from the widget tree and animation plan from `design-analysis`.
2. Emit only supported widget types, properties, slot keys, and animation paths.
3. Omit defaults and unnecessary structure.
4. Keep file names, widget names, and animation names stable and readable by following `project-rules.md`.
5. Choose the draft path by following `project-rules.md`.
6. Save the draft and pass it to `dsl-validation`.
7. If validation fails, rewrite the same file from the commandlet issues.

## Lookup Order

1. Check `spec.md` for syntax and canonical shape.
2. Check `support-surface.md` for allowed widgets, properties, slots, and animations.
3. Check `project-rules.md` for file naming, widget naming, animation naming, and output placement.
4. Check `examples.md` for a known-good shape.
5. If the exact key or path is still unclear, inspect the repository implementation or tests.

## Rules

- use indentation-based DSL only
- root line: `CvsRoot CanvasPanel` for generated page DSL unless an existing file must preserve a different root name
- full-screen page DSL should follow UMG Designer `Fill Screen`: omit custom `design_size` unless the request explicitly needs one, keep `CvsRoot` as the viewport root, and give first-level background or main-frame children `anchors "0,0,1,1"` with zero offsets when they should fill the screen
- property line: `key "value"`
- escape strings with `\\n`, `\\r`, `\\\"`, and `\\\\`
- do not emit `schema`, `widget`, `end`, YAML, JSON, or speculative syntax
- do not guess enum values, property names, slot keys, or animation paths
- do not emit unsupported resource, material, or object animation paths

## Strategy

- prefer the simplest supported widget tree
- preserve semantic region containers from `design-analysis`; simple means low-noise, neither flat nor deeply nested
- for full-screen pages, put viewport-filling behavior on top-level slot anchors and offsets, then handle content margins and panel widths inside grouped containers
- do not use whole-page `render_scale`, root pivot changes, or root-level fixed offsets to repair a full-screen layout; correct the slot anchors, fill behavior, padding, and internal container sizing
- avoid placing unrelated controls as siblings under `CvsRoot` or a single catch-all container when a functional grouping container would make the UMG hierarchy clearer
- collapse redundant one-child wrappers unless they are needed for slot behavior, sizing, visual background, clipping, or a named reusable/semantic boundary
- do not default to `Border` for every group. Use layout panels for layout-only structure, `Image` for childless decorative/background rectangles, `SizeBox` for sizing constraints, and `Border` only for visible framed/skinned single-child containers that need `brush_tint`, `padding`, or child alignment
- prefer supported fallback over speculative parity
- if a requested feature is blocked or excluded, leave it out and state the fallback
- treat this file as a draft until `dsl-validation` imports it and stabilizes it

## Rule

`dsl-generation = produce the smallest supported DSL draft, then hand it to dsl-validation.`
