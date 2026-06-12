# DSL Validation, Normalization, Preview Review, and Import

Normalize a generated `.materialdsl` by running the platform fixed launcher. For normal material creation or edit workflows, use `normalize` first, repair until it succeeds, review the generated material preview image, then use `import` only after the normalized DSL and preview are accepted.

If the user explicitly asks only to `import`, `reimport`, `directly import`, or `导入` an existing `.materialdsl` file, do not run the normalize flow first. Run `mode: "import"` directly, unless the user also asks to validate, normalize, repair, or stabilize the DSL.

For files under `.ue_dsl/MaterialDSL/<relative_path>.materialdsl`, the review image path is canonicalized to `Saved/MaterialSemanticBridge/MaterialDSLPreview/<relative_path>.png` for static materials. Dynamic materials may emit numbered frames such as `Saved/MaterialSemanticBridge/MaterialDSLPreview/<relative_path>_01.png` through `_09.png` after skipping the first two warmup intervals. Dynamic reports use the frame sequence in `preview_images` for review and do not generate stitched contact sheets. If only `preview_image` is present, read that path. Normalize preview export uses the material preview path. The normalize report leaves preview image fields empty only when no preview was generated.

## Flow

1. Take the `.materialdsl` file from `dsl-generation`.
2. Write `Saved/MaterialSemanticBridge/MaterialDSLTemp/materialsemantic-request.json` with `mode` set to `normalize`, then run the platform fixed launcher with no arguments.
3. Always provide `project` and `input` in the request file. Provide `engine` only when you need to override automatic engine resolution.
4. The launcher uses the project-local `.ue_dsl/MaterialDSL` root for import target mapping.
5. If normalize mode fails validation or temporary import/export, keep the file unchanged and send the issues from the JSON report back to `dsl-generation`.
6. If normalize mode succeeds, check whether material preview image output was generated as part of the normalize report.
7. Check `preview_generated`, `preview_images`, and `preview_image`. Treat missing files or impossible paths as stale output from an older commandlet or a regression.
8. Read every generated preview frame from `preview_images` for dynamic materials; for older reports or static materials, read `preview_image`. Dynamic materials can emit up to 9 interval frames after skipping two warmup frames.
9. If previews are available, review all generated images against the requested material read by using the `Preview Review Checklist` below.
10. If the preview does not satisfy the request, reject the file and send visual feedback back to `dsl-generation`.
11. If preview generation failed but normalize succeeded, record that visual review was unavailable and continue; missing previews must not block the later `import`.
12. If the preview matches or preview generation was unavailable, keep the canonical DSL export and let it overwrite the original file.
13. For final delivery, after the normalized DSL is accepted, run the same platform fixed launcher again after changing the request file mode to `import`. This imports the stabilized DSL into the mapped `/Game` material or material instance target.

Normalize validates the DSL first and reports diagnostics on failure. If validation or temporary import/export fails, the input file is left unchanged. Preview generation is non-blocking: the commandlet uses a single material preview path. On success, the commandlet imports the DSL into a transient in-memory material or material instance object, exports canonical DSL text, attempts to export one or more material preview images, and overwrites the input file. Any `/Temp/MaterialSemanticBridgeNormalize/...` value in the report is an Unreal object path for the transient package/object, not a filesystem path and not a saved asset.

## Preview Review Checklist

- the first-read visual feature matches the user's request
- color, roughness, metallic, opacity, emissive, normal, and mask behavior read plausibly for the intended material
- texture sampling, UV transforms, panning, rotation, tiling, and masks are visibly coherent
- parameterized controls produce a production-usable default, not a flat placeholder unless the user requested one
- transparency, opacity mask, two-sided, and shading model choices are visually consistent with the brief
- no obvious broken output appears, such as black material, missing texture fallback, blown-out emissive, inverted mask, or unconnected-looking result
- for dynamic materials, compare all emitted frames and reject the DSL if the motion, pulse, panning, or animated transition is missing, too subtle, too chaotic, or visually wrong
- the preview still looks acceptable for the declared target use, performance tier, and renderer limitations

