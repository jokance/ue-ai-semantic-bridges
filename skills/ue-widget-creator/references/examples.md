# Examples

Use these examples as canonical shapes.

## Basic Layout

```text
CvsRoot CanvasPanel
  BdrHeader Border
    padding "12,8,12,8"
    brush_tint "0.08,0.1,0.16,1"
    slot
      offsets "24,24,720,72"
    TxtTitle TextBlock
      text "WidgetSemanticBridge"
      font_size "28"
      justification "Center"
  BtnConfirm Button
    background_color "0.16,0.32,0.84,1"
    normal_tint "0.16,0.32,0.84,1"
    hovered_tint "0.22,0.38,0.9,1"
    pressed_tint "0.1,0.24,0.72,1"
    slot
      offsets "24,132,240,44"
    TxtLabel TextBlock
      text "Confirm"
```

## Basic Animation

```text
CvsRoot CanvasPanel
  BdrPanel Border
    slot
      offsets "40,40,420,120"
    TxtTitle TextBlock
      text "Animated"
      font_size "24"

animation "AnimReveal"
  track BdrPanel
    color_and_opacity
      a
        0 "0"
        0.25 "1"
  track TxtTitle
    render_opacity
      0 "0"
      0.25 "1"
    render_transform
      translation.y
        0 "16"
        0.25 "0"
```

## Escaped Text

```text
CvsRoot CanvasPanel
  MtbNotes MultiLineEditableTextBox
    text "Line1\nLine2"
    hint_text "Say \"Hi\" \\ Path"
    foreground_color "0.2,0.6,0.9,1"
    allow_context_menu "false"
    slot
      offsets "24,24,320,96"
```
