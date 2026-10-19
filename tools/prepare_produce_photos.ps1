param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
# Reuse the deterministic pixel-preserving mask/resize/outline implementation.
# Loading the class never rewrites the three historical sample files.
. (Join-Path $PSScriptRoot 'prepare_photo_samples.ps1') -Root $Root -LoadOnly
$batch = Get-Content (Join-Path $Root 'artifacts/photo_samples/produce_batch_manifest.json') -Raw | ConvertFrom-Json
foreach ($asset in $batch.accepted) {
    $inputPath = Join-Path $Root $asset.original
    $outputPath = Join-Path $Root $asset.path
    if ((Get-FileHash $inputPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $asset.originalSha256) {
        throw "Original hash mismatch: $($asset.id)"
    }
    [RealPhotoSamples]::Export($inputPath, $outputPath, $true, $true)
    [RealPhotoSamples]::Verify($outputPath)
}
$manifestPath = Join-Path $Root 'assets/content/real_photo_manifest.json'
$manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
$newEntries = @(foreach ($asset in $batch.accepted) {
    [ordered]@{
        id = $asset.id; path = $asset.path; author = $asset.author
        source = $asset.source; original = $asset.original
        originalSha256 = $asset.originalSha256
        license = $asset.license; licenseUrl = $asset.licenseUrl
        adaptationLicense = $asset.license
        licenseVerified = $true; licenseVerifiedOn = '2026-10-16'
        processing = 'tools/prepare_produce_photos.ps1'
        whiteOutlinePixels = 4
        changes = 'Border-connected neutral white removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.'
        sha256 = (Get-FileHash (Join-Path $Root $asset.path)).Hash.ToLowerInvariant()
    }
})
$batchIds = @($batch.accepted.id)
$manifest.assets = @(@($manifest.assets | Where-Object {$_.id -notin $batchIds}) + $newEntries | Sort-Object id)
$manifest | ConvertTo-Json -Depth 12 | Set-Content $manifestPath -Encoding utf8
$credits = [System.Collections.Generic.List[string]]::new()
$credits.Add('# Real photo credits')
$credits.Add('')
$credits.Add('Adaptations of real photographs, not generated images. Source licenses/public-domain dedications are retained. Processing preserves photographed detail through deterministic masking/crop/resize. The app also draws a white outline at display time.')
foreach ($entry in $manifest.assets) {
    $credits.Add(''); $credits.Add("## $($entry.id)"); $credits.Add('')
    $credits.Add("File: $($entry.path)")
    $credits.Add("Photo author: $($entry.author)")
    if ($entry.existingBackgroundRemoval) {$credits.Add("Original background removal: $($entry.existingBackgroundRemoval)")}
    $credits.Add("Source: $($entry.source)")
    $credits.Add("Source and adaptation license: $($entry.license) — $($entry.licenseUrl)")
    $credits.Add("Changes: $($entry.changes)")
}
$credits | Set-Content (Join-Path $Root 'assets/content/REAL_PHOTOS.md') -Encoding utf8
