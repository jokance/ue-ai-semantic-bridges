#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
DEFAULT_REQUEST_PATH="$REPO_ROOT/Saved/MaterialDSLTemp/materialsemantic-request.json"

PROJECT_FILE=""
ENGINE_ROOT=""

INPUT_PATH=""
REPORT_PATH=""
LOG_PATH=""
TIMEOUT_SECONDS=1800
BUILD_BEFORE_RUN=0
MODE="validate"
MODE_SPECIFIED=0

usage() {
  cat <<EOF
Usage:
  $0
  $0 --input <file.materialdsl> [options]

No-argument mode:
  Reads request settings from Saved/MaterialDSLTemp/materialsemantic-request.json.
  This is the preferred mode for fixed-command approval reuse.

Options:
  --project <path>      Required .uproject path
  --input <path>        Absolute or relative .materialdsl input path
  --report <path>       Optional commandlet report path
  --validate            Validate only (default if no mode is passed)
  --normalize           Normalize the input file in place after validation/import/export round-trip
  --import              Import the input file into its mapped /Game target
  --build               Build the project Editor target before running the selected mode
  --engine <path>       Required Unreal Engine root path
  --help                Show this help

Modes are mutually exclusive: --validate, --normalize, and --import.

Examples:
  $0
  $0 --input .ue_dsl/MaterialDSL/Materials/M_Test.materialdsl --validate
  $0 --input .ue_dsl/MaterialDSL/Materials/M_Test.materialdsl --normalize
  $0 --input .ue_dsl/MaterialDSL/Materials/M_Test.materialdsl --import
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

  echo "Mode flags are mutually exclusive: --validate, --normalize, and --import." >&2
  return 2
}

resolve_file_path() {
  local input_path="$1"
  local input_dir

  input_dir="$(dirname "$input_path")"
  input_dir="$(cd "$input_dir" && pwd)"
  printf '%s/%s\n' "$input_dir" "$(basename "$input_path")"
}

resolve_optional_path() {
  local input_path="$1"
  local input_dir

  if [[ "$input_path" = /* ]]; then
    printf '%s\n' "$input_path"
    return 0
  fi

  input_dir="$(dirname "$input_path")"
  mkdir -p "$input_dir"
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
emit("REPORT_PATH", request.get("report"))

if request.get("build") is True:
    print("BUILD_BEFORE_RUN=1")

mode = str(request.get("mode", "validate")).strip().lower()
if mode in ("", "validate"):
    print("MODE=validate")
elif mode == "normalize":
    print("MODE=normalize")
elif mode == "import":
    print("MODE=import")
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
      REPORT_PATH) REPORT_PATH="$value" ;;
      BUILD_BEFORE_RUN) BUILD_BEFORE_RUN=1 ;;
      MODE)
        MODE="$value"
        MODE_SPECIFIED=1
        ;;
    esac
  done
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
    --report)
      REPORT_PATH="$2"
      shift 2
      ;;
    --project)
      PROJECT_FILE="$2"
      shift 2
      ;;
    --validate)
      set_mode validate || exit $?
      shift
      ;;
    --normalize)
      set_mode normalize || exit $?
      shift
      ;;
    --import)
      set_mode import || exit $?
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
  echo "Missing required --project argument or request field." >&2
  usage >&2
  exit 2
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
  echo "Missing required --engine argument or request field." >&2
  usage >&2
  exit 2
fi

BUILD_SCRIPT="${ENGINE_ROOT}/Engine/Build/BatchFiles/Mac/Build.sh"
EDITOR_CMD="${UE_EDITOR_CMD:-$ENGINE_ROOT/Engine/Binaries/Mac/UnrealEditor-Cmd}"

if [[ ! -x "$BUILD_SCRIPT" ]]; then
  echo "Build script not found: $BUILD_SCRIPT" >&2
  exit 2
fi

if [[ ! -x "$EDITOR_CMD" ]]; then
  echo "UnrealEditor-Cmd not found: $EDITOR_CMD" >&2
  exit 2
fi

INPUT_PATH="$(resolve_file_path "$INPUT_PATH")"
if [[ ! -f "$INPUT_PATH" ]]; then
  echo "Input DSL file not found: $INPUT_PATH" >&2
  exit 2
fi

INPUT_ROOT="$PROJECT_ROOT/.ue_dsl/MaterialDSL"
INPUT_ROOT="$(resolve_optional_path "$INPUT_ROOT")"

TEMP_OUTPUT_DIR="$PROJECT_ROOT/Saved/MaterialDSLTemp"
mkdir -p "$TEMP_OUTPUT_DIR"
if [[ -z "$REPORT_PATH" ]]; then
  REPORT_PATH="$TEMP_OUTPUT_DIR/materialsemantic-${MODE}.json"
fi
REPORT_PATH="$(resolve_optional_path "$REPORT_PATH")"
LOG_PATH="$TEMP_OUTPUT_DIR/materialsemantic-${MODE}.log"

if [[ "$BUILD_BEFORE_RUN" == "1" ]]; then
  echo "Building ${EDITOR_TARGET}..."
  "$BUILD_SCRIPT" "$EDITOR_TARGET" Mac Development -Project="$PROJECT_FILE" -WaitMutex -NoHotReloadFromIDE -NoUBA
fi

echo "Project file: $PROJECT_FILE"
echo "Engine root: $ENGINE_ROOT"
echo "Input DSL: $INPUT_PATH"
echo "Mode: $MODE"
echo "Report file: $REPORT_PATH"
echo "Log file: $LOG_PATH"

COMMANDLET_MODE="validate"
if [[ "$MODE" == "normalize" ]]; then
  COMMANDLET_MODE="normalize"
elif [[ "$MODE" == "import" ]]; then
  COMMANDLET_MODE="import"
fi

COMMANDLET_ARGS=(
  "$PROJECT_FILE"
  -run=MaterialSemanticCommandlet
  "-Mode=$COMMANDLET_MODE"
  "-Input=$INPUT_PATH"
  "-InputRoot=$INPUT_ROOT"
  "-Report=$REPORT_PATH"
  -Format=json
  -Unattended
  -nop4
  -NullRHI
  -nosplash
  -NoEpicPortal
  -stdout
  -FullStdOutLogOutput
  "-abslog=$LOG_PATH"
)

rm -f "$REPORT_PATH" "$LOG_PATH"

"$EDITOR_CMD" "${COMMANDLET_ARGS[@]}" &
LAUNCH_PID=$!
WATCHDOG_FILE="$(mktemp /tmp/materialsemantic_${MODE}_watchdog.XXXXXX)"

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

if [[ ! -f "$REPORT_PATH" ]]; then
  echo "Expected commandlet report was not created: $REPORT_PATH" >&2
  exit 2
fi

cat "$REPORT_PATH"
exit "$LAUNCH_STATUS"
