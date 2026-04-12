@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "REPO_ROOT=%%~fI"
set "DEFAULT_REQUEST_PATH=%REPO_ROOT%\Saved\WidgetDSLTemp\widgetsemantic-request.json"

set "PROJECT_FILE="
if defined UE_PROJECT_FILE set "PROJECT_FILE=%UE_PROJECT_FILE%"
set "PROJECT_SEARCH_DIR=%CD%"
set "ENGINE_ROOT="
if defined UE_ENGINE_ROOT set "ENGINE_ROOT=%UE_ENGINE_ROOT%"

set "INPUT_PATH="
set "OUTPUT_PATH="
set "LOG_PATH="
set "PREVIEW_SIZE="
set "BUILD_BEFORE_RUN=0"
set "MODE=validate"
set "MODE_SPECIFIED=0"
set "SHOW_HELP=0"
set "DDC_SWITCHES="
set "DDC_MODE_LABEL=default Unreal cache settings"

if "%~1"=="" (
	call :load_request_file
	if errorlevel 1 exit /b %ERRORLEVEL%
)

call :parse_args %*
if errorlevel 1 exit /b %ERRORLEVEL%
if "%SHOW_HELP%"=="1" exit /b 0

if not defined INPUT_PATH (
	1>&2 echo Missing required --input argument.
	call :usage 1>&2
	exit /b 2
)

if not defined PROJECT_FILE (
	call :resolve_project_file
	if errorlevel 1 exit /b 2
)

for %%I in ("%PROJECT_FILE%") do (
	set "PROJECT_FILE=%%~fI"
	set "PROJECT_ROOT=%%~dpI"
	set "PROJECT_NAME=%%~nI"
)

if not exist "%PROJECT_FILE%" (
	1>&2 echo Project file not found: %PROJECT_FILE%
	exit /b 2
)

set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "EDITOR_TARGET=%PROJECT_NAME%Editor"

if not defined ENGINE_ROOT (
	call :resolve_engine_root
	if errorlevel 1 exit /b 2
)

set "BUILD_SCRIPT=%ENGINE_ROOT%\Engine\Build\BatchFiles\Build.bat"
set "EDITOR_BINARY=%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
if not exist "%EDITOR_BINARY%" set "EDITOR_BINARY=%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor.exe"

if not exist "%BUILD_SCRIPT%" (
	1>&2 echo Build script not found: %BUILD_SCRIPT%
	exit /b 2
)

if not exist "%EDITOR_BINARY%" (
	1>&2 echo UnrealEditor executable not found under: %ENGINE_ROOT%\Engine\Binaries\Win64
	exit /b 2
)

for %%I in ("%INPUT_PATH%") do set "INPUT_PATH=%%~fI"
if not exist "%INPUT_PATH%" (
	1>&2 echo Input DSL file not found: %INPUT_PATH%
	exit /b 2
)

call :prepare_output_paths
if errorlevel 1 exit /b %ERRORLEVEL%

if "%BUILD_BEFORE_RUN%"=="1" call :run_build
if errorlevel 1 exit /b %ERRORLEVEL%

call :print_run_header

if /I "%MODE%"=="import" (
	call :run_import
) else (
	call :run_validate
)
exit /b %ERRORLEVEL%

:parse_args
if "%~1"=="" exit /b 0

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

