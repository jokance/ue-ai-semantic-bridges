# DSL Validation

Validate a generated `.widgetdsl` by running the platform fixed launcher. For normal review workflow, use `preview` first, then `import` after the preview is accepted.

For files under `.ue_dsl/WidgetDSL/<relative_path>.widgetdsl`, the review image path is canonicalized to: `Saved/WidgetDSLPreview/<relative_path>.png`

## Flow

1. Take the `.widgetdsl` file from `dsl-generation`.
2. Write `Saved/WidgetDSLTemp/widgetsemantic-request.json` with `mode` set to `preview`, then run the platform fixed launcher with no arguments.
3. Prefer providing the project path explicitly, and provide the engine root explicitly when engine auto-discovery is not guaranteed to work on the current machine. Put both values in the request file for launcher-driven runs.
4. If preview mode fails validation or preview generation, reject the file and send it back to `dsl-generation`.
5. If preview mode succeeds, read the generated preview image file from `Saved/WidgetDSLPreview/<relative_path>.png` when the DSL lives under `.ue_dsl/WidgetDSL/`, otherwise read the exact file path reported in the JSON `preview_image` field.
6. Review that image file against the requested layout and appearance by using the `Preview Review Checklist` below.
7. If the preview does not match the request, reject the file and send it back to `dsl-generation`.
8. If the preview matches, keep the canonical DSL export and let it overwrite the original file.
9. For final delivery, after the preview-reviewed DSL is accepted, run the same platform fixed launcher again after changing the request file mode to `import`. This imports the stabilized DSL into the mapped `/Game` Widget Blueprint path without re-running validation.

## Preview Review Checklist

Use this checklist during step 6 review:

- layout structure matches the request
- panel size and relative proportion feel correct
- alignment, padding, and spacing are consistent
- repeated units such as slots, cards, or list entries have the right size, density, and flow direction
- text hierarchy is clear and important text is readable without clipping
- visual emphasis matches the requested focal points
- placeholder images or fallback visuals still preserve the intended structure
- interactive widgets visually read as their intended role
- no obvious overlap, clipping, collision, or unintended empty space appears at the preview size
- no explicitly requested section or information block is missing

## Success

- Import into `transient WBP` succeeds.
- The review step reads the generated preview image file and that image matches the user request.
- Canonical DSL export succeeds.
- The original file is overwritten with the canonical result.
- The stabilized DSL is imported into the mapped `/Game` Widget Blueprint target when finalization is requested.

## Failure

- Parse, syntax, scope, capability, import, export, or preview review fails.
- Keep the original file unchanged.
- Send the issues from the commandlet JSON output file, plus preview review feedback when needed, back to `dsl-generation` for rewrite.

## Fixed Launchers

When running on Windows or macOS for normal agent work, use the skill-local fixed launcher instead of calling ad hoc command variants:

The fixed launcher must be run with escalated execution outside the sandbox.

- Windows launcher: `scripts/run_widgetsemantic_validate_windows.bat`
- macOS launcher: `scripts/run_widgetsemantic_validate_mac.sh`
- request file: `Saved/WidgetDSLTemp/widgetsemantic-request.json`

Each launcher supports two modes:

- preferred: no arguments; reads the request JSON and keeps the escalated command fixed
- fallback: explicit arguments; forwards directly to the lower-level platform wrapper for debugging

Minimal request file fields:

- `project`: absolute `.uproject` path
- `engine`: absolute Unreal Engine root path
- `input`: absolute `.widgetdsl` path
- `mode`: `validate`, `preview`, or `import`

Optional request file fields:

- `build`: `true` to build before running
- `preview_size`: preview-only size string, default is `1280x720`

Preview example:

```json
{
  "project": "D:\\Projects\\SilverGame\\SilverGame.uproject",
  "engine": "D:\\Games\\UE_5.7",
  "input": "D:\\Projects\\SilverGame\\.ue_dsl\\WidgetDSL\\Blueprints\\WidgetBP\\Login\\WBP_Login.widgetdsl",
  "mode": "preview"
}
```

Import example:

```json
{
  "project": "D:\\Projects\\SilverGame\\SilverGame.uproject",
  "engine": "D:\\Games\\UE_5.7",
  "input": "D:\\Projects\\SilverGame\\.ue_dsl\\WidgetDSL\\Blueprints\\WidgetBP\\Login\\WBP_Login.widgetdsl",
  "mode": "import"
}
```

For debugging or manual reproduction, each launcher also supports explicit arguments such as `--input`, `--validate`, `--preview`, and `--import`. Temporary files are written under `Saved/WidgetDSLTemp/` with fixed names: `widgetsemantic-validate.json/.log` for both validate and preview runs, and `widgetsemantic-import.json/.log` for import runs.

## Running Editor Fallback

If the commandlet path is blocked because this project already has a running Unreal Editor instance, use the editor request bridge instead of closing the editor. The plugin watches `Saved/WidgetSemanticBridge/request.json` every 1.8 seconds, processes one JSON request in the open editor, and writes the result back to the same file.

Windows:

```bat
scripts\request_widgetsemantic_editor_windows.bat --mode preview --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl --preview-size 1280x720
scripts\request_widgetsemantic_editor_windows.bat --mode import --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl --input-root .ue_dsl\WidgetDSL
```

macOS:

```bash
scripts/request_widgetsemantic_editor_mac.sh --mode preview --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl --preview-size 1280x720
scripts/request_widgetsemantic_editor_mac.sh --mode import --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl --input-root .ue_dsl/WidgetDSL
```

Supported request modes are `validate`, `preview`, `stabilize`, `import`, and `import-root`. The same `request.json` file carries the status: `pending`, `running`, `completed`, or `failed`. Only one request may exist at a time; if the wrapper reports that `request.json` is pending or running, wait for the editor to finish or remove the stale file only after confirming the editor is not processing it.

## Exit Codes

- `0`: selected mode succeeded
- `1`: validation or import failed; regenerate DSL or fix import input
- `2`: argument, I/O, or environment error
