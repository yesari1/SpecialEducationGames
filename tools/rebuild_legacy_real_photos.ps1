param([string]$Root = (Split-Path $PSScriptRoot -Parent), [switch]$ApplyStaged)
$ErrorActionPreference = 'Stop'
$backup = Join-Path $Root 'artifacts/photo_samples/pre_pixel_copy_fix'
$evidence = Join-Path $Root 'artifacts/photo_samples/dpi_copy_audit'
New-Item -ItemType Directory -Force -Path $backup | Out-Null
$manifestPath = Join-Path $Root 'assets/content/real_photo_manifest.json'
$creditsPath = Join-Path $Root 'assets/content/REAL_PHOTOS.md'
foreach ($path in @($manifestPath,$creditsPath)) {
  $destination = Join-Path $backup (Split-Path $path -Leaf)
  if (-not (Test-Path -LiteralPath $destination)) { Copy-Item -LiteralPath $path -Destination $destination }
}
$prior = Get-Content (Join-Path $backup 'real_photo_manifest.json') -Raw | ConvertFrom-Json
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$ids = @('produce.banana','produce.apple','produce.pepper','produce.lemon','produce.zucchini','produce.tomato','produce.orange')
$originalMap = @{}
foreach ($row in (Get-Content (Join-Path $Root 'artifacts/photo_samples/prior8-source-dpi-audit.json') -Raw | ConvertFrom-Json)) { $originalMap[$row.id] = $row.path }
$pinned = @{
  'produce.banana'='fe23c58652b3da3471fd86bf333aa27b45f2d9238ad03b42f4dfc795acf3954c'
  'produce.apple'='cea946e014439186f69019f420148842e7441c090be450f4fe2288b519e4c40b'
}
foreach ($entry in $prior.assets | Where-Object { $_.id -in $ids }) {
  if ($entry.originalSha256) { $pinned[$entry.id] = $entry.originalSha256 }
  $destination = Join-Path $backup (Split-Path $entry.path -Leaf)
  if (-not (Test-Path -LiteralPath $destination)) {
    if ((Get-FileHash (Join-Path $Root $entry.path)).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Existing app asset mismatch: $($entry.id)" }
    Copy-Item -LiteralPath (Join-Path $Root $entry.path) -Destination $destination
  }
  if ((Get-FileHash $destination).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Backup hash mismatch: $($entry.id)" }
  if ((Get-FileHash (Join-Path $Root $originalMap[$entry.id])).Hash.ToLowerInvariant() -ne $pinned[$entry.id]) { throw "Original hash mismatch: $($entry.id)" }
}
# Shared exporter now performs the verified explicit pixel-to-pixel initial copy.
. (Join-Path $PSScriptRoot 'prepare_photo_samples.ps1') -Root $Root -LoadOnly
$results = @()
if ($ApplyStaged) {
  $results = @(Get-Content (Join-Path $evidence 'rebuild-results.json') -Raw | ConvertFrom-Json)
  if ($results.Count -ne 7) { throw 'Expected seven inspected staged results.' }
  foreach ($id in $ids) {
    $result = @($results | Where-Object id -eq $id)
    if ($result.Count -ne 1 -or $result[0].originalSha256 -ne $pinned[$id]) { throw "Invalid staged identity: $id" }
    $entry = $prior.assets | Where-Object id -eq $id
    foreach ($run in 1..2) {
      $path = Join-Path $evidence ("rebuild-run$run/" + (Split-Path $entry.path -Leaf))
      if ((Get-FileHash $path).Hash.ToLowerInvariant() -ne $result[0].newSha256) { throw "Staged hash mismatch: $id" }
      [RealPhotoSamples]::Verify($path) | Out-Null
    }
  }
}
else { foreach ($run in 1..2) {
  $folder = Join-Path $evidence "rebuild-run$run"
  New-Item -ItemType Directory -Force -Path $folder | Out-Null
  foreach ($id in $ids) {
    $entry = $prior.assets | Where-Object id -eq $id
    $output = Join-Path $folder (Split-Path $entry.path -Leaf)
    # Preserve original mask policy: banana/apple border-mask only, other five
    # also remove disconnected background components.
    [RealPhotoSamples]::Export((Join-Path $Root $originalMap[$id]),$output,$true,($id -notin @('produce.banana','produce.apple')))
    $verification = [RealPhotoSamples]::Verify($output)
    $digest = (Get-FileHash $output).Hash.ToLowerInvariant()
    if ($run -eq 1) {
      $results += [ordered]@{id=$id; original=$originalMap[$id]; originalSha256=$pinned[$id]; oldSha256=$entry.sha256; newSha256=$digest; verification=$verification}
    } elseif ($digest -ne ($results | Where-Object {$_.id -eq $id}).newSha256) { throw "Nondeterministic output: $id" }
    Write-Output "$run $id $digest $verification"
  }
} }
foreach ($entry in $prior.assets | Where-Object {$_.id -notin $ids}) {
  $current = $manifest.assets | Where-Object id -eq $entry.id
  if ((Get-FileHash (Join-Path $Root $entry.path)).Hash.ToLowerInvariant() -ne $entry.sha256) { throw "Unaffected asset changed: $($entry.id)" }
  if (($current | ConvertTo-Json -Depth 12 -Compress) -ne ($entry | ConvertTo-Json -Depth 12 -Compress)) { throw "Unaffected manifest entry changed: $($entry.id)" }
}
$results | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 (Join-Path $evidence 'rebuild-results.json')
if (-not $ApplyStaged) {
  Write-Output 'Two deterministic staged runs complete. Inspect all seven PNGs before -ApplyStaged.'
  return
}
foreach ($entry in $manifest.assets | Where-Object {$_.id -in $ids}) {
  $result = $results | Where-Object {$_.id -eq $entry.id}
  Copy-Item -LiteralPath (Join-Path $evidence ("rebuild-run2/" + (Split-Path $entry.path -Leaf))) -Destination (Join-Path $Root $entry.path)
  $entry.sha256 = $result.newSha256
  $entry.processing = 'tools/rebuild_legacy_real_photos.ps1'
  $entry.changes = 'Initial copy uses identical source/destination pixel rectangles, independent of source DPI; decoded opaque RGB and alpha identity verified. Border-connected neutral white removed mechanically; ' + $(if ($entry.id -notin @('produce.banana','produce.apple')) {'disconnected background specks discarded retaining largest silhouette; '} else {''}) + 'original photographic detail retained before one proportional 912px bicubic resize, centered 1024x1024 RGBA canvas and 4px white silhouette outline. No generative editing.'
}
$manifest | ConvertTo-Json -Depth 12 | Set-Content -Encoding utf8 $manifestPath
# Update only the affected Changes lines; retain all existing credits verbatim.
$credits = Get-Content $creditsPath -Raw
foreach ($entry in $manifest.assets | Where-Object {$_.id -in $ids}) {
  $pattern = '(?s)(## ' + [regex]::Escape($entry.id) + '\r?\n.*?Changes: )[^\r\n]*'
  $replacement = $entry.changes
  $credits = [regex]::Replace($credits,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{param($match) $match.Groups[1].Value + $replacement})
}
[IO.File]::WriteAllText($creditsPath,$credits,[Text.UTF8Encoding]::new($false))
Write-Output 'Applied seven inspected staged assets; all other photos/records remain unchanged. Original app bytes and manifest retained in pre_pixel_copy_fix.'