if /I "%~1"=="--project" (
	if "%~2"=="" (
		1>&2 echo Missing value for --project.
		call :usage 1>&2
		exit /b 2
	)
	set "PROJECT_FILE=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--validate" (
	call :set_mode validate
	if errorlevel 1 exit /b 2
	shift
	goto parse_args
)

if /I "%~1"=="--preview" (
	call :set_mode preview
	if errorlevel 1 exit /b 2
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
	call :set_mode preview
	if errorlevel 1 exit /b 2
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--build" (
	set "BUILD_BEFORE_RUN=1"
	shift
	goto parse_args
)

if /I "%~1"=="--engine" (
	if "%~2"=="" (
		1>&2 echo Missing value for --engine.
		call :usage 1>&2
		exit /b 2
	)
	set "ENGINE_ROOT=%~2"
	shift
	shift
	goto parse_args
)

if /I "%~1"=="--import" (
	call :set_mode import
	if errorlevel 1 exit /b 2
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

:set_mode
if "%MODE_SPECIFIED%"=="0" (
	set "MODE=%~1"
	set "MODE_SPECIFIED=1"
	exit /b 0
)

if /I "%MODE%"=="%~1" exit /b 0

1>&2 echo Mode flags are mutually exclusive: --validate, --preview, and --import.
exit /b 2

:load_request_file
if not exist "%DEFAULT_REQUEST_PATH%" (
	1>&2 echo Request file not found: %DEFAULT_REQUEST_PATH%
	exit /b 2
)

for /f "usebackq tokens=1,* delims=|" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $data = Get-Content -Raw -LiteralPath $env:DEFAULT_REQUEST_PATH | ConvertFrom-Json } catch { exit 3 }; function Emit([string] $key, [object] $value) { if ($null -eq $value) { return }; $stringValue = [string] $value; if ([string]::IsNullOrWhiteSpace($stringValue)) { return }; [Console]::WriteLine($key + '|' + $stringValue) }; Emit 'project' $data.project; Emit 'engine' $data.engine; Emit 'input' $data.input; Emit 'preview_size' $data.preview_size; if ($data.build -eq $true) { [Console]::WriteLine('build|true') }; $mode = [string] $data.mode; if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'validate' }; [Console]::WriteLine('mode|' + $mode.ToLowerInvariant())"`) do (
	if /I "%%I"=="project" set "PROJECT_FILE=%%J"
	if /I "%%I"=="engine" set "ENGINE_ROOT=%%J"
	if /I "%%I"=="input" set "INPUT_PATH=%%J"
	if /I "%%I"=="preview_size" set "PREVIEW_SIZE=%%J"
	if /I "%%I"=="build" set "BUILD_BEFORE_RUN=1"
	if /I "%%I"=="mode" (
		call :set_mode %%J
		if errorlevel 1 exit /b 2
	)
)
set "REQUEST_LOAD_STATUS=%ERRORLEVEL%"

if not "%REQUEST_LOAD_STATUS%"=="0" (
	1>&2 echo Failed to parse request file: %DEFAULT_REQUEST_PATH%
	exit /b 2
)

if not defined PROJECT_FILE set "PROJECT_SEARCH_DIR=%REPO_ROOT%"
exit /b 0

:resolve_project_file
set "PROJECT_FILE="
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$projects = Get-ChildItem -LiteralPath $env:PROJECT_SEARCH_DIR -Filter '*.uproject' -File -ErrorAction SilentlyContinue | Sort-Object -Property Name; if ($projects.Count -eq 1) { [Console]::Write($projects[0].FullName); exit 0 }; if ($projects.Count -eq 0) { exit 10 }; exit 11"`) do set "PROJECT_FILE=%%I"
set "PROJECT_LOOKUP_STATUS=%ERRORLEVEL%"

if "%PROJECT_LOOKUP_STATUS%"=="0" exit /b 0
if "%PROJECT_LOOKUP_STATUS%"=="10" (
	1>&2 echo No .uproject file found in current directory: %PROJECT_SEARCH_DIR%
	1>&2 echo Pass --project ^<path^> explicitly.
	exit /b 2
)
if "%PROJECT_LOOKUP_STATUS%"=="11" (
	1>&2 echo Multiple .uproject files found in current directory: %PROJECT_SEARCH_DIR%
	1>&2 echo Pass --project ^<path^> explicitly.
	exit /b 2
)

1>&2 echo Failed to resolve project file from current directory: %PROJECT_SEARCH_DIR%
exit /b 2

