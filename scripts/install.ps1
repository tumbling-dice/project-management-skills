param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

# Skills use the cross-client Agent Skills location; custom agents remain Codex-specific.
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME ".codex" }
$SkillsDir = Join-Path (Join-Path $HOME ".agents") "skills"
$AgentsDir = Join-Path $CodexHome "agents"

# Copies one path without silently replacing an existing user installation.
# Parameters: Source and Destination paths. Returns: no pipeline output.
function Copy-ItemWithPrompt {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Destination
    )

    if (Test-Path -LiteralPath $Destination) {
        if ($DryRun) {
            Write-Host "would prompt overwrite: $Destination"
            return
        }

        $Answer = Read-Host "Overwrite existing path? $Destination [y/N]"
        if ($Answer -notmatch "^(y|yes)$") {
            Write-Host "skip existing: $Destination"
            return
        }

        Remove-Item -LiteralPath $Destination -Recurse -Force
        Write-Host "removed: $Destination"
    }

    if ($DryRun) {
        Write-Host "copy: $Source -> $Destination"
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse
    Write-Host "copied: $Source -> $Destination"
}

if ($DryRun) {
    Write-Host "dry-run: no filesystem changes"
} else {
    New-Item -ItemType Directory -Path $SkillsDir -Force | Out-Null
    New-Item -ItemType Directory -Path $AgentsDir -Force | Out-Null
}

Get-ChildItem -LiteralPath $RepoRoot -Directory |
    Where-Object {
        -not $_.Name.StartsWith(".") -and
        $_.Name -notin @("agents", "scripts") -and
        (Test-Path -LiteralPath (Join-Path $_.FullName "SKILL.md"))
    } |
    Sort-Object Name |
    ForEach-Object {
        Copy-ItemWithPrompt -Source $_.FullName -Destination (Join-Path $SkillsDir $_.Name)
    }

$AgentsSourceDir = Join-Path $RepoRoot "agents"
if (Test-Path -LiteralPath $AgentsSourceDir) {
    Get-ChildItem -LiteralPath $AgentsSourceDir -File -Filter "*.toml" |
        Sort-Object Name |
        ForEach-Object {
            Copy-ItemWithPrompt -Source $_.FullName -Destination (Join-Path $AgentsDir $_.Name)
        }
}
