#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEFAULT_REQUEST_PATH="$REPO_ROOT/Saved/WidgetDSLTemp/widgetsemantic-request.json"

PROJECT_FILE="${UE_PROJECT_FILE:-}"
PROJECT_SEARCH_DIR="$(pwd)"
ENGINE_ROOT="${UE_ENGINE_ROOT:-}"

INPUT_PATH=""
OUTPUT_PATH=""
LOG_PATH=""
PREVIEW_SIZE=""
TIMEOUT_SECONDS=1800
BUILD_BEFORE_RUN=0
MODE="validate"
MODE_SPECIFIED=0

usage() {
  cat <<EOF
Usage:
  $0
  $0 --input <file.widgetdsl> [options]

No-argument mode:
  Reads request settings from Saved/WidgetDSLTemp/widgetsemantic-request.json.
  This is the preferred mode for fixed-command approval reuse.

Options:
  --project <path>        .uproject path; defaults to the only .uproject in current directory
  --input <path>          Absolute or relative .widgetdsl input path
  --validate              Validate only (default if no mode is passed)
  --preview               Validate and require preview_image output
  --preview-size <size>   Preview-only option; pass WidthxHeight (for example 1280x720)
  --build                 Build the project Editor target before running the selected mode
  --engine <path>         Unreal Engine root path; defaults to project EngineAssociation lookup
  --import                Import only; do not run validate first
  --help                  Show this help

Modes are mutually exclusive: --validate, --preview, and --import.

Examples:
  $0
  $0 --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl --validate
  $0 --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl --preview
  $0 --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl --preview-size 1280x720
  $0 --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl --import
  $0 --project /Users/example/Game/Game.uproject --input .ue_dsl/WidgetDSL/UI/WBP_MainMenu.widgetdsl
  $0 --build --input /absolute/path/to/file.widgetdsl
EOF
}

set_mode() {
  local next_mode="$1"

  if [[ "$MODE_SPECIFIED" == "0" ]]; then
    MODE="$next_mode"
    MODE_SPECIFIED=1
    return 0
  fi

  if [[ "$MODE" == "$next_mode" ]]; then
    return 0
  fi

  echo "Mode flags are mutually exclusive: --validate, --preview, and --import." >&2
  return 2
}

resolve_file_path() {
  local input_path="$1"
  local input_dir

  input_dir="$(dirname "$input_path")"
  input_dir="$(cd "$input_dir" && pwd)"
  printf '%s/%s\n' "$input_dir" "$(basename "$input_path")"
}

load_request_file() {
  local request_path="$DEFAULT_REQUEST_PATH"

  if [[ ! -f "$request_path" ]]; then
    echo "Request file not found: $request_path" >&2
    exit 2
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 is required to parse $request_path" >&2
    exit 2
  fi

  local parsed_lines=()
  while IFS= read -r line; do
    parsed_lines+=("$line")
  done < <(
    python3 - "$request_path" <<'PY'
import json
import sys

request_path = sys.argv[1]

with open(request_path, "r", encoding="utf-8") as handle:
    request = json.load(handle)

def emit(key: str, value) -> None:
    if value is None:
        return
    text = str(value).strip()
    if not text:
        return
    print(f"{key}={text}")

emit("PROJECT_FILE", request.get("project"))
emit("ENGINE_ROOT", request.get("engine"))
emit("INPUT_PATH", request.get("input"))
emit("PREVIEW_SIZE", request.get("preview_size"))

if request.get("build") is True:
    print("BUILD_BEFORE_RUN=1")

mode = str(request.get("mode", "validate")).strip().lower()
if mode == "preview":
    print("MODE=preview")
elif mode == "import":
    print("MODE=import")
elif mode in ("", "validate"):
    print("MODE=validate")
else:
    print(f"Unsupported mode in request file: {mode}", file=sys.stderr)
    sys.exit(2)
PY
  )

  local line key value
  for line in "${parsed_lines[@]}"; do
    key="${line%%=*}"
    value="${line#*=}"
    case "$key" in
      PROJECT_FILE) PROJECT_FILE="$value" ;;
      ENGINE_ROOT) ENGINE_ROOT="$value" ;;
      INPUT_PATH) INPUT_PATH="$value" ;;
      PREVIEW_SIZE) PREVIEW_SIZE="$value" ;;
      BUILD_BEFORE_RUN) BUILD_BEFORE_RUN=1 ;;
      MODE)
        MODE="$value"
        MODE_SPECIFIED=1
        ;;
    esac
  done
}

