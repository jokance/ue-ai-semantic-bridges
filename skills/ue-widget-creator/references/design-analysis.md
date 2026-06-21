# Design Analysis

Use this step before writing DSL.

## Goal

Turn the UI request into a layout-first, support-safe widget plan before `dsl-generation` starts.

## Flow

1. Identify the main layout containers.
2. For full-screen page widgets, plan around the UMG Designer `Fill Screen` model. Treat `CvsRoot` as the viewport-sized root; anchor first-level background and main-frame children to fill the screen unless the user explicitly requests a fixed custom designer size; place margins, safe areas, and fixed-width panels inside those full-screen groups.
3. Group the design into semantic regions and functional subcontainers before placing leaf controls. Typical groups include background, header, content columns, preview, navigation, parameter groups, repeated rows, palette/options, footer actions, and modal sections.
4. Keep grouping proportional. Add a container when it owns shared layout, spacing, sizing, clipping, visual background, interaction state, repeated-item structure, or a clear semantic boundary; avoid wrappers around a single leaf widget when they do not serve one of those purposes.
5. Choose each container's widget class by responsibility: layout-only groups should use layout panels (`VerticalBox`, `HorizontalBox`, `Overlay`, `CanvasPanel`, `SizeBox`); decorative backgrounds with no children should usually use `Image`; `Border` should be reserved for a visible brush/background, padding owned by the visual skin, alignment around one child, or a deliberate frame.
6. Decide the widget tree, parent-child structure, and child order. Avoid placing most controls directly under `CvsRoot` or one large catch-all panel, but also avoid deep nesting that makes the hierarchy harder to inspect than the visual design requires.
7. Decide the slot and layout rules that control anchors, offsets, padding, alignment, spacing, sizing, and fill behavior.
8. Add the required widget properties that are necessary after the layout is stable.
9. Detect repeated or reusable UI units early. If the request contains repeated cells or reusable items, such as skill slots, bag slots, or `ListView`/`TileView` entry widgets, split them into a dedicated item widget plan instead of flattening them into one page widget.
10. Add an animation plan only when the user explicitly requests animation, or when an existing file already contains animation that must be preserved.
11. Check every requested widget, property, slot rule, and animation against `support-surface.md`.
12. Replace unsupported or unclear requests with the nearest supported fallback.

## Output

- widget tree
- semantic region and functional container plan, including any deliberate shallow grouping or avoided wrappers
- full-screen or fixed-size layout decision, including root fill anchors, safe margins, and any deliberate custom `design_size`
- widget-class choice rationale for major containers, especially any `Border` use
- reusable item widgets, when the design contains repeated cells or entry widgets
- layout and slot plan
- required widget properties
- animation plan, only when explicitly needed
- fallback decisions
- assumptions, if they affect import behavior
