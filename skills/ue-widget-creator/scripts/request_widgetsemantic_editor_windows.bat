@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_DIR=%~dp0"

set "PROJECT_ROOT=%UE_PROJECT_ROOT%"
if not defined PROJECT_ROOT (
	call :find_project_root "%CD%"
	if errorlevel 1 call :find_project_root "%SCRIPT_DIR%"
)
if not defined PROJECT_ROOT (
	1>&2 echo Failed to locate project root. Run from a project directory or set UE_PROJECT_ROOT.
	exit /b 2
)

for %%I in ("%PROJECT_ROOT%") do set "PROJECT_ROOT=%%~fI"

set "MODE=preview"
set "INPUT_PATH="
set "INPUT_ROOT=%PROJECT_ROOT%\.ue_dsl\WidgetDSL"
set "PREVIEW_SIZE="
set "TIMEOUT_SECONDS=120"
set "SHOW_HELP=0"

call :parse_args %*
if errorlevel 1 exit /b %ERRORLEVEL%
if "%SHOW_HELP%"=="1" exit /b 0

if /I "%MODE%"=="import-root" goto mode_ok
if /I "%MODE%"=="validate" goto require_input
if /I "%MODE%"=="preview" goto require_input
if /I "%MODE%"=="stabilize" goto require_input
if /I "%MODE%"=="import" goto require_input

1>&2 echo Unsupported mode: %MODE%
call :usage 1>&2
exit /b 2

:require_input
if not defined INPUT_PATH (
	1>&2 echo --input is required for --mode %MODE%
	exit /b 2
)

:mode_ok
if defined INPUT_PATH (
	call :absolute_path "%INPUT_PATH%" INPUT_PATH
	if errorlevel 1 exit /b %ERRORLEVEL%
)
call :absolute_path "%INPUT_ROOT%" INPUT_ROOT
if errorlevel 1 exit /b %ERRORLEVEL%

for /f %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()"') do set "REQUEST_TIME=%%I"
set "REQUEST_ID=widgetsemantic-%MODE%-%REQUEST_TIME%-%RANDOM%%RANDOM%"
set "BRIDGE_DIR=%PROJECT_ROOT%\Saved\WidgetSemanticBridge"
set "REQUEST_PATH=%BRIDGE_DIR%\request.json"

if not exist "%BRIDGE_DIR%" mkdir "%BRIDGE_DIR%"
if errorlevel 1 exit /b %ERRORLEVEL%

