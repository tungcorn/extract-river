@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo  Usage: extract_river.bat ^<dem.tif^> ^<output.shp^> [threshold]
    echo.
    echo  Parameters:
    echo    dem.tif     - Input DEM raster file
    echo    output.shp  - Output shapefile path
    echo    threshold   - Min watershed basin size in cells ^(default: 100^)
    echo                  Higher = fewer streams, lower = more streams
    echo.
    echo  Examples:
    echo    extract_river.bat D:\data\dem.tif D:\data\river.shp
    echo    extract_river.bat D:\data\dem.tif D:\data\river.shp 500
    echo.
    echo  Requires: QGIS installed ^(uses qgis_process + GRASS r.watershed^)
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
set "QP="
if exist "%SCRIPT_DIR%config.txt" (
    for /f "usebackq tokens=1,* delims==" %%a in ("%SCRIPT_DIR%config.txt") do (
        if /i "%%a"=="QGIS_PROCESS" if not "%%b"=="" set "QP=%%b"
        if /i "%%a"=="DEFAULT_THRESHOLD" if "%THRESHOLD%"=="" if not "%%b"=="" set "THRESHOLD=%%b"
    )
)

if "%THRESHOLD%"=="" set "THRESHOLD=100"

:: --- Validate or auto-detect qgis_process ---
if not "!QP!"=="" (
    if not exist "!QP!" (
        echo [WARN] qgis_process from config.txt not found: !QP!
        echo        Trying auto-detect...
        set "QP="
    )
)

if "!QP!"=="" (
    for /f "delims=" %%i in ('dir /b /ad "D:\QGIS*" 2^>nul') do (
        if exist "D:\%%i\bin\qgis_process-qgis-ltr.bat" set "QP=D:\%%i\bin\qgis_process-qgis-ltr.bat"
        if "!QP!"=="" if exist "D:\%%i\bin\qgis_process-qgis.bat" set "QP=D:\%%i\bin\qgis_process-qgis.bat"
    )
)
if "!QP!"=="" (
    for /f "delims=" %%i in ('dir /b /ad "C:\Program Files\QGIS*" 2^>nul') do (
        if exist "C:\Program Files\%%i\bin\qgis_process-qgis-ltr.bat" set "QP=C:\Program Files\%%i\bin\qgis_process-qgis-ltr.bat"
        if "!QP!"=="" if exist "C:\Program Files\%%i\bin\qgis_process-qgis.bat" set "QP=C:\Program Files\%%i\bin\qgis_process-qgis.bat"
    )
)

if "!QP!"=="" (
    echo [ERROR] qgis_process not found.
    echo        Set QGIS_PROCESS in config.txt or install QGIS: winget install OSGeo.QGIS_LTR
    exit /b 1
)

if not exist "%DEM%" (
    echo [ERROR] DEM file not found: %DEM%
    exit /b 1
)

:: Create output directory if needed
for %%f in ("%OUTPUT%") do (
    if not exist "%%~dpf" mkdir "%%~dpf"
)

set "TEMP_DIR=%~dp2_extract_river_temp"
if not exist "%TEMP_DIR%" mkdir "%TEMP_DIR%"

echo.
echo ============================================================
echo  Extract River from DEM  ^(QGIS/GRASS r.watershed^)
echo  Input:     %DEM%
echo  Output:    %OUTPUT%
echo  Threshold: %THRESHOLD%
echo ============================================================
echo.

echo [1/2] Running GRASS r.watershed (threshold=%THRESHOLD%)...
call "!QP!" run grass:r.watershed -- "elevation=%DEM%" "threshold=%THRESHOLD%" "stream=%TEMP_DIR%\stream.tif" >nul 2>&1
if not exist "%TEMP_DIR%\stream.tif" (
    echo [ERROR] r.watershed failed - no stream raster produced
    echo        Re-running with verbose output:
    call "!QP!" run grass:r.watershed -- "elevation=%DEM%" "threshold=%THRESHOLD%" "stream=%TEMP_DIR%\stream.tif"
    goto :cleanup_fail
)
echo        Done.

echo [2/2] Vectorizing streams to shapefile...
call "!QP!" run grass:r.to.vect -- "input=%TEMP_DIR%\stream.tif" "type=0" "column=value" "-s=1" "output=%OUTPUT%" >nul 2>&1
if not exist "%OUTPUT%" (
    echo [ERROR] Vectorization failed - no shapefile produced
    echo        Re-running with verbose output:
    call "!QP!" run grass:r.to.vect -- "input=%TEMP_DIR%\stream.tif" "type=0" "column=value" "-s=1" "output=%OUTPUT%"
    goto :cleanup_fail
)
echo        Done.

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
