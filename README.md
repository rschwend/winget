Quelle: https://www.tech51.de/category/windows/updates/

windows11_update_settings.ps1 -> Optionale Updates werden automatisch installiert und das innert 2 Tagen

app_updates.ps1 -> Winget Update commands

update.ps1 -> Lokale executable Datei, welche per TaskScheduler in Windows mit ausgeführt wird (run with highest privileges).

TaskScheduler:

- start a programm
- powershell.exe
- -NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\custom_rsc\taskscheduler\update.ps1"
- C:\Program Files\custom_rsc\taskscheduler
