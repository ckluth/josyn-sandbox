# JOSYN Toolbox

Convenience scripts for the JOSYN PoC driver. Covers two concerns:
fresh-machine bootstrap and keeping GitHub remotes in sync when switching
between machines ("Planet Home-Office" ↔ "Planet Company").

---

## Scripts

### `josyn-clone-repos.cmd`
Clones all JOSYN repositories from GitHub into the configured root folder.
Run once on a fresh machine before anything else.

---

### `repo-status.cmd`
Shows the current state of every repository at a glance: active branch,
last commit, unpushed commits, staged changes, unstaged changes, untracked files.
Ends with a one-line-per-repo summary.

**Use it any time** to get an overview, or after a pull/push to confirm the state.

---

### `repo-push-all.cmd` — Planet Departure
Run this **before leaving a machine**.

For each repository it will:
1. Fetch the remote.
2. Refuse to continue if the local branch is **behind** the remote — pull first.
3. Stage all modifications, deletions, **and untracked files** (`git add -A`) and commit them
   with an automatic message: `wip: sync [YYYY-MM-DD HH:mm]`.
4. Push all unpushed commits to the remote.

Result: the remote is guaranteed to hold everything that was in your working tree.

---

### `repo-pull-all.cmd` — Planet Arrival
Run this **after arriving on a machine**.

For each repository it will:
1. Skip with a warning if the working tree is **dirty** — clean up first.
2. Fetch the remote.
3. Pull new commits via `--ff-only` (fast-forward only, never a merge commit).
4. Warn if the local branch is **ahead** of the remote (forgotten push from last departure).

---

## Typical machine-switch workflow

```
[Planet A — end of session]
  repo-push-all          ← commits WIP + pushes everything

[Planet B — start of session]
  repo-pull-all          ← pulls everything, fast-forward only
```

If `repo-push-all` reports **untracked files**, decide whether to add them to
`.gitignore` or commit them manually before switching machines.

If `repo-pull-all` reports a repo as **dirty** or **ahead**, resolve that repo
manually (`git status`, `git push`, etc.) and re-run.

---

## Configuration

Machine-to-path detection lives in **one place only**: `detect-root.cmd`.
All other scripts `CALL` it — nothing to touch elsewhere.

| Hostname pattern | ROOT |
|-----------------|------|
| `RZ-*` (starts-with, case-insensitive) | `C:\DevGit` |
| *(anything else)* | `C:\Users\chris\OneDrive\DevGit` |

To add a machine class, add one block to `detect-root.cmd` (template is in the file comments).
To add or remove a repository, edit the `REPOS` variable near the top of each `.cmd` file.
