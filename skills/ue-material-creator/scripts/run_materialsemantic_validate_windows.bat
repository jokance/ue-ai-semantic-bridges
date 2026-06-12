@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT="
call :find_project_root "%CD%"
if errorlevel 1 call :find_project_root "%SCRIPT_DIR%"
if defined PROJECT_ROOT (
	set "REPO_ROOT=%PROJECT_ROOT%"
) else (
	for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "REPO_ROOT=%%~fI"
)
set "DEFAULT_REQUEST_PATH=%REPO_ROOT%\Saved\MaterialSemanticBridge\MaterialDSLTemp\materialsemantic-request.json"
set "PROJECT_ROOT="

set "PROJECT_FILE="
set "ENGINE_ROOT="

set "INPUT_PATH="
set "REPORT_PATH="
set "LOG_PATH="
set "PREVIEW_FRAME_INTERVAL_SECONDS="
set "BUILD_BEFORE_RUN=0"
set "MODE=validate"
set "MODE_SPECIFIED=0"
set "SHOW_HELP=0"

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
	1>&2 echo Missing required --project argument or request field.
	call :usage 1>&2
	exit /b 2
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
if defined UE_EDITOR_CMD (
	set "EDITOR_BINARY=%UE_EDITOR_CMD%"
) else (
	set "EDITOR_BINARY=%ENGINE_ROOT%\Engine\Binaries\Win64\UnrealEditor-Cmd.exe"
)

if not exist "%BUILD_SCRIPT%" (
	1>&2 echo Build script not found: %BUILD_SCRIPT%
	exit /b 2
)

if not exist "%EDITOR_BINARY%" (
	1>&2 echo UnrealEditor-Cmd not found: %EDITOR_BINARY%
	exit /b 2
)

call :resolve_project_path "%INPUT_PATH%" INPUT_PATH
if errorlevel 1 exit /b %ERRORLEVEL%
if not exist "%INPUT_PATH%" (
	1>&2 echo Input DSL file not found: %INPUT_PATH%
	exit /b 2
)

set "INPUT_ROOT=%PROJECT_ROOT%\.ue_dsl\MaterialDSL"
for %%I in ("%INPUT_ROOT%") do set "INPUT_ROOT=%%~fI"

set "TEMP_OUTPUT_DIR=%PROJECT_ROOT%\Saved\MaterialSemanticBridge\MaterialDSLTemp"
if not exist "%TEMP_OUTPUT_DIR%" mkdir "%TEMP_OUTPUT_DIR%"
if not defined REPORT_PATH set "REPORT_PATH=%TEMP_OUTPUT_DIR%\materialsemantic-%MODE%.json"
call :resolve_project_path "%REPORT_PATH%" REPORT_PATH
if errorlevel 1 exit /b %ERRORLEVEL%
set "LOG_PATH=%TEMP_OUTPUT_DIR%\materialsemantic-%MODE%.log"
for %%I in ("%LOG_PATH%") do set "LOG_PATH=%%~fI"

if "%BUILD_BEFORE_RUN%"=="1" call :run_build
if errorlevel 1 exit /b %ERRORLEVEL%

call :print_run_header
call :run_commandlet
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

