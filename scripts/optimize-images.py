#!/usr/bin/env python3
"""
optimize-images.py — keep smartlawnny.com fast.

Walks the repo, recompresses any image > 150 KB in place using
sensible defaults. Files that would get BIGGER from re-encoding are
skipped. Maintains the existing filename so no HTML refs break.

For best results install pngquant + cwebp; this falls back to Pillow.
Run locally or via .github/workflows/optimize-images.yml on push.
"""
from pathlib import Path
from PIL import Image, ImageFile
ImageFile.LOAD_TRUNCATED_IMAGES = True

MAX_WIDTH    = 1920      # plenty for any retina layout
MIN_TARGET   = 150_000   # only bother touching files over this size
JPG_QUALITY  = 85
WEBP_QUALITY = 88

SKIP_DIRS = {'.git', 'node_modules', '_bm-reference', '.github'}

savings = 0
for p in Path('.').rglob('*'):
    if not p.is_file(): continue
    if any(part in SKIP_DIRS for part in p.parts): continue
    if p.suffix.lower() not in ('.png','.jpg','.jpeg','.webp'): continue
    if p.stat().st_size < MIN_TARGET: continue

    before = p.stat().st_size
    try:
        im = Image.open(p)
        if p.suffix.lower() == '.png':
            im = im.convert('RGBA')
        else:
            im = im.convert('RGB')
        w,h = im.size
        if w > MAX_WIDTH:
            im = im.resize((MAX_WIDTH, int(h * MAX_WIDTH / w)), Image.LANCZOS)
        tmp = p.with_suffix(p.suffix + '.tmp')
        ext = p.suffix.lower()
        if ext == '.png':
            im.save(tmp, format='PNG', optimize=True)
        elif ext in ('.jpg','.jpeg'):
            im.save(tmp, format='JPEG', quality=JPG_QUALITY, optimize=True, progressive=True)
        elif ext == '.webp':
            im.save(tmp, format='WEBP', quality=WEBP_QUALITY, method=6)
        after = tmp.stat().st_size
        if after < before:
            tmp.replace(p)
            print(f"  {p}: {before//1024} KB → {after//1024} KB ({100*(before-after)//before}%)")
            savings += (before - after)
        else:
            tmp.unlink()
            print(f"  skip (no win): {p}")
    except Exception as e:
        print(f"  err {p}: {e}")

print(f"\nTotal saved: {savings/1024:.0f} KB")
