#Requires -Version 5.1
<#
.SYNOPSIS
    Maintainer-Deployment — JOSYN (erste Iteration)

.DESCRIPTION
    Baut alle JOSYN-Backend-Executables und den Contoso-Demojob und
    deployt sie auf dem lokalen Entwicklungsrechner.

    Zielstruktur:
        $BackendRoot\                           <- CLI + JAPServer
        $BackendRoot\adapters\                  <- Adapter-Assemblies (ADR-009)
        $JobRepositoryRoot\<JobName>\           <- Job-Executables

    Voraussetzung:
        - .NET SDK installiert (net10.0)
        - Lokale NuGet-Feeds muessen existieren (local-packages/ je Repo).
          Das Skript baut alle Pakete selbst neu — beim allerersten Mal
          muss der Feed zuvor einmalig befuellt worden sein:
          josyn-sandbox\tools\convenience-scripts\nuget-total-rebuild.cmd

    Dokumentation: josyn-platform/decisions/ADR-012-maintainer-deployment.md
#>
param(
    [switch] $SkipNugets,  # NuGet-Cache-Bereinigung und Pack-Schritte ueberspringen
    [switch] $Debug        # Debug-Konfiguration statt Release verwenden
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# ---------------------------------------------------------------------------
# Konfiguration — hier anpassen fuer andere Umgebungen
# ---------------------------------------------------------------------------
$BackendRoot       = "C:\ProgramData\JOSYN"
$CliRoot           = Join-Path $BackendRoot "CLI"
$JapServerRoot     = Join-Path $BackendRoot "JAPServer"
$JobRepositoryRoot = Join-Path $BackendRoot "JobRepository"
$Configuration     = if ($Debug) { "Debug" } else { "Release" }

# ---------------------------------------------------------------------------
# Quell-Repo-Wurzeln (relativ zum Skriptstandort abgeleitet)
# Skript liegt in: josyn-sandbox\tools\deploy\
# ---------------------------------------------------------------------------
$DevRoot         = (Resolve-Path "$PSScriptRoot\..\..\..").Path
$BackendRepoRoot = Join-Path $DevRoot "josyn-backend"
$ContosoRepoRoot = Join-Path $DevRoot "josyn-contoso"
$SandboxRepoRoot = Join-Path $DevRoot "josyn-sandbox"

# ---------------------------------------------------------------------------
# Hilfsfunktionen
# ---------------------------------------------------------------------------
function Invoke-Pack {
    param(
        [string] $Label,
        [string] $PackCmd
    )

    Write-Host ""
    Write-Host "=== Pack: $Label ===" -ForegroundColor Cyan

    & cmd.exe /c "$PackCmd"

    if ($LASTEXITCODE -ne 0) {
        throw "Pack fehlgeschlagen: $Label (Exit-Code $LASTEXITCODE)"
    }

    Write-Host "[OK] $Label gepackt" -ForegroundColor Green
}

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
        --property:PublishDir="$OutputDirectory\" `
        --no-self-contained

    if ($LASTEXITCODE -ne 0) {
        throw "Publish fehlgeschlagen: $Label (Exit-Code $LASTEXITCODE)"
    }

    Write-Host "[OK] $Label" -ForegroundColor Green
}

# ---------------------------------------------------------------------------
# Schritt 1: NuGet-Cache bereinigen (josyn.* Pakete)
# ---------------------------------------------------------------------------
if ($SkipNugets) {
    Write-Host ""
    Write-Host "=== NuGet-Cache + Pack: uebersprungen (SkipNugets = `$true) ===" -ForegroundColor DarkGray
}
else {
    Write-Host ""
    Write-Host "=== NuGet-Cache bereinigen ===" -ForegroundColor Yellow

    $nugetCacheBase = Join-Path $env:USERPROFILE ".nuget\packages"
    Get-ChildItem $nugetCacheBase -Directory -Filter "josyn.*" | ForEach-Object {
        Remove-Item $_.FullName -Recurse -Force
        Write-Host "  Geloescht: $($_.FullName)"
    }

    Write-Host "[OK] NuGet-Cache bereinigt" -ForegroundColor Green

    # ---------------------------------------------------------------------------
    # Schritt 2: Alle NuGet-Pakete neu packen (Dependency-Reihenfolge)
    # ---------------------------------------------------------------------------
    Invoke-Pack "josyn-foundation" "$DevRoot\josyn-foundation\.local-build\pack.cmd"
    Invoke-Pack "josyn-commons"    "$DevRoot\josyn-commons\.local-build\pack.cmd"
    Invoke-Pack "josyn-jap"        "$DevRoot\josyn-jap\.local-build\pack.cmd"
    Invoke-Pack "josyn-job-host"   "$DevRoot\josyn-job-host\.local-build\pack.cmd"
    Invoke-Pack "josyn-backend"    "$DevRoot\josyn-backend\.local-build\pack.cmd"
}

