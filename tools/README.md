# JOSYN Toolbox

Convenience tools for the JOSYN platform maintainer. Each sub-folder is self-contained.

---

## [`git-tools/`](git-tools/)

Scripts for bootstrapping a fresh machine and keeping all JOSYN repositories in sync
when switching between machines (Planet Home-Office ↔ Planet Company).

See [git-tools/README.md](git-tools/README.md) for full documentation.

---

## [`doc-generator/`](doc-generator/)

A .NET 10 console tool that converts the `solution-architecture` markdown tree into a
browsable static HTML site. Output folder is caller-specified — nothing is committed.

**Usage:**
```
dotnet run --project tools/doc-generator -- <source-dir> <output-dir>
```

**Example** (from josyn-sandbox root):
```
dotnet run --project tools/doc-generator -- ..\josyn-platform\solution-architecture C:\Temp\josyn-docs
```

Then open `C:\Temp\josyn-docs\index.html` in any browser.

---

## [`arg-gen/`](arg-gen/)

A .NET 10 console tool that generates the full `local-arguments\` scaffold for a deployed
job — `arguments-default.ini`, `_launcher.cmd`, and `arguments-default.cmd`. Called by
`deploy-maintainer.ps1` after each job publish step.

`local-arguments\` is a deploy-time artefact. It must not be committed to job repos.

**Usage:**
```
dotnet run --project tools/arg-gen -- <job-exe-path> --cli-path <cli-exe-path> [--output-dir <dir>]
```

**Example** (from josyn-sandbox root):
```
dotnet run --project tools/arg-gen -- `
    C:\ProgramData\JOSYN\JobRepository\Contoso.DemoProduct.DemoJob\Contoso.DemoProduct.DemoJob.exe `
    --cli-path C:\ProgramData\JOSYN\CLI\JOSYN.Backend.CLI.exe
```

If the job has no `[JobEntryPoint]` parameters, no files are generated (exit 0).
See ADR-014 for the full design rationale.