:resolve_engine_root
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$projectFile = $env:PROJECT_FILE; $projectDir = Split-Path -Parent $projectFile; $searchDir = $projectDir; while ($searchDir) { if (Test-Path (Join-Path $searchDir 'Engine\Build\BatchFiles\Build.bat')) { [Console]::Write($searchDir); exit 0 }; $parentDir = Split-Path -Parent $searchDir; if ($parentDir -eq $searchDir) { break }; $searchDir = $parentDir }; try { $projectData = Get-Content -Raw -LiteralPath $projectFile | ConvertFrom-Json } catch { exit 3 }; $association = [string]$projectData.EngineAssociation; if ([string]::IsNullOrWhiteSpace($association)) { exit 4 }; $candidates = New-Object 'System.Collections.Generic.List[string]'; function AddCandidate([string]$path) { if ([string]::IsNullOrWhiteSpace($path)) { return }; try { $fullPath = [System.IO.Path]::GetFullPath($path) } catch { return }; if (-not [string]::IsNullOrWhiteSpace($fullPath)) { $script:candidates.Add($fullPath) } }; $buildsKey = 'HKCU:\Software\Epic Games\Unreal Engine\Builds'; if (Test-Path $buildsKey) { $builds = Get-ItemProperty -Path $buildsKey -ErrorAction SilentlyContinue; if ($null -ne $builds) { $value = $builds.PSObject.Properties[$association]; if ($null -ne $value) { AddCandidate ([string]$value.Value) } } }; foreach ($registryKey in @(('HKLM:\SOFTWARE\EpicGames\Unreal Engine\{0}' -f $association), ('HKLM:\SOFTWARE\WOW6432Node\EpicGames\Unreal Engine\{0}' -f $association), ('HKCU:\SOFTWARE\EpicGames\Unreal Engine\{0}' -f $association))) { if (Test-Path $registryKey) { AddCandidate ((Get-ItemProperty -Path $registryKey -Name InstalledDirectory -ErrorAction SilentlyContinue).InstalledDirectory) } }; $launcherInstalledPath = 'C:\ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat'; if (Test-Path $launcherInstalledPath) { try { $launcherData = Get-Content -Raw -LiteralPath $launcherInstalledPath | ConvertFrom-Json } catch { $launcherData = $null }; if ($null -ne $launcherData -and $null -ne $launcherData.InstallationList) { $expectedAppName = 'UE_{0}' -f $association; foreach ($entry in $launcherData.InstallationList) { $appName = [string]$entry.AppName; $artifactId = [string]$entry.ArtifactId; $namespaceId = [string]$entry.NamespaceId; $appVersion = [string]$entry.AppVersion; if ($namespaceId -eq 'ue' -and (($appName -eq $expectedAppName) -or ($artifactId -eq $expectedAppName) -or ((-not [string]::IsNullOrWhiteSpace($appVersion)) -and $appVersion.StartsWith($association + '.')))) { AddCandidate ([string]$entry.InstallLocation) } } } }; if ($association -match '^\d+(\.\d+)?$') { foreach ($baseDir in @('C:\Program Files\Epic Games', 'D:\Program Files\Epic Games', 'D:\Epic Games', 'D:\Games', 'E:\Program Files\Epic Games', 'E:\Epic Games', 'E:\Games')) { AddCandidate (Join-Path $baseDir ('UE_' + $association)) } }; $resolved = $candidates | Select-Object -Unique | Where-Object { Test-Path (Join-Path $_ 'Engine\Build\BatchFiles\Build.bat') } | Select-Object -First 1; if ($resolved) { [Console]::Write($resolved); exit 0 }; exit 5"`) do set "ENGINE_ROOT=%%I"
set "ENGINE_LOOKUP_STATUS=%ERRORLEVEL%"

if "%ENGINE_LOOKUP_STATUS%"=="0" exit /b 0

1>&2 echo Failed to resolve Unreal Engine root from project: %PROJECT_FILE%
1>&2 echo Pass --engine ^<path^> explicitly or set UE_ENGINE_ROOT.
exit /b 2

:prepare_output_paths
set "TEMP_OUTPUT_DIR=%PROJECT_ROOT%\Saved\WidgetDSLTemp"
if not exist "%TEMP_OUTPUT_DIR%" mkdir "%TEMP_OUTPUT_DIR%"
set "ARTIFACT_BASENAME=widgetsemantic-validate"
if /I "%MODE%"=="import" set "ARTIFACT_BASENAME=widgetsemantic-import"
set "OUTPUT_PATH=%TEMP_OUTPUT_DIR%\%ARTIFACT_BASENAME%.json"
set "LOG_PATH=%TEMP_OUTPUT_DIR%\%ARTIFACT_BASENAME%.log"

