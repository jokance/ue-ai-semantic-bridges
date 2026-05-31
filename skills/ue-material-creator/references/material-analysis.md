# Material Analysis

Use this step before writing DSL.

## Goal

Turn the material request into a graph-first, import-safe material plan before `dsl-generation` starts.

## Flow

1. Identify the material domain, blend mode, shading model, two-sided state, and required material outputs.
2. Split the requested look into graph branches: base color, roughness, metallic/specular, normal, opacity, emissive, world-position offset, and material attributes when needed.
3. Decide the smallest set of real `MaterialExpression*` nodes needed for each branch.
4. Decide texture, parameter, and asset dependencies. Use project or engine asset paths only when they are known.
5. Decide scalar/vector channel flow. Use `.r`, `.rg`, `.rgb`, `.a`, or `.output0` deliberately.
6. Add material function calls, custom nodes, named reroutes, switches, or material attributes only when the request needs them.
7. Check every node class, property, pin, setting, and output through `support-surface.md` and commandlet schema discovery. For property-driven dynamic pins, plan from the relevant property values or a known normalized/exported graph.
8. Replace unsupported or unclear requests with the nearest supported fallback.

## Output

- material settings
- node list with exact `MaterialExpression*` class names
- connection plan
- material output plan
- required assets and parameter names
- fallback decisions
- assumptions that affect import behavior
