@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo.
    echo  Su dung: extract_river.bat ^<dem.tif^> ^<output.shp^> [threshold]
    echo.
    echo  Tham so:
    echo    dem.tif     - File DEM dau vao
    echo    output.shp  - File shapefile dau ra
    echo    threshold   - Nguong tich luy dong chay ^(mac dinh: tu dong tinh^)
    echo                  Tang len = it song hon, giam = nhieu song hon
    echo.
    echo  Vi du:
    echo    extract_river.bat D:\data\dem.tif D:\data\river.shp
    echo    extract_river.bat D:\data\dem.tif D:\data\river.shp 500
    echo.
    exit /b 1
)

set "DEM=%~1"
set "OUTPUT=%~2"
set "THRESHOLD=%~3"

if "%OUTPUT%"=="" (
    echo [LOI] Thieu tham so output.shp
    exit /b 1
)

set "SCRIPT_DIR=%~dp0"
set "WBT=%SCRIPT_DIR%WhiteboxTools_win_amd64\WBT\whitebox_tools.exe"

if not exist "%WBT%" (
    echo [LOI] Khong tim thay whitebox_tools.exe tai: %WBT%
    exit /b 1
)

if not exist "%DEM%" (
    echo [LOI] Khong tim thay file DEM: %DEM%
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

echo [1/5] Convert DEM sang format tuong thich...
python "%SCRIPT_DIR%convert_tif.py" convert "%DEM%" "%CONVERTED%"
if errorlevel 1 (
    echo [LOI] Convert DEM that bai
    goto :cleanup_fail
)

echo [2/5] Lap ho trung (Fill Depressions)...
"%WBT%" -r=FillDepressions -i="%CONVERTED%" -o="%FILLED%" --fix_flats 2>nul
if errorlevel 1 (
    echo [LOI] Fill Depressions that bai
    goto :cleanup_fail
)

echo [3/5] Tinh huong chay (D8 Flow Direction)...
"%WBT%" -r=D8Pointer -i="%FILLED%" -o="%FLOWDIR%" 2>nul
if errorlevel 1 (
    echo [LOI] D8 Flow Direction that bai
    goto :cleanup_fail
)

echo [4/5] Tinh tich luy dong chay (D8 Flow Accumulation)...
"%WBT%" -r=D8FlowAccumulation -i="%FLOWDIR%" -o="%ACCUM%" --pntr --out_type=cells 2>nul
if errorlevel 1 (
    echo [LOI] D8 Flow Accumulation that bai
    goto :cleanup_fail
)

if "%THRESHOLD%"=="" (
    echo        Tinh threshold tu dong...
    for /f "tokens=1,2" %%a in ('python "%SCRIPT_DIR%convert_tif.py" auto_threshold "%ACCUM%"') do (
        set "THRESHOLD=%%a"
        set "MAX_ACCUM=%%b"
    )
    echo        Max accumulation: !MAX_ACCUM!, threshold tu dong: !THRESHOLD!
)

echo [5/5] Trich xuat song (threshold=!THRESHOLD!) va tao shapefile...
"%WBT%" -r=ExtractStreams --flow_accum="%ACCUM%" -o="%STREAMS%" --threshold=!THRESHOLD! 2>nul
if errorlevel 1 (
    echo [LOI] Extract Streams that bai
    goto :cleanup_fail
)

"%WBT%" -r=RasterStreamsToVector --streams="%STREAMS%" --d8_pntr="%FLOWDIR%" -o="%OUTPUT%" 2>nul
if errorlevel 1 (
    echo [LOI] Vector hoa that bai - co the threshold qua cao, thu giam xuong
    goto :cleanup_fail
)

echo.
echo ============================================================
echo  HOAN THANH!
echo  File shapefile: %OUTPUT%
echo ============================================================

:cleanup
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
endlocal
exit /b 0

:cleanup_fail
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%" 2>nul
endlocal
exit /b 1
