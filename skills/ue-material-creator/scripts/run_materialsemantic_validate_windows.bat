@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..\..\..\..") do set "REPO_ROOT=%%~fI"
set "DEFAULT_REQUEST_PATH=%REPO_ROOT%\Saved\MaterialDSLTemp\materialsemantic-request.json"

set "PROJECT_FILE="
set "ENGINE_ROOT="

set "INPUT_PATH="
set "REPORT_PATH="
set "LOG_PATH="
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
	1>&2 echo Missing required --engine argument or request field.
	call :usage 1>&2
	exit /b 2
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

for %%I in ("%INPUT_PATH%") do set "INPUT_PATH=%%~fI"
if not exist "%INPUT_PATH%" (
	1>&2 echo Input DSL file not found: %INPUT_PATH%
	exit /b 2
)

set "INPUT_ROOT=%PROJECT_ROOT%\.ue_dsl\MaterialDSL"
for %%I in ("%INPUT_ROOT%") do set "INPUT_ROOT=%%~fI"

set "TEMP_OUTPUT_DIR=%PROJECT_ROOT%\Saved\MaterialDSLTemp"
if not exist "%TEMP_OUTPUT_DIR%" mkdir "%TEMP_OUTPUT_DIR%"
if not defined REPORT_PATH set "REPORT_PATH=%TEMP_OUTPUT_DIR%\materialsemantic-%MODE%.json"
for %%I in ("%REPORT_PATH%") do set "REPORT_PATH=%%~fI"
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

for /f "usebackq tokens=1,* delims=|" %%I in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $data = Get-Content -Raw -LiteralPath $env:DEFAULT_REQUEST_PATH | ConvertFrom-Json } catch { exit 3 }; function Emit([string] $key, [object] $value) { if ($null -eq $value) { return }; $stringValue = [string] $value; if ([string]::IsNullOrWhiteSpace($stringValue)) { return }; [Console]::WriteLine($key + '|' + $stringValue) }; Emit 'project' $data.project; Emit 'engine' $data.engine; Emit 'input' $data.input; Emit 'report' $data.report; if ($data.build -eq $true) { [Console]::WriteLine('build|true') }; $mode = [string] $data.mode; if ([string]::IsNullOrWhiteSpace($mode)) { $mode = 'validate' }; $mode = $mode.ToLowerInvariant(); if ($mode -notin @('validate','normalize','import')) { [Console]::Error.WriteLine('Unsupported mode in request file: ' + $mode); exit 2 }; [Console]::WriteLine('mode|' + $mode)"`) do (
	if /I "%%I"=="project" set "PROJECT_FILE=%%J"
	if /I "%%I"=="engine" set "ENGINE_ROOT=%%J"
	if /I "%%I"=="input" set "INPUT_PATH=%%J"
	if /I "%%I"=="report" set "REPORT_PATH=%%J"
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
exit /b 0

:run_commandlet
set "COMMANDLET_MODE=validate"
if /I "%MODE%"=="normalize" set "COMMANDLET_MODE=normalize"
if /I "%MODE%"=="import" set "COMMANDLET_MODE=import"

if exist "%REPORT_PATH%" del /q "%REPORT_PATH%" >nul 2>nul
if exist "%LOG_PATH%" del /q "%LOG_PATH%" >nul 2>nul

"%EDITOR_BINARY%" "%PROJECT_FILE%" -run=MaterialSemanticCommandlet "-Mode=%COMMANDLET_MODE%" "-Input=%INPUT_PATH%" "-InputRoot=%INPUT_ROOT%" "-Report=%REPORT_PATH%" -Format=json -Unattended -nop4 -NullRHI -nosplash -NoEpicPortal -stdout -FullStdOutLogOutput "-abslog=%LOG_PATH%"
set "COMMANDLET_STATUS=%ERRORLEVEL%"

if not exist "%REPORT_PATH%" (
	1>&2 echo Expected commandlet report was not created: %REPORT_PATH%
	exit /b 2
)

type "%REPORT_PATH%"
exit /b %COMMANDLET_STATUS%

:usage
echo Usage:
echo   .agents\skills\ue-material-creator\scripts\run_materialsemantic_validate_windows.bat
echo   .agents\skills\ue-material-creator\scripts\run_materialsemantic_validate_windows.bat --input ^<file.materialdsl^> [options]
echo.
echo No-argument mode:
echo   Reads request settings from Saved\MaterialDSLTemp\materialsemantic-request.json.
echo   This is the preferred mode for fixed-command approval reuse.
echo.
echo Options:
echo   --project ^<path^>      Required .uproject path
echo   --input ^<path^>        Absolute or relative .materialdsl input path
echo   --report ^<path^>       Optional commandlet report path
echo   --validate              Validate only ^(default if no mode is passed^)
echo   --normalize             Normalize the input file in place
echo   --import                Import the input file into its mapped /Game target
echo   --build                 Build the project Editor target before running the selected mode
echo   --engine ^<path^>       Required Unreal Engine root path
echo   --help                  Show this help
echo.
echo Modes are mutually exclusive: --validate, --normalize, and --import.
echo Examples:
echo   %~f0
echo   %~f0 --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --validate
echo   %~f0 --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --normalize
echo   %~f0 --input .ue_dsl\MaterialDSL\Materials\M_Test.materialdsl --import
exit /b 0
