$ErrorActionPreference = 'Stop'
# Export-Clixml encrypts SecureString with Windows DPAPI for this Windows user.
$secretDirectory = Join-Path $env:USERPROFILE '.codex/secrets'
$secretPath = Join-Path $secretDirectory 'inferx.credential.xml'
$token = Read-Host 'InferX API token (hidden)' -AsSecureString
if ($token.Length -eq 0) { throw 'Token cannot be empty.' }
New-Item -ItemType Directory -Path $secretDirectory -Force | Out-Null
$credential = New-Object System.Management.Automation.PSCredential('inferx', $token)
$credential | Export-Clixml -LiteralPath $secretPath
Write-Host 'Token saved encrypted for your Windows account. No API request was sent.'