if exist "%REQUEST_PATH%" (
	powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = $env:REQUEST_PATH; try { $data = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json } catch { exit 4 }; $status = [string]$data.status; if ($status -eq 'completed' -or $status -eq 'failed') { exit 0 }; exit 3"
	if errorlevel 4 (
		1>&2 echo Failed to parse existing request file: %REQUEST_PATH%
		exit /b 2
	)
	if errorlevel 3 (
		1>&2 echo A WidgetSemantic request is already pending or running: %REQUEST_PATH%
		1>&2 echo Wait for it to finish, or remove the file if the editor is not running and the request is stale.
		exit /b 3
	)
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "$mode = ([string]$env:MODE).ToLowerInvariant(); $request = [ordered]@{ request_id = $env:REQUEST_ID; commandlet = 'WidgetSemanticCommandlet'; mode = $mode; status = 'pending' }; if ($mode -eq 'import-root') { $request.input_root = $env:INPUT_ROOT } elseif ($mode -eq 'import') { $request.input = $env:INPUT_PATH; $request.input_root = $env:INPUT_ROOT } elseif ($mode -eq 'validate' -or $mode -eq 'preview' -or $mode -eq 'stabilize') { $request.input = $env:INPUT_PATH; if (-not [string]::IsNullOrWhiteSpace($env:PREVIEW_SIZE)) { $request.preview_size = $env:PREVIEW_SIZE } } else { [Console]::Error.WriteLine('Unsupported mode: ' + $mode); exit 2 }; $request | ConvertTo-Json -Compress | Set-Content -LiteralPath $env:REQUEST_PATH -NoNewline -Encoding UTF8"
if errorlevel 1 exit /b %ERRORLEVEL%

echo Queued WidgetSemantic request: %REQUEST_ID%
echo Waiting for running Unreal Editor to update: %REQUEST_PATH%

powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = $env:REQUEST_PATH; $timeout = [int]$env:TIMEOUT_SECONDS; $deadline = [DateTime]::UtcNow.AddSeconds($timeout); while ($true) { try { $data = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json } catch { Start-Sleep -Milliseconds 250; continue }; $status = [string]$data.status; if ($status -ne 'pending' -and $status -ne 'running') { break }; if ([DateTime]::UtcNow -ge $deadline) { [Console]::Error.WriteLine('Timed out waiting for Unreal Editor to process request.'); [Console]::Error.WriteLine('Request file remains at: ' + $path); exit 124 }; Start-Sleep -Milliseconds 250 }; Get-Content -Raw -LiteralPath $path; if ($status -eq 'completed') { exit 0 }; exit 1"
exit /b %ERRORLEVEL%

:parse_args
if "%~1"=="" exit /b 0

if /I "%~1"=="--mode" (
	if "%~2"=="" (
		1>&2 echo Missing value for --mode.
		call :usage 1>&2
		exit /b 2
	)
	set "MODE=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--input" (
	if "%~2"=="" (
		1>&2 echo Missing value for --input.
		call :usage 1>&2
		exit /b 2
	)
	set "INPUT_PATH=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--input-root" (
	if "%~2"=="" (
		1>&2 echo Missing value for --input-root.
		call :usage 1>&2
		exit /b 2
	)
	set "INPUT_ROOT=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--preview-size" (
	if "%~2"=="" (
		1>&2 echo Missing value for --preview-size.
		call :usage 1>&2
		exit /b 2
	)
	set "PREVIEW_SIZE=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--timeout" (
	if "%~2"=="" (
		1>&2 echo Missing value for --timeout.
		call :usage 1>&2
		exit /b 2
	)
	set "TIMEOUT_SECONDS=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--help" (
	call :usage
	set "SHOW_HELP=1"
	exit /b 0
)

1>&2 echo Unknown argument: %~1
call :usage 1>&2
exit /b 2

:find_project_root
set "SEARCH_DIR=%~f1"

:find_project_root_loop
if exist "%SEARCH_DIR%\*.uproject" (
	set "PROJECT_ROOT=%SEARCH_DIR%"
	exit /b 0
)
for %%I in ("%SEARCH_DIR%\..") do set "PARENT_DIR=%%~fI"
if /I "%PARENT_DIR%"=="%SEARCH_DIR%" exit /b 1
set "SEARCH_DIR=%PARENT_DIR%"
goto find_project_root_loop

:absolute_path
set "ABSOLUTE_INPUT=%~1"
set "ABSOLUTE_OUTPUT_VAR=%~2"
if not defined ABSOLUTE_INPUT (
	set "%ABSOLUTE_OUTPUT_VAR%="
	exit /b 0
)

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = $env:ABSOLUTE_INPUT; if ([System.IO.Path]::IsPathRooted($path)) { [System.IO.Path]::GetFullPath($path) } else { [System.IO.Path]::GetFullPath((Join-Path $env:PROJECT_ROOT $path)) }"`) do set "%ABSOLUTE_OUTPUT_VAR%=%%I"
exit /b %ERRORLEVEL%

:usage
echo Usage:
echo   request_widgetsemantic_editor_windows.bat [options]
echo.
echo Options:
echo   --mode ^<validate^|preview^|stabilize^|import^|import-root^>
echo   --input ^<file.widgetdsl^>  Required except for import-root
echo   --input-root ^<path^>       DSL root for import-root, or mapping root for import
echo   --preview-size ^<size^>     Preview mode size, for example 1280x720
echo   --timeout ^<seconds^>       Seconds to wait for the running Unreal Editor response; defaults to 120
echo   --help                      Show this help
echo.
echo This does not launch UnrealEditor-Cmd. It writes a WidgetSemanticCommandlet-shaped request
echo to Saved\WidgetSemanticBridge\request.json for the already-running Unreal Editor to process.
exit /b 0
