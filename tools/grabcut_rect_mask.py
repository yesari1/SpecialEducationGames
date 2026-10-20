"""Classical OpenCV GrabCut cutout from a rectangle (no learned model).

Keeps the original photo RGB; only alpha is estimated. Steps: GrabCut
initialised from the object rectangle, keep the largest foreground component
plus enclosed holes the cut marked as background (e.g. the simit's hole),
1 px alpha feather. Writes a review report next to the output.

    python -I tools/grabcut_rect_mask.py <photo> <out.png> x0 y0 x1 y1 [iterations]
Coordinates are in source pixels. Uses the pinned OpenCV in
artifacts/photo-tools/.deps (see its README).
"""
import hashlib
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'artifacts' / 'photo-tools' / '.deps'))
import cv2  # noqa: E402
import numpy as np  # noqa: E402


def main():
    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    x0, y0, x1, y1 = map(int, sys.argv[3:7])
    iterations = int(sys.argv[7]) if len(sys.argv) > 7 else 6
    image = cv2.imread(str(src), cv2.IMREAD_COLOR)
    h, w = image.shape[:2]
    scale = min(1.0, 1600 / max(h, w))
    small = cv2.resize(image, (round(w * scale), round(h * scale)), interpolation=cv2.INTER_AREA)
    mask = np.zeros(small.shape[:2], np.uint8)
    rect = (round(x0 * scale), round(y0 * scale), round((x1 - x0) * scale), round((y1 - y0) * scale))
    bgd, fgd = np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64)
    cv2.grabCut(small, mask, rect, bgd, fgd, iterations, cv2.GC_INIT_WITH_RECT)
    fg = np.where((mask == cv2.GC_FGD) | (mask == cv2.GC_PR_FGD), 255, 0).astype(np.uint8)
    count, labels, stats, _ = cv2.connectedComponentsWithStats(fg, 8)
    if count > 1:
        largest = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
        fg = np.where(labels == largest, 255, 0).astype(np.uint8)
    fg = cv2.morphologyEx(fg, cv2.MORPH_OPEN, np.ones((3, 3), np.uint8))
    full = cv2.resize(fg, (w, h), interpolation=cv2.INTER_LINEAR)
    alpha = cv2.GaussianBlur(full, (3, 3), 0)
    rgba = cv2.cvtColor(image, cv2.COLOR_BGR2BGRA)
    rgba[:, :, 3] = alpha
    cv2.imwrite(str(out), rgba)
    report = {
        'source': src.name, 'sourceSha256': hashlib.sha256(src.read_bytes()).hexdigest(),
        'output': out.name, 'outputSha256': hashlib.sha256(out.read_bytes()).hexdigest(),
        'method': 'OpenCV GrabCut from rectangle, largest component, 3x3 open, 1 px feather; original RGB kept',
        'rect': [x0, y0, x1, y1], 'iterations': iterations, 'processingScale': scale,
    }
    report_path = out.with_suffix('.report.json')
    if report_path.exists():
        raise SystemExit(f'{report_path} exists; reports are write-once, use a new attempt folder')
    report_path.write_text(json.dumps(report, indent=1), encoding='utf-8')
    print(json.dumps(report))


if __name__ == '__main__':
    main()
