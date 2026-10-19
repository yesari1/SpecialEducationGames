param([string]$Root = (Split-Path $PSScriptRoot -Parent))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @('System.Drawing.Common', 'System.Drawing.Primitives', 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core', 'System.Security.Cryptography') -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
using System.Security.Cryptography;
public static class PhotoCopyDpiAudit {
  private static byte[] Pixels(Bitmap image) {
    var data=image.LockBits(new Rectangle(0,0,image.Width,image.Height),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
    try {
      var pixels=new byte[image.Width*image.Height*4];
      for(int y=0;y<image.Height;y++) Marshal.Copy(IntPtr.Add(data.Scan0,y*data.Stride),pixels,y*image.Width*4,image.Width*4);
      return pixels;
    } finally { image.UnlockBits(data); }
  }
  private static string Hash(byte[] pixels) { using(var hash=SHA256.Create()) return BitConverter.ToString(hash.ComputeHash(pixels)).Replace("-","").ToLowerInvariant(); }
  private static Bitmap Copy(Bitmap source,bool exact) {
    var result=new Bitmap(source.Width,source.Height,PixelFormat.Format32bppArgb);
    using(var g=Graphics.FromImage(result)) {
      g.CompositingMode=CompositingMode.SourceCopy;
      if(exact) g.DrawImage(source,new Rectangle(0,0,source.Width,source.Height),0,0,source.Width,source.Height,GraphicsUnit.Pixel);
      else g.DrawImageUnscaled(source,0,0);
    }
    return result;
  }
  public sealed class Result {
    public string id, sourceDecodedArgbSha256, oldDecodedArgbSha256, exactDecodedArgbSha256;
    public int width,height,oldOpaquePixels,sourceOpaquePixels,exactOpaquePixels,oldRgbMismatches,exactRgbMismatches,oldAlphaMismatches,exactAlphaMismatches;
    public float dpiX,dpiY,destinationDpi;
    public int[] oldAlphaBounds,exactAlphaBounds;
  }
  private static int[] Bounds(byte[] pixels,int width,int height) {
    int left=width,top=height,right=-1,bottom=-1;
    for(int y=0;y<height;y++)for(int x=0;x<width;x++)if(pixels[(y*width+x)*4+3]!=0){left=Math.Min(left,x);right=Math.Max(right,x);top=Math.Min(top,y);bottom=Math.Max(bottom,y);}
    return new[]{left,top,right,bottom};
  }
  public static Result Audit(Bitmap source,string id,string evidenceFolder,bool saveImages) {
    using(var old=Copy(source,false))using(var exact=Copy(source,true)) {
      var baseline=Pixels(source);var oldPixels=Pixels(old);var exactPixels=Pixels(exact);
      var result=new Result{id=id,width=source.Width,height=source.Height,dpiX=source.HorizontalResolution,dpiY=source.VerticalResolution,destinationDpi=old.HorizontalResolution,
        sourceDecodedArgbSha256=Hash(baseline),oldDecodedArgbSha256=Hash(oldPixels),exactDecodedArgbSha256=Hash(exactPixels),
        oldAlphaBounds=Bounds(oldPixels,source.Width,source.Height),exactAlphaBounds=Bounds(exactPixels,source.Width,source.Height)};
      for(int i=0;i<baseline.Length;i+=4) {
        if(baseline[i+3]==255) {
          result.sourceOpaquePixels++;
          if(baseline[i]!=oldPixels[i]||baseline[i+1]!=oldPixels[i+1]||baseline[i+2]!=oldPixels[i+2])result.oldRgbMismatches++;
          if(baseline[i]!=exactPixels[i]||baseline[i+1]!=exactPixels[i+1]||baseline[i+2]!=exactPixels[i+2])result.exactRgbMismatches++;
        }
        if(oldPixels[i+3]==255)result.oldOpaquePixels++;
        if(exactPixels[i+3]==255)result.exactOpaquePixels++;
        if(baseline[i+3]!=oldPixels[i+3])result.oldAlphaMismatches++;
        if(baseline[i+3]!=exactPixels[i+3])result.exactAlphaMismatches++;
      }
      if(result.exactRgbMismatches!=0||result.exactAlphaMismatches!=0||result.sourceOpaquePixels!=result.exactOpaquePixels)
        throw new Exception("Pixel-accurate copy assertion failed: "+id);
      if(saveImages) {
        source.Save(System.IO.Path.Combine(evidenceFolder,id+"-source.png"),ImageFormat.Png);
        old.Save(System.IO.Path.Combine(evidenceFolder,id+"-old.png"),ImageFormat.Png);
        exact.Save(System.IO.Path.Combine(evidenceFolder,id+"-exact.png"),ImageFormat.Png);
      }
      return result;
    }
  }
  public static Result Diagnostic(float dpi,string folder) {
    using(var image=new Bitmap(257,193,PixelFormat.Format32bppArgb)) {
      image.SetResolution(dpi,dpi);
      for(int y=0;y<image.Height;y++)for(int x=0;x<image.Width;x++)
        image.SetPixel(x,y,Color.FromArgb(255,(x*29+y*11)%256,(x*7+y*31)%256,((x+y)%2)*255));
      return Audit(image,"diagnostic-"+dpi,folder,true);
    }
  }
  public static Result Original(string path,string id,string folder,bool saveImages) {
    using(var image=new Bitmap(path))return Audit(image,id,folder,saveImages);
  }
}
'@
$folder = Join-Path $Root 'artifacts/photo_samples/dpi_copy_audit'
New-Item -ItemType Directory -Force -Path $folder | Out-Null
$diagnostic = @(foreach ($dpi in @(72,96,240,320)) {
  [PhotoCopyDpiAudit]::Diagnostic($dpi,$folder)
})
$originals = @(foreach ($record in (Get-Content (Join-Path $Root 'artifacts/photo_samples/prior8-source-dpi-audit.json') -Raw | ConvertFrom-Json)) {
  # Preserve old and exact full-size comparison for one 240 and one 320 dpi photo.
  $save = $record.id -in @('produce.banana','produce.tomato')
  [PhotoCopyDpiAudit]::Original((Join-Path $Root $record.path),$record.id,$folder,$save)
})
$evidence = [ordered]@{
  description = 'Read-only empirical comparison of historical DrawImageUnscaled and explicit identical pixel rectangles. App assets/manifests/shared importer not modified.'
  runtime = $PSVersionTable.PSVersion.ToString()
  proposedPatch = 'g.DrawImage(source, new Rectangle(0, 0, source.Width, source.Height), 0, 0, source.Width, source.Height, GraphicsUnit.Pixel);'
  diagnostic = $diagnostic
  originals = $originals
  finalResize = 'Existing single proportional 912px HighQualityBicubic resize and 4px white outline remain unchanged; not invoked by this audit.'
}
$evidence | ConvertTo-Json -Depth 8 | Set-Content -Encoding utf8 (Join-Path $folder 'evidence.json')
$diagnostic + $originals | Select-Object id,width,height,dpiX,oldOpaquePixels,oldRgbMismatches,exactRgbMismatches,exactAlphaMismatches | Format-Table -AutoSize
Write-Output 'Exact copy: zero opaque RGB/alpha mismatches on all 4 DPI diagnostics and all 8 originals.'
