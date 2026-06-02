#!/bin/bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_project_root() {
  local dir="$1"
  while [[ "$dir" != "/" ]]; do
    if compgen -G "$dir/*.uproject" >/dev/null; then
      printf '%s' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

PROJECT_ROOT="${UE_PROJECT_ROOT:-}"
if [[ -z "$PROJECT_ROOT" ]]; then
  PROJECT_ROOT="$(find_project_root "$PWD" || find_project_root "$SCRIPT_DIR" || true)"
fi
if [[ -z "$PROJECT_ROOT" ]]; then
  echo "Failed to locate project root. Run from a project directory or set UE_PROJECT_ROOT." >&2
  exit 2
fi

MODE="preview"
INPUT_PATH=""
INPUT_ROOT="${PROJECT_ROOT}/.ue_dsl/WidgetDSL"
PREVIEW_SIZE=""
TIMEOUT_SECONDS=120

usage() {
  cat <<'EOF'
Usage:
  request_widgetsemantic_editor_mac.sh [options]

Options:
  --mode <validate|preview|stabilize|import|import-root>
  --input <file.widgetdsl>  Required except for import-root
  --input-root <path>       DSL root for import-root, or mapping root for import
  --preview-size <size>     Preview mode size, for example 1280x720
  --timeout <seconds>       Seconds to wait for the running Unreal Editor response; defaults to 120
  --help                    Show this help

This does not launch UnrealEditor-Cmd. It writes a WidgetSemanticCommandlet-shaped request
to Saved/WidgetSemanticBridge/request.json for the already-running Unreal Editor to process.
EOF
}

json_escape() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  value="${value//$'\n'/\\n}"
  value="${value//$'\r'/}"
  printf '%s' "$value"
}

absolute_path() {
  local path="$1"
  if [[ -z "$path" ]]; then
    printf ''
    return
  fi

  if [[ "$path" == /* ]]; then
    printf '%s' "$path"
  else
    printf '%s/%s' "$PROJECT_ROOT" "$path"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="$2"
      shift 2
      ;;
    --input)
      INPUT_PATH="$2"
      shift 2
      ;;
    --input-root)
      INPUT_ROOT="$2"
      shift 2
      ;;
    --preview-size)
      PREVIEW_SIZE="$2"
      shift 2
      ;;
    --timeout)
      TIMEOUT_SECONDS="$2"
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

MODE="$(printf '%s' "$MODE" | tr '[:upper:]' '[:lower:]')"
case "$MODE" in
  import-root)
    ;;
  validate|preview|stabilize|import)
    [[ -n "$INPUT_PATH" ]] || { echo "--input is required for --mode $MODE" >&2; exit 2; }
    ;;
  *)
    echo "Unsupported mode: $MODE" >&2
    usage >&2
    exit 2
    ;;
esac

INPUT_PATH="$(absolute_path "$INPUT_PATH")"
INPUT_ROOT="$(absolute_path "$INPUT_ROOT")"

REQUEST_ID="widgetsemantic-${MODE}-$(date +%s)-$$"
BRIDGE_DIR="${PROJECT_ROOT}/Saved/WidgetSemanticBridge"
REQUEST_PATH="${BRIDGE_DIR}/request.json"

mkdir -p "$BRIDGE_DIR"

if [[ -f "$REQUEST_PATH" ]]; then
  if ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"(completed|failed)"' "$REQUEST_PATH"; then
    echo "A WidgetSemantic request is already pending or running: $REQUEST_PATH" >&2
    echo "Wait for it to finish, or remove the file if the editor is not running and the request is stale." >&2
    exit 3
  fi
fi

TMP_REQUEST_PATH="${REQUEST_PATH}.tmp"
case "$MODE" in
  import-root)
    cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"WidgetSemanticCommandlet","mode":"import-root","status":"pending","input_root":"$(json_escape "$INPUT_ROOT")"}
EOF
    ;;
  import)
    cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"WidgetSemanticCommandlet","mode":"import","status":"pending","input":"$(json_escape "$INPUT_PATH")","input_root":"$(json_escape "$INPUT_ROOT")"}
EOF
    ;;
  validate|preview|stabilize)
    if [[ -n "$PREVIEW_SIZE" ]]; then
      cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"WidgetSemanticCommandlet","mode":"$(json_escape "$MODE")","status":"pending","input":"$(json_escape "$INPUT_PATH")","preview_size":"$(json_escape "$PREVIEW_SIZE")"}
EOF
    else
      cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"WidgetSemanticCommandlet","mode":"$(json_escape "$MODE")","status":"pending","input":"$(json_escape "$INPUT_PATH")"}
EOF
    fi
    ;;
esac
mv "$TMP_REQUEST_PATH" "$REQUEST_PATH"

echo "Queued WidgetSemantic request: $REQUEST_ID"
echo "Waiting for running Unreal Editor to update: $REQUEST_PATH"

START_TIME="$(date +%s)"
while grep -Eq '"status"[[:space:]]*:[[:space:]]*"(pending|running)"' "$REQUEST_PATH"; do
  NOW="$(date +%s)"
  if (( NOW - START_TIME >= TIMEOUT_SECONDS )); then
    echo "Timed out waiting for Unreal Editor to process request." >&2
    echo "Request file remains at: $REQUEST_PATH" >&2
    exit 124
  fi
  sleep 0.25
done

cat "$REQUEST_PATH"
echo

if grep -Eq '"status"[[:space:]]*:[[:space:]]*"completed"' "$REQUEST_PATH"; then
  exit 0
fi

exit 1
