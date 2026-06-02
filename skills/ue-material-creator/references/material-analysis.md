# Material Analysis

Use this step before writing DSL.

## Goal

Turn the material request into a graph-first, import-safe material plan before `dsl-generation` starts.

## Flow

1. Define the TA plan: target use, first-read visual feature, quality needs, performance budget, graph strategy, exposed controls, renderer limitations, and fallback.
2. Identify the material domain, blend mode, shading model, two-sided state, and required material outputs.
3. Split the requested look into graph branches: base color, roughness, metallic/specular, normal, opacity, emissive, world-position offset, and material attributes when needed.
4. Decide the smallest production-quality set of real `MaterialExpression*` nodes needed for each branch.
5. Decide texture, parameter, and asset dependencies. Use project or engine asset paths only when they are known.
6. Decide scalar/vector channel flow. Use `.r`, `.rg`, `.rgb`, `.a`, or `.output0` deliberately.
7. Add material function calls, custom nodes, named reroutes, switches, or material attributes when the visual read, quality bar, or art direction needs them.
8. Check every node class, property, pin, setting, and output through `support-surface.md` and commandlet schema discovery. For property-driven dynamic pins, plan from the relevant property values or a known normalized/exported graph.
9. Replace unsupported or unclear requests with the nearest supported fallback.

## TA Plan

- target use and material domain
- first-read visual feature
- quality needs such as contrast, falloff, transition, masking, and art direction
- performance budget and cheapest viable production-quality graph strategy
- artist/designer parameters to expose
- Unreal rendering limitations that may affect the requested look
- closest reliable fallback when the exact request is outside material-graph scope

## Output

- material settings
- node list with exact `MaterialExpression*` class names
- connection plan
- material output plan
- required assets and parameter names
- fallback decisions
- TA plan summary
- assumptions that affect import behavior
