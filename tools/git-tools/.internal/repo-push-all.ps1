<#
.SYNOPSIS
    Planet-departure tool. For each repo: commits any dirty tracked files with a
    WIP message and pushes all unpushed commits to the remote.

    Untracked files are reported as warnings but never auto-committed.
    Repos that are behind their remote are skipped - pull first.

.PARAMETER Path
    One or more paths to git repositories. Defaults to the current directory.

.EXAMPLE
    repo-push-all
    repo-push-all C:\DevGit\josyn-backend C:\DevGit\josyn-jap
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

function Push-RepoChanges([string] $repoPath) {

    $isRepo = git --no-pager -C $repoPath rev-parse --is-inside-work-tree 2>$null
    if ($isRepo -ne "true") {
        Write-Host ""
        Write-Host "  [SKIP] Not a git repository: $repoPath" -ForegroundColor DarkYellow
        return $null
    }

    function git-cmd { git --no-pager -C $repoPath @args }

    $repoName = git-cmd rev-parse --show-toplevel | Split-Path -Leaf
    $branch   = git-cmd rev-parse --abbrev-ref HEAD

    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  ## $repoName  [$branch]" -ForegroundColor White
    Write-Host "     $repoPath" -ForegroundColor DarkGray

    # upstream required
    $upstreamRaw = git --no-pager -C $repoPath rev-parse --abbrev-ref "@{u}" 2>$null
    $hasUpstream = $LASTEXITCODE -eq 0
    if (-not $hasUpstream) {
        Write-Item "  [SKIP]" "No upstream configured - skipping." "DarkYellow"
        return [PSCustomObject]@{ Name = $repoName; Result = "no-upstream"; Untracked = 0 }
    }
    $upstream = $upstreamRaw

    # fetch so ahead/behind counts are fresh
    Write-Host "    Fetching remote..." -ForegroundColor DarkGray
    git-cmd fetch | Out-Null

    # refuse to push if behind - merging is the human's job
    $behindCount = @(git-cmd log "HEAD..$upstream" --format="%h").Count
    if ($behindCount -gt 0) {
        Write-Host "    [ERROR] Behind remote by $behindCount commit(s). Pull first, then re-run." -ForegroundColor Red
        return [PSCustomObject]@{ Name = $repoName; Result = "behind"; Untracked = 0 }
    }

    # inspect working tree
    $statusLines = git-cmd status --porcelain
    $untracked   = @($statusLines | Where-Object { $_.StartsWith("??") })
    $hasUnstaged = @($statusLines | Where-Object { $_ -match "^.[MD]" }).Count -gt 0
    $hasStaged   = @($statusLines | Where-Object { $_ -match "^[MARCDT]" -and -not $_.StartsWith("??") }).Count -gt 0

    # confirmation guard for untracked files
    if ($untracked.Count -gt 0) {
        Write-Host "    Untracked files:" -ForegroundColor Yellow
        foreach ($f in $untracked) {
            Write-Host "      ? $($f.Substring(3))" -ForegroundColor DarkYellow
        }
        $choices = @(
            [System.Management.Automation.Host.ChoiceDescription]::new("&Add",  "Stage and commit all untracked files"),
            [System.Management.Automation.Host.ChoiceDescription]::new("&Skip", "Skip this repository entirely")
        )
        $choice = $Host.UI.PromptForChoice("", "    Add untracked files?", $choices, 0)
        if ($choice -eq 1) {
            Write-Host "    [SKIP] Skipped by user." -ForegroundColor DarkYellow
            return [PSCustomObject]@{ Name = $repoName; Result = "skipped" }
        }
    }

    # auto-commit all changes including untracked files
    $committed = $false
    if ($hasUnstaged -or $hasStaged -or $untracked.Count -gt 0) {
        Write-Host "    Staging all changes (git add -A)..." -ForegroundColor DarkGray
        $out = git-cmd add -A
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    [ERROR] git add -A failed: $out" -ForegroundColor Red
            return [PSCustomObject]@{ Name = $repoName; Result = "error" }
        }
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm"
        $msg       = "wip: sync [$timestamp]"
        Write-Host "    Committing: $msg" -ForegroundColor DarkGray
        $out = git-cmd commit -m $msg
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    [ERROR] git commit failed: $out" -ForegroundColor Red
            return [PSCustomObject]@{ Name = $repoName; Result = "error" }
        }
        $committed = $true
    }

    # push if ahead
    $aheadCount = @(git-cmd log "$upstream..HEAD" --format="%h").Count
    $pushed = $false
    if ($aheadCount -gt 0) {
        Write-Host "    Pushing $aheadCount commit(s)..." -ForegroundColor DarkGray
        $out = git-cmd push
        if ($LASTEXITCODE -ne 0) {
            Write-Host "    [ERROR] git push failed: $out" -ForegroundColor Red
            return [PSCustomObject]@{ Name = $repoName; Result = "error" }
        }
        $pushed = $true
        $action = if ($committed) { "Committed + pushed." } else { "Pushed." }
        Write-Host "    [OK] $action" -ForegroundColor Green
    } else {
        Write-Host "    [OK] Already up to date with remote." -ForegroundColor Green
    }

    $result = if     ($pushed -and $committed) { "committed+pushed" }
              elseif ($pushed)                 { "pushed" }
              else                             { "up-to-date" }

    return [PSCustomObject]@{
        Name   = $repoName
        Result = $result
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
    $result = Push-RepoChanges ($resolved.Path)
    if ($result) { $results += $result }
}

# batch summary
if ($results.Count -gt 1) {
    Write-Host ""
    Write-Host ("=" * 70) -ForegroundColor DarkGray
    Write-Host "  SUMMARY  ($($results.Count) repos)" -ForegroundColor Cyan
    Write-Host ("  " + ("-" * 40)) -ForegroundColor DarkCyan
    foreach ($r in $results) {
        $isOk    = $r.Result -in @("up-to-date", "pushed", "committed+pushed")
        $isSkip  = $r.Result -eq "skipped"
        $flag    = if ($isOk) { "[OK]" } elseif ($isSkip) { "[--]" } else { "[!]" }
        $color   = if ($isOk) { "Green" } elseif ($isSkip) { "DarkYellow" } else { "Red" }
        Write-Host ("    {0,-6} {1,-30} {2}" -f $flag, $r.Name, $r.Result) -ForegroundColor $color
    }
    Write-Host ""
}