for %%I in ("%OUTPUT_PATH%") do set "OUTPUT_PATH=%%~fI"
for %%I in ("%LOG_PATH%") do set "LOG_PATH=%%~fI"
exit /b 0

:print_run_header
echo Project file: %PROJECT_FILE%
echo Engine root: %ENGINE_ROOT%
echo Input DSL: %INPUT_PATH%
echo Mode: %MODE%
echo Output file: %OUTPUT_PATH%
echo Log file: %LOG_PATH%
echo DDC mode: %DDC_MODE_LABEL%
if /I "%MODE%"=="preview" (
	if defined PREVIEW_SIZE (
		echo Preview size: %PREVIEW_SIZE%
	) else (
		echo Preview size: default
	)
) else (
	echo Preview: disabled
)
exit /b 0

:run_build
echo Building %EDITOR_TARGET%...
call "%BUILD_SCRIPT%" "%EDITOR_TARGET%" Win64 Development "-Project=%PROJECT_FILE%" -WaitMutex -NoHotReloadFromIDE -NoUBA
exit /b %ERRORLEVEL%

:run_validate
set "COMMANDLET_ARGS="%PROJECT_FILE%" -run=WidgetSemanticCommandlet -Mode=validate "-Input=%INPUT_PATH%" "-Format=json" %DDC_SWITCHES% -unattended -nop4 -nosplash -NoEpicPortal -HomeScreen.EnableHomeScreen=0 -stdout -FullStdOutLogOutput "-abslog=%LOG_PATH%""
if /I not "%MODE%"=="preview" goto validate_no_preview
set "COMMANDLET_ARGS=%COMMANDLET_ARGS% -AllowCommandletRendering"
if defined PREVIEW_SIZE set "COMMANDLET_ARGS=%COMMANDLET_ARGS% "-PreviewSize=%PREVIEW_SIZE%""
goto validate_args_ready

:validate_no_preview
set "COMMANDLET_ARGS=%COMMANDLET_ARGS% -NoPreview -NullRHI"

:validate_args_ready

if exist "%OUTPUT_PATH%" del /q "%OUTPUT_PATH%" >nul 2>nul
if exist "%LOG_PATH%" del /q "%LOG_PATH%" >nul 2>nul

"%EDITOR_BINARY%" %COMMANDLET_ARGS%
set "LAUNCH_STATUS=%ERRORLEVEL%"

if not exist "%OUTPUT_PATH%" (
	1>&2 echo Expected commandlet output was not created: %OUTPUT_PATH%
	exit /b 2
)

call :read_validate_result
if errorlevel 1 exit /b %ERRORLEVEL%

if "%VALID_FIELD%"=="true" (
	if not "%LAUNCH_STATUS%"=="0" (
		type "%OUTPUT_PATH%"
		exit /b 2
	)
	if /I "%MODE%"=="preview" if not defined PREVIEW_PATH (
		1>&2 echo Validation passed but preview_image is empty.
		exit /b 1
	)
	if defined PREVIEW_PATH if not exist "%PREVIEW_PATH%" (
		1>&2 echo Validation passed but preview_image was not written to disk: %PREVIEW_PATH%
		exit /b 1
	)
	type "%OUTPUT_PATH%"
	exit /b 0
)

if "%VALID_FIELD%"=="false" (
	type "%OUTPUT_PATH%"
	exit /b 1
)

type "%OUTPUT_PATH%"
exit /b 2

:run_import
set "COMMANDLET_ARGS="%PROJECT_FILE%" -run=WidgetSemanticCommandlet -Mode=import "-Input=%INPUT_PATH%" "-Format=json" %DDC_SWITCHES% -NullRHI -unattended -nop4 -nosplash -NoEpicPortal -HomeScreen.EnableHomeScreen=0 -stdout -FullStdOutLogOutput "-abslog=%LOG_PATH%""

if exist "%OUTPUT_PATH%" del /q "%OUTPUT_PATH%" >nul 2>nul
if exist "%LOG_PATH%" del /q "%LOG_PATH%" >nul 2>nul

"%EDITOR_BINARY%" %COMMANDLET_ARGS%
set "IMPORT_STATUS=%ERRORLEVEL%"

if not exist "%OUTPUT_PATH%" (
	1>&2 echo Expected import output was not created: %OUTPUT_PATH%
	exit /b 2
)

