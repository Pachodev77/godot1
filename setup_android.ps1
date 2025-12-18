Param()

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls

function Write-Info($msg) { Write-Host "[INFO] $msg" -ForegroundColor Cyan }
function Write-Ok($msg) { Write-Host "[OK]   $msg" -ForegroundColor Green }
function Write-Warn($msg) { Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err($msg) { Write-Host "[ERR]  $msg" -ForegroundColor Red }

function Ensure-Dir($path) {
  if (-not (Test-Path -LiteralPath $path)) { New-Item -ItemType Directory -Force -Path $path | Out-Null }
}

# Temp directory setup early
$sdkRoot = 'C:\Android'
$tmpBase = $env:TEMP
if (-not $tmpBase) { $tmpBase = Join-Path $sdkRoot 'tmp' }
Ensure-Dir $tmpBase
$tmpDir = Join-Path $tmpBase ('android_setup_' + [guid]::NewGuid().ToString())
Ensure-Dir $tmpDir

# Root paths
$cmdToolsLatest = Join-Path $sdkRoot 'cmdline-tools\latest'
$platformTools = Join-Path $sdkRoot 'platform-tools'
$buildToolsVer = '28.0.3'
$buildToolsPath = Join-Path $sdkRoot ("build-tools\$buildToolsVer")
$ndkRoot = Join-Path $sdkRoot 'ndk\r19c'

Ensure-Dir $sdkRoot
Ensure-Dir (Split-Path $cmdToolsLatest -Parent)
Ensure-Dir $cmdToolsLatest

# 1) Install JDK 8 via winget if available
$jdkInstalled = $false
$jdkHome = $null
Write-Info 'Checking for winget to install JDK 8...'
if (Get-Command winget -ErrorAction SilentlyContinue) {
  try {
    Write-Info 'Installing Eclipse Temurin JDK 8 via winget (if not installed)...'
    winget install --id EclipseAdoptium.Temurin.8.JDK -e --source winget --accept-package-agreements --accept-source-agreements | Out-Null
  } catch { Write-Warn 'winget install failed or JDK 8 already installed.' }
}

Write-Info 'Locating JDK 8 installation...'
$possibleJdkDirs = @(
  'C:\Program Files\Eclipse Adoptium',
  'C:\Program Files\Java',
  'C:\Program Files (x86)\Java'
)
foreach ($dir in $possibleJdkDirs) {
  if (Test-Path $dir) {
    $candidate = Get-ChildItem -Directory -Path $dir -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'jdk.*8' -or $_.Name -match 'jdk1\.8' } | Select-Object -First 1
    if ($candidate) { $jdkHome = $candidate.FullName; break }
  }
}
if ($jdkHome) { $jdkInstalled = $true; Write-Ok "Found JDK at $jdkHome" } else { Write-Warn 'JDK 8 not found. SDK Manager may fail; proceed with SDK setup.' }

if ($jdkInstalled) { setx JAVA_HOME $jdkHome | Out-Null }

# Fallback: Download Temurin JDK 8 via Adoptium API if not found
if (-not $jdkInstalled) {
  Write-Info 'Downloading Temurin JDK 8 (Adoptium API)...'
  $jdkZipUrl = 'https://api.adoptium.net/v3/binary/latest/8/ga/windows/x64/jdk/hotspot/normal/adoptium'
  $jdkZip = Join-Path $tmpDir 'temurin8.zip'
  Invoke-WebRequest -Uri $jdkZipUrl -OutFile $jdkZip
  $jdkExtractDir = Join-Path $tmpDir 'jdk8'
  Ensure-Dir $jdkExtractDir
  Expand-Archive -LiteralPath $jdkZip -DestinationPath $jdkExtractDir -Force
  $extractedJdkDir = Get-ChildItem -Directory -Path $jdkExtractDir | Select-Object -First 1
  if ($extractedJdkDir) {
    $jdkHome = $extractedJdkDir.FullName
    setx JAVA_HOME $jdkHome | Out-Null
    $jdkInstalled = $true
    Write-Ok "Installed JDK to $jdkHome"
  } else {
    Write-Warn 'Failed to extract JDK 8; proceeding without JAVA_HOME.'
  }
}

