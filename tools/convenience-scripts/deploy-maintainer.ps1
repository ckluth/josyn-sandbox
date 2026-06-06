#Requires -Version 5.1
<#
.SYNOPSIS
    Maintainer-Deployment — JOSYN (erste Iteration)

.DESCRIPTION
    Baut alle JOSYN-Backend-Executables und den Contoso-Demojob und
    deployt sie auf dem lokalen Entwicklungsrechner.

    Zielstruktur:
        $BackendRoot\                           ← CLI + JAPServer
        $BackendRoot\adapters\                  ← Adapter-Assemblies (ADR-009)
        $JobRepositoryRoot\<JobName>\           ← Job-Executables

    Voraussetzung:
        - .NET SDK installiert (net10.0)
        - Alle JOSYN-NuGet-Pakete sind im lokalen Feed vorhanden
          (josyn-sandbox\tools\convenience-scripts\nuget-total-rebuild.cmd)

    Dokumentation: josyn-platform/decisions/ADR-012-maintainer-deployment.md
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Konfiguration — hier anpassen für andere Umgebungen
# ---------------------------------------------------------------------------
$BackendRoot       = "C:\Programme\JOSYN"
$JobRepositoryRoot = "C:\Programme\JOSYN\JobRepository"
$Configuration     = "Release"

# ---------------------------------------------------------------------------
# Quell-Repo-Wurzeln (relativ zum Skriptstandort abgeleitet)
# Skript liegt in: josyn-sandbox\tools\convenience-scripts\
# ---------------------------------------------------------------------------
$DevRoot         = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$BackendRepoRoot = Join-Path $DevRoot "josyn-backend"
$ContosoRepoRoot = Join-Path $DevRoot "josyn-contoso"

# ---------------------------------------------------------------------------
# Hilfsfunktion
# ---------------------------------------------------------------------------
function Invoke-Publish {
    param(
        [string] $Label,
        [string] $SolutionFile,
        [string] $OutputDirectory
    )

    Write-Host ""
    Write-Host "=== $Label ===" -ForegroundColor Cyan

    dotnet publish "$SolutionFile" `
        --configuration $Configuration `
        --output "$OutputDirectory" `
        --no-self-contained

    if ($LASTEXITCODE -ne 0) {
        throw "Publish fehlgeschlagen: $Label (Exit-Code $LASTEXITCODE)"
    }

    Write-Host "[OK] $Label" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Schritt 1: Zielordner bereinigen und neu anlegen
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Bereinige Zielordner ===" -ForegroundColor Yellow

if (Test-Path $BackendRoot) {
    Remove-Item $BackendRoot -Recurse -Force
    Write-Host "  Geloescht: $BackendRoot"
}

@(
    $BackendRoot,
    (Join-Path $BackendRoot "adapters"),
    $JobRepositoryRoot,
    (Join-Path $JobRepositoryRoot "Contoso.DemoProduct.DemoJob")
) | ForEach-Object {
    New-Item -ItemType Directory -Force -Path $_ | Out-Null
    Write-Host "  Erstellt:  $_"
}

# ---------------------------------------------------------------------------
# Schritt 2: Backend-Executables bauen und deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "JOSYN.Jap.JAPServer" `
    -SolutionFile   "$BackendRepoRoot\josyn-backend-jap-server\JOSYN.Jap.JAPServer.slnx" `
    -OutputDirectory $BackendRoot

Invoke-Publish `
    -Label          "JOSYN.Backend.CLI" `
    -SolutionFile   "$BackendRepoRoot\josyn-backend-cli\JOSYN.Backend.CLI.slnx" `
    -OutputDirectory $BackendRoot

# ---------------------------------------------------------------------------
# Schritt 3: Contoso-Adapter bauen und in adapters\ deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "Contoso.Josyn.Adapter" `
    -SolutionFile   "$ContosoRepoRoot\contoso-adapter\Contoso.Josyn.Adapter.slnx" `
    -OutputDirectory (Join-Path $BackendRoot "adapters")

# ---------------------------------------------------------------------------
# Schritt 4: Contoso-Demojob bauen und ins Job-Repository deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "Contoso.DemoProduct.DemoJob" `
    -SolutionFile   "$ContosoRepoRoot\contoso-demo-job\Contoso.DemoProduct.DemoJob.slnx" `
    -OutputDirectory (Join-Path $JobRepositoryRoot "Contoso.DemoProduct.DemoJob")

# ---------------------------------------------------------------------------
# Schritt 5: bootstrap.ini kopieren und Pfade anpassen
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== bootstrap.ini anpassen ===" -ForegroundColor Yellow

$bootstrapSource = Join-Path $BackendRepoRoot "josyn.bootstrap.ini"
$bootstrapDest   = Join-Path $BackendRoot "josyn.bootstrap.ini"

$lines = Get-Content $bootstrapSource | ForEach-Object {
    if ($_ -match "^JapServerExePath=") {
        "JapServerExePath=$BackendRoot\JOSYN.Jap.JAPServer.exe"
    }
    elseif ($_ -match "^JobRepositoryRoot=") {
        "JobRepositoryRoot=$JobRepositoryRoot"
    }
    else {
        $_
    }
}
Set-Content -Path $bootstrapDest -Value $lines -Encoding UTF8

Write-Host "[OK] bootstrap.ini geschrieben: $bootstrapDest" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Zusammenfassung
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " Deployment abgeschlossen ($Configuration)" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Backend-Root:    $BackendRoot"
Write-Host "  Job-Repository:  $JobRepositoryRoot"
Write-Host ""