## Request File

Request file path:

- `Saved/MaterialSemanticBridge/MaterialDSLTemp/materialsemantic-request.json`

Minimal request file fields:

- `project`: absolute `.uproject` path
- `input`: absolute or project-relative `.materialdsl` path
- `mode`: `validate`, `normalize`, or `import`

Optional request file fields:

- `engine`: absolute Unreal Engine root path; if omitted, the launcher resolves from the project `EngineAssociation`, then falls back to `UE_ENGINE_ROOT`
- `report`: optional JSON report path
- `build`: `true` to build before running
- `preview_frame_interval_seconds`: optional positive number of seconds between captured dynamic preview frames; defaults to `0.25`

Normal preview behavior and report fields:

- By default, the commandlet chooses one frame for static materials and up to 9 interval frames for dynamic materials.
- By default, dynamic previews skip the first two warmup render frames before saving review frames.
- The default dynamic frame interval is `0.25` seconds, which gives slower pulses, panners, and short animation cycles enough time to read across the nine-frame sequence. Override it per request with `preview_frame_interval_seconds` when a material needs a shorter or longer review window.
- In `normalize` mode, the fixed launchers pass `-AllowCommandletRendering` so material previews can render with RHI instead of using `-NullRHI`.
- Material previews require rendering. Missing dimensions or an invalid pixel buffer should be reported as `preview_generated: false`; valid black, transparent, or alpha-only previews should still be saved as preview output.
- Preview PNGs should match the requested material type.
- For direct object preview checks, run `preview-object` through `scripts/request_materialsemantic_editor_windows.bat` or `scripts/request_materialsemantic_editor_mac.sh`; that mode invokes `UnrealEditor-Cmd` directly and does not launch or depend on a running Unreal Editor. UI materials are rendered through the commandlet's Slate material preview path. If unrelated editor plugins block commandlet startup, pass `--disable-plugins A,B,C` or set `UE_MATERIAL_PREVIEW_DISABLE_PLUGINS`.
- `preview_image` is the first generated preview path, or empty when no preview source produced an image.
- `preview_images` contains every generated preview frame path. Review only the emitted paths in this array.
- `preview_contact_sheet` is kept as a compatibility field but should be empty; dynamic previews are reviewed from the individual frame paths in `preview_images`.
- `preview_source` and `preview_sources` are compatibility report fields; review workflow should use `preview_image` and `preview_images` as the source of truth for generated files.
- `preview_frame_count`, `preview_frame_interval_seconds`, and `preview_skipped_frame_count` describe what the commandlet emitted. `preview_frame_interval_seconds` reports either the default interval or the request override that was used.
- `preview_generated: false` means visual review was unavailable from the commandlet output. It is not a normalize/import blocker by itself.

Normalize example:

```json
{
  "project": "<Project>/SilverGame.uproject",
  "input": ".ue_dsl/MaterialDSL/Materials/M_Test.materialdsl",
  "mode": "normalize",
  "preview_frame_interval_seconds": 0.25
}
```

Import example:

```json
{
  "project": "<Project>/SilverGame.uproject",
  "input": ".ue_dsl/MaterialDSL/Materials/M_Test.materialdsl",
  "mode": "import"
}
```

Use `mode: "validate"` only for exceptional read-only debugging where canonical rewrite must not happen even if the DSL is valid. `normalize` is the normal diagnostic path because it includes validation and is write-safe on failure.

## Fixed Launchers

When running on Windows or macOS for normal agent work, use the skill-local fixed launcher instead of calling ad hoc command variants:

Run the fixed launcher from the project workspace. If the host agent requires approval to launch Unreal Editor commandlets, use that host's normal approval path.

