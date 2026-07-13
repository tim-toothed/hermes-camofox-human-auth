param(
  [string]$CamofoxRef = 'ce3a3b0',
  [ValidateSet('x86_64','aarch64')][string]$Arch = 'x86_64',
  [switch]$SkipHermesConfig
)
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker is required.' }
if (-not (Get-Command git -ErrorAction SilentlyContinue)) { throw 'Git is required.' }
if (-not (Test-Path .env)) { Copy-Item .env.example .env; throw 'Created .env. Set VNC_PASSWORD, then rerun install.ps1.' }
$Vendor = Join-Path $Root 'vendor/camofox-browser'
if (-not (Test-Path (Join-Path $Vendor '.git'))) {
  New-Item -ItemType Directory -Force (Split-Path $Vendor) | Out-Null
  git clone --depth 1 --branch master https://github.com/jo-inc/camofox-browser.git $Vendor
}
Push-Location $Vendor
try {
  git fetch --depth 1 origin master
  git checkout --detach origin/master
  if ((git rev-parse HEAD).Trim() -ne 'ce3a3b085aacba73eb8de6c51733c19fb13bfae4') { throw 'Unexpected upstream Camofox revision.' }
  git reset --hard HEAD
} finally { Pop-Location }
Get-ChildItem (Join-Path $Root 'patches/*.patch') | Sort-Object Name | ForEach-Object {
  Push-Location $Vendor
  try { git apply --check --ignore-space-change --ignore-whitespace $_.FullName; git apply --ignore-space-change --ignore-whitespace $_.FullName } finally { Pop-Location }
}
$Watcher = Join-Path $Vendor 'plugins/vnc/vnc-watcher.sh'
$WatcherText = [System.IO.File]::ReadAllText($Watcher).Replace([char]13, '')
[System.IO.File]::WriteAllText($Watcher, $WatcherText, (New-Object System.Text.UTF8Encoding($false)))
$Dist = Join-Path $Vendor 'dist'
New-Item -ItemType Directory -Force $Dist | Out-Null
$CamoufoxUrl = "https://github.com/daijiro/camoufox/releases/download/v135.0.1-beta.24/camoufox-135.0.1-beta.24-lin.$Arch.zip"
$YtdlpSuffix = if ($Arch -eq 'aarch64') { '_aarch64' } else { '' }
$YtdlpUrl = "https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux$YtdlpSuffix"
$CamoufoxOut = Join-Path $Dist "camoufox-$Arch.zip"
$YtdlpOut = Join-Path $Dist "yt-dlp-$Arch"
if (-not (Test-Path $CamoufoxOut)) { Invoke-WebRequest -UseBasicParsing -Uri $CamoufoxUrl -OutFile $CamoufoxOut }
if (-not (Test-Path $YtdlpOut)) { Invoke-WebRequest -UseBasicParsing -Uri $YtdlpUrl -OutFile $YtdlpOut }
docker compose up -d --build
if (-not $SkipHermesConfig) {
  $envPath = (& hermes config env-path).Trim()
  $envDir = Split-Path -Parent $envPath
  New-Item -ItemType Directory -Force $envDir | Out-Null
  $lines = if (Test-Path $envPath) { Get-Content $envPath } else { @() }
  $set = @{
    CAMOFOX_URL='http://127.0.0.1:9378'
    CAMOFOX_USER_ID='hermes'
    CAMOFOX_SESSION_KEY='visible-auth'
    CAMOFOX_ADOPT_EXISTING_TAB='true'
  }
  foreach ($key in $set.Keys) {
    $lines = @($lines | Where-Object { $_ -notmatch "^$key=" })
    $lines += "$key=$($set[$key])"
  }
  Set-Content -Path $envPath -Value $lines -Encoding utf8
  Write-Host "Hermes env configured at $envPath. Restart Hermes to load it."
}
& (Join-Path $PSScriptRoot 'status.ps1')
