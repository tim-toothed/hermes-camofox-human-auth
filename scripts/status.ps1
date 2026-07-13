$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
Write-Host '--- Docker ---'
docker compose ps
Write-Host '--- Camofox health ---'
try { Invoke-RestMethod http://127.0.0.1:9378/health | ConvertTo-Json -Compress } catch { Write-Host 'Camofox unavailable' }
Write-Host '--- noVNC ---'
try { $r = Invoke-WebRequest http://127.0.0.1:6089/vnc.html -UseBasicParsing; Write-Host $r.StatusCode } catch { Write-Host 'noVNC unavailable' }