# 2) Download Android Command-line Tools (latest) by scraping official page for the versioned zip
Write-Info 'Fetching Android command-line tools URL from developer.android.com...'
$studioUrl = 'https://developer.android.com/studio'
$html = Invoke-WebRequest -Uri $studioUrl -UseBasicParsing
$match = [regex]::Match($html.Content, 'https://dl\.google\.com/android/repository/commandlinetools-win-\d+_latest\.zip')
if (-not $match.Success) { throw 'Could not find commandlinetools-win zip URL on developer.android.com/studio' }
$cmdZipUrl = $match.Value
Write-Ok "Command-line tools URL: $cmdZipUrl"

$cmdZip = Join-Path $tmpDir 'cmdtools.zip'
Write-Info 'Downloading command-line tools...'
Invoke-WebRequest -Uri $cmdZipUrl -OutFile $cmdZip

Write-Info 'Extracting command-line tools...'
Expand-Archive -LiteralPath $cmdZip -DestinationPath $tmpDir -Force
if (Test-Path (Join-Path $cmdToolsLatest 'bin')) { Remove-Item -Recurse -Force $cmdToolsLatest }
Ensure-Dir $cmdToolsLatest
# Move extracted cmdline-tools into .../latest
$extractedCmd = Join-Path $tmpDir 'cmdline-tools'
if (-not (Test-Path $extractedCmd)) { throw 'Extraction did not produce cmdline-tools folder' }
Copy-Item -Recurse -Force $extractedCmd\* $cmdToolsLatest
Write-Ok "Installed command-line tools to $cmdToolsLatest"

# 3) Set ANDROID_SDK_ROOT and PATH
setx ANDROID_SDK_ROOT $sdkRoot | Out-Null
$pathsToAdd = @(
  (Join-Path $cmdToolsLatest 'bin'),
  $platformTools,
  $buildToolsPath,
  (Join-Path $jdkHome 'bin')
) | Where-Object { $_ -and (Test-Path $_) }
foreach ($p in $pathsToAdd) { setx PATH ("$env:PATH;$p") | Out-Null }
Write-Ok 'Environment variables set (JAVA_HOME, ANDROID_SDK_ROOT, PATH)'

# 4) Install SDK components
$sdkmanager = Join-Path $cmdToolsLatest 'bin\sdkmanager.bat'
if (-not (Test-Path $sdkmanager)) { throw 'sdkmanager not found under cmdline-tools latest bin' }

