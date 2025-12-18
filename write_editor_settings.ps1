$ErrorActionPreference = 'Stop'
$appdata = $env:APPDATA
$dir = Join-Path $appdata 'Godot'
if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }

$adb = 'C:\Android\platform-tools\adb.exe'
$sdk = 'C:\Android'
$zipalign = 'C:\Android\build-tools\28.0.3\zipalign.exe'
$apksigner = 'C:\Android\build-tools\28.0.3\apksigner.bat'
$ndk = 'C:\Android\ndk\r19c'
$jarsigner = 'C:\Program Files\Android\Android Studio\jbr\bin\jarsigner.exe'
$dks = 'C:\Android\debug.keystore'

$content = @"
[gd_resource type="EditorSettings" format=2]

[resource]
export/android/adb = "$adb"
export/android/sdk_path = "$sdk"
export/android/zipalign = "$zipalign"
export/android/apksigner = "$apksigner"
export/android/ndk_path = "$ndk"
export/android/jarsigner = "$jarsigner"
export/android/debug_keystore = "$dks"
export/android/debug_keystore_user = "androiddebugkey"
export/android/debug_keystore_pass = "android"
"@

$files = @(
  (Join-Path $dir 'editor_settings.tres'),
  (Join-Path $dir 'editor_settings-3.tres')
)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
foreach ($f in $files) { [System.IO.File]::WriteAllText($f, $content, $utf8NoBom) }
Write-Host "Updated: $($files -join ', ')"
