<#
    Configure-WindowsUpdatePolicies.ps1
    Erstellt/aktualisiert die Registry-Werte im WindowsUpdate-Policy-Zweig.
#>

# Pfad der Windows Update Richtlinien
$RegPath = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate'

# Benötigte Werte + Soll-Konfiguration
$DesiredValues = @{
    SetAllowOptionalContent                          = 1
    AllowOptionalContent                             = 1
    SetAutoRestartDeadline                           = 1
    AutoRestartDeadlinePeriodInDays                  = 2
    AutoRestartDeadlinePeriodInDaysForFeatureUpdates = 2
}

# Prüfen ob als Admin ausgeführt
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "Dieses Skript muss als Administrator ausgeführt werden!"
    exit 1
}

Write-Host "Überprüfe/erstelle Registry-Pfad..." -ForegroundColor Cyan

# Registry-Pfad erstellen falls er fehlt
if (-not (Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
    Write-Host "Registry-Pfad wurde erstellt: $RegPath" -ForegroundColor Green
}

Write-Host "`nSetze erforderliche Werte..." -ForegroundColor Cyan

# Alle benötigten Werte setzen bzw. korrigieren
foreach ($entry in $DesiredValues.GetEnumerator()) {

    $name  = $entry.Key
    $value = $entry.Value

    # Aktuellen Wert auslesen (falls vorhanden)
    $current = (Get-ItemProperty -Path $RegPath -Name $name -ErrorAction SilentlyContinue).$name

    if ($null -eq $current) {
        Write-Host "Erstelle '$name' = $value" -ForegroundColor Yellow
    }
    elseif ($current -ne $value) {
        Write-Host "Aktualisiere '$name' von $current auf $value" -ForegroundColor Yellow
    }
    else {
        Write-Host "'$name' ist bereits korrekt ($value)" -ForegroundColor Green
    }

    # Wert setzen
    Set-ItemProperty -Path $RegPath -Name $name -Value $value -Type DWord -Force
}

Write-Host "`nFertig! Aktuelle Konfiguration:" -ForegroundColor Cyan
Get-ItemProperty -Path $RegPath | Select-Object *

Write-Host "`n(Optional) gpupdate /force wird ausgeführt..." -ForegroundColor Cyan
gpupdate /force | Out-Null

Write-Host "`nAlle Richtlinien wurden erfolgreich angewendet." -ForegroundColor Green
