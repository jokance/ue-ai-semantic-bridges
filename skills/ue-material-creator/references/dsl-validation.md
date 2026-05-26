# DSL Validation, Normalization, and Import

Normalize a generated `.materialdsl` by running the platform fixed launcher. For normal material workflow, use `normalize` first, repair until it succeeds, then use `import` after the normalized DSL is accepted.

## Flow

1. Take the `.materialdsl` file from `dsl-generation`.
2. Write `Saved/MaterialDSLTemp/materialsemantic-request.json` with `mode` set to `normalize`, then run the platform fixed launcher with no arguments.
3. Always provide `project`, `engine`, and `input` in the request file. These fields are required.
4. The launcher uses the project-local `.ue_dsl/MaterialDSL` root for import target mapping.
5. If normalize mode fails validation or temporary import/export, keep the file unchanged and send the issues from the JSON report back to `dsl-generation`.
6. If normalize mode succeeds, keep the canonical DSL export and let it overwrite the original file.
7. For final delivery, after the normalized DSL is accepted, run the same platform fixed launcher again after changing the request file mode to `import`. This imports the stabilized DSL into the mapped `/Game` material or material instance target.

Normalize validates the DSL first and reports diagnostics on failure. If validation or temporary import/export fails, the input file is left unchanged. On success, the commandlet imports the DSL into a transient in-memory material or material instance object, exports canonical DSL text, and overwrites the input file. Any `/Temp/MaterialSemanticBridgeNormalize/...` value in the report is an Unreal object path for the transient package/object, not a filesystem path and not a saved asset.

## Request File

Request file path:

- `Saved/MaterialDSLTemp/materialsemantic-request.json`

Minimal request file fields:

- `project`: absolute `.uproject` path
- `engine`: absolute Unreal Engine root path
- `input`: absolute or project-relative `.materialdsl` path
- `mode`: `validate`, `normalize`, or `import`

Optional request file fields:

- `report`: optional JSON report path
- `build`: `true` to build before running

Normalize example:

```json
{
  "project": "<Project>/SilverGame.uproject",
  "engine": "<EngineRoot>",
  "input": ".ue_dsl/MaterialDSL/Materials/M_Test.materialdsl",
  "mode": "normalize"
}
```

Import example:

```json
{
  "project": "<Project>/SilverGame.uproject",
  "engine": "<EngineRoot>",
  "input": ".ue_dsl/MaterialDSL/Materials/M_Test.materialdsl",
  "mode": "import"
}
```

Use `mode: "validate"` only for exceptional read-only debugging where canonical rewrite must not happen even if the DSL is valid. `normalize` is the normal diagnostic path because it includes validation and is write-safe on failure.

## Fixed Launchers

When running on Windows or macOS for normal agent work, use the skill-local fixed launcher instead of calling ad hoc command variants:

The fixed launcher must be run with escalated execution outside the sandbox.

- Windows launcher: `scripts/run_materialsemantic_validate_windows.bat`
- macOS launcher: `scripts/run_materialsemantic_validate_mac.sh`
- request file: `Saved/MaterialDSLTemp/materialsemantic-request.json`

Each launcher supports two modes of invocation:

- preferred: no arguments; reads the request JSON and keeps the escalated command fixed
- fallback: explicit arguments; forwards directly to the lower-level platform wrapper for debugging

For debugging or manual reproduction, each launcher also supports explicit arguments such as `--project`, `--engine`, `--input`, `--validate`, `--normalize`, and `--import`. Temporary files are written under `Saved/MaterialDSLTemp/` with fixed default names such as `materialsemantic-normalize.json/.log`, `materialsemantic-validate.json/.log`, and `materialsemantic-import.json/.log`.

## Already-Running Editor Fallback

If the commandlet path is blocked because this project already has a running Unreal Editor instance, do not close the editor just to run `UnrealEditor-Cmd`. Use the editor request bridge instead; it writes `Saved/MaterialSemanticBridge/request.json`, waits for the open editor to process it in-process, and supports the normal material workflow modes `normalize` and `import`.

Windows examples:

```bat
scripts\request_materialsemantic_editor_windows.bat --mode normalize --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl
scripts\request_materialsemantic_editor_windows.bat --mode import --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --input-root .ue_dsl\MaterialDSL
```

macOS examples:

```bash
scripts/request_materialsemantic_editor_mac.sh --mode normalize --input .ue_dsl/MaterialDSL/Materials/M_Test.materialdsl
scripts/request_materialsemantic_editor_mac.sh --mode import --input .ue_dsl/MaterialDSL/Materials/M_Test.materialdsl --input-root .ue_dsl/MaterialDSL
```

The same `request.json` file carries the status: `pending`, `running`, `completed`, or `failed`. Only one request may exist at a time; if the wrapper reports that `request.json` is pending or running, wait for the editor to finish or remove the stale file only after confirming the editor is not processing it.

## Issue Repair

- If normalize fails because of a property or pin, inspect `references/support-surface.md`, plugin source, or local tests before changing the graph.
- If normalize fails because of a material output or material setting, inspect `references/support-surface.md`, plugin source, or local tests before changing the output.
- Do not guess unsupported class names, pins, properties, or material outputs.
- Re-run normalize after each repair until the file is canonical and valid.

## Success

- Single-file normalization returns `normalized: true` and `valid: true`.
- No blocking issue remains.
- Any class/property/pin uncertainty was resolved by local references, plugin source, or tests.
- The stabilized DSL is imported into the mapped `/Game` material target when finalization is requested.

## Failure

- Parse, syntax, scope, capability, validation, temporary import, export, or final import fails.
- Keep the original file unchanged when normalize fails.
- Send the issues from the commandlet JSON output file back to `dsl-generation` for rewrite.

## Exit Codes

- `0`: selected mode succeeded
- `1`: validation, normalization, or import failed; regenerate DSL or fix import input
- `2`: argument, I/O, or environment error
- `124`: launcher timeout
