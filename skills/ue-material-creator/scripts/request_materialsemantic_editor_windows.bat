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

set "MODE=import-root"
set "INPUT_PATH="
set "INPUT_ROOT=%PROJECT_ROOT%\.ue_dsl\MaterialDSL"
set "OBJECT_PATH="
set "OUTPUT_PATH="
set "TIMEOUT_SECONDS=240"
set "AUTO_LAUNCH_EDITOR=1"
set "EDITOR_EXE=%UE_EDITOR_EXE%"
if not defined EDITOR_EXE set "EDITOR_EXE=D:\Games\UE_5.7\Engine\Binaries\Win64\UnrealEditor.exe"
set "EDITOR_CMD_EXE=%UE_EDITOR_CMD_EXE%"
if not defined EDITOR_CMD_EXE set "EDITOR_CMD_EXE=%EDITOR_EXE:UnrealEditor.exe=UnrealEditor-Cmd.exe%"
set "DISABLE_PLUGINS=%UE_MATERIAL_PREVIEW_DISABLE_PLUGINS%"
set "SHOW_HELP=0"

call :parse_args %*
if errorlevel 1 exit /b %ERRORLEVEL%
if "%SHOW_HELP%"=="1" exit /b 0

if /I "%MODE%"=="import-root" goto mode_ok
if /I "%MODE%"=="import" (
	if not defined INPUT_PATH goto missing_import_input
	goto mode_ok
)
if /I "%MODE%"=="normalize" (
	if not defined INPUT_PATH goto missing_normalize_input
	goto mode_ok
)
if /I "%MODE%"=="preview-object" (
	if not defined OBJECT_PATH goto missing_preview_object
	if not defined OUTPUT_PATH goto missing_preview_output
	goto mode_ok
)

1>&2 echo Unsupported mode: %MODE%
call :usage 1>&2
exit /b 2

:missing_import_input
1>&2 echo --input is required for --mode import
exit /b 2

:missing_normalize_input
1>&2 echo --input is required for --mode normalize
exit /b 2

:missing_preview_object
1>&2 echo --object is required for --mode preview-object
exit /b 2

:missing_preview_output
1>&2 echo --output is required for --mode preview-object
exit /b 2

:mode_ok
if defined INPUT_PATH (
	call :absolute_path "%INPUT_PATH%" INPUT_PATH
	if errorlevel 1 exit /b %ERRORLEVEL%
)
if defined OUTPUT_PATH (
	call :absolute_path "%OUTPUT_PATH%" OUTPUT_PATH
	if errorlevel 1 exit /b %ERRORLEVEL%
)
call :absolute_path "%INPUT_ROOT%" INPUT_ROOT
if errorlevel 1 exit /b %ERRORLEVEL%

if /I "%MODE%"=="preview-object" (
	call :run_preview_object_commandlet
	exit /b %ERRORLEVEL%
)

call :ensure_editor_running
if errorlevel 1 exit /b %ERRORLEVEL%

for /f %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()"') do set "REQUEST_TIME=%%I"
set "REQUEST_ID=materialsemantic-%MODE%-%REQUEST_TIME%-%RANDOM%%RANDOM%"
set "BRIDGE_DIR=%PROJECT_ROOT%\Saved\MaterialSemanticBridge"
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
		1>&2 echo A MaterialSemantic request is already pending or running: %REQUEST_PATH%
		1>&2 echo Wait for it to finish, or remove the file if the editor is not running and the request is stale.
		exit /b 3
	)
)

set "TMP_REQUEST_PATH=%REQUEST_PATH%.tmp"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$mode = $env:MODE; $request = [ordered]@{ request_id = $env:REQUEST_ID; commandlet = 'MaterialSemanticCommandlet'; mode = $mode; status = 'pending' }; if ($mode -eq 'import-root') { $request.input_root = $env:INPUT_ROOT } elseif ($mode -eq 'import') { $request.input = $env:INPUT_PATH; $request.input_root = $env:INPUT_ROOT } elseif ($mode -eq 'normalize') { $request.input = $env:INPUT_PATH } else { [Console]::Error.WriteLine('Unsupported editor request mode: ' + $mode); exit 2 }; $request | ConvertTo-Json -Compress | Set-Content -LiteralPath $env:TMP_REQUEST_PATH -NoNewline -Encoding UTF8"
if errorlevel 1 exit /b %ERRORLEVEL%

