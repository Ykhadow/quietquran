"""The King Fahd Complex's IndoPak 15-line Mushaf as page images, straight
from the Complex's own PDF, checked page by page.

The Complex published the Mushaf as `isdarat/hafs/nastaleeq.pdf` on
qurancomplex.gov.sa, which can't be reached from outside Saudi Arabia; the
Internet Archive keeps the file exactly as published. Each PDF page holds one
lossless image, saved here untouched (no resizing, no colour changes).

    python tool/kfgqpc_indopak15.py extract   # download, verify, save pages
    python tool/kfgqpc_indopak15.py mapping   # every page is the right page
    python tool/kfgqpc_indopak15.py check     # compare line by line
    python tool/kfgqpc_indopak15.py check 1 150   # just those pages

Pages are saved as hosting/indopak-15-kfgqpc/page{NNN}.png, where NNN is the
page in the app's IndoPak 15-line layout (1-610).

Both checks compare with the copy Quran for Android serves (the same Mushaf,
made independently). `mapping` matches every mark inside a page's frame
against the second copy's same page and the pages either side: the page's
own must match far better, so the numbering is right and no page is
missing, repeated or damaged. `check` compares line by line and lists marks
in one copy but not the other; the copies place short lines, surah titles
and some marks a little differently, so what it lists needs looking at by
eye.
"""

import base64
import hashlib
import io
import json
import sys
import time
import urllib.request
from pathlib import Path

import numpy as np
import pymupdf
from PIL import Image
from scipy import ndimage as nd

ROOT = Path(__file__).resolve().parent.parent
CACHE = ROOT / 'tool' / '.cache' / 'kfgqpc'
OUT = ROOT / 'hosting' / 'indopak-15-kfgqpc'

PDF_URL = ('https://web.archive.org/web/20250126140752id_/'
           'https://qurancomplex.gov.sa/wp-content/uploads/isdarat/hafs/'
           'nastaleeq.pdf')
# The Internet Archive's record of the file: SHA-1 in base 32.
PDF_SHA1 = 'YXOJYSGFSJGO7VH3NRYRIXMIEZZNRCSK'
PDF_SIZE = 206630417

PAGES = 610
# PDF page (1-based) of layout page 1; before it are the covers and front
# matter, after the last page the closing du'a and colophon.
PDF_OFFSET = 5

SECOND_COPY = 'https://files.quran.app/hafs/naskh/width_1280/page{:03d}.png'
SECOND_OFFSET = 1  # file N+1 is layout page N
EDGE = 12  # pixels at a line's edges not compared


def fetch(url, path):
    if not path.exists():
        path.parent.mkdir(parents=True, exist_ok=True)
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        # Hosts time out now and then; try a few times before giving up.
        for attempt in range(5):
            try:
                with urllib.request.urlopen(req, timeout=600) as r:
                    path.write_bytes(r.read())
                break
            except (urllib.error.URLError, TimeoutError):
                if attempt == 4:
                    raise
                time.sleep(10 * (attempt + 1))
    return path


def pdf():
    path = fetch(PDF_URL, CACHE / 'nastaleeq.pdf')
    data = path.read_bytes()
    sha1 = base64.b32encode(hashlib.sha1(data).digest()).decode()
    if len(data) != PDF_SIZE or sha1 != PDF_SHA1:
        sys.exit(f'nastaleeq.pdf is not the archived file ({len(data)} bytes, '
                 f'SHA-1 {sha1}); delete {path} and try again')
    return pymupdf.open(path)


def extract():
    doc = pdf()
    if doc.page_count != PAGES + 14:
        sys.exit(f'expected {PAGES + 14} PDF pages, found {doc.page_count}')
    OUT.mkdir(parents=True, exist_ok=True)
    sizes = {}
    for p in range(1, PAGES + 1):
        page = doc[p + PDF_OFFSET - 1]
        images = page.get_images()
        if len(images) != 1:
            sys.exit(f'page {p}: expected one image, found {len(images)}')
        info = doc.extract_image(images[0][0])
        # Flate-compressed images come out as PNG: the stored pixels, exactly.
        if info['ext'] != 'png':
            sys.exit(f'page {p}: stored as {info["ext"]}, not lossless')
        (OUT / f'page{p:03d}.png').write_bytes(info['image'])
        sizes[p] = (info['width'], info['height'])
    manifest = {
        'source': 'King Fahd Glorious Quran Printing Complex, Madinah',
        'file': PDF_URL,
        'sha1_base32': PDF_SHA1,
        'pdf_page_of_page_1': PDF_OFFSET + 1,
        'pages': {p: list(s) for p, s in sizes.items()},
    }
    (OUT / 'manifest.json').write_text(json.dumps(manifest, indent=1))
    odd = {p: s for p, s in sizes.items() if s != (1532, 2189)}
    print(f'saved {len(sizes)} pages to {OUT}')
    print(f'pages not 1532x2189: {odd}')


