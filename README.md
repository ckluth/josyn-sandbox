# JOSYN Playground

> **This repo is a consumer of the JOSYN platform. It is not a platform component.**
> The platform never references it. It carries none of the platform's obligations.

---

## Purpose

`josyn-playground` is the maintainer's playground for:

- **Demonstration** — running and showing the living system end-to-end
- **Exploration** — first contact with new features and concepts before they earn a place in the platform
- **Experimental integration** — rough, non-regression-protected tests of the full runtime flow

Code here may be rough, incomplete, or throwaway. That is not a deficiency — it is the point.

When something matures into a real feature, it moves — rewritten and reviewed — into the appropriate platform repo.

---

## What this repo is not

- Not a platform component
- Not maintained to platform standards
- Not a source of architectural truth
- Not referenced by any platform repo — in any form

---

## The one hard rule

**The platform must never take any dependency on this repo.**

This means: no `ProjectReference`, no NuGet dependency, no solution inclusion, no documentation treating playground content as canonical. The platform does not know this repo exists.

---

## Repository layout

This repo follows the platform's structural conventions as a starting baseline:

```
josyn-playground/
├── <AssemblyName>/               ← directory name matches assembly name
│   └── <AssemblyName>.csproj
├── JOSYN.Playground.slnx         ← solution file (initially empty; projects added as content arrives)
├── nuget.config                  ← local package feed
└── .local-build/
    ├── build.cmd
    ├── build.debug.cmd
    ├── build.release.cmd
    └── test.cmd                  ← no pack.cmd; playground produces no NuGet packages
```

> **Note:** `nuget.config` points to `../local-packages`. This assumes `josyn-playground` sits beside
> the other JOSYN repos in a common parent directory. Local package restore will fail if this
> layout is not in place.

---

## Namespace policy

| Content kind | Namespace |
|---|---|
| Playground-owned harness, demo infrastructure, test scaffolding | `JOSYN.Sandbox.*` |
| Example consumer apps or jobs meant to resemble real adopters | Domain-specific (e.g. `MyCompany.MyJob`) |

`JOSYN.Sandbox.*` signals JOSYN-ecosystem membership without pretending to be a platform component.

---

## Build and test

The build scripts are scaffold-only until the first project is added to the solution.

```
.local-build\build.cmd [Release|Debug]   ← default: Release
.local-build\build.debug.cmd
.local-build\build.release.cmd
.local-build\test.cmd
```

All build output goes to `C:\Temp\VS.OUT\JOSYN\`.

