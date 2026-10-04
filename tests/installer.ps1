# Run with Windows PowerShell 5.1 or PowerShell 7. All writes use an isolated temp home.
$ErrorActionPreference = 'Stop'
$installer = Join-Path (Split-Path $PSScriptRoot -Parent) 'unlock-dsh.ps1'
$engine = (Get-Process -Id $PID).Path
$testRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('dsh-unlock-test-' + [guid]::NewGuid().ToString('N'))
$profileDir = Join-Path $testRoot 'profiles\desktop'
$patchPath = Join-Path $profileDir 'cordis.patch.yml'
$encoding = New-Object System.Text.UTF8Encoding($false)
function Assert-Test([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}
function Run-Installer([string]$Action, [int]$Expected = 0) {
    $output = & $engine -NoProfile -ExecutionPolicy Bypass -File $installer $Action -DshHome $testRoot -Yes 2>&1
    Assert-Test ($LASTEXITCODE -eq $Expected) "$Action returned $LASTEXITCODE (expected $Expected): $output"
}
try {
    New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    [System.IO.File]::WriteAllText((Join-Path $profileDir 'package.json'), '{"dsh":{"profile":{"bundles":["@deepseek-ai/dsh-web-app"]}}}', $encoding)
    $original = "# Keep user settings`r`n- id: ui-chat`r`n  config:`r`n    transcriptView: standard`r`n"
    [System.IO.File]::WriteAllText($patchPath, $original, $encoding)
    Run-Installer 'dry-run'
    Run-Installer 'diagnose'
    Run-Installer 'list'
    Assert-Test ([System.IO.File]::ReadAllText($patchPath) -ceq $original) 'Read-only actions changed profile'
    Assert-Test (-not (Test-Path (Join-Path $testRoot '.agent-presets'))) 'Read-only actions created preset root'
    Run-Installer 'check' 1
    Run-Installer 'install'
    $installed = [System.IO.File]::ReadAllText($patchPath)
    Assert-Test ($installed.StartsWith($original.TrimEnd())) 'User config was lost'
    Assert-Test ($installed.Contains('@deepseek-ai/dsh-agent-preset')) 'Missing modern declaration'
    Assert-Test ($installed.Contains('@deepseek-ai/dsh-workflow-ptc')) 'Missing compatible workflow plugin'
    Assert-Test (-not $installed.Contains('@deepseek-ai/dsh-workflow-worker-thread')) 'Obsolete workflow plugin remains'
    Assert-Test (@(Get-ChildItem -LiteralPath $profileDir -Filter '*.bak-unlock-*').Count -eq 1) 'Backup missing'
    Run-Installer 'install'
    Assert-Test ([System.IO.File]::ReadAllText($patchPath) -ceq $installed) 'Reinstall duplicated/changed registration'
    Run-Installer 'check'
    # A disk-only preset must not pass check if its registration was removed.
    [System.IO.File]::WriteAllText($patchPath, $original, $encoding)
    Run-Installer 'check' 1
    Run-Installer 'install'
    Run-Installer 'uninstall'
    Assert-Test ([System.IO.File]::ReadAllText($patchPath).TrimEnd() -ceq $original.TrimEnd()) 'Uninstall damaged user config'
    Assert-Test (-not (Test-Path (Join-Path $testRoot '.agent-presets\pj-mode'))) 'Uninstall left active preset'
    Assert-Test (@(Get-ChildItem (Join-Path $testRoot '.agent-presets') -Directory -Filter '_uninstalled-*').Count -eq 1) 'Uninstall did not retain backup'
    # The shipped profile can have an empty flow-style array.
    [System.IO.File]::WriteAllText($patchPath, "# Empty profile`r`n[]`r`n", $encoding)
    Run-Installer 'install'
    Assert-Test (-not ([System.IO.File]::ReadAllText($patchPath) -match '(?m)^\[\]')) 'Empty array conflicts with inserted list'
    Run-Installer 'uninstall'
    Assert-Test ([System.IO.File]::ReadAllText($patchPath).Contains('[]')) 'Uninstall did not restore valid empty list'
    Write-Host '[OK] Isolated installer integration tests passed'
} finally {
    $tempRoot = [System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()).TrimEnd('\') + '\'
    $resolvedTestRoot = [System.IO.Path]::GetFullPath($testRoot)
    if (-not $resolvedTestRoot.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -or
        [System.IO.Path]::GetFileName($resolvedTestRoot) -notlike 'dsh-unlock-test-*') {
        throw 'Refusing to clean an unexpected test path'
    }
    if (Test-Path -LiteralPath $resolvedTestRoot) { Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force }
}
