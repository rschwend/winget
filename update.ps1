# update.ps1
# Lädt app_updates.ps1 von GitHub, extrahiert Winget-Befehle und führt sie als Admin aus.
# Erstellt update.log (neu) sowie Archiv-Logs update_YYYYMMDD_HHMMSS.log
# Schreibt Ereignisse ins Windows Event Log ("Application") nur wenn Admin.

# ----------------------------
# Einstellungen
# ----------------------------
$sourceUrl     = "https://raw.githubusercontent.com/rschwend/winget/main/app_updates.ps1"
$scriptDir     = Split-Path -Parent $PSCommandPath
$logFile       = Join-Path $scriptDir "update.log"
$archiveStamp  = (Get-Date -Format "yyyyMMdd_HHmmss")
$archiveFile   = Join-Path $scriptDir ("update_{0}.log" -f $archiveStamp)
$eventSource   = "WingetUpdateScript"
$eventLog      = "Application"
$timestampFormat = "yyyy-MM-dd HH:mm:ss"

# ----------------------------
# Prüfe Admin-Rechte früh (nur zum Event-Log-Handling)
# ----------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

# Wenn Admin: Stelle Event Source sicher (New-EventLog benötigt Admin)
if ($isAdmin) {
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($eventSource)) {
            New-EventLog -LogName $eventLog -Source $eventSource
        }
    } catch {
        # Falls Registrierung fehlschlägt, protokollieren wir das später in der Datei
        # aber wir brechen nicht ab.
    }
}

# ----------------------------
# Hilfsfunktionen für Event-Log (falls Admin) und Logging in Datei
# ----------------------------
function Write-EventInfo($message) {
    if ($isAdmin) {
        try {
            Write-EventLog -LogName $eventLog -Source $eventSource -EntryType Information -EventId 1000 -Message $message
        } catch {
            # ignorieren - wird in Datei geloggt
        }
    }
}

function Write-EventError($message) {
    if ($isAdmin) {
        try {
            Write-EventLog -LogName $eventLog -Source $eventSource -EntryType Error -EventId 2000 -Message $message
        } catch {
            # ignorieren - wird in Datei geloggt
        }
    }
}

function Log($text) {
    $timestamp = (Get-Date -Format $timestampFormat)
    "$timestamp  $text" | Out-File -FilePath $logFile -Encoding utf8 -Append
}

# ----------------------------
# Archivierung der alten Log (falls vorhanden)
# ----------------------------
if (Test-Path $logFile) {
    try {
        Copy-Item $logFile $archiveFile -Force
    } catch {
        # Falls Kopie fehlschlägt, weiterhin weitermachen und Fehler protokollieren
        $err = "Fehler beim Archivieren der Log-Datei: $($_.Exception.Message)"
        "$((Get-Date -Format $timestampFormat))  $err" | Out-File -FilePath $logFile -Encoding utf8 -Append
    }
}

# ----------------------------
# Neue Logdatei starten (mit formatiertem Zeitstempel)
# ----------------------------
"Update gestartet: $(Get-Date -Format $timestampFormat)" | Out-File -FilePath $logFile -Encoding utf8
Log "Archiv-Datei (falls vorhanden) wurde kopiert nach: $archiveFile"
if ($isAdmin) { Write-EventInfo "Update gestartet: $(Get-Date -Format $timestampFormat)" }

Write-Host "Lade app_updates.ps1 von GitHub..." -ForegroundColor Cyan
Log "Lade app_updates.ps1 von GitHub: $sourceUrl"

# ----------------------------
# Datei herunterladen
# ----------------------------
try {
    $content = Invoke-WebRequest -Uri $sourceUrl -UseBasicParsing
    $lines = $content.Content -split "`n"
    Log "Download erfolgreich"
    if ($isAdmin) { Write-EventInfo "app_updates.ps1 erfolgreich heruntergeladen" }
} catch {
    $err = "Fehler beim Laden der Datei: $($_.Exception.Message)"
    Write-Host $err -ForegroundColor Red
    Log $err
    if ($isAdmin) { Write-EventError $err }
    exit 1
}

# ----------------------------
# Winget-Befehle extrahieren
# ----------------------------
$wingetCmds = $lines | Where-Object { $_.TrimStart().ToLower().StartsWith("winget") }

if ($wingetCmds.Count -eq 0) {
    $msg = "Keine Winget-Befehle gefunden."
    Write-Host $msg -ForegroundColor Yellow
    Log $msg
    if ($isAdmin) { Write-EventError $msg }
    exit 1
}

Write-Host "Gefundene Winget-Befehle:" -ForegroundColor Green
Log "Gefundene Winget-Befehle:"
$wingetCmds | ForEach-Object {
    Write-Host " → $_"
    Log " → $_"
}

# ----------------------------
# Falls nicht als Admin gestartet: Skript neu als Admin starten
# ----------------------------
if (-not $isAdmin) {
    Write-Host "Starte Skript neu mit Administratorrechten..." -ForegroundColor Yellow
    Log "Starte Skript neu mit Administratorrechten"
    # Beim Neustart per Start-Process wird $PSCommandPath erneut ausgeführt; danach ist $isAdmin true.
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Ab hier sind wir Admin (im neuen Prozess)
Write-Host "Führe Winget-Befehle mit Administratorrechten aus..." -ForegroundColor Cyan
Log "Starte Ausführung der Winget-Befehle"
Write-EventInfo "Ausführung der Winget-Befehle gestartet: $(Get-Date -Format $timestampFormat)"

# ----------------------------
# Winget-Befehle ausführen
# ----------------------------
foreach ($cmd in $wingetCmds) {
    Write-Host ">>> $cmd" -ForegroundColor Magenta
    Log "Ausführen: $cmd"
    try {
        $output = Invoke-Expression $cmd 2>&1
        if ($output) {
            $output | ForEach-Object { Log "   $_" }
        } else {
            Log "   (kein Ausgabeinhalt)"
        }
    } catch {
        $err = "Fehler bei Befehl '$cmd' : $($_.Exception.Message)"
        Write-Host $err -ForegroundColor Red
        Log $err
        Write-EventError $err
    }
}

Write-Host "Update beendet." -ForegroundColor Green
Log "Update abgeschlossen: $(Get-Date -Format $timestampFormat)"
Write-EventInfo "Update abgeschlossen: $(Get-Date -Format $timestampFormat)"
