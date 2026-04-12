# Project Rules

## Files

- DSL file names must start with `WBP_`.
  Examples: `WBP_MainMenu.widgetdsl`, `WBP_CreateCharacter.widgetdsl`
- Place generated `.widgetdsl` files under `.ue_dsl/WidgetDSL/Blueprints/WidgetBP/<subdir>/`, not directly in the `.ue_dsl/WidgetDSL/`, `.ue_dsl/WidgetDSL/Blueprints/`, or `.ue_dsl/WidgetDSL/Blueprints/WidgetBP/` root.
- Reuse an existing subdirectory under `.ue_dsl/WidgetDSL/Blueprints/WidgetBP/` when it clearly matches the widget's area, feature, or asset grouping; otherwise create a new concise subdirectory before writing the file.
- The mapped Widget Blueprint path mirrors the DSL path relative to `.ue_dsl/WidgetDSL/`. For example, `.ue_dsl/WidgetDSL/Blueprints/WidgetBP/Menu/WBP_MainMenu.widgetdsl` maps to `/Game/Blueprints/WidgetBP/Menu/WBP_MainMenu`.
- When `project-rules.md` conflicts with generic naming or placement examples in other references, follow `project-rules.md`.

## Naming

- Names must use English PascalCase only.
  Do not use Chinese, pinyin, spaces, snake_case, or mixed-language names.
- Widget names inside the DSL must use `TypeAbbreviation + DescriptiveName`.
  Examples: `BtnConfirm`, `TxtTitle`, `ImgAvatar`, `CvsRoot`, `OvbMainLayout`
- Page root widgets must be named exactly `CvsRoot`.
  Use `CvsRoot CanvasPanel` as the top-level root line for generated page DSL unless the user explicitly asks to preserve a different existing root name.
- Common semantic suffixes should be used when they match the widget role.
  Examples: `Page`, `Panel`, `Dialog`, `Item`, `Card`, `Entry`, `Icon`, `Label`, `Background`

## Animations

- Animation names must start with `Anim`.
  Examples: `AnimReveal`, `AnimFadeIn`, `AnimSwitchPage`

## Compatibility

- When editing an existing DSL file, preserve existing file names, widget names, and animation names unless they clearly violate the project rules or the user explicitly asks for renaming.

## Type Abbreviations

- `CanvasPanel=Cvs`
- `Overlay=Ovb`
- `VerticalBox=Vbx`
- `HorizontalBox=Hbx`
- `WrapBox=Wbx`
- `UniformGridPanel=Ugp`
- `GridPanel=Grp`
- `WidgetSwitcher=Wsw`
- `SizeBox=Szb`
- `ScaleBox=Scb`
- `BackgroundBlur=Bgb`
- `InvalidationBox=Ivb`
- `RetainerBox=Rtb`
- `SafeZone=Sfz`
- `Border=Bdr`
- `Button=Btn`
- `CheckBox=Chk`
- `TextBlock=Txt`
- `RichTextBlock=Rtx`
- `Image=Img`
- `EditableText=Edt`
- `EditableTextBox=Etb`
- `MultiLineEditableTextBox=Mtb`
- `ListView=Lvw`
- `TileView=Tvw`
- `ProgressBar=Pgb`
- `Slider=Sld`
- `SpinBox=Spb`
- `ScrollBox=Scv`
- `Spacer=Spc`
- `Throbber=Thr`
- `CircularThrobber=Cth`
