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

1. Start with `material "<Name>"` for material graphs or `material_instance "<Name>"` for instances.
2. Add material settings inside a `settings` block only when needed or when preserving an existing file.
3. Emit nodes with exact `MaterialExpression*` class names.
4. Emit reflected properties as indented entries inside their owning `node` block.
5. Emit connections after all nodes inside a `connections` block: `<sourceNode>.<sourcePin> -> <targetNode>.<targetPin>`.
6. Emit material outputs last inside an `outputs` block: `<MaterialOutput> <sourceNode>.<sourcePin>`.
7. Save the draft under the Material DSL root from `project-rules.md`.
8. Pass it to `dsl-validation` for normalization.
9. If normalization fails or preview review finds a visual mismatch, rewrite the same file using the commandlet issue codes, messages, and concrete visual review feedback. If preview image generation itself fails but normalization succeeds, do not rewrite only because of the missing preview.

## Lookup Order

1. Check `spec.md` for syntax and canonical shape.
2. Check `support-surface.md` for class, property, pin, and material-output discovery commands. For material outputs, use `Mode=material-schema` for target names and `spec.md` for the canonical outputs block syntax.
3. Check `project-rules.md` for file naming and output placement.
4. Check `examples.md` for a known-good graph shape.
5. If the exact key or pin is still unclear, inspect plugin implementation or tests.

## Rules

- Use quoted values for settings, graph settings, node properties, and parameters.
- Use UE reflected property names exactly, including case.
- Use bare asset paths only when accepted by existing DSL; full object references are also accepted when already known.
- Use `<MaterialOutput> <sourceNode>.<sourcePin>` inside the `outputs` block for material outputs. `Mode=material-schema` output names are authoritative.
- For property-driven dynamic pins, `Mode=schema` only tells you that dynamic pins exist. Use the configured property values, an exported/normalized graph, or local tests to determine exact dynamic pin names.
- All generated graph DSL nodes must include `pos`. The importer does not auto-layout nodes, so missing `pos` values default to `0,0` and will overlap.
- For new material graphs, include a `graph` block with `result_pos "0,0"` and treat the Material Result node as the fixed output anchor.
- Do not place generated expression nodes at `0,0` in new graphs; reserve `0,0` for the Material Result node unless preserving an existing layout.
- Place expression nodes to the left of the Material Result node and adjust every `pos` relative to that anchor.
- Lay out nodes left-to-right by data flow, ending with output-near nodes in the rightmost expression column before the result node.
- Keep horizontal column spacing at least `420`, preferably `520`; use `560` or more for wide nodes such as texture samples, material attributes, custom expressions, or nodes with many visible pins.
- Keep same-column node vertical spacing at least `260`, preferably `320`; use `380` or more for tall nodes, texture samples, material attributes, or dense parameter groups.
- Place common input nodes in the leftmost column.
- Place output-near nodes in the rightmost column.
- Group nodes by output branch into lanes where possible to reduce crossings.
- Use `pos` only for graph readability; it does not change material behavior.
- Prefer `output0` for default scalar/vector output unless a named pin is clearer or schema/export examples show a canonical pin.
- For vector-to-scalar material outputs, connect an explicit channel such as `.r`.
- For vector material outputs, connect `.rgb` or a compatible multi-channel pin.
- Treat preview review feedback as a material-art direction bug: adjust the graph, settings, parameters, or fallback approach until the exported preview matches the requested read.
