param(
    [Parameter(Mandatory = $true)][string]$TaskFile,
    [string[]]$WriteScope = @(),
    [switch]$AllowChecks,
    [ValidateRange(1, 30)][int]$MaxSteps = 12,
    [ValidateRange(64, 8192)][int]$MaxOutputTokens = 4096,
    [ValidateSet('provider', 'enabled', 'disabled')][string]$Thinking = 'disabled',
    [switch]$JsonMode = $false
)
$ErrorActionPreference = 'Stop'
$credentialPath = Join-Path $env:USERPROFILE '.codex/secrets/deepseek.credential.xml'
if (-not (Test-Path -LiteralPath $credentialPath)) { throw 'Run tools/set_deepseek_key.ps1 first.' }
$oldKey = [Environment]::GetEnvironmentVariable('DEEPSEEK_API_KEY', 'Process')
try {
    $credential = Import-Clixml -LiteralPath $credentialPath
    $env:DEEPSEEK_API_KEY = $credential.GetNetworkCredential().Password
    $agentArgs = @((Join-Path $PSScriptRoot 'inferx_agent.py'), '--provider', 'deepseek', '--transport', 'sdk', '--task-file', $TaskFile,
        '--max-steps', "$MaxSteps", '--max-output-tokens', "$MaxOutputTokens", '--thinking', $Thinking)
    if ($JsonMode) { $agentArgs += '--json-mode' }
    foreach ($scope in $WriteScope) { $agentArgs += @('--write-scope', $scope) }
    if ($AllowChecks) { $agentArgs += '--allow-checks' }
    $deepseekPython = Join-Path $env:USERPROFILE '.codex/tools/deepseek-venv/Scripts/python.exe'
    if (-not (Test-Path -LiteralPath $deepseekPython)) { throw 'DeepSeek SDK tool runtime is missing.' }
    & $deepseekPython @agentArgs
    if ($LASTEXITCODE -ne 0) { throw 'DeepSeek worker did not complete. Review its run status and partial changes.' }
} finally {
    [Environment]::SetEnvironmentVariable('DEEPSEEK_API_KEY', $oldKey, 'Process')
    $credential = $null
}
