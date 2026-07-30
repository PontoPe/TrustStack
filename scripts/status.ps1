<#
.SYNOPSIS
    Reads the current state of all four TrustStack repositories.

.DESCRIPTION
    The status table in README.md goes stale every time a session runs. This reads the
    repos instead of trusting the document: commit counts, unpushed work, dirty trees,
    visibility, ADR counts, and what is actually sitting in docs/evidence/.

    Evidence is the column that matters. A repo with code and no evidence has claims;
    a repo with evidence has proof. An empty evidence directory is a valid state and is
    reported as such rather than as a failure.

.PARAMETER Markdown
    Emit a markdown table ready to paste into README.md instead of the console view.

.EXAMPLE
    .\status.ps1
    .\status.ps1 -Markdown
#>
[CmdletBinding()]
param(
    [switch]$Markdown
)

$ErrorActionPreference = 'Stop'

$Root  = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$Repos = 'AwLZ', 'ProvenancePipeline', 'KateClusters', 'PontoAntiCrack'

function Get-RepoState {
    param([string]$Name)

    $path = Join-Path $Root $Name
    if (-not (Test-Path (Join-Path $path '.git'))) {
        return [pscustomobject]@{ Repo = $Name; Error = 'not a git repository' }
    }

    # Unpushed count fails when there is no upstream; that is information, not an error.
    $unpushed = try { [int](git -C $path rev-list --count '@{u}..HEAD' 2>$null) } catch { $null }

    $evidence = Get-ChildItem (Join-Path $path 'docs/evidence') -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -notmatch '^(\.gitkeep|README\.md)$' }

    $img = Get-ChildItem (Join-Path $path 'docs/img') -File -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne '.gitkeep' }

    $adrs = (Select-String -Path (Join-Path $path 'docs/architecture.md') `
                           -Pattern '^#{2,3} ADR-\d+' -ErrorAction SilentlyContinue |
             Measure-Object).Count

    # Visibility needs the GitHub API; absent auth this is simply unknown.
    $private = try { gh api "repos/PontoPe/$Name" --jq '.private' 2>$null } catch { $null }

    [pscustomobject]@{
        Repo       = $Name
        Commits    = [int](git -C $path rev-list --count HEAD)
        Unpushed   = if ($null -eq $unpushed) { 'no upstream' } else { $unpushed }
        Dirty      = (git -C $path status --porcelain | Measure-Object -Line).Lines
        Visibility = switch ($private) { 'true' { 'private' } 'false' { 'public' } default { '?' } }
        ADRs       = $adrs
        Evidence   = $evidence.Count
        Demo       = if ($img | Where-Object Extension -eq '.gif') { 'yes' } else { 'no' }
        Head       = (git -C $path log --oneline -1)
    }
}

$state = $Repos | ForEach-Object { Get-RepoState $_ }

if ($Markdown) {
    ''
    '| Repo | Commits | Visibility | ADRs | Evidence | Demo GIF |'
    '|---|---:|---|---:|---:|---|'
    foreach ($r in $state) {
        "| **$($r.Repo)** | $($r.Commits) | $($r.Visibility) | $($r.ADRs) | $($r.Evidence) | $($r.Demo) |"
    }
    ''
    "_Generated $(Get-Date -Format 'yyyy-MM-dd') by ``scripts/status.ps1``._"
    return
}

$state | Format-Table Repo, Commits, Unpushed, Dirty, Visibility, ADRs, Evidence, Demo -AutoSize

''
'Head commit:'
foreach ($r in $state) { '  {0,-20} {1}' -f $r.Repo, $r.Head }

# Things worth acting on, rather than a wall of green ticks.
$flags = @()
foreach ($r in $state) {
    if ($r.Unpushed -is [int] -and $r.Unpushed -gt 0) { $flags += "$($r.Repo): $($r.Unpushed) commit(s) not pushed" }
    if ($r.Dirty    -gt 0)                            { $flags += "$($r.Repo): $($r.Dirty) uncommitted file(s)" }
    if ($r.Evidence -eq 0)                            { $flags += "$($r.Repo): docs/evidence is empty — nothing proven yet" }
    if ($r.Demo     -eq 'no')                         { $flags += "$($r.Repo): no demo GIF" }
    if ($r.Visibility -eq 'public' -and $r.Dirty -gt 0) { $flags += "$($r.Repo): PUBLIC repo with a dirty working tree" }
}

''
if ($flags) {
    'Needs attention:'
    $flags | ForEach-Object { "  - $_" }
} else {
    'Nothing outstanding.'
}
