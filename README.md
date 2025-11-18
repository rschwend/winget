# Windows Update Automation Scripts

Dieses Repository enthält PowerShell-Skripte zur automatisierten Verwaltung und Installation von Windows-Updates und Anwendungs-Updates unter Windows 11. Die Skripte sind so konzipiert, dass sie optional Updates automatisch installieren und per Task Scheduler ausgeführt werden können.

---

## Skripte

### `windows11_update_settings.ps1`
- Installiert optionale Windows-Updates automatisch.
- Updates werden innerhalb von 2 Tagen nach Verfügbarkeit installiert.

### `app_updates.ps1`
- Führt Updates für installierte Anwendungen durch.
- Nutzt `winget` (Windows Package Manager) zum Aktualisieren der Programme.

### `update.ps1`
- Lokale ausführbare Datei, die als zentraler Update-Task ausgeführt wird.
- Wird per Task Scheduler unter Windows mit höchsten Rechten ausgeführt.

---

## Task Scheduler Konfiguration

Der Task Scheduler startet das Skript `update.ps1` automatisch mit administrativen Rechten. 

### Beispielkonfiguration:

**General:** 
- **Name:**  
  `Winget_update`

- **Run with highest privileges:**  
  `check`
  
**Triggers:** 
- **Name:**  
  `At startup`

- **Delay Task for:**  
  `15 minutes`

- **Stop task if it runs longer than:**  
  `2 hours`

**Actions:**
- **Programm/Skript:**  
  `powershell.exe`

- **Argumente:**  
  `-NoProfile -ExecutionPolicy Bypass -File "C:\Program Files\custom_rsc\taskscheduler\update.ps1"`

- **Start in (optional):**  
  `C:\Program Files\custom_rsc\taskscheduler`

**Settings:**
- **Stop task if it runs longer than:**  
  `4 hours`

---

## Voraussetzungen

- Windows 11 (für optionale Updates relevant)
- Windows mit installiertem **winget** (Windows Package Manager).
- Ausreichende Berechtigungen, um winget-Befehle auszuführen (z. B. Administrator).
- PowerShell mit Ausführungsrechten für Skripte (`ExecutionPolicy Bypass`)

- **Vor dem ersten Ausführen des Skripts** muss winget bereinigt werden, um eventuelle Altversionen oder nicht erkannte Programme zu behandeln:
  1. Führe aus:  
     ```powershell
     winget upgrade --all --accept-package-agreements --include-unknown
     ```
  2. Prüfe danach mit:  
     ```powershell
     winget upgrade
     ```
  3. Wenn weiterhin Programme angezeigt werden, deinstalliere diese mit dem `uninstall`-Befehl. Die Ursache ist oft, dass der Upgrade-Pfad fehlerhaft oder nicht vorhanden ist:
     ```powershell
     winget uninstall --all-versions <Paket-ID>
     ```
     Beispiel:  
     ```powershell
     winget uninstall --all-versions Microsoft.DotNet.Framework.DeveloperPack.4.6
     ```
     Hinweis: `"Microsoft.DotNet.Framework.DeveloperPack.4.6"` ist **nicht** der Name, sondern die **ID** des Pakets. Wiederhole diese Deinstallation, bis keine Updates mehr gemeldet werden.

  4. Falls Programme deinstalliert werden mussten, weil der Upgrade-Pfad fehlte, kannst du die gewünschte Version neu installieren:
     - Suche zuerst die ID:  
       ```powershell
       winget search 7-zip
       ```
     - Installiere dann das Programm anhand der ID:  
       ```powershell
       winget install 7zip.7zip
       ```

- Optional: Überprüfe, dass deine winget-Quellen aktuell sind, z. B. via `winget source update`.


---

## Nutzung

1. Skripte an den vorgesehenen Pfad kopieren (z.B. `C:\Program Files\custom_rsc\taskscheduler`)
2. Task Scheduler konfigurieren, um `update.ps1` regelmäßig mit höchsten Rechten auszuführen
3. Die Skripte kümmern sich automatisch um die Installation von Updates

---

## Hinweise

- Bitte stellen Sie sicher, dass der Task Scheduler mit administrativen Rechten läuft, um alle Updates korrekt installieren zu können.
- Die Skripte sind so ausgelegt, dass sie keine Benutzerinteraktion benötigen und im Hintergrund laufen.

---

## Lizenz

MIT License

---

Bei Fragen oder Problemen gerne Issues öffnen!