if /I "%~1"=="--report" (
	if "%~2"=="" (
		1>&2 echo Missing value for --report.
		call :usage 1>&2
		exit /b 2
	)
	set "REPORT_PATH=%~2"
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

if /I "%~1"=="--preview-frame-interval-seconds" (
	if "%~2"=="" (
		1>&2 echo Missing value for --preview-frame-interval-seconds.
		call :usage 1>&2
		exit /b 2
	)
	set "PREVIEW_FRAME_INTERVAL_SECONDS=%~2"
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

if /I "%~1"=="--normalize" (
	call :set_mode normalize
	if errorlevel 1 exit /b 2
	shift
	goto parse_args
)

if /I "%~1"=="--import" (
	call :set_mode import
	if errorlevel 1 exit /b 2
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

1>&2 echo Mode flags are mutually exclusive: --validate, --normalize, and --import.
exit /b 2

:load_request_file
if not exist "%DEFAULT_REQUEST_PATH%" (
	1>&2 echo Request file not found: %DEFAULT_REQUEST_PATH%
	exit /b 2
)

for /f "usebackq tokens=1,* delims=|" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $data = Get-Content -Raw -LiteralPath $env:DEFAULT_REQUEST_PATH | ConvertFrom-Json } catch { exit 3 }; function Emit([string] $key, [object] $value) { if ($null -eq $value) { return }; $stringValue = [string] $value; if ([string]::IsNullOrWhiteSpace($stringValue)) { return }; [Console]::WriteLine($key + '|' + $stringValue) }; Emit 'project' $data.project; Emit 'engine' $data.engine; Emit 'input' $data.input; Emit 'report' $data.report; Emit 'preview_frame_interval_seconds' $data.preview_frame_interval_seconds; if ($data.build -eq $true) { [Console]::WriteLine('build|true') }; $mode = [string] $data.mode; if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'validate' }; $mode = $mode.ToLowerInvariant(); if ($mode -notin @('validate','normalize','import')) { [Console]::Error.WriteLine('Unsupported mode in request file: ' + $mode); exit 2 }; [Console]::WriteLine('mode|' + $mode)"`) do (
	if /I "%%I"=="project" set "PROJECT_FILE=%%J"
	if /I "%%I"=="engine" set "ENGINE_ROOT=%%J"
	if /I "%%I"=="input" set "INPUT_PATH=%%J"
	if /I "%%I"=="report" set "REPORT_PATH=%%J"
	if /I "%%I"=="preview_frame_interval_seconds" set "PREVIEW_FRAME_INTERVAL_SECONDS=%%J"
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

exit /b 0

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

:resolve_project_path
set "RESOLVE_INPUT=%~1"
set "RESOLVE_OUTPUT_VAR=%~2"
if not defined RESOLVE_INPUT (
	set "%RESOLVE_OUTPUT_VAR%="
	exit /b 0
)

for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$path = $env:RESOLVE_INPUT; $root = $env:PROJECT_ROOT; if ([System.IO.Path]::IsPathRooted($path)) { [System.IO.Path]::GetFullPath($path) } else { [System.IO.Path]::GetFullPath((Join-Path $root $path)) }"`) do set "%RESOLVE_OUTPUT_VAR%=%%I"
exit /b %ERRORLEVEL%

:resolve_engine_root
for /f "usebackq delims=" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$projectFile = $env:PROJECT_FILE; $projectDir = Split-Path -Parent $projectFile; $candidates = New-Object 'System.Collections.Generic.List[string]'; function AddCandidate([string]$path) { if ([string]::IsNullOrWhiteSpace($path)) { return }; try { $fullPath = [System.IO.Path]::GetFullPath($path) } catch { return }; if (-not [string]::IsNullOrWhiteSpace($fullPath)) { $script:candidates.Add($fullPath) } }; try { $projectData = Get-Content -Raw -LiteralPath $projectFile | ConvertFrom-Json } catch { exit 3 }; $association = [string]$projectData.EngineAssociation; if (-not [string]::IsNullOrWhiteSpace($association)) { AddCandidate $association; $buildsKey = 'HKCU:\Software\Epic Games\Unreal Engine\Builds'; if (Test-Path $buildsKey) { $builds = Get-ItemProperty -Path $buildsKey -ErrorAction SilentlyContinue; if ($null -ne $builds) { $value = $builds.PSObject.Properties[$association]; if ($null -ne $value) { AddCandidate ([string]$value.Value) } } }; foreach ($registryKey in @(('HKLM:\SOFTWARE\EpicGames\Unreal Engine\{0}' -f $association), ('HKLM:\SOFTWARE\WOW6432Node\EpicGames\Unreal Engine\{0}' -f $association), ('HKCU:\SOFTWARE\EpicGames\Unreal Engine\{0}' -f $association))) { if (Test-Path $registryKey) { AddCandidate ((Get-ItemProperty -Path $registryKey -Name InstalledDirectory -ErrorAction SilentlyContinue).InstalledDirectory) } }; $launcherInstalledPath = 'C:\ProgramData\Epic\UnrealEngineLauncher\LauncherInstalled.dat'; if (Test-Path $launcherInstalledPath) { try { $launcherData = Get-Content -Raw -LiteralPath $launcherInstalledPath | ConvertFrom-Json } catch { $launcherData = $null }; if ($null -ne $launcherData -and $null -ne $launcherData.InstallationList) { $expectedAppName = 'UE_{0}' -f $association; foreach ($entry in $launcherData.InstallationList) { $appName = [string]$entry.AppName; $artifactId = [string]$entry.ArtifactId; $namespaceId = [string]$entry.NamespaceId; $appVersion = [string]$entry.AppVersion; if ($namespaceId -eq 'ue' -and (($appName -eq $expectedAppName) -or ($artifactId -eq $expectedAppName) -or ((-not [string]::IsNullOrWhiteSpace($appVersion)) -and $appVersion.StartsWith($association + '.')))) { AddCandidate ([string]$entry.InstallLocation) } } } }; if ($association -match '^\d+(\.\d+)?$') { foreach ($baseDir in @('C:\Program Files\Epic Games', 'D:\Program Files\Epic Games', 'D:\Epic Games', 'D:\Games', 'E:\Program Files\Epic Games', 'E:\Epic Games', 'E:\Games')) { AddCandidate (Join-Path $baseDir ('UE_' + $association)) } } }; $resolved = $candidates | Select-Object -Unique | Where-Object { Test-Path (Join-Path $_ 'Engine\Build\BatchFiles\Build.bat') } | Select-Object -First 1; if ($resolved) { [Console]::Write($resolved); exit 0 }; AddCandidate $env:UE_ENGINE_ROOT; $resolved = $candidates | Select-Object -Unique | Where-Object { Test-Path (Join-Path $_ 'Engine\Build\BatchFiles\Build.bat') } | Select-Object -First 1; if ($resolved) { [Console]::Write($resolved); exit 0 }; $searchDir = $projectDir; while ($searchDir) { if (Test-Path (Join-Path $searchDir 'Engine\Build\BatchFiles\Build.bat')) { [Console]::Write($searchDir); exit 0 }; $parentDir = Split-Path -Parent $searchDir; if ($parentDir -eq $searchDir) { break }; $searchDir = $parentDir }; exit 5"`) do set "ENGINE_ROOT=%%I"
set "ENGINE_LOOKUP_STATUS=%ERRORLEVEL%"

if "%ENGINE_LOOKUP_STATUS%"=="0" exit /b 0

1>&2 echo Failed to resolve Unreal Engine root from project: %PROJECT_FILE%
1>&2 echo Pass --engine ^<path^> explicitly or set UE_ENGINE_ROOT.
exit /b 2

:run_build
echo Building %EDITOR_TARGET%...
call "%BUILD_SCRIPT%" "%EDITOR_TARGET%" Win64 Development "-Project=%PROJECT_FILE%" -WaitMutex -NoHotReloadFromIDE -NoUBA
exit /b %ERRORLEVEL%

:print_run_header
echo Project file: %PROJECT_FILE%
echo Engine root: %ENGINE_ROOT%
echo Input DSL: %INPUT_PATH%
echo Mode: %MODE%
echo Report file: %REPORT_PATH%
echo Log file: %LOG_PATH%
if defined PREVIEW_FRAME_INTERVAL_SECONDS echo Preview frame interval seconds: %PREVIEW_FRAME_INTERVAL_SECONDS%
exit /b 0

:run_commandlet
set "COMMANDLET_MODE=validate"
if /I "%MODE%"=="normalize" set "COMMANDLET_MODE=normalize"
if /I "%MODE%"=="import" set "COMMANDLET_MODE=import"
set "RHI_SWITCH=-NullRHI"
if /I "%COMMANDLET_MODE%"=="normalize" set "RHI_SWITCH=-AllowCommandletRendering"
set "PREVIEW_FRAME_INTERVAL_ARG="
if defined PREVIEW_FRAME_INTERVAL_SECONDS set "PREVIEW_FRAME_INTERVAL_ARG=-PreviewFrameIntervalSeconds=%PREVIEW_FRAME_INTERVAL_SECONDS%"

if exist "%REPORT_PATH%" del /q "%REPORT_PATH%" >nul 2>nul
if exist "%LOG_PATH%" del /q "%LOG_PATH%" >nul 2>nul

"%EDITOR_BINARY%" "%PROJECT_FILE%" -run=MaterialSemanticCommandlet "-Mode=%COMMANDLET_MODE%" "-Input=%INPUT_PATH%" "-InputRoot=%INPUT_ROOT%" "-Report=%REPORT_PATH%" -Format=json -Unattended -nop4 %RHI_SWITCH% %PREVIEW_FRAME_INTERVAL_ARG% -nosplash -NoEpicPortal -stdout -FullStdOutLogOutput "-abslog=%LOG_PATH%"
set "COMMANDLET_STATUS=%ERRORLEVEL%"

if not exist "%REPORT_PATH%" (
	1>&2 echo Expected commandlet report was not created: %REPORT_PATH%
	exit /b 2
)

type "%REPORT_PATH%"
exit /b %COMMANDLET_STATUS%

:usage
echo Usage:
echo   %~f0
echo   %~f0 --input ^<file.materialdsl^> [options]
echo.
echo No-argument mode:
echo   Reads request settings from Saved\MaterialSemanticBridge\MaterialDSLTemp\materialsemantic-request.json.
echo   This is the preferred mode for stable command invocation.
echo.
echo Options:
echo   --project ^<path^>      Required .uproject path
echo   --input ^<path^>        Absolute or project-relative .materialdsl input path
echo   --report ^<path^>       Optional commandlet report path; relative paths resolve under the project root
echo   --preview-frame-interval-seconds ^<seconds^>  Dynamic normalize preview frame spacing; request field: preview_frame_interval_seconds
echo   --validate              Validate only ^(default if no mode is passed^)
echo   --normalize             Normalize the input file in place
echo   --import                Import the input file into its mapped /Game target
echo   --build                 Build the project Editor target before running the selected mode
echo   --engine ^<path^>       Unreal Engine root path; defaults to project EngineAssociation, then UE_ENGINE_ROOT
echo   --help                  Show this help
echo.
echo Modes are mutually exclusive: --validate, --normalize, and --import.
echo Examples:
echo   %~f0
echo   %~f0 --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --validate
echo   %~f0 --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --normalize
echo   %~f0 --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --import
exit /b 0
