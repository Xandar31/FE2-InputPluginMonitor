# FE2-InputPluginMonitor
Dieses PowerShell Skript fragt den Status der FE2 Input-Plugins ab und startet diese ggf. neu und löst einen "manuellen" Alarm auf eine bestimmte Einheit in der Admin-Organisation aus.

## Installation
### firEmergency 2
1. Erstelle eine neue Einheit in der Admin-Organisation. z.B.: [Input Überwachung]
2. Importiere den Alarmablauf [fe2_pipeline_InputUEberwachung.json](fe2_pipeline_InputUEberwachung.json) und ändere im aPager Plugin die Empfänger und ggf. andere Einstellungen
  3. Für die Überwachung benötigst du einen Benutzer mit den Berechtigungen um im Admin-Bereich die Alarmeingänge zu steuern und einen "manuellen" Alarm auszulösen.<br />
  Hierzu kannst du entweder den Admin-Benutzer verwenden !nicht empfehlenswert<br />
  Oder du erstellst dir einen Service-Benutzer.
  - Lege eine neue Rolle an mit den benötigten [Berechtigungen](FE2%20Rolle%20Input%20Überwachung.png)
  - Erstelle eine neue Person und weise dieser die neue Rolle hinzu.
  
### Windows-Server
1. Speichere dir das PowerShell Skript [MonitorFE2Inputs.ps1](MonitorFE2Inputs.ps1) => C:\FE2Scripte\
2. Ändere im Script im oberen Bereich die URL, Benuztername und Passwort
```
$url = "http://localhost:83"

$bodyLogin = @{
 "username"="***USERNAME***"
 "password"="***PASSWORD***"
} | ConvertTo-Json
```
3. Optional: Der Alarmeingang mit dem Typ "MailInputRLP" wird immer gestartet, auch wenn dieser gestoppt ist. Wenn das nicht gewünscht ist, einfach die Zeile rauslöschen.
4. Über die Windowseigenen Aufgabenplanung das Skript in der gewünschten Frequenz, z.B. alle 15 Minuten starten.
```
Command: C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe
Arguments -Executionpolicy Bypass -command "C:\FE2Scripte\MonitorFE2Inputs.ps1"
```
