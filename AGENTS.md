# AGENTS.md — JOSYN Playground

> Read this file before working in this repo.

---

## What this repo is

`josyn-playground` is a **consumer** of the JOSYN platform. It is the maintainer's playground for
demonstration, exploration, and experimental integration. It is not maintained to platform standards.
Code here may be rough, incomplete, or throwaway — that is intentional.

---

## The one hard rule

**The platform must never take any dependency on this repo — in any form.**

Forbidden: `ProjectReference`, NuGet dependency, solution inclusion, or any documentation
that treats playground content as platform truth. The platform does not know this repo exists.
An agent must never propose or create a dependency edge pointing from a platform repo into this one.

---

## Agent behavior in this repo

- The relaxed standards of this repo are deliberate. Do not apply platform-level review rigour here.
- The structural conventions (solution layout, build scripts, namespace policy) are a starting baseline — not a strict mandate.
- When something in the playground matures into a real feature, it moves into the appropriate platform repo — rewritten and reviewed there.
- For all architectural questions, the canonical source of truth remains `josyn-platform`.

---

## Confirmation gate

Before creating or editing any file, or running any git operation (`commit`, `push`,
`branch`, `merge`, etc.), state what you are about to do and why — and wait for
explicit confirmation.
