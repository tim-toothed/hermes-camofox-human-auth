$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
if (-not (Test-Path .env)) { throw 'Missing .env. Copy .env.example to .env and set VNC_PASSWORD.' }
docker compose up -d --build
