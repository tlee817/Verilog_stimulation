@echo off
REM Simple script to run the FPCVT simulation on Windows

REM Change directory to the "sim" folder relative to this script
pushd "%~dp0sim"

echo Compiling Verilog...
iverilog -o FPCVT_sim.exe ..\src\FPCVT.v FPCVT_tb.v

REM Check if the previous command (compilation) succeeded
if %errorlevel% equ 0 (
    echo.
    echo Running simulation...
    echo ================================
    vvp FPCVT_sim
    echo ================================
) else (
    echo Compilation failed!
    exit /b 1
)

REM Return to the original directory
popd