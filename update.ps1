# update.ps1
# Lädt app_updates.ps1 von GitHub, extrahiert winget-Befehle und führt sie als Admin aus.

# --- Einstellungen ---
$sourceUrl = "https://raw.githubusercontent.com/rschwend/winget/main/app_updates.ps1"

Write-Host "Lade app_updates.ps1 von GitHub..." -ForegroundColor Cyan

try {
    $content = Invoke-WebRequest -Uri $sourceUrl -UseBasicParsing
    $lines = $content.Content -split "`n"
} catch {
    Write-Host "Fehler beim Laden der Datei: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Winget-Befehle extrahieren
$wingetCmds = $lines | Where-Object { $_.TrimStart().ToLower().StartsWith("winget") }

if ($wingetCmds.Count -eq 0) {
    Write-Host "Keine Winget-Befehle gefunden." -ForegroundColor Yellow
    exit 1
}

Write-Host "Gefundene Winget-Befehle:" -ForegroundColor Green
$wingetCmds | ForEach-Object { Write-Host " → $_" }

# Prüfen ob Adminrechte vorhanden
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "Starte Skript neu mit Administratorrechten..." -ForegroundColor Yellow
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Führe Winget-Befehle mit Administratorrechten aus..." -ForegroundColor Cyan

foreach ($cmd in $wingetCmds) {
    Write-Host ">>> $cmd" -ForegroundColor Magenta
    try {
        iex $cmd
    } catch {
        Write-Host "Fehler bei: $cmd" -ForegroundColor Red
    }
}

Write-Host "Update beendet." -ForegroundColor Green
