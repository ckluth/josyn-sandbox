<#
.SYNOPSIS
    Shows the local status of one or more git repositories at a glance.

.PARAMETER Path
    One or more paths to git repositories. Defaults to the current directory.

.EXAMPLE
    repo-status
    repo-status C:\DevGit\josyn-backend
    repo-status C:\DevGit\josyn-backend C:\DevGit\josyn-jap C:\DevGit\josyn-platform
#>

param(
    [Parameter(ValueFromRemainingArguments)]
    [string[]] $Path = @(".")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# -- helpers ------------------------------------------------------------------

function Write-Header([string] $text) {
    Write-Host ""
    Write-Host "  $text" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * $text.Length)) -ForegroundColor DarkCyan
}

function Write-Item([string] $label, [string] $value, [string] $color = "White") {
    Write-Host ("    {0,-28} {1}" -f $label, $value) -ForegroundColor $color
}

function Write-RepoStatus([string] $repoPath) {

    $isRepo = git --no-pager -C $repoPath rev-parse --is-inside-work-tree 2>&1
    if ($isRepo -ne "true") {
        Write-Host ""
        Write-Host "  [SKIP] Not a git repository: $repoPath" -ForegroundColor DarkYellow
        return $null
    }

    function git-cmd { git --no-pager -C $repoPath @args 2>&1 }

    $repoName = git-cmd rev-parse --show-toplevel | Split-Path -Leaf

    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  ## $repoName" -ForegroundColor White
    Write-Host "     $repoPath" -ForegroundColor DarkGray

    # branch + remote
    Write-Header "Branch"

    $branch       = git-cmd rev-parse --abbrev-ref HEAD
    $upstreamRaw  = git-cmd rev-parse --abbrev-ref "@{u}" 2>&1
    $hasUpstream  = $LASTEXITCODE -eq 0
    $upstream     = if ($hasUpstream) { $upstreamRaw } else { $null }

    Write-Item "Local branch:" $branch
    if ($hasUpstream) {
        Write-Item "Tracking:" $upstream
    } else {
        Write-Item "Tracking:" "(no upstream configured)" "DarkYellow"
    }

    # last commit
    Write-Header "Last Commit"

    Write-Item "Hash:"    (git-cmd log -1 --format="%h")
    Write-Item "Message:" (git-cmd log -1 --format="%s")
    Write-Item "Author:"  (git-cmd log -1 --format="%an")
    Write-Item "Date:"    (git-cmd log -1 --format="%ci")

    # last push
    Write-Header "Last Push"

    if ($hasUpstream) {
        $pushDate = git-cmd log -1 --format="%ci" $upstream 2>&1
        if ($LASTEXITCODE -eq 0 -and $pushDate) {
            Write-Item "Remote ref date:" $pushDate
        } else {
            Write-Item "Remote ref date:" "(could not resolve)" "DarkYellow"
        }
    } else {
        Write-Item "Remote ref date:" "(no upstream)" "DarkYellow"
    }

    # commits not pushed
    Write-Header "Commits Not Pushed"

    if ($hasUpstream) {
        $aheadLog = git-cmd log "$upstream..HEAD" --format="%h %ci  %s"
        if ($aheadLog) {
            foreach ($line in $aheadLog) {
                Write-Host "    ^ $line" -ForegroundColor Yellow
            }
        } else {
            Write-Host "    [OK] Up to date with remote." -ForegroundColor Green
        }
    } else {
        $allLocal = git-cmd log --format="%h %ci  %s"
        if ($allLocal) {
            Write-Host "    (no upstream -- showing last 10 local commits)" -ForegroundColor DarkYellow
            foreach ($line in ($allLocal | Select-Object -First 10)) {
                Write-Host "    ^ $line" -ForegroundColor Yellow
            }
        }
    }

    # working tree
    $statusLines = git-cmd status --porcelain
    $untracked   = @($statusLines | Where-Object { $_.StartsWith("??") })
    $unstaged    = @($statusLines | Where-Object { $_ -match "^.[MD]" })
    $staged      = @($statusLines | Where-Object { $_ -match "^[MARCDT]" -and -not $_.StartsWith("??") })

    Write-Header "Staged (not committed)"
    if ($staged.Count -gt 0) {
        foreach ($f in $staged)    { Write-Host "    $f" -ForegroundColor Red }
    } else {
        Write-Host "    [OK] Nothing staged." -ForegroundColor Green
    }

    Write-Header "Unstaged Changes"
    if ($unstaged.Count -gt 0) {
        foreach ($f in $unstaged)  { Write-Host "    $f" -ForegroundColor Red }
    } else {
        Write-Host "    [OK] No unstaged changes." -ForegroundColor Green
    }

    Write-Header "Untracked Files"
    if ($untracked.Count -gt 0) {
        foreach ($f in $untracked) { Write-Host "    $($f.Substring(3))" -ForegroundColor Red }
    } else {
        Write-Host "    [OK] No untracked files." -ForegroundColor Green
    }

    # return summary token for the batch summary line
    $needsAttention = ($staged.Count + $unstaged.Count + $untracked.Count) -gt 0
    $aheadCount = 0
    if ($hasUpstream) {
        $aheadCount = @(git-cmd log "$upstream..HEAD" --format="%h").Count
    }

    return [PSCustomObject]@{
        Name           = $repoName
        NeedsAttention = $needsAttention
        AheadCount     = $aheadCount
        HasUpstream    = $hasUpstream
    }
}

# -- main ---------------------------------------------------------------------

$results = @()

foreach ($p in $Path) {
    $resolved = Resolve-Path $p -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Host ""
        Write-Host "  [ERROR] Path not found: $p" -ForegroundColor Red
        continue
    }
    $result = Write-RepoStatus ($resolved.Path)
    if ($result) { $results += $result }
}

# batch summary (only shown when processing more than one repo)
if ($results.Count -gt 1) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  SUMMARY  ($($results.Count) repos)" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 40)) -ForegroundColor DarkCyan
    foreach ($r in $results) {
        $flag  = if ($r.NeedsAttention -or $r.AheadCount -gt 0) { "[!]" } else { "[OK]" }
        $color = if ($r.NeedsAttention -or $r.AheadCount -gt 0) { "DarkYellow" } else { "Green" }
        $ahead = if ($r.AheadCount -gt 0) { "  ($($r.AheadCount) unpushed)" } else { "" }
        $dirty = if ($r.NeedsAttention) { "  dirty" } else { "" }
        $noUp  = if (-not $r.HasUpstream) { "  no upstream" } else { "" }
        Write-Host ("    {0,-6} {1}{2}{3}{4}" -f $flag, $r.Name, $ahead, $dirty, $noUp) -ForegroundColor $color
    }
    Write-Host ""
}