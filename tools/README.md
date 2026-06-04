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
