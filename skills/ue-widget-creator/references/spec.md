# Widget DSL Spec

This file is the syntax reference for this skill.
For the supported widget catalog, blueprint metadata, property whitelist, and text/localization support surface, see `support-surface.md`.

## Format

- file extension: `.widgetdsl`
- style: indentation-based DSL
- do not use JSON, YAML, XML, `schema`, or `end` markers

## Core Blocks

- blueprint interface declaration:

```text
implements "UserObjectListEntry"
```

- parent Widget Blueprint / UserWidget class:

```text
parent_class "/Game/UI/WBP_UIBase.WBP_UIBase_C"
```

- designer preview size:

```text
design_size "1280,720"
```

- widget declaration:

```text
WidgetName WidgetType
```

- widget property:

```text
key "value"
```

- slot block:

```text
slot
  key "value"
```

- animation block:

```text
animation "AnimName"
  duration "1.0"
  track WidgetName
    property_path
      0 "value"
      0.25 "value"
```

- grouped animation path:

```text
animation "AnimIntro"
  track TxtTitle
    color_and_opacity
      r
        0 "1"
        0.25 "0.5"
      a
        0 "0.25"
        0.25 "1"
```

## Escaping

Quoted strings support:

- `\\n`
- `\\r`
- `\\\"`
- `\\\\`

## Canonical Rules

- export omits default-valued widget and slot properties
- export emits supported blueprint metadata before the root widget in this order: `parent_class`, `design_size`, `implements`
- `parent_class` defaults to `/Script/UMG.UserWidget`, so canonical export omits that default
- `design_size` exports only when the Widget Blueprint uses a custom designer size
- `is_variable` defaults to `false`, so only `true` should normally appear
- use stable widget names
- keep indentation consistent
- keep the simplest import-safe widget tree that satisfies the request

## Rejected Legacy Syntax

Do not emit:

- `schema`
- `widget_blueprint`
- `widget`
- `end`
- `prop`
- single-line `slot key value`

## Minimal Layout Example

```text
implements "UserObjectListEntry"

CvsRoot CanvasPanel
  TxtTitle TextBlock
    text "Hello World"
    font_size "24"
    is_variable "true"
    slot
      offsets "40,32,320,48"
```

## Blueprint Metadata Example

```text
parent_class "/Game/UI/WBP_UIBase.WBP_UIBase_C"
design_size "1280,720"

Root CanvasPanel
  Title TextBlock
    text "Parented"
```

## Nested UserWidget Example

```text
Root CanvasPanel
  Entry UserWidget
    widget_class "/Game/UI/WBP_InventoryEntry.WBP_InventoryEntry_C"
    slot
      offsets "40,32,320,64"
```

## Minimal Animation Example

```text
animation "AnimIntro"
  duration "1"
  track TxtTitle
    render_opacity
      0 "0" Constant
      0.25 "1"
    render_transform
      translation.y
        0 "20"
        0.25 "0" CubicAuto
```