resolve_engine_root_from_project() {
  local search_dir="$PROJECT_ROOT"
  local parent_dir
  local engine_association
  local candidate
  local candidates=()

  while true; do
    if [[ -x "$search_dir/Engine/Build/BatchFiles/Mac/Build.sh" ]]; then
      printf '%s\n' "$search_dir"
      return 0
    fi

    parent_dir="$(dirname "$search_dir")"
    if [[ "$parent_dir" == "$search_dir" ]]; then
      break
    fi

    search_dir="$parent_dir"
  done

  engine_association="$(grep -Eo '"EngineAssociation"[[:space:]]*:[[:space:]]*"[^"]*"' "$PROJECT_FILE" | head -n 1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"
  if [[ -z "$engine_association" ]]; then
    return 1
  fi

  if [[ "$engine_association" = /* ]]; then
    candidates+=("$engine_association")
  fi

  if [[ "$engine_association" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
    candidates+=(
      "/Users/Shared/Epic Games/UE_${engine_association}"
      "/Users/Shared/EpicGames/UE_${engine_association}"
      "/Users/Shared/UnrealEngine/${engine_association}"
      "/Applications/Epic Games/UE_${engine_association}"
      "$HOME/Documents/Projects/UE_${engine_association}"
    )
  fi

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate/Engine/Build/BatchFiles/Mac/Build.sh" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

if [[ $# -eq 0 ]]; then
  load_request_file
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --input)
      INPUT_PATH="$2"
      shift 2
      ;;
    --project)
      PROJECT_FILE="$2"
      shift 2
      ;;
    --preview)
      set_mode preview || exit $?
      shift
      ;;
    --preview-size)
      PREVIEW_SIZE="$2"
      set_mode preview || exit $?
      shift 2
      ;;
    --validate)
      set_mode validate || exit $?
      shift
      ;;
    --build)
      BUILD_BEFORE_RUN=1
      shift
      ;;
    --engine)
      ENGINE_ROOT="$2"
      shift 2
      ;;
    --import)
      set_mode import || exit $?
      shift
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ -z "$INPUT_PATH" ]]; then
  echo "Missing required --input argument." >&2
  usage >&2
  exit 2
fi

if [[ -z "$PROJECT_FILE" ]]; then
  PROJECT_FILES=()
  while IFS= read -r project_file; do
    PROJECT_FILES+=("$project_file")
  done < <(find "$PROJECT_SEARCH_DIR" -maxdepth 1 -type f -name '*.uproject' | sort)

  if [[ "${#PROJECT_FILES[@]}" -eq 0 ]]; then
    echo "No .uproject file found in current directory: $PROJECT_SEARCH_DIR" >&2
    echo "Pass --project <path> explicitly." >&2
    exit 2
  fi

  if [[ "${#PROJECT_FILES[@]}" -ne 1 ]]; then
    echo "Multiple .uproject files found in current directory: $PROJECT_SEARCH_DIR" >&2
    echo "Pass --project <path> explicitly." >&2
    exit 2
  fi

  PROJECT_FILE="${PROJECT_FILES[0]}"
fi

PROJECT_FILE="$(resolve_file_path "$PROJECT_FILE")"
if [[ ! -f "$PROJECT_FILE" ]]; then
  echo "Project file not found: $PROJECT_FILE" >&2
  exit 2
fi

PROJECT_ROOT="$(cd "$(dirname "$PROJECT_FILE")" && pwd)"
PROJECT_NAME="$(basename "$PROJECT_FILE" .uproject)"
EDITOR_TARGET="${PROJECT_NAME}Editor"

if [[ -z "$ENGINE_ROOT" ]]; then
  if ! ENGINE_ROOT="$(resolve_engine_root_from_project)"; then
    echo "Failed to resolve Unreal Engine root from project: $PROJECT_FILE" >&2
    echo "Pass --engine <path> explicitly or set UE_ENGINE_ROOT." >&2
    exit 2
  fi
fi

BUILD_SCRIPT="${ENGINE_ROOT}/Engine/Build/BatchFiles/Mac/Build.sh"
EDITOR_APP="${ENGINE_ROOT}/Engine/Binaries/Mac/UnrealEditor.app"
EDITOR_BINARY="${EDITOR_APP}/Contents/MacOS/UnrealEditor"

if [[ ! -x "$BUILD_SCRIPT" ]]; then
  echo "Build script not found: $BUILD_SCRIPT" >&2
  exit 2
fi

if [[ ! -d "$EDITOR_APP" ]]; then
  echo "UnrealEditor.app not found: $EDITOR_APP" >&2
  exit 2
fi

INPUT_PATH="$(resolve_file_path "$INPUT_PATH")"
if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Input DSL file not found: $INPUT_PATH" >&2
  exit 2
fi

TEMP_OUTPUT_DIR="$PROJECT_ROOT/Saved/WidgetDSLTemp"
mkdir -p "$TEMP_OUTPUT_DIR"
ARTIFACT_BASENAME="widgetsemantic-validate"
if [[ "$MODE" == "import" ]]; then
  ARTIFACT_BASENAME="widgetsemantic-import"
fi
OUTPUT_PATH="$TEMP_OUTPUT_DIR/${ARTIFACT_BASENAME}.json"
LOG_PATH="$TEMP_OUTPUT_DIR/${ARTIFACT_BASENAME}.log"

if [[ "$BUILD_BEFORE_RUN" == "1" ]]; then
  echo "Building ${EDITOR_TARGET}..."
  "$BUILD_SCRIPT" "$EDITOR_TARGET" Mac Development -Project="$PROJECT_FILE" -WaitMutex -NoHotReloadFromIDE -NoUBA
fi

echo "Project file: $PROJECT_FILE"
echo "Engine root: $ENGINE_ROOT"
echo "Input DSL: $INPUT_PATH"
echo "Mode: $MODE"
echo "Output file: $OUTPUT_PATH"
echo "Log file: $LOG_PATH"
echo "DDC mode: default Unreal cache settings"
if [[ "$MODE" == "preview" && -n "$PREVIEW_SIZE" ]]; then
  echo "Preview size: $PREVIEW_SIZE"
elif [[ "$MODE" != "preview" ]]; then
  echo "Preview: disabled"
fi

if [[ "$MODE" == "import" ]]; then
  COMMANDLET_ARGS=(
    "$PROJECT_FILE"
    -run=WidgetSemanticCommandlet
    -Mode=import
    "-Input=$INPUT_PATH"
    "-Format=json"
    -NullRHI
    -unattended
    -nop4
    -nosplash
    -NoEpicPortal
    -HomeScreen.EnableHomeScreen=0
    -stdout
    -FullStdOutLogOutput
    "-abslog=$LOG_PATH"
    "-ini:EditorSettings:[/Script/UnrealEd.AnalyticsPrivacySettings]:bSendUsageData=False"
    "-ini:EditorSettings:[/Script/UnrealEd.CrashReportsPrivacySettings]:bSendUnattendedBugReports=False"
    "-ini:EditorSettings:[/Script/MainFrame.HomeScreenSettings]:LoadAtStartup=LastProject"
  )

  rm -f "$OUTPUT_PATH" "$LOG_PATH"

  if [[ -x "$EDITOR_BINARY" ]]; then
    "$EDITOR_BINARY" "${COMMANDLET_ARGS[@]}" &
    LAUNCH_PID=$!
  else
    open -n -W "$EDITOR_APP" --args "${COMMANDLET_ARGS[@]}" &
    LAUNCH_PID=$!
  fi
  WATCHDOG_FILE="$(mktemp /tmp/widgetsemantic_import_watchdog.XXXXXX)"

  (
    sleep "$TIMEOUT_SECONDS"
    if kill -0 "$LAUNCH_PID" 2>/dev/null; then
      echo "timeout" > "$WATCHDOG_FILE"
      while IFS= read -r UnrealPid; do
        kill "$UnrealPid" 2>/dev/null || true
      done < <(ps -axo pid=,command= | grep -F -- "-abslog=$LOG_PATH" | grep -v grep | awk '{print $1}')
      kill "$LAUNCH_PID" 2>/dev/null || true
    fi
  ) &
  WATCHDOG_PID=$!

  set +e
  wait "$LAUNCH_PID"
  LAUNCH_STATUS=$?
  set -e

  kill "$WATCHDOG_PID" 2>/dev/null || true
  wait "$WATCHDOG_PID" 2>/dev/null || true

  if [[ -s "$WATCHDOG_FILE" ]]; then
    rm -f "$WATCHDOG_FILE"
    echo "Import commandlet timed out after ${TIMEOUT_SECONDS}s." >&2
    exit 124
  fi

  rm -f "$WATCHDOG_FILE"

  if [[ ! -f "$OUTPUT_PATH" ]]; then
    echo "Expected import output was not created: $OUTPUT_PATH" >&2
    exit 2
  fi

  IMPORTED_FIELD="$(grep -Eo '"imported":[[:space:]]*(true|false)' "$OUTPUT_PATH" | head -n 1 | sed -E 's/.*:[[:space:]]*(true|false)/\1/')"
  IMPORT_ERROR_FIELD="$(grep -Eo '"error":[[:space:]]*"[^"]*"' "$OUTPUT_PATH" | head -n 1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

  if [[ "$IMPORTED_FIELD" == "true" ]]; then
    cat "$OUTPUT_PATH"
    exit 0
  fi

  if [[ -n "$IMPORT_ERROR_FIELD" ]]; then
    echo "Import failed: $IMPORT_ERROR_FIELD" >&2
  fi
  cat "$OUTPUT_PATH"
  if [[ "$IMPORTED_FIELD" == "false" ]]; then
    exit 1
  fi
  exit 2
fi

COMMANDLET_ARGS=(
  "$PROJECT_FILE"
  -run=WidgetSemanticCommandlet
  -Mode=validate
  "-Input=$INPUT_PATH"
  "-Format=json"
  -unattended
  -nop4
  -nosplash
  -NoEpicPortal
  -HomeScreen.EnableHomeScreen=0
  -stdout
  -FullStdOutLogOutput
  "-abslog=$LOG_PATH"
  "-ini:EditorSettings:[/Script/UnrealEd.AnalyticsPrivacySettings]:bSendUsageData=False"
  "-ini:EditorSettings:[/Script/UnrealEd.CrashReportsPrivacySettings]:bSendUnattendedBugReports=False"
  "-ini:EditorSettings:[/Script/MainFrame.HomeScreenSettings]:LoadAtStartup=LastProject"
)

if [[ "$MODE" == "preview" ]]; then
  COMMANDLET_ARGS+=(-AllowCommandletRendering)
  if [[ -n "$PREVIEW_SIZE" ]]; then
    COMMANDLET_ARGS+=("-PreviewSize=$PREVIEW_SIZE")
  fi
else
  COMMANDLET_ARGS+=(-NoPreview -NullRHI)
fi

rm -f "$OUTPUT_PATH" "$LOG_PATH"

if [[ -x "$EDITOR_BINARY" ]]; then
  "$EDITOR_BINARY" "${COMMANDLET_ARGS[@]}" &
  LAUNCH_PID=$!
else
  open -n -W "$EDITOR_APP" --args "${COMMANDLET_ARGS[@]}" &
  LAUNCH_PID=$!
fi
WATCHDOG_FILE="$(mktemp /tmp/widgetsemantic_validate_watchdog.XXXXXX)"

(
  sleep "$TIMEOUT_SECONDS"
  if kill -0 "$LAUNCH_PID" 2>/dev/null; then
    echo "timeout" > "$WATCHDOG_FILE"
    while IFS= read -r UnrealPid; do
      kill "$UnrealPid" 2>/dev/null || true
    done < <(ps -axo pid=,command= | grep -F -- "-abslog=$LOG_PATH" | grep -v grep | awk '{print $1}')
    kill "$LAUNCH_PID" 2>/dev/null || true
  fi
) &
WATCHDOG_PID=$!

set +e
wait "$LAUNCH_PID"
LAUNCH_STATUS=$?
set -e

kill "$WATCHDOG_PID" 2>/dev/null || true
wait "$WATCHDOG_PID" 2>/dev/null || true

if [[ -s "$WATCHDOG_FILE" ]]; then
  rm -f "$WATCHDOG_FILE"
  echo "Commandlet timed out after ${TIMEOUT_SECONDS}s." >&2
  exit 124
fi

rm -f "$WATCHDOG_FILE"

if [[ ! -f "$OUTPUT_PATH" ]]; then
  echo "Expected commandlet output was not created: $OUTPUT_PATH" >&2
  exit 2
fi

VALID_FIELD="$(grep -Eo '"valid":[[:space:]]*(true|false)' "$OUTPUT_PATH" | head -n 1 | sed -E 's/.*:[[:space:]]*(true|false)/\1/')"
PREVIEW_PATH="$(grep -Eo '"preview_image":[[:space:]]*"[^"]*"' "$OUTPUT_PATH" | head -n 1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/')"

if [[ "$VALID_FIELD" == "true" ]]; then
  if [[ "$MODE" == "preview" && -z "$PREVIEW_PATH" ]]; then
    echo "Validation passed but preview_image is empty." >&2
    exit 1
  fi

  if [[ -n "$PREVIEW_PATH" && ! -f "$PREVIEW_PATH" ]]; then
    echo "Validation passed but preview_image was not written to disk: $PREVIEW_PATH" >&2
    exit 1
  fi

  cat "$OUTPUT_PATH"
  exit 0
fi

if [[ "$VALID_FIELD" == "false" ]]; then
  cat "$OUTPUT_PATH"
  exit 1
fi

cat "$OUTPUT_PATH"
exit 2
