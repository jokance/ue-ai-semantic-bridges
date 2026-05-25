# DSL Generation

Use this step to create or edit a `.materialdsl` draft.

## Goal

Turn the material plan into the smallest import-safe DSL draft that follows `project-rules.md`.

## Inputs

- the material plan from `material-analysis`
- the current `.materialdsl` file, if this is an edit
- `spec.md`
- `support-surface.md`
- `project-rules.md`
- `examples.md`, when shape or naming is unclear

## Flow

1. Start with `schema 2`, `asset_type "material"`, and `material "<Name>"`.
2. Add material settings only when needed or when preserving an existing file.
3. Emit nodes with exact `MaterialExpression*` class names.
4. Emit reflected properties with `set <node>.<PropertyName> "<value>"`.
5. Emit connections after all nodes: `connect <sourceNode>.<sourcePin> <targetNode>.<targetPin>`.
6. Emit material outputs last: `output <MaterialOutput> <sourceNode>.<sourcePin>`.
7. Save the draft under the Material DSL root from `project-rules.md`.
8. Pass it to `dsl-validation` for normalization.
9. If normalization fails, rewrite the same file using the commandlet issue codes and messages.

## Lookup Order

1. Check `spec.md` for syntax and canonical shape.
2. Check `support-surface.md` for class, property, pin, and material-output discovery commands.
3. Check `project-rules.md` for file naming and output placement.
4. Check `examples.md` for a known-good graph shape.
5. If the exact key or pin is still unclear, inspect plugin implementation or tests.

## Rules

- Use quoted values for `set` values.
- Use UE reflected property names exactly, including case.
- Use bare asset paths only when accepted by existing DSL; full object references are also accepted when already known.
- All generated graph DSL nodes must include `pos`. The importer does not auto-layout nodes, so missing `pos` values default to `0,0` and will overlap.
- Use `set graph.result_pos "X,Y"` when you need to move the material result node away from expression nodes.
- Lay out nodes left-to-right by data flow.
- Keep same-column node vertical spacing at least `180`, preferably `220`.
- Place common input nodes in the leftmost column.
- Place output-near nodes in the rightmost column.
- Group nodes by output branch into lanes where possible to reduce crossings.
- Use `pos` only for graph readability; it does not change material behavior.
- Prefer `output0` for default scalar/vector output unless a named pin is clearer or schema/export examples show a canonical pin.
- For vector-to-scalar material outputs, connect an explicit channel such as `.r`.
- For vector material outputs, connect `.rgb` or a compatible multi-channel pin.