Write-Info 'Installing Android SDK components (platform-tools, platforms;android-28, build-tools;28.0.3)...'
& $sdkmanager --sdk_root=$sdkRoot 'platform-tools' 'platforms;android-28' "build-tools;$buildToolsVer" | Write-Host
Write-Info 'Accepting SDK licenses...'
cmd /c "echo y | `"$sdkmanager`" --sdk_root=$sdkRoot --licenses" | Write-Host

# 5) Download NDK r19c (optional, needed for Custom Build)
Write-Info 'Downloading Android NDK r19c (Windows x86_64)...'
$ndkZipUrl = 'https://dl.google.com/android/repository/android-ndk-r19c-windows-x86_64.zip'
$ndkZip = Join-Path $tmpDir 'ndk-r19c.zip'
Invoke-WebRequest -Uri $ndkZipUrl -OutFile $ndkZip
Ensure-Dir $ndkRoot
Write-Info 'Extracting NDK r19c... this may take a while.'
Expand-Archive -LiteralPath $ndkZip -DestinationPath (Split-Path $ndkRoot -Parent) -Force
# The zip extracts as android-ndk-r19c; rename to ndk\r19c
$extractedNdk = Join-Path (Split-Path $ndkRoot -Parent) 'android-ndk-r19c'
if (Test-Path $extractedNdk) {
  if (Test-Path $ndkRoot) { Remove-Item -Recurse -Force $ndkRoot }
  Rename-Item -Path $extractedNdk -NewName 'r19c'
}
setx ANDROID_NDK_ROOT $ndkRoot | Out-Null
Write-Ok "Installed NDK to $ndkRoot"

# 6) Install Godot 3.1 export templates
Write-Info 'Installing Godot 3.1 export templates...'
$tpzUrl = 'https://downloads.tuxfamily.org/godotengine/3.1/Godot_v3.1-stable_export_templates.tpz'
$tpzPath = Join-Path $tmpDir 'Godot_v3.1-stable_export_templates.tpz'
Invoke-WebRequest -Uri $tpzUrl -OutFile $tpzPath
$templatesDir = Join-Path $env:APPDATA 'Godot\templates\3.1.stable'
Ensure-Dir $templatesDir
Expand-Archive -LiteralPath $tpzPath -DestinationPath $templatesDir -Force
Write-Ok "Installed export templates to $templatesDir"

# 7) Verify
Write-Info 'Verifying installations...'
try { & adb --version | Write-Host } catch { Write-Warn 'ADB not in PATH yet; restart PowerShell or sign out/in.' }
try { & (Join-Path $buildToolsPath 'zipalign.exe') -h | Out-Null; Write-Ok 'zipalign OK' } catch { Write-Warn 'zipalign not found' }
try { & (Join-Path $buildToolsPath 'apksigner.bat') -h | Out-Null; Write-Ok 'apksigner OK' } catch { Write-Warn 'apksigner not found' }
if ($jdkInstalled) { try { & (Join-Path $jdkHome 'bin\java.exe') -version | Write-Host } catch { Write-Warn 'JAVA not in PATH yet' } }

Write-Ok 'Android export setup completed.'
Write-Info 'If tools are not recognized, restart PowerShell or Windows session to refresh PATH.'

# 8) Configure Godot Editor Settings automatically
Write-Info 'Configuring Godot Editor Settings for Android export...'
$editorSettings = Join-Path $env:APPDATA 'Godot\editor_settings.tres'
$editorSettings3 = Join-Path $env:APPDATA 'Godot\editor_settings-3.tres'
Ensure-Dir (Split-Path $editorSettings -Parent)

function Set-EditorSettingValue([string]$content, [string]$key, [string]$value) {
  $escaped = [regex]::Escape($key)
  $pattern = "^$escaped\s*=\s*.*$"
  $replacement = "$key = `"$value`""
  $lines = $content -split "`r?`n"
  $found = $false
  for ($i = 0; $i -lt $lines.Length; $i++) {
    if ($lines[$i] -match $pattern) { $lines[$i] = $replacement; $found = $true; break }
  }
  if (-not $found) { $lines += $replacement }
  return ($lines -join "`r`n")
}

if (-not (Test-Path $editorSettings)) {
  Write-Warn "Editor settings file not found. Creating a new one at $editorSettings"
  @"
[gd_resource type="EditorSettings" format=2]

[resource]
"@ | Set-Content -LiteralPath $editorSettings -Encoding UTF8
}

if (-not (Test-Path $editorSettings3)) {
  Write-Warn "Editor settings file not found. Creating a new one at $editorSettings3"
  @"
[gd_resource type="EditorSettings" format=2]

[resource]
"@ | Set-Content -LiteralPath $editorSettings3 -Encoding UTF8
}

$content = Get-Content -LiteralPath $editorSettings -Raw -ErrorAction SilentlyContinue
$content3 = Get-Content -LiteralPath $editorSettings3 -Raw -ErrorAction SilentlyContinue
if (-not $content) {
  $content = @"
[gd_resource type="EditorSettings" format=2]

[resource]
"@
}

if (-not $content3) {
  $content3 = @"
[gd_resource type="EditorSettings" format=2]

[resource]
"@
}

$pairs = @{
  'export/android/adb'       = (Join-Path $platformTools 'adb.exe');
  'export/android/sdk_path'  = $sdkRoot;
  'export/android/zipalign'  = (Join-Path $buildToolsPath 'zipalign.exe');
  'export/android/apksigner' = (Join-Path $buildToolsPath 'apksigner.bat');
  'export/android/ndk_path'  = $ndkRoot
}

if ($jdkInstalled) {
  $pairs['export/android/jarsigner'] = (Join-Path $jdkHome 'bin\jarsigner.exe')
}

foreach ($k in $pairs.Keys) { $content = Set-EditorSettingValue $content $pairs[$k]; $content3 = Set-EditorSettingValue $content3 $pairs[$k] }
Set-Content -LiteralPath $editorSettings -Value $content -Encoding UTF8
Set-Content -LiteralPath $editorSettings3 -Value $content3 -Encoding UTF8
Write-Ok "Updated $editorSettings and $editorSettings3 with Android export settings"
