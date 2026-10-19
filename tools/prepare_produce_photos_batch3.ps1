param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'prepare_photo_samples.ps1') -Root $Root -LoadOnly
Add-Type -ReferencedAssemblies @('System.Drawing.Common', 'System.Drawing.Primitives', 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core', 'System.Security.Cryptography') -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
public static class Batch3PhotoPreparation {
    private static string Pixels(Bitmap bitmap) {
        var rect = new Rectangle(0,0,bitmap.Width,bitmap.Height);
        var data = bitmap.LockBits(rect,ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
        var bytes = new byte[bitmap.Width*bitmap.Height*4];
        for(int y=0;y<bitmap.Height;y++)
            Marshal.Copy(IntPtr.Add(data.Scan0,y*data.Stride),bytes,y*bitmap.Width*4,bitmap.Width*4);
        bitmap.UnlockBits(data);
        return Convert.ToHexString(SHA256.HashData(bytes)).ToLowerInvariant();
    }
    public static string Normalize(string input,string output) {
        string before;
        using(var bitmap = new Bitmap(input)) {
            before = Pixels(bitmap);
            // Set metadata only: never redraw, resample, recolor or alter alpha.
            // DrawImageUnscaled otherwise uses physical size when source DPI differs.
            bitmap.SetResolution(96,96);
            bitmap.Save(output,ImageFormat.Png);
        }
        using(var bitmap = new Bitmap(output)) {
            if(Pixels(bitmap)!=before)throw new Exception("Decoded pixel change during DPI normalization");
        }
        return System.IO.Path.GetFileName(input)+": decoded RGBA SHA256 preserved "+before;
    }
}
'@
$batch = Get-Content (Join-Path $Root 'artifacts/photo_samples/batch3_manifest.json') -Raw | ConvertFrom-Json
foreach ($asset in $batch.accepted) {
    $inputPath = Join-Path $Root $asset.original
    $outputPath = Join-Path $Root $asset.path
    if ((Get-FileHash $inputPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne $asset.originalSha256) {
        throw "Original hash mismatch: $($asset.id)"
    }
    $normalized = Join-Path $Root ("artifacts/photo_samples/batch3_evidence/" + $asset.id + "-dpi96.png")
    [Batch3PhotoPreparation]::Normalize($inputPath, $normalized)
    [RealPhotoSamples]::Export($normalized, $outputPath, $asset.removeWhite, $true)
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
        processing = 'tools/prepare_produce_photos_batch3.ps1'
        whiteOutlinePixels = 4
        changes = 'Decoded pixel RGBA checked identical after lossless96dpi working-copy normalization (prevents GDI DrawImageUnscaled physical-size clipping). Existing source transparency retained where present; border-connected neutral white otherwise removed mechanically; disconnected background specks discarded while retaining the largest photographed silhouette. Original RGB detail retained; alpha crop, proportional 912px resize, centered 1024x1024 RGBA and 4px white silhouette outline. No generative editing.'
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

