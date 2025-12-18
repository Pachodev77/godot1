$ErrorActionPreference = 'Stop'
Get-Process | Where-Object { $_.ProcessName -like 'Godot*' } | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Process -FilePath 'C:\Users\DEV\Desktop\Godot_v3.1-stable_win64.exe' -ArgumentList '--path','C:\Users\DEV\Desktop\city demo'
Write-Host 'Godot restarted'
