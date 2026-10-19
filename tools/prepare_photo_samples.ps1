param([string]$Root = (Split-Path $PSScriptRoot -Parent), [switch]$LoadOnly)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @('System.Drawing.Common', 'System.Drawing.Primitives', 'System.Private.Windows.GdiPlus', 'System.Private.Windows.Core') -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.Drawing.Drawing2D;
using System.Runtime.InteropServices;
public static class RealPhotoSamples {
  public static string Verify(string path) {
    using(var image=new Bitmap(path)) {
      if(image.Width!=1024||image.Height!=1024||image.PixelFormat!=PixelFormat.Format32bppArgb)
        throw new Exception("Expected 1024x1024 RGBA PNG");
      var data=image.LockBits(new Rectangle(0,0,1024,1024),ImageLockMode.ReadOnly,PixelFormat.Format32bppArgb);
      var pixels=new byte[data.Stride*1024];
      Marshal.Copy(data.Scan0,pixels,0,pixels.Length);
      image.UnlockBits(data);
      int left=1024,top=1024,right=-1,bottom=-1,minAlpha=255,maxAlpha=0,white=0;
      for(int y=0;y<1024;y++)for(int x=0;x<1024;x++) {
        int o=y*data.Stride+x*4,alpha=pixels[o+3];
        minAlpha=Math.Min(minAlpha,alpha);maxAlpha=Math.Max(maxAlpha,alpha);
        if(alpha==0)continue;
        left=Math.Min(left,x);right=Math.Max(right,x);top=Math.Min(top,y);bottom=Math.Max(bottom,y);
        if(pixels[o]==255&&pixels[o+1]==255&&pixels[o+2]==255)white++;
      }
      if(minAlpha!=0||maxAlpha!=255||left<52||top<52||right>971||bottom>971||white==0)
        throw new Exception("Transparency / silhouette padding validation failed");
      return System.IO.Path.GetFileName(path)+": RGBA 1024x1024; alpha=0..255; bounds="+left+","+top+".."+right+","+bottom+"; white pixels="+white;
    }
  }
  private static void AddWhiteOutline(Bitmap canvas, int radius) {
    var data = canvas.LockBits(new Rectangle(0,0,canvas.Width,canvas.Height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
    var original = new byte[data.Stride * canvas.Height];
    Marshal.Copy(data.Scan0, original, 0, original.Length);
    var result = (byte[])original.Clone();
    for(int y=0;y<canvas.Height;y++) for(int x=0;x<canvas.Width;x++) {
      int offset=y*data.Stride+x*4, alpha=original[offset+3];
      if(alpha==255)continue; // Opaque photographed pixels remain unchanged.
      int expanded=alpha;
      for(int dy=-radius;dy<=radius;dy++) for(int dx=-radius;dx<=radius;dx++) {
        if(dx*dx+dy*dy>radius*radius)continue;
        int nx=x+dx, ny=y+dy;
        if(nx<0||ny<0||nx>=canvas.Width||ny>=canvas.Height)continue;
        expanded=Math.Max(expanded,original[ny*data.Stride+nx*4+3]);
      }
      // Composite the original photo over the dilated white alpha mask.
      // This follows the silhouette, never a rectangular frame or redraw.
      double foreground=alpha/255.0, behind=expanded/255.0*(1-foreground);
      double combined=foreground+behind;
      if(combined==0)continue;
      for(int channel=0;channel<3;channel++)
        result[offset+channel]=(byte)Math.Round((original[offset+channel]*foreground+255*behind)/combined);
      result[offset+3]=(byte)Math.Round(combined*255);
    }
    Marshal.Copy(result,0,data.Scan0,result.Length);
    canvas.UnlockBits(data);
  }
  public static void Export(string input, string output, bool removeWhite, bool keepLargest = false) {
    using (var source = new Bitmap(input))
    using (var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb)) {
      using (var g = Graphics.FromImage(bitmap)) {
        g.CompositingMode = CompositingMode.SourceCopy;
        // Copy decoded pixels 1:1, independent of source physical DPI.
        g.DrawImage(source, new Rectangle(0, 0, source.Width, source.Height),
          0, 0, source.Width, source.Height, GraphicsUnit.Pixel);
      }
      int width = bitmap.Width, height = bitmap.Height;
      var data = bitmap.LockBits(new Rectangle(0,0,width,height), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
      var pixels = new byte[data.Stride * height];
      Marshal.Copy(data.Scan0, pixels, 0, pixels.Length);
      if (removeWhite) {
        // Remove only neutral white pixels connected to the image border.
        // Preserve the photographed banana RGB; no generative fill or repainting.
        var background = new bool[width * height];
        var queue = new int[width * height];
        int head = 0, tail = 0;
        Action<int> visit = index => {
          if (background[index]) return;
          int offset = (index / width) * data.Stride + (index % width) * 4;
          int b = pixels[offset], g = pixels[offset+1], r = pixels[offset+2];
          int low = Math.Min(r,Math.Min(g,b)), high = Math.Max(r,Math.Max(g,b));
          if (low < 225 || high-low > 22) return;
          background[index] = true; queue[tail++] = index;
        };
        for(int x=0;x<width;x++){visit(x);visit((height-1)*width+x);}
        for(int y=0;y<height;y++){visit(y*width);visit(y*width+width-1);}
        while(head<tail){
          int i=queue[head++], x=i%width, y=i/width;
          if(x>0)visit(i-1); if(x+1<width)visit(i+1);
          if(y>0)visit(i-width); if(y+1<height)visit(i+width);
        }
        for(int i=0;i<background.Length;i++)
          if(background[i]) pixels[(i/width)*data.Stride+(i%width)*4+3]=0;
      }
      if (keepLargest) {
        // Remove disconnected background specks only; preserve the largest
        // photographed silhouette and every pixel connected to it.
        var labels = new int[width*height];
        var queue = new int[width*height];
        int label=0, largest=0, largestCount=0;
        for(int start=0;start<labels.Length;start++) {
          if(labels[start]!=0 || pixels[(start/width)*data.Stride+(start%width)*4+3]==0)continue;
          label++; int head=0,tail=1; queue[0]=start; labels[start]=label;
          while(head<tail) {
            int i=queue[head++], x=i%width,y=i/width;
            for(int dy=-1;dy<=1;dy++)for(int dx=-1;dx<=1;dx++) {
              int nx=x+dx,ny=y+dy;
              if(nx<0||ny<0||nx>=width||ny>=height)continue;
              int next=ny*width+nx;
              if(labels[next]!=0||pixels[ny*data.Stride+nx*4+3]==0)continue;
              labels[next]=label;queue[tail++]=next;
            }
          }
          if(tail>largestCount){largestCount=tail;largest=label;}
        }
        for(int i=0;i<labels.Length;i++)if(labels[i]!=largest)
          pixels[(i/width)*data.Stride+(i%width)*4+3]=0;
      }
      int left=width,top=height,right=-1,bottom=-1;
      for(int y=0;y<height;y++) for(int x=0;x<width;x++) {
        if(pixels[y*data.Stride+x*4+3]==0)continue;
        left=Math.Min(left,x);right=Math.Max(right,x);
        top=Math.Min(top,y);bottom=Math.Max(bottom,y);
      }
      Marshal.Copy(pixels,0,data.Scan0,pixels.Length);
      bitmap.UnlockBits(data);
      if(right<left)throw new Exception("No foreground found");
      var crop = new Rectangle(left,top,right-left+1,bottom-top+1);
      // 912 px photograph + 4 px contour on each side = at most 920 px.
      const int canvasSize=1024, available=912;
      double scale=Math.Min((double)available/crop.Width,(double)available/crop.Height);
      int outWidth=(int)Math.Round(crop.Width*scale),outHeight=(int)Math.Round(crop.Height*scale);
      using(var canvas=new Bitmap(canvasSize,canvasSize,PixelFormat.Format32bppArgb))
      using(var g=Graphics.FromImage(canvas))
      using(var attributes=new ImageAttributes()) {
        g.Clear(Color.Transparent);
        g.CompositingMode=CompositingMode.SourceCopy;
        g.CompositingQuality=CompositingQuality.HighQuality;
        g.InterpolationMode=InterpolationMode.HighQualityBicubic;
        g.PixelOffsetMode=PixelOffsetMode.HighQuality;
        attributes.SetWrapMode(WrapMode.TileFlipXY);
        g.DrawImage(bitmap,new Rectangle((canvasSize-outWidth)/2,(canvasSize-outHeight)/2,outWidth,outHeight),crop.X,crop.Y,crop.Width,crop.Height,GraphicsUnit.Pixel,attributes);
        AddWhiteOutline(canvas,4);
        canvas.Save(output,ImageFormat.Png);
      }
    }
  }
}
'@
if ($LoadOnly) { return }
$sampleFolder = Join-Path $Root 'artifacts/photo_samples'
[RealPhotoSamples]::Export((Join-Path $sampleFolder 'source/cat-van-transparent.png'), (Join-Path $sampleFolder 'cat-1024.png'), $false)
[RealPhotoSamples]::Export((Join-Path $sampleFolder 'source/banana-evan-amos.jpg'), (Join-Path $sampleFolder 'banana-1024.png'), $true)
[RealPhotoSamples]::Export((Join-Path $sampleFolder 'source/apple-honeycrisp.jpg'), (Join-Path $sampleFolder 'apple-1024.png'), $true)
[RealPhotoSamples]::Verify((Join-Path $sampleFolder 'cat-1024.png'))
[RealPhotoSamples]::Verify((Join-Path $sampleFolder 'banana-1024.png'))
[RealPhotoSamples]::Verify((Join-Path $sampleFolder 'apple-1024.png'))
Write-Output 'Exported three real-photo PNG samples at 1024 x 1024.'
