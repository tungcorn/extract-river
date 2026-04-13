@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo  Usage: extract_river.bat ^<dem.tif^> ^<output.shp^> [threshold]
    echo.
    echo  Parameters:
    echo    dem.tif     - Input DEM raster file
    echo    output.shp  - Output shapefile path
    echo    threshold   - Flow accumulation threshold ^(default: auto^)
    echo                  Higher = fewer streams, lower = more streams
    echo.
    echo  Examples:
    echo    extract_river.bat D:\data\dem.tif D:\data\river.shp
    echo    extract_river.bat D:\data\dem.tif D:\data\river.shp 500
    echo.
    exit /b 1
)

set "DEM=%~1"
set "OUTPUT=%~2"
set "THRESHOLD=%~3"

if "%OUTPUT%"=="" (
    echo [ERROR] Missing output.shp parameter
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"

:: --- Read config.txt ---
set "WBT="
if exist "%SCRIPT_DIR%config.txt" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%SCRIPT_DIR%config.txt") do (
        if /i "%%a"=="WHITEBOX_TOOLS" if not "%%b"=="" set "WBT=%%b"
        if /i "%%a"=="DEFAULT_THRESHOLD" if "%THRESHOLD%"=="" if not "%%b"=="" set "THRESHOLD=%%b"
    )
)

:: Fallback to default path
if "!WBT!"=="" set "WBT=%SCRIPT_DIR%WhiteboxTools_win_amd64\WBT\whitebox_tools.exe"

if not exist "!WBT!" (
    echo [ERROR] whitebox_tools.exe not found at: !WBT!
    echo         Set WHITEBOX_TOOLS in config.txt or download from:
    echo         https://www.whiteboxgeo.com/download-whiteboxtools/
    exit /b 1
)

if not exist "%DEM%" (
    echo [ERROR] DEM file not found: %DEM%
    exit /b 1
)

set "TEMP_DIR=%~dp2_extract_river_temp"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

set "CONVERTED=%TEMP_DIR%\converted.tif"
set "FILLED=%TEMP_DIR%\filled.tif"
set "FLOWDIR=%TEMP_DIR%\d8_pointer.tif"
set "ACCUM=%TEMP_DIR%\d8_accum.tif"
set "STREAMS=%TEMP_DIR%\streams.tif"

echo.
echo ============================================================
echo  Extract River from DEM
echo  Input:  %DEM%
echo  Output: %OUTPUT%
echo ============================================================
echo.

echo [1/5] Converting DEM to compatible format...
python "%SCRIPT_DIR%convert_tif.py" convert "%DEM%" "%CONVERTED%"
if errorlevel 1 (
    echo [ERROR] DEM conversion failed
    goto :cleanup_fail
)

echo [2/5] Filling depressions...
"%WBT%" -r=FillDepressions -i="%CONVERTED%" -o="%FILLED%" --fix_flats 2>nul
if errorlevel 1 (
    echo [ERROR] Fill Depressions failed
    goto :cleanup_fail
)

echo [3/5] Computing flow direction (D8)...
"%WBT%" -r=D8Pointer -i="%FILLED%" -o="%FLOWDIR%" 2>nul
if errorlevel 1 (
    echo [ERROR] D8 Flow Direction failed
    goto :cleanup_fail
)

echo [4/5] Computing flow accumulation...
"%WBT%" -r=D8FlowAccumulation -i="%FLOWDIR%" -o="%ACCUM%" --pntr --out_type=cells 2>nul
if errorlevel 1 (
    echo [ERROR] D8 Flow Accumulation failed
    goto :cleanup_fail
)

if "%THRESHOLD%"=="" (
    echo        Computing auto threshold...
    for /f "tokens=1,2" %%a in ('python "%SCRIPT_DIR%convert_tif.py" auto_threshold "%ACCUM%"') do (
        set "THRESHOLD=%%a"
        set "MAX_ACCUM=%%b"
    )
    echo        Max accumulation: !MAX_ACCUM!, auto threshold: !THRESHOLD!
)

echo [5/5] Extracting streams (threshold=!THRESHOLD!) and vectorizing...
"%WBT%" -r=ExtractStreams --flow_accum="%ACCUM%" -o="%STREAMS%" --threshold=!THRESHOLD! 2>nul
if errorlevel 1 (
    echo [ERROR] Stream extraction failed
    goto :cleanup_fail
)

"%WBT%" -r=RasterStreamsToVector --streams="%STREAMS%" --d8_pntr="%FLOWDIR%" -o="%OUTPUT%" 2>nul
if errorlevel 1 (
    echo [ERROR] Vectorization failed - threshold may be too high, try a lower value
    goto :cleanup_fail
)

echo        Writing .prj and .cpg...
python "%SCRIPT_DIR%convert_tif.py" write_prj "%DEM%" "%OUTPUT%"

echo.
echo ============================================================
echo  DONE!
echo  Shapefile: %OUTPUT%
echo ============================================================

:cleanup
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
endlocal
exit /b 0

:cleanup_fail
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
endlocal
exit /b 1