move /y "%TMP_REQUEST_PATH%" "%REQUEST_PATH%" >nul
if errorlevel 1 exit /b %ERRORLEVEL%

echo Queued MaterialSemantic request: %REQUEST_ID%
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

if /I "%~1"=="--object" (
	if "%~2"=="" (
		1>&2 echo Missing value for --object.
		call :usage 1>&2
		exit /b 2
	)
	set "OBJECT_PATH=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--output" (
	if "%~2"=="" (
		1>&2 echo Missing value for --output.
		call :usage 1>&2
		exit /b 2
	)
	set "OUTPUT_PATH=%~2"
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

if /I "%~1"=="--editor-exe" (
	if "%~2"=="" (
		1>&2 echo Missing value for --editor-exe.
		call :usage 1>&2
		exit /b 2
	)
	set "EDITOR_EXE=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--editor-cmd-exe" (
	if "%~2"=="" (
		1>&2 echo Missing value for --editor-cmd-exe.
		call :usage 1>&2
		exit /b 2
	)
	set "EDITOR_CMD_EXE=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--disable-plugins" (
	if "%~2"=="" (
		1>&2 echo Missing value for --disable-plugins.
		call :usage 1>&2
		exit /b 2
	)
	set "DISABLE_PLUGINS=%~2"
	shift
	shift
	goto parse_disable_plugins
)

if /I "%~1"=="--launch-editor" (
	set "AUTO_LAUNCH_EDITOR=1"
	shift
	goto parse_args
)

if /I "%~1"=="--no-launch-editor" (
	set "AUTO_LAUNCH_EDITOR=0"
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

:parse_disable_plugins
if "%~1"=="" exit /b 0
set "NEXT_ARG=%~1"
if "%NEXT_ARG:~0,2%"=="--" goto parse_args
set "DISABLE_PLUGINS=%DISABLE_PLUGINS%,%~1"
shift
goto parse_disable_plugins

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

:run_preview_object_commandlet
set "PROJECT_FILE="
for %%I in ("%PROJECT_ROOT%\*.uproject") do if not defined PROJECT_FILE set "PROJECT_FILE=%%~fI"
if not defined PROJECT_FILE (
	1>&2 echo Failed to locate .uproject under: %PROJECT_ROOT%
	exit /b 2
)

if not exist "%PROJECT_FILE%" (
	1>&2 echo Project file not found: %PROJECT_FILE%
	exit /b 2
)

if not defined EDITOR_CMD_EXE (
	1>&2 echo UnrealEditor-Cmd.exe path is empty. Set UE_EDITOR_CMD_EXE or pass --editor-cmd-exe.
	exit /b 2
)

for %%I in ("%EDITOR_CMD_EXE%") do set "EDITOR_CMD_EXE=%%~fI"
if not exist "%EDITOR_CMD_EXE%" (
	1>&2 echo UnrealEditor-Cmd.exe not found: %EDITOR_CMD_EXE%
	1>&2 echo Set UE_EDITOR_CMD_EXE or pass --editor-cmd-exe.
	exit /b 2
)

for /f %%I in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "[DateTimeOffset]::UtcNow.ToUnixTimeSeconds()"') do set "REQUEST_TIME=%%I"
set "REPORT_DIR=%PROJECT_ROOT%\Saved\MaterialSemanticBridge\MaterialDSLTemp"
if not exist "%REPORT_DIR%" mkdir "%REPORT_DIR%"
if errorlevel 1 exit /b %ERRORLEVEL%
set "REPORT_PATH=%REPORT_DIR%\materialsemantic-preview-object-%REQUEST_TIME%-%RANDOM%%RANDOM%.json"

echo Running MaterialSemantic preview-object through UnrealEditor-Cmd: %PROJECT_FILE%
if defined DISABLE_PLUGINS (
	"%EDITOR_CMD_EXE%" "%PROJECT_FILE%" -run=MaterialSemanticCommandlet -Mode=preview-object -Format=json -Object="%OBJECT_PATH%" -Output="%OUTPUT_PATH%" -Report="%REPORT_PATH%" -AllowCommandletRendering -unattended -nop4 -nosplash -stdout -FullStdOutLogOutput -DisablePlugins="%DISABLE_PLUGINS%"
) else (
	"%EDITOR_CMD_EXE%" "%PROJECT_FILE%" -run=MaterialSemanticCommandlet -Mode=preview-object -Format=json -Object="%OBJECT_PATH%" -Output="%OUTPUT_PATH%" -Report="%REPORT_PATH%" -AllowCommandletRendering -unattended -nop4 -nosplash -stdout -FullStdOutLogOutput
)
set "COMMANDLET_EXIT=%ERRORLEVEL%"
if exist "%REPORT_PATH%" type "%REPORT_PATH%"
exit /b %COMMANDLET_EXIT%

:ensure_editor_running
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$uproject = Get-ChildItem -LiteralPath $env:PROJECT_ROOT -Filter '*.uproject' | Select-Object -First 1 -ExpandProperty FullName; if (-not $uproject) { [Console]::Error.WriteLine('Failed to locate .uproject under: ' + $env:PROJECT_ROOT); exit 2 }; $running = Get-CimInstance Win32_Process | Where-Object { $_.Name -eq 'UnrealEditor.exe' -and $_.CommandLine -and $_.CommandLine.Contains($uproject) } | Select-Object -First 1; if ($running) { 'running'; exit 0 }; if ($env:AUTO_LAUNCH_EDITOR -ne '1') { [Console]::Error.WriteLine('No running Unreal Editor found for: ' + $uproject); exit 3 }; $editor = $env:EDITOR_EXE; if (-not [System.IO.Path]::IsPathRooted($editor)) { $editor = [System.IO.Path]::GetFullPath((Join-Path $env:PROJECT_ROOT $editor)) }; if (-not (Test-Path -LiteralPath $editor)) { [Console]::Error.WriteLine('UnrealEditor.exe not found: ' + $editor); [Console]::Error.WriteLine('Set UE_EDITOR_EXE or pass --editor-exe.'); exit 4 }; Start-Process -FilePath $editor -ArgumentList @($uproject, '-nop4', '-nosplash', '-DisablePlugins=NiagaraSemanticBridge') -WindowStyle Hidden; 'launched'; exit 0"`) do set "EDITOR_STATE=%%I"
if errorlevel 1 exit /b %ERRORLEVEL%
if /I "%EDITOR_STATE%"=="launched" (
	echo Launched Unreal Editor for MaterialSemantic request.
)
exit /b 0

:usage
echo Usage:
echo   request_materialsemantic_editor_windows.bat [options]
echo.
echo Options:
echo   --mode ^<import-root^|import^|normalize^|preview-object^>
echo   --input ^<file.materialdsl^>  Required for import and normalize
echo   --input-root ^<path^>         DSL root for import-root, or mapping root for import
echo   --object ^</Game/Path.Asset^> Required for preview-object
echo   --output ^<file.png^>         Required for preview-object
echo   --timeout ^<seconds^>         Seconds to wait for the Unreal Editor response; defaults to 240
echo   --editor-cmd-exe ^<path^>     UnrealEditor-Cmd.exe path for preview-object; defaults to UE_EDITOR_CMD_EXE or project UE 5.7 path
echo   --editor-exe ^<path^>         UnrealEditor.exe path for editor request modes; defaults to UE_EDITOR_EXE or project UE 5.7 path
echo   --disable-plugins ^<a,b,c^>   Extra plugins to disable for preview-object commandlet startup; defaults to UE_MATERIAL_PREVIEW_DISABLE_PLUGINS
echo   --launch-editor               Launch Unreal Editor for editor request modes when none is running; default
echo   --no-launch-editor            Require an already-running Unreal Editor for editor request modes
echo   --help                       Show this help
echo.
echo This writes a MaterialSemanticCommandlet-shaped request to Saved\MaterialSemanticBridge\request.json.
echo For preview-object, this runs UnrealEditor-Cmd directly and exports the material preview without launching Unreal Editor.
exit /b 0
