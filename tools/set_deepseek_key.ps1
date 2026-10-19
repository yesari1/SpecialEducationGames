$ErrorActionPreference = 'Stop'
$secretDirectory = Join-Path $env:USERPROFILE '.codex/secrets'
$secretPath = Join-Path $secretDirectory 'deepseek.credential.xml'
$apiKey = Read-Host 'DeepSeek API key (hidden)' -AsSecureString
if ($apiKey.Length -eq 0) { throw 'API key cannot be empty.' }
New-Item -ItemType Directory -Path $secretDirectory -Force | Out-Null
$credential = New-Object System.Management.Automation.PSCredential('deepseek', $apiKey)
$credential | Export-Clixml -LiteralPath $secretPath
Write-Host 'DeepSeek key saved with Windows user encryption. No API request sent.'
