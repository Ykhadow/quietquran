"""The King Fahd Complex's Madani 15-line Mushaf (Hafs) as page images,
straight from the Complex's own PDF of its Mumtaz print.

The Complex published it as `isdarat/hafs/mumtaz.pdf` on qurancomplex.gov.sa,
which can't be reached from outside Saudi Arabia; the Internet Archive keeps
the file exactly as published. Each PDF page holds one lossless image, saved
here untouched (no resizing, no colour changes).

    python tool/kfgqpc_madani.py extract   # download, verify, save pages
    python tool/kfgqpc_madani.py numbers   # sheet of printed page numbers

Pages are saved as hosting/madani-15-kfgqpc/page{NNN}.png, where NNN is the
page in the Madani 604-page layout (1-604).

This is the Complex's revised print (1421H on), not the 1405H one: each page
holds the same ayahs, but some lines break at different words, so pages
can't be matched mark for mark against a 1405H copy as the IndoPak pages
are. `numbers` instead lays out the printed page numbers beside the file
numbers, to read by eye.
"""

import json
import sys

from PIL import Image

import kfgqpc_indopak15 as kf

OUT = kf.ROOT / 'hosting' / 'madani-15-kfgqpc'

PDF_URL = ('https://web.archive.org/web/20240816072852id_/'
           'https://qurancomplex.gov.sa/wp-content/uploads/isdarat/hafs/'
           'mumtaz.pdf')
# The Internet Archive's record of the file: SHA-1 in base 32.
PDF_SHA1 = 'T7RNGUE4TCV257RPYQROJCTDZAPVETYB'
PDF_SIZE = 359883829

PAGES = 604
PDF_PAGES = 640
# PDF page (1-based) of layout page 1 is PDF_OFFSET + 1.
PDF_OFFSET = 3

SECOND_COPY = 'https://files.quran.app/hafs/madani/width_1024/page{:03d}.png'


def pdf():
    import base64
    import hashlib
    import pymupdf
    path = kf.fetch(PDF_URL, kf.CACHE / 'mumtaz.pdf')
    data = path.read_bytes()
    sha1 = base64.b32encode(hashlib.sha1(data).digest()).decode()
    if len(data) != PDF_SIZE or sha1 != PDF_SHA1:
        sys.exit(f'mumtaz.pdf is not the archived file ({len(data)} bytes, '
                 f'SHA-1 {sha1}); delete {path} and try again')
    return pymupdf.open(path)


def extract():
    doc = pdf()
    if doc.page_count != PDF_PAGES:
        sys.exit(f'expected {PDF_PAGES} PDF pages, found {doc.page_count}')
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
    odd = {p: s for p, s in sizes.items() if s != (1816, 2609)}
    print(f'saved {len(sizes)} pages to {OUT}')
    print(f'pages not 1816x2609: {odd}')


def numbers(first=1, last=PAGES, step=13):
    """A sheet of printed page numbers, each beside its file number, to read
    by eye: every page is the right page."""
    from PIL import ImageDraw
    pages = sorted({first, first + 1, last - 1, last,
                    *range(first, last + 1, step)})
    cols, cw, ch = 6, 300, 70
    rows = (len(pages) + cols - 1) // cols
    sheet = Image.new('RGB', (cols * cw, rows * ch), 'white')
    draw = ImageDraw.Draw(sheet)
    for i, p in enumerate(pages):
        x, y = (i % cols) * cw, (i // cols) * ch
        # The number sits under the frame, a little off centre on odd and
        # even pages.
        crop = Image.open(OUT / f'page{p:03d}.png').convert('RGB').crop(
            (608, 2390, 1208, 2475)).resize((240, 34))
        draw.text((x + 4, y + 4), str(p), fill='blue')
        sheet.paste(crop, (x + 50, y + 26))
    path = kf.CACHE / 'madani_numbers.png'
    sheet.save(path)
    print(f'{len(pages)} pages: {path}')


if __name__ == '__main__':
    {'extract': extract, 'numbers': numbers}[sys.argv[1]](
        *map(int, sys.argv[2:]))
