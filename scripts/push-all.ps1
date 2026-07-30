<#
.SYNOPSIS
    Push every TrustStack repository that has something to push.

.DESCRIPTION
    Skips repos with no upstream and repos already up to date, and warns about
    uncommitted work rather than pushing around it. A dirty tree usually means an
    agent session is still running — pushing then is not wrong, it is just useless,
    and it hides the fact that the real work is not committed yet.

.EXAMPLE
    .\push-all.ps1
#>
[CmdletBinding()]
param()

$Root  = 'C:/Users/Pedro/Documents/Coding'
$Repos = 'AwLZ', 'ProvenancePipeline', 'KateClusters', 'PontoAntiCrack', 'TrustStack'

foreach ($name in $Repos) {
    $path = "$Root/$name"

    if (-not (Test-Path "$path/.git")) {
        Write-Host ("{0,-20} not a git repository" -f $name) -ForegroundColor DarkGray
        continue
    }

    $dirty = (git -C $path status --porcelain | Measure-Object -Line).Lines
    $remote = git -C $path remote get-url origin 2>$null

    if (-not $remote) {
        Write-Host ("{0,-20} no remote — create one first" -f $name) -ForegroundColor Yellow
        continue
    }

    $ahead = git -C $path rev-list --count '@{u}..HEAD' 2>$null
    if ([string]::IsNullOrWhiteSpace($ahead)) {
        Write-Host ("{0,-20} no upstream — git push -u origin main" -f $name) -ForegroundColor Yellow
        continue
    }

    if ([int]$ahead -eq 0) {
        $msg = if ($dirty -gt 0) { "up to date ($dirty uncommitted)" } else { 'up to date' }
        Write-Host ("{0,-20} {1}" -f $name, $msg) -ForegroundColor DarkGray
    }
    else {
        Write-Host ("{0,-20} pushing $ahead commit(s)" -f $name) -ForegroundColor Cyan
        git -C $path push
    }

    if ($dirty -gt 0) {
        Write-Host ("{0,-20} WARNING: $dirty uncommitted file(s) — not pushed" -f '') -ForegroundColor Yellow
    }
}