- Windows launcher: `scripts/run_materialsemantic_validate_windows.bat`
- macOS launcher: `scripts/run_materialsemantic_validate_mac.sh`
- request file: `Saved/MaterialSemanticBridge/MaterialDSLTemp/materialsemantic-request.json`

Each launcher supports two modes of invocation:

- preferred: no arguments; reads the request JSON and keeps the command shape fixed
- fallback: explicit arguments; invokes `UnrealEditor-Cmd` with equivalent commandlet arguments for debugging

For `normalize`, the fixed launcher must run the commandlet with `-AllowCommandletRendering` so preview review can use generated preview images. For `validate` and `import`, the launcher may keep using `-NullRHI` because those modes do not require preview rendering.

For debugging or manual reproduction, each launcher also supports explicit arguments such as `--project`, `--engine`, `--input`, `--validate`, `--normalize`, and `--import`. If `--engine` or request-field `engine` is omitted, the launcher resolves the engine from the project `EngineAssociation` first, then falls back to `UE_ENGINE_ROOT` and platform-specific local engine probes. Relative `--input` values are resolved under the project root. Temporary files are written under `Saved/MaterialSemanticBridge/MaterialDSLTemp/` with fixed default names such as `materialsemantic-normalize.json/.log`, `materialsemantic-validate.json/.log`, and `materialsemantic-import.json/.log`.

## Already-Running Editor Fallback

For import-oriented workflows where a running Unreal Editor must process assets in-process, use the editor request bridge; it writes `Saved/MaterialSemanticBridge/request.json`, waits for the open editor to process it, and supports `import-root`, `normalize`, and `import`. `preview-object` is intentionally not an editor request fallback; it runs through `UnrealEditor-Cmd` so preview generation does not require opening the editor.

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
- If preview generation fails, do not treat normalize or import as failed. Record that visual review could not be completed from exported previews, inspect the report/log if useful, and continue to import when the normalized DSL is otherwise accepted.
- If generated preview paths are missing or stale, inspect the commandlet log for stale binaries or report output from an older commandlet, rebuild if needed, and rerun normalize. If preview generation failed, inspect the `preview_generation_failed` issue and the commandlet log.
- If preview review fails, describe the visual mismatch in concrete material terms and send that feedback back to `dsl-generation`.
- Do not guess unsupported class names, pins, properties, or material outputs.
- Re-run normalize after each repair until the file is canonical and valid.
- Re-read every preview frame after each successful normalize; do not accept a file based on syntax validity alone.

## Success

- Single-file normalization returns `normalized: true` and `valid: true`.
- If `preview_generated: true`, the normalize report includes at least one path in `preview_images`, every preview image exists on disk, and every preview image was read.
- When commandlet rendering is available and preview generation succeeds, normalize preview review uses the generated files listed in `preview_images`.
- For dynamic materials, `preview_contact_sheet` is empty and every emitted frame in `preview_images` exists on disk and was read.
- If `preview_generated: false` but normalization succeeded, the missing preview is a review limitation, not an import blocker.
- When previews are available, every preview image matches the requested material look closely enough for the supported graph surface.
- No blocking issue remains.
- Any class/property/pin uncertainty was resolved by local references, plugin source, or tests.
- The stabilized DSL is imported into the mapped `/Game` material target when finalization is requested.

## Failure

- Parse, syntax, scope, capability, validation, temporary import, export, preview review, or final import fails.
- Keep the original file unchanged when normalize fails.
- Send the issues from the commandlet JSON output file, plus preview review feedback when needed, back to `dsl-generation` for rewrite. Do not rewrite solely because preview generation failed after successful normalization.

## Exit Codes

- `0`: selected mode succeeded
- `1`: validation, normalization, or import failed; regenerate DSL or fix import input
- `2`: argument, I/O, or environment error
- `124`: editor request wrapper timeout, or macOS commandlet launcher watchdog timeout