# --- check ---------------------------------------------------------------

def ink(img):
    """Text ink: dark and colourless. The two copies have different coloured
    borders, which this leaves out."""
    rgb = np.asarray(img.convert('RGB')).astype(np.int16)
    dark = rgb.max(axis=2) < 150
    grey = (rgb.max(axis=2) - rgb.min(axis=2)) < 40
    return dark & grey


def second_copy(p):
    path = fetch(SECOND_COPY.format(p + SECOND_OFFSET),
                 CACHE / 'naskh' / f'page{p + SECOND_OFFSET:03d}.png')
    img = Image.open(path).convert('RGBA')
    white = Image.new('RGBA', img.size, 'white')
    white.alpha_composite(img)
    return white


def lines(mask):
    """The ruled text lines of a page, top to bottom, as (top, bottom, left,
    right) boxes inside the frame. The two copies have different borders
    and margins, so pages are compared line by line."""
    h, w = mask.shape
    across = mask[:, int(w * .3):int(w * .7)].mean(axis=1)
    rules = []
    # Rules span the width (Quran for Android's copy has small breaks in
    # them); a line of text never covers more than about two thirds.
    for r in np.where(across > 0.75)[0]:
        if rules and r - rules[-1][1] <= 2:
            rules[-1][1] = r
        else:
            rules.append([r, r])
    out = []
    for (_, top), (bottom, _) in zip(rules, rules[1:]):
        # Skip border strips and empty space (a short last page).
        if bottom - top < 0.04 * h:
            continue
        band = mask[top + 4:bottom - 3]
        if band[:, int(w * .3):int(w * .7)].mean() < 0.01:
            continue
        # The frame's sides: the innermost full-height lines either side of
        # the middle (ruku marks in the margin lie outside them).
        down = band.mean(axis=0) > 0.9
        left = max([x for x in range(w // 2) if down[x]], default=0)
        right = min([x for x in range(w // 2, w) if down[x]], default=w - 1)
        out.append((top + 4, bottom - 3, left + 4, right - 3))
    return out


def ink_box(mask):
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    return mask[rows[0]:rows[-1] + 1, cols[0]:cols[-1] + 1]


def aligned(a, b):
    """Line [a] scaled to line [b]'s ink extent and nudged to the best
    overlap."""
    a, b = ink_box(a), ink_box(b)
    img = Image.fromarray(a.astype(np.uint8) * 255)
    a = np.asarray(img.resize((b.shape[1], b.shape[0]), Image.BILINEAR)) > 100
    # The copies space words a little differently, so each stretch of the
    # line finds its own small shift. A shift moves a whole stretch, so it
    # can't make a single mark appear or disappear.
    out = np.zeros_like(a)
    step, my, mx = 120, 10, 30
    # Shifts move ink into blank margins, never round from the other edge.
    padded = np.pad(a, ((my, my), (mx, mx)))
    h, w = a.shape
    for x0 in range(0, w, step):
        x1 = min(w, x0 + step)
        best = (-1, None)
        for dy in range(-my, my + 1):
            for dx in range(-mx, mx + 1, 2):
                moved = padded[my - dy:my - dy + h, mx - dx + x0:mx - dx + x1]
                s = (moved & b[:, x0:x1]).sum()
                if s > best[0]:
                    best = (s, moved)
        out[:, x0:x1] = best[1]
    return out, b


def marks(mask, min_area):
    labels, _ = nd.label(mask)
    out = []
    for i, box in enumerate(nd.find_objects(labels), 1):
        mark = labels[box] == i
        area = int(mark.sum())
        if area >= min_area:
            cy, cx = nd.center_of_mass(mark)
            out.append((box, mark, area, box[1].start + cx, box[0].start + cy))
    return out


def lone_marks(a, b, tolerance=3, reach=10, min_area=12):
    """Marks of [a] missing from [b]: neither covered by [b]'s ink nor
    matched by a mark of [b] of similar size within [reach] pixels (the
    copies place some marks a few pixels apart)."""
    near = nd.binary_dilation(b, iterations=tolerance)
    theirs = marks(b, min_area // 2)
    found = []
    for box, mark, area, x, y in marks(a, min_area):
        if (mark & near[box]).sum() >= 0.6 * area:
            continue
        if any(abs(x - tx) <= reach and abs(y - ty) <= reach
               and 0.5 <= area / ta <= 2 for _, _, ta, tx, ty in theirs):
            continue
        found.append((int(x), int(y), area))
    return found


def frame_marks(mask):
    """Every mark inside a page's frame, as (x, y) in 0-1 of the frame, and
    its area as a share of the frame."""
    ls = lines(mask)
    if ls:
        top, bottom = ls[0][0], ls[-1][1]
        left, right = min(l[2] for l in ls), max(l[3] for l in ls)
        mask = mask[top:bottom, left:right]
    h, w = mask.shape
    return np.array([(x / w, y / h, area / (w * h))
                     for _, _, area, x, y in marks(mask, 12)])


def unmatched_share(a, b, xtol=0.03, ytol=0.012):
    """Share of marks in [a] and [b] left without a partner of similar size
    at about the same place."""
    from scipy.spatial import cKDTree
    tree = cKDTree(b[:, :2] / (xtol, ytol))
    used = set()
    matched = 0
    for x, y, s in a:
        for j in sorted(tree.query_ball_point((x / xtol, y / ytol), 1.0),
                        key=lambda j: abs(b[j, 0] - x) + abs(b[j, 1] - y)):
            if j not in used and 0.5 <= s / b[j, 2] <= 2:
                used.add(j)
                matched += 1
                break
    return 1 - 2 * matched / (len(a) + len(b))


def mapping(first=1, last=PAGES):
    """Each page must match its own page in the second copy far better than
    the pages either side: the numbering is right and no page is missing,
    repeated or damaged."""
    theirs = {}

    def copy(q):
        if q not in theirs:
            theirs[q] = frame_marks(ink(second_copy(q)))
        return theirs[q]

    worst = []
    for p in range(first, last + 1):
        ours = frame_marks(ink(Image.open(OUT / f'page{p:03d}.png')))
        own = unmatched_share(ours, copy(p))
        others = {q: unmatched_share(ours, copy(q))
                  for q in (p - 1, p + 1) if 1 <= q <= PAGES}
        closest = min(others.values())
        ok = own < 0.5 * closest
        worst.append((own / closest, p))
        print(f'page {p:3d}  own {own:.3f}  neighbours '
              + ' '.join(f'{q}:{v:.3f}' for q, v in others.items())
              + ('' if ok else '  CHECK'), flush=True)
    worst.sort(reverse=True)
    print('\nclosest calls (own / best neighbour):',
          [(p, round(r, 2)) for r, p in worst[:10]])


def check(first=1, last=PAGES):
    results = {}
    review = []
    for p in range(first, last + 1):
        path = OUT / f'page{p:03d}.png'
        if not path.exists():
            sys.exit('run extract first')
        ours = ink(Image.open(path))
        theirs = ink(second_copy(p))
        ol, tl = lines(ours), lines(theirs)
        if len(ol) != len(tl) or not ol:
            results[p] = {'lines': [len(ol), len(tl)]}
            review.append(p)
            print(f'page {p:3d}  lines {len(ol)} vs {len(tl)}: review by eye',
                  flush=True)
            continue
        page = []
        for n, ((a0, a1, a2, a3), (b0, b1, b2, b3)) in enumerate(zip(ol, tl), 1):
            a, b = aligned(ours[a0:a1, a2:a3], theirs[b0:b1, b2:b3])
            h, w = b.shape

            def inner(found):
                # Marks at the line's edges can be cut off differently in
                # each copy (by the frame or a rule); those are left out.
                return [m for m in found
                        if EDGE < m[0] < w - EDGE and EDGE < m[1] < h - EDGE]

            only_ours = inner(lone_marks(a, b))
            only_theirs = inner(lone_marks(b, a))
            if only_ours or only_theirs:
                page.append({'line': n, 'only_ours': only_ours,
                             'only_theirs': only_theirs})
        results[p] = {'lines': len(ol), 'differences': page}
        if page:
            review.append(p)
        note = ', '.join(
            f"line {d['line']}: {len(d['only_ours'])}+{len(d['only_theirs'])}"
            for d in page)
        print(f'page {p:3d}  {len(ol)} lines  {note or "identical marks"}',
              flush=True)
    (CACHE / f'check_{first}_{last}.json').write_text(
        json.dumps(results, indent=1))
    total = last - first + 1
    print(f'\n{total - len(review)} of {total} pages match mark for mark; '
          f'to review: {review}')


if __name__ == '__main__':
    {'extract': extract, 'check': check, 'mapping': mapping}[sys.argv[1]](
        *map(int, sys.argv[2:]))
