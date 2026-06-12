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

MODE="import-root"
INPUT_PATH=""
INPUT_ROOT="${PROJECT_ROOT}/.ue_dsl/MaterialDSL"
OBJECT_PATH=""
OUTPUT_PATH=""
PREVIEW_SHAPE=""
TIMEOUT_SECONDS=240
AUTO_LAUNCH_EDITOR=1
EDITOR_EXE="${UE_EDITOR_EXE:-}"
EDITOR_CMD_EXE="${UE_EDITOR_CMD_EXE:-${UE_EDITOR_CMD:-}}"
DISABLE_PLUGINS="${UE_MATERIAL_PREVIEW_DISABLE_PLUGINS:-}"

usage() {
  cat <<'EOF'
Usage:
  request_materialsemantic_editor_mac.sh [options]

Options:
  --mode <import-root|import|normalize|preview-object>
  --input <file.materialdsl>  Required for import and normalize
  --input-root <path>         DSL root for import-root, or mapping root for import
  --object </Game/Path.Asset> Required for preview-object
  --output <file.png>         Required for preview-object
  --preview-shape <sphere|cube|plane>
                                Mesh shape for preview-object; default sphere
  --timeout <seconds>         Seconds to wait for the running Unreal Editor response; defaults to 240
  --editor-cmd-exe <path>     UnrealEditor-Cmd path for preview-object; defaults to UE_EDITOR_CMD_EXE, UE_EDITOR_CMD, or project engine resolution
  --editor-exe <path>         UnrealEditor path for editor request modes; defaults to UE_EDITOR_EXE or project engine resolution
  --disable-plugins <a,b,c>   Extra plugins to disable for preview-object commandlet startup; defaults to UE_MATERIAL_PREVIEW_DISABLE_PLUGINS
  --launch-editor             Launch Unreal Editor for editor request modes when none is running; default
  --no-launch-editor          Require an already-running Unreal Editor for editor request modes
  --help                      Show this help

This writes a MaterialSemanticCommandlet-shaped request to
Saved/MaterialSemanticBridge/request.json for the already-running Unreal Editor to process.
For preview-object, this runs UnrealEditor-Cmd directly and exports the material preview without launching Unreal Editor.
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

require_value() {
  local option="$1"
  local value="${2:-}"
  if [[ -z "$value" ]]; then
    echo "Missing value for $option." >&2
    usage >&2
    exit 2
  fi
}

find_project_file() {
  local matches=("$PROJECT_ROOT"/*.uproject)
  if [[ ! -f "${matches[0]:-}" ]]; then
    echo "Failed to locate .uproject under: $PROJECT_ROOT" >&2
    return 2
  fi

  printf '%s' "${matches[0]}"
}

resolve_engine_root_from_project() {
  local project_file="$1"
  local project_dir
  local engine_association
  local candidate
  local candidates=()

  project_dir="$(dirname "$project_file")"
  engine_association="$(grep -Eo '"EngineAssociation"[[:space:]]*:[[:space:]]*"[^"]*"' "$project_file" | head -n 1 | sed -E 's/.*:[[:space:]]*"([^"]*)"/\1/' || true)"

  if [[ -n "${UE_ENGINE_ROOT:-}" ]]; then
    candidates+=("$UE_ENGINE_ROOT")
  fi

  if [[ -n "$engine_association" ]]; then
    if [[ "$engine_association" == /* ]]; then
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
  fi

  local search_dir="$project_dir"
  while [[ -n "$search_dir" && "$search_dir" != "/" ]]; do
    candidates+=("$search_dir")
    search_dir="$(dirname "$search_dir")"
  done

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate/Engine/Binaries/Mac/UnrealEditor-Cmd" || -f "$candidate/Engine/Binaries/Mac/UnrealEditor-Cmd" ]]; then
      printf '%s' "$candidate"
      return 0
    fi
  done

  return 1
}

resolve_editor_cmd_exe() {
  local project_file="$1"
  local engine_root

  if [[ -n "$EDITOR_CMD_EXE" ]]; then
    if [[ "$EDITOR_CMD_EXE" != /* ]]; then
      EDITOR_CMD_EXE="$(absolute_path "$EDITOR_CMD_EXE")"
    fi
  else
    engine_root="$(resolve_engine_root_from_project "$project_file" || true)"
    if [[ -n "$engine_root" ]]; then
      EDITOR_CMD_EXE="$engine_root/Engine/Binaries/Mac/UnrealEditor-Cmd"
    fi
  fi

  if [[ -z "$EDITOR_CMD_EXE" ]]; then
    echo "UnrealEditor-Cmd path is empty. Set UE_EDITOR_CMD_EXE or pass --editor-cmd-exe." >&2
    return 2
  fi

  if [[ ! -x "$EDITOR_CMD_EXE" && ! -f "$EDITOR_CMD_EXE" ]]; then
    echo "UnrealEditor-Cmd not found: $EDITOR_CMD_EXE" >&2
    echo "Set UE_EDITOR_CMD_EXE or pass --editor-cmd-exe." >&2
    return 2
  fi

  return 0
}

resolve_editor_exe() {
  local project_file="$1"
  local engine_root
  local candidate
  local candidates=()

  if [[ -n "$EDITOR_EXE" ]]; then
    if [[ "$EDITOR_EXE" != /* ]]; then
      EDITOR_EXE="$(absolute_path "$EDITOR_EXE")"
    fi
  else
    engine_root="$(resolve_engine_root_from_project "$project_file" || true)"
    if [[ -n "$engine_root" ]]; then
      candidates+=(
        "$engine_root/Engine/Binaries/Mac/UnrealEditor.app/Contents/MacOS/UnrealEditor"
        "$engine_root/Engine/Binaries/Mac/UnrealEditor"
        "$engine_root/Engine/Binaries/Mac/UnrealEditor.app"
      )
    fi

    for candidate in "${candidates[@]}"; do
      if [[ -x "$candidate" || -d "$candidate" ]]; then
        EDITOR_EXE="$candidate"
        break
      fi
    done
  fi

  if [[ -z "$EDITOR_EXE" ]]; then
    echo "UnrealEditor path is empty. Set UE_EDITOR_EXE or pass --editor-exe." >&2
    return 2
  fi

  if [[ ! -x "$EDITOR_EXE" && ! -d "$EDITOR_EXE" && ! -f "$EDITOR_EXE" ]]; then
    echo "UnrealEditor not found: $EDITOR_EXE" >&2
    echo "Set UE_EDITOR_EXE or pass --editor-exe." >&2
    return 2
  fi

  return 0
}

is_editor_running_for_project() {
  local project_file="$1"
  ps -axo command= | grep -F "UnrealEditor" | grep -F -- "$project_file" | grep -v grep >/dev/null 2>&1
}

ensure_editor_running() {
  local project_file

  project_file="$(find_project_file)" || return $?
  if is_editor_running_for_project "$project_file"; then
    return 0
  fi

  if [[ "$AUTO_LAUNCH_EDITOR" != "1" ]]; then
    echo "No running Unreal Editor found for: $project_file" >&2
    return 3
  fi

  resolve_editor_exe "$project_file" || return $?

  if [[ -d "$EDITOR_EXE" && "$EDITOR_EXE" == *.app ]]; then
    open -na "$EDITOR_EXE" --args "$project_file" -nop4 -nosplash -DisablePlugins=NiagaraSemanticBridge
  else
    "$EDITOR_EXE" "$project_file" -nop4 -nosplash -DisablePlugins=NiagaraSemanticBridge >/dev/null 2>&1 &
  fi

  echo "Launched Unreal Editor for MaterialSemantic request."
  return 0
}

run_preview_object_commandlet() {
  local project_file
  local report_dir
  local report_path
  local exit_code
  local commandlet_args

  project_file="$(find_project_file)" || return $?
  resolve_editor_cmd_exe "$project_file" || return $?

  report_dir="${PROJECT_ROOT}/Saved/MaterialSemanticBridge/MaterialDSLTemp"
  mkdir -p "$report_dir"
  report_path="${report_dir}/materialsemantic-preview-object-$(date +%s)-$$.json"

  echo "Running MaterialSemantic preview-object through UnrealEditor-Cmd: $project_file"
  commandlet_args=(
    "$project_file"
    -run=MaterialSemanticCommandlet
    -Mode=preview-object
    -Format=json
    "-Object=$OBJECT_PATH"
    "-Output=$OUTPUT_PATH"
    "-Report=$report_path"
    -AllowCommandletRendering
    -unattended
    -nop4
    -nosplash
    -stdout
    -FullStdOutLogOutput
  )

  if [[ -n "$PREVIEW_SHAPE" ]]; then
    commandlet_args+=("-PreviewShape=$PREVIEW_SHAPE")
  fi

  if [[ -n "$DISABLE_PLUGINS" ]]; then
    commandlet_args+=("-DisablePlugins=$DISABLE_PLUGINS")
  fi

  set +e
  "$EDITOR_CMD_EXE" "${commandlet_args[@]}"
  exit_code=$?
  set -e

  if [[ -f "$report_path" ]]; then
    cat "$report_path"
    echo
  fi

  return "$exit_code"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      require_value "$1" "${2:-}"
      MODE="$2"
      shift 2
      ;;
    --input)
      require_value "$1" "${2:-}"
      INPUT_PATH="$2"
      shift 2
      ;;
    --input-root)
      require_value "$1" "${2:-}"
      INPUT_ROOT="$2"
      shift 2
      ;;
    --object)
      require_value "$1" "${2:-}"
      OBJECT_PATH="$2"
      shift 2
      ;;
    --output)
      require_value "$1" "${2:-}"
      OUTPUT_PATH="$2"
      shift 2
      ;;
    --preview-shape)
      require_value "$1" "${2:-}"
      PREVIEW_SHAPE="$2"
      shift 2
      ;;
    --timeout)
      require_value "$1" "${2:-}"
      TIMEOUT_SECONDS="$2"
      shift 2
      ;;
    --editor-cmd-exe)
      require_value "$1" "${2:-}"
      EDITOR_CMD_EXE="$2"
      shift 2
      ;;
    --editor-exe)
      require_value "$1" "${2:-}"
      EDITOR_EXE="$2"
      shift 2
      ;;
    --disable-plugins)
      require_value "$1" "${2:-}"
      DISABLE_PLUGINS="$2"
      shift 2
      while [[ $# -gt 0 && "$1" != --* ]]; do
        DISABLE_PLUGINS="${DISABLE_PLUGINS},$1"
        shift
      done
      ;;
    --launch-editor)
      AUTO_LAUNCH_EDITOR=1
      shift
      ;;
    --no-launch-editor)
      AUTO_LAUNCH_EDITOR=0
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

case "$MODE" in
  import-root)
    ;;
  import|normalize)
    [[ -n "$INPUT_PATH" ]] || { echo "--input is required for --mode $MODE" >&2; exit 2; }
    ;;
  preview-object)
    [[ -n "$OBJECT_PATH" ]] || { echo "--object is required for --mode preview-object" >&2; exit 2; }
    [[ -n "$OUTPUT_PATH" ]] || { echo "--output is required for --mode preview-object" >&2; exit 2; }
    ;;
  *)
    echo "Unsupported mode: $MODE" >&2
    usage >&2
    exit 2
    ;;
esac

INPUT_PATH="$(absolute_path "$INPUT_PATH")"
INPUT_ROOT="$(absolute_path "$INPUT_ROOT")"
OUTPUT_PATH="$(absolute_path "$OUTPUT_PATH")"

if [[ "$MODE" == "preview-object" ]]; then
  run_preview_object_commandlet
  exit $?
fi

ensure_editor_running

REQUEST_ID="materialsemantic-${MODE}-$(date +%s)-$$"
BRIDGE_DIR="${PROJECT_ROOT}/Saved/MaterialSemanticBridge"
REQUEST_PATH="${BRIDGE_DIR}/request.json"

mkdir -p "$BRIDGE_DIR"

if [[ -f "$REQUEST_PATH" ]]; then
  if ! grep -Eq '"status"[[:space:]]*:[[:space:]]*"(completed|failed)"' "$REQUEST_PATH"; then
    echo "A MaterialSemantic request is already pending or running: $REQUEST_PATH" >&2
    echo "Wait for it to finish, or remove the file if the editor is not running and the request is stale." >&2
    exit 3
  fi
fi

TMP_REQUEST_PATH="${REQUEST_PATH}.tmp"
case "$MODE" in
  import-root)
    cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"MaterialSemanticCommandlet","mode":"import-root","status":"pending","input_root":"$(json_escape "$INPUT_ROOT")"}
EOF
    ;;
  import)
    cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"MaterialSemanticCommandlet","mode":"import","status":"pending","input":"$(json_escape "$INPUT_PATH")","input_root":"$(json_escape "$INPUT_ROOT")"}
EOF
    ;;
  normalize)
    cat > "$TMP_REQUEST_PATH" <<EOF
{"request_id":"$(json_escape "$REQUEST_ID")","commandlet":"MaterialSemanticCommandlet","mode":"normalize","status":"pending","input":"$(json_escape "$INPUT_PATH")"}
EOF
    ;;
esac
mv "$TMP_REQUEST_PATH" "$REQUEST_PATH"

echo "Queued MaterialSemantic request: $REQUEST_ID"
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
