<#
.SYNOPSIS
    Planet-arrival tool. For each repo: pulls the latest remote commits via
    fast-forward only. Dirty repos are skipped to prevent conflicts.

.PARAMETER Path
    One or more paths to git repositories. Defaults to the current directory.

.EXAMPLE
    repo-pull-all
    repo-pull-all C:\DevGit\josyn-backend C:\DevGit\josyn-jap
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

function Pull-RepoChanges([string] $repoPath) {

    $isRepo = git --no-pager -C $repoPath rev-parse --is-inside-work-tree 2>&1
    if ($isRepo -ne "true") {
        Write-Host ""
        Write-Host "  [SKIP] Not a git repository: $repoPath" -ForegroundColor DarkYellow
        return $null
    }

    function git-cmd { git --no-pager -C $repoPath @args 2>&1 }

    $repoName = git-cmd rev-parse --show-toplevel | Split-Path -Leaf
    $branch   = git-cmd rev-parse --abbrev-ref HEAD

    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  ## $repoName  [$branch]" -ForegroundColor White
    Write-Host "     $repoPath" -ForegroundColor DarkGray

    # upstream required
    $upstreamRaw = git-cmd rev-parse --abbrev-ref "@{u}" 2>&1
    $hasUpstream = $LASTEXITCODE -eq 0
    if (-not $hasUpstream) {
        Write-Item "  [SKIP]" "No upstream configured - skipping." "DarkYellow"
        return [PSCustomObject]@{ Name = $repoName; Result = "no-upstream" }
    }
    $upstream = $upstreamRaw

    # a dirty working tree means we'd risk losing work - skip
    $statusLines = git-cmd status --porcelain
    $dirtyLines  = @($statusLines | Where-Object { -not $_.StartsWith("??") })
    if ($dirtyLines.Count -gt 0) {
        Write-Host "    [SKIP] Working tree is dirty - commit or stash changes first." -ForegroundColor DarkYellow
        foreach ($f in $dirtyLines) {
            Write-Host "      $f" -ForegroundColor DarkYellow
        }
        return [PSCustomObject]@{ Name = $repoName; Result = "dirty" }
    }

    # fetch so ahead/behind counts are fresh
    Write-Host "    Fetching remote..." -ForegroundColor DarkGray
    $out = git-cmd fetch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "    [ERROR] git fetch failed: $out" -ForegroundColor Red
        return [PSCustomObject]@{ Name = $repoName; Result = "error" }
    }

    $behindCount = @(git-cmd log "HEAD..$upstream" --format="%h").Count
    $aheadCount  = @(git-cmd log "$upstream..HEAD" --format="%h").Count

    if ($behindCount -gt 0) {
        Write-Host "    Pulling $behindCount new commit(s)..." -ForegroundColor DarkGray
        $out = git-cmd pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    [ERROR] git pull --ff-only failed: $out" -ForegroundColor Red
            return [PSCustomObject]@{ Name = $repoName; Result = "error" }
        }
        Write-Host "    [OK] Pulled $behindCount commit(s)." -ForegroundColor Green
        $result = "pulled"
    } elseif ($aheadCount -gt 0) {
        Write-Host "    [!] $aheadCount local commit(s) not yet pushed - run repo-push-all." -ForegroundColor DarkYellow
        $result = "ahead"
    } else {
        Write-Host "    [OK] Already up to date." -ForegroundColor Green
        $result = "up-to-date"
    }

    return [PSCustomObject]@{ Name = $repoName; Result = $result }
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
    $result = Pull-RepoChanges ($resolved.Path)
    if ($result) { $results += $result }
}

# batch summary
if ($results.Count -gt 1) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  SUMMARY  ($($results.Count) repos)" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 40)) -ForegroundColor DarkCyan
    foreach ($r in $results) {
        $isOk  = $r.Result -in @("up-to-date", "pulled")
        $flag  = if ($isOk) { "[OK]" } else { "[!]" }
        $color = if ($isOk) { "Green" } else { "DarkYellow" }
        if ($r.Result -eq "error") { $color = "Red" }
        Write-Host ("    {0,-6} {1,-30} {2}" -f $flag, $r.Name, $r.Result) -ForegroundColor $color
    }
    Write-Host ""
}
