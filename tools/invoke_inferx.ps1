param(
    [Parameter(Mandatory = $true)][string]$PromptFile,
    [Parameter(Mandatory = $true)][string]$OutputFile,
    [ValidateRange(1, 8192)][int]$MaxTokens = 2048
)
$ErrorActionPreference = 'Stop'
$secretPath = Join-Path $env:USERPROFILE '.codex/secrets/inferx.credential.xml'
if (-not (Test-Path -LiteralPath $secretPath)) {
    throw 'Run tools/set_inferx_token.ps1 first to enter your token privately.'
}
$prompt = Get-Content -LiteralPath $PromptFile -Raw -Encoding UTF8
if ([string]::IsNullOrWhiteSpace($prompt)) { throw 'Prompt file is empty.' }
if (Test-Path -LiteralPath $OutputFile) { throw 'Output file already exists; choose a new path.' }
$outputPath = [System.IO.Path]::GetFullPath($OutputFile)
if (-not (Test-Path -LiteralPath ([System.IO.Path]::GetDirectoryName($outputPath)))) {
    throw 'Output directory does not exist.'
}
$credential = Import-Clixml -LiteralPath $secretPath
$body = @{
    model = 'deepseek-v4.1-flash'
    messages = @(
        @{ role = 'system'; content = 'Complete the supplied task only. Return suggestions as text. You have no tool or filesystem access. Never request secrets.' },
        @{ role = 'user'; content = $prompt }
    )
    max_tokens = $MaxTokens
    stream = $false
} | ConvertTo-Json -Depth 8
try {
    $headers = @{ Authorization = 'Bearer ' + $credential.GetNetworkCredential().Password }
    $response = Invoke-RestMethod -Method Post -Uri 'https://model.inferx.net/endpoints/v1/chat/completions' -Headers $headers -ContentType 'application/json; charset=utf-8' -Body ([System.Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 120
    $answer = $response.choices[0].message.content
    if ([string]::IsNullOrWhiteSpace($answer)) { throw 'Empty response.' }
    [System.IO.File]::WriteAllText($outputPath, $answer, (New-Object System.Text.UTF8Encoding($false)))
    Write-Host 'Response saved. Generated text has not been executed or applied.'
} catch {
    # Do not echo exception details, request headers, or provider response bodies.
    throw 'InferX request failed or returned no usable text. Check token, access, balance and endpoint configuration. No automatic retry was made.'
} finally {
    if ($headers) { $headers.Clear() }
    $credential = $null
}
