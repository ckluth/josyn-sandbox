# deploy

Maintainer-Deployment-Skripte für JOSYN auf dem lokalen Entwicklungsrechner.

---

## Inhalt

| Datei | Beschreibung |
|-------|--------------|
| `deploy-maintainer.ps1` | Deployment-Skript (PowerShell) |
| `launch.cmd` | Vollständiges Deployment inkl. NuGet-Cache-Bereinigung und Pack |
| `launch-skipnugets.cmd` | Deployment ohne NuGet-Schritte (nur Publish + bootstrap.ini) |

---

## Voraussetzung — erster Lauf

Beim allerersten Mal müssen die lokalen NuGet-Feeds (`local-packages/` in jedem Repo)
einmalig befüllt werden. Danach übernimmt das Deploy-Skript das Packen bei jedem Lauf.

```
josyn-sandbox\tools\convenience-scripts\nuget-total-rebuild.cmd
```

---

## Verwendung

```
launch.cmd                  vollständiges Deployment (NuGet-Cache + Pack + Publish)
launch-skipnugets.cmd       nur Publish + bootstrap.ini (NuGet-Schritte übersprungen)
```

oder direkt:

```
pwsh -ExecutionPolicy Bypass -File deploy-maintainer.ps1
pwsh -ExecutionPolicy Bypass -File deploy-maintainer.ps1 -SkipNugets
```

---

## Was das Skript tut

1. `josyn.*`-Pakete aus dem NuGet-Cache löschen
2. Alle NuGet-Pakete neu bauen und packen (foundation → commons → jap → job-host → backend)
3. Zielordner bereinigen (`C:\Programme\JOSYN`)
4. `JOSYN.Jap.JAPServer` publizieren
5. `JOSYN.Backend.CLI` publizieren
6. `Contoso.Josyn.Adapter` → `Adapters\` publizieren
7. `Contoso.DemoProduct.DemoJob` → `JobRepository\` publizieren
8. `josyn.bootstrap.ini` kopieren und Pfade auf Deployment-Ziele anpassen

---

## Konfiguration

Deployment-Ziele stehen als Variablen am Anfang von `deploy-maintainer.ps1`:

```powershell
$BackendRoot       = "C:\Programme\JOSYN"
$JobRepositoryRoot = "C:\Programme\JOSYN\JobRepository"
$Configuration     = "Release"
```

---

## Architektur-Entscheidung

Siehe `josyn-platform/decisions/ADR-012-maintainer-deployment.md`.