call :read_import_result
if errorlevel 1 exit /b %ERRORLEVEL%

if /I "%IMPORTED_FIELD%"=="true" (
	if not "%IMPORT_STATUS%"=="0" (
		type "%OUTPUT_PATH%"
		exit /b 2
	)
	type "%OUTPUT_PATH%"
	exit /b 0
)

if defined IMPORT_ERROR_FIELD 1>&2 echo Import failed: %IMPORT_ERROR_FIELD%
type "%OUTPUT_PATH%"
if /I "%IMPORTED_FIELD%"=="false" exit /b 1
exit /b 2

:read_validate_result
set "VALID_FIELD="
set "PREVIEW_PATH="
for /f "usebackq tokens=1,* delims=|" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $data = Get-Content -Raw -LiteralPath $env:OUTPUT_PATH | ConvertFrom-Json } catch { exit 3 }; $valid = ''; if ($null -ne $data.valid) { $valid = $data.valid.ToString().ToLowerInvariant() }; $preview = ''; if ($null -ne $data.preview_image) { $preview = [string]$data.preview_image }; [Console]::Write($valid + '|' + $preview)"`) do (
	set "VALID_FIELD=%%I"
	set "PREVIEW_PATH=%%J"
)
if not "%ERRORLEVEL%"=="0" (
	1>&2 echo Failed to parse validation JSON: %OUTPUT_PATH%
	exit /b 2
)
exit /b 0

:read_import_result
set "IMPORTED_FIELD="
set "IMPORTED_OBJECT_PATH="
set "IMPORT_ERROR_FIELD="
for /f "usebackq tokens=1,2,* delims=|" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $data = Get-Content -Raw -LiteralPath $env:OUTPUT_PATH | ConvertFrom-Json } catch { exit 3 }; $imported = ''; if ($null -ne $data.imported) { $imported = $data.imported.ToString().ToLowerInvariant() }; $objectPath = ''; if ($null -ne $data.object_path) { $objectPath = [string]$data.object_path }; $importError = ''; if ($null -ne $data.error) { $importError = [string]$data.error }; [Console]::Write($imported + '|' + $objectPath + '|' + $importError)"`) do (
	set "IMPORTED_FIELD=%%I"
	set "IMPORTED_OBJECT_PATH=%%J"
	set "IMPORT_ERROR_FIELD=%%K"
)
if not "%ERRORLEVEL%"=="0" (
	1>&2 echo Failed to parse import JSON: %OUTPUT_PATH%
	exit /b 2
)
exit /b 0

:usage
echo Usage:
echo   .agents\skills\ue-widget-creator\scripts\run_widgetsemantic_validate_windows.bat
echo   .agents\skills\ue-widget-creator\scripts\run_widgetsemantic_validate_windows.bat --input ^<file.widgetdsl^> [options]
echo.
echo No-argument mode:
echo   Reads request settings from Saved\WidgetDSLTemp\widgetsemantic-request.json.
echo   This is the preferred mode for fixed-command approval reuse.
echo.
echo Options:
echo   --project ^<path^>        .uproject path; defaults to the only .uproject in current directory
echo   --input ^<path^>          Absolute or relative .widgetdsl input path
echo   --validate                Validate only ^(default if no mode is passed^)
echo   --preview                 Validate and require preview_image output
echo   --preview-size ^<size^>   Preview-only option; pass WidthxHeight ^(for example 1280x720^)
echo   --build                   Build the project Editor target before running the selected mode
echo   --engine ^<path^>         Unreal Engine root path; defaults to project EngineAssociation lookup
echo   --import                  Import only; do not run validate first
echo   --help                    Show this help
echo.
echo Modes are mutually exclusive: --validate, --preview, and --import.
echo Examples:
echo   %~f0
echo   %~f0 --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl --validate
echo   %~f0 --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl --preview
echo   %~f0 --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl --preview-size 1280x720
echo   %~f0 --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl --import
echo   %~f0 --project D:\Game\Game.uproject --input .ue_dsl\WidgetDSL\UI\WBP_MainMenu.widgetdsl
echo   %~f0 --build --input C:\absolute\path\to\file.widgetdsl
exit /b 0
