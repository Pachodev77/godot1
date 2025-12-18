@echo off
setlocal
set GODOT_EXE=%USERPROFILE%\Desktop\Godot_v3.1-stable_win64.exe
set PROJ=C:\city_demo
set OUT=%PROJ%\builds
if not exist "%PROJ%" (
  mkdir "%PROJ%"
  robocopy "%USERPROFILE%\Desktop\city demo" "%PROJ%" /E /NFL /NDL /NJH /NJS /NC /NS >nul
)
if not exist "%OUT%" mkdir "%OUT%"
"%GODOT_EXE" --path "%PROJ%" --export-debug "Android" "%OUT%\city-demo-debug.apk" --quit
if exist "%OUT%\city-demo-debug.apk" (
  echo APK generado: %OUT%\city-demo-debug.apk
) else (
  echo Error: no se generó el APK.
  exit /b 1
)
endlocal