# ---------------------------------------------------------------------------
# Schritt 3: Zielordner bereinigen und neu anlegen
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== Bereinige Zielordner ===" -ForegroundColor Yellow

if (Test-Path $BackendRoot) {
    Remove-Item $BackendRoot -Recurse -Force
    Write-Host "  Geloescht: $BackendRoot"
}

@(
    $BackendRoot,
    $CliRoot,
    $JapServerRoot,
    (Join-Path $JapServerRoot "Adapters"),
    $JobRepositoryRoot,
    (Join-Path $JobRepositoryRoot "Contoso.DemoProduct.DemoJob")
) | ForEach-Object {
    New-Item -ItemType Directory -Force -Path $_ | Out-Null
    Write-Host "  Erstellt:  $_"
}

# ---------------------------------------------------------------------------
# Schritt 4: JAPServer bauen und deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "JOSYN.Jap.JAPServer" `
    -SolutionFile   "$BackendRepoRoot\josyn-backend-jap-server\JOSYN.Jap.JAPServer.slnx" `
    -OutputDirectory $JapServerRoot

# ---------------------------------------------------------------------------
# Schritt 5: CLI bauen und deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "JOSYN.Backend.CLI" `
    -SolutionFile   "$BackendRepoRoot\josyn-backend-cli\JOSYN.Backend.CLI.slnx" `
    -OutputDirectory $CliRoot

# ---------------------------------------------------------------------------
# Schritt 6: Contoso-Adapter bauen und in adapters\ deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "Contoso.Josyn.Adapter" `
    -SolutionFile   "$ContosoRepoRoot\contoso-adapter\Contoso.Josyn.Adapter.slnx" `
    -OutputDirectory (Join-Path $JapServerRoot "Adapters")

# ---------------------------------------------------------------------------
# Schritt 7: Contoso-Demojob bauen und ins Job-Repository deployen
# ---------------------------------------------------------------------------
Invoke-Publish `
    -Label          "Contoso.DemoProduct.DemoJob" `
    -SolutionFile   "$ContosoRepoRoot\contoso-demo-job\Contoso.DemoProduct.DemoJob.slnx" `
    -OutputDirectory (Join-Path $JobRepositoryRoot "Contoso.DemoProduct.DemoJob")

# ---------------------------------------------------------------------------
# Schritt 7a: ArgGen — local-arguments scaffold fuer Contoso-Demojob generieren
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== ArgGen: Contoso.DemoProduct.DemoJob ===" -ForegroundColor Cyan

$demoJobExe = Join-Path $JobRepositoryRoot "Contoso.DemoProduct.DemoJob\Contoso.DemoProduct.DemoJob.exe"
$cliExe     = Join-Path $CliRoot "JOSYN.Backend.CLI.exe"
$argGenProj = Join-Path $SandboxRepoRoot "tools\arg-gen"

dotnet run --project "$argGenProj" --configuration Release -- `
    "$demoJobExe" --cli-path "$cliExe"

if ($LASTEXITCODE -ne 0) {
    throw "ArgGen fehlgeschlagen fuer Contoso.DemoProduct.DemoJob (Exit-Code $LASTEXITCODE)"
}

Write-Host "[OK] ArgGen: Contoso.DemoProduct.DemoJob" -ForegroundColor Green

# ---------------------------------------------------------------------------
# Schritt 8: bootstrap.ini kopieren und Pfade anpassen
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "=== bootstrap.ini anpassen ===" -ForegroundColor Yellow

$bootstrapSource = Join-Path $BackendRepoRoot "josyn.bootstrap.ini"
$bootstrapDest   = Join-Path $BackendRoot "josyn.bootstrap.ini"

$lines = Get-Content $bootstrapSource | ForEach-Object {
    if ($_ -match "^JapServerExePath=" -or $_ -match "^JobRepositoryRoot=") {
        # omitted — paths are computed by convention from BackendRoot (ADR-012)
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
Write-Host "  CLI:             $CliRoot"
Write-Host "  JAPServer:       $JapServerRoot"
Write-Host "  Job-Repository:  $JobRepositoryRoot"
Write-Host "  local-arguments: generiert von ArgGen"
Write-Host ""
