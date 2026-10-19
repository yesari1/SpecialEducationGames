param(
    [Parameter(Mandatory = $true)][string]$TaskFile,
    [string[]]$WriteScope = @(),
    [switch]$AllowChecks,
    [ValidateRange(1, 30)][int]$MaxSteps = 12,
    [ValidateRange(64, 8192)][int]$MaxOutputTokens = 4096,
    [ValidateSet('provider', 'enabled', 'disabled')][string]$Thinking = 'provider',
    [switch]$JsonMode
)
$ErrorActionPreference = 'Stop'
$credentialPath = Join-Path $env:USERPROFILE '.codex/secrets/inferx.credential.xml'
if (-not (Test-Path -LiteralPath $credentialPath)) { throw 'Run set_inferx_token.ps1 first.' }
$oldToken = [Environment]::GetEnvironmentVariable('INFERX_TOKEN', 'Process')
try {
    $credential = Import-Clixml -LiteralPath $credentialPath
    $env:INFERX_TOKEN = $credential.GetNetworkCredential().Password
    $agentArgs = @((Join-Path $PSScriptRoot 'inferx_agent.py'), '--task-file', $TaskFile, '--max-steps', "$MaxSteps", '--max-output-tokens', "$MaxOutputTokens")
    $agentArgs += @('--thinking', $Thinking)
    if ($JsonMode) { $agentArgs += '--json-mode' }
    foreach ($scope in $WriteScope) { $agentArgs += @('--write-scope', $scope) }
    if ($AllowChecks) { $agentArgs += '--allow-checks' }
    & python @agentArgs
    if ($LASTEXITCODE -ne 0) { throw 'InferX agent did not complete. Inspect the run status; do not assume changes were validated.' }
} finally {
    [Environment]::SetEnvironmentVariable('INFERX_TOKEN', $oldToken, 'Process')
    $credential = $null
}
