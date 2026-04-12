# Design Analysis

Use this step before writing DSL.

## Goal

Turn the UI request into a layout-first, support-safe widget plan before `dsl-generation` starts.

## Flow

1. Identify the main layout containers.
2. Decide the widget tree, parent-child structure, and child order.
3. Decide the slot and layout rules that control anchors, offsets, padding, alignment, spacing, sizing, and fill behavior.
4. Add the required widget properties that are necessary after the layout is stable.
5. Detect repeated or reusable UI units early. If the request contains repeated cells or reusable items, such as skill slots, bag slots, or `ListView`/`TileView` entry widgets, split them into a dedicated item widget plan instead of flattening them into one page widget.
6. Add an animation plan only when the user explicitly requests animation, or when an existing file already contains animation that must be preserved.
7. Check every requested widget, property, slot rule, and animation against `support-surface.md`.
8. Replace unsupported or unclear requests with the nearest supported fallback.

## Output

- widget tree
- reusable item widgets, when the design contains repeated cells or entry widgets
- layout and slot plan
- required widget properties
- animation plan, only when explicitly needed
- fallback decisions
- assumptions, if they affect import behavior
