"""Checks that no letter or mark of a Mushaf page line touches the line above
or below it, for every page of every edition and typeface, across screen
shapes from tablets (text sized by the page height) to tall phones (sized by
the width, so lines have room to grow).

It lays out every line as QuranLinePainter does (0.18em minimum gap, justified,
lines with room to spare grown up to the app's limit) and compares the ink
boxes of every glyph (from HarfBuzz, with the bundled fonts) in neighbouring
lines. Run it after changing QuranTypeface.lineFill, the growth rule in
mushaf_text_page.dart, the word gap, or the fonts:

    python tool/check_line_spacing.py

Prints each case and exits non-zero if any glyphs collide.
"""
import os
import sqlite3
import sys

import uharfbuzz as hb

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DB = os.path.join(ROOT, "assets", "db", "quran.db")
FONTS = os.path.join(ROOT, "assets", "fonts")

# Must match the app.
GAP = 0.18  # QuranLinePainter._gap
MAX_GROW = 1.3  # _maxGrow in mushaf_text_page.dart
GROW_MARGIN = 0.96  # the growth rule's safety margin, same file
TYPEFACES = {  # column -> (font file, QuranTypeface.lineFill, drawn markers)
    "indopak": ("IndoPakNastaleeq.ttf", 0.55, False),
    "qpc_nastaleeq": ("KFGQPCNastaleeq.ttf", 0.55, True),
    "madani": ("UthmanicHafs.ttf", 0.56, False),
}
# Line height / base font size: from text sized by height (1 / lineFill) up
# to tall phones.
SHAPES = [1.9, 1.95, 2.0, 2.05, 2.1, 2.2, 2.3, 2.45, 2.6]

db = sqlite3.connect(DB)
columns = ["id", "is_end"] + list(TYPEFACES)
words = db.execute(f"SELECT {', '.join(columns)} FROM words ORDER BY id").fetchall()


def measurer(font_file):
    face = hb.Face(hb.Blob.from_file_path(os.path.join(FONTS, font_file)))
    font = hb.Font(face)
    upem = face.upem
    cache = {}

    def measure(text):
        """(advance, ink above baseline, ink below, glyph boxes) in em."""
        if text not in cache:
            buf = hb.Buffer()
            buf.add_str(text)
            buf.guess_segment_properties()
            hb.shape(font, buf, {})
            top = bottom = advance = 0
            glyphs = []
            for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
                ext = font.get_glyph_extents(info.codepoint)
                if ext is not None and ext.width:
                    y0 = pos.y_offset + ext.y_bearing
                    y1 = y0 + ext.height
                    x0 = advance + pos.x_offset + ext.x_bearing
                    glyphs.append((x0 / upem, (x0 + ext.width) / upem, y0 / upem, -y1 / upem))
                    top, bottom = max(top, y0), min(bottom, y1)
                advance += pos.x_advance
            cache[text] = (advance / upem, top / upem, -bottom / upem, glyphs)
        return cache[text]

    return measure


def check(edition, column):
    font_file, fill, drawn_markers = TYPEFACES[column]
    measure = measurer(font_file)
    ci = columns.index(column)

    def text(w):
        t = w[ci]
        if drawn_markers and w[1]:  # the app draws U+06DD, then any sign
            digits = len(t) - len(t.lstrip("٠١٢٣٤٥٦٧٨٩"))
            t = "۝" + t[digits:]
        return t

    sizes = [measure(text(w)) for w in words]
    ends = [w[1] for w in words]
    # Extra space after words whose ink would touch the next word's (Word.gapAfter).
    extra = dict(db.execute("SELECT id, extra FROM word_gap WHERE column_name = ?", (column,)))
    fit = db.execute(
        "SELECT width FROM line_fit WHERE edition = ? AND column_name = ?", (edition, column)
    ).fetchone()[0] / 100
    rows = db.execute(
        "SELECT page, line, centered, first_word, last_word FROM lines "
        "WHERE edition = ? AND kind = 0 ORDER BY page, line", (edition,)
    ).fetchall()

    def layout(first, last, centered, max_grow):
        ws = sizes[first - 1:last]
        glued = ends[first:last]  # a gap before a marker doesn't stretch
        gaps = [GAP + extra.get(i, 0.0) for i in range(first, last)]
        natural = sum(w[0] for w in ws) + sum(gaps)
        fits = fit / natural
        scale = fits if fits < 1 else (1.0 if centered else min(fits, max_grow))
        free = sum(1 for g in glued if not g)
        stretch = max(0, fit / scale - natural) / free if not centered and free else 0
        x = fit if not centered or scale < 1 else fit - (fit - natural) / 2
        out = []
        for i, (advance, top, below, glyphs) in enumerate(ws):
            if i:
                x -= (gaps[i - 1] + (0 if glued[i - 1] else stretch)) * scale
            left = x - advance * scale
            out.append((left, x, top * scale, below * scale,
                        [(left + a * scale, left + b * scale, t * scale, d * scale)
                         for a, b, t, d in glyphs]))
            x -= advance * scale
        return out

    failures = 0
    for shape in [1 / fill] + [s for s in SHAPES if s > 1 / fill]:
        max_grow = max(1.0, min(MAX_GROW, shape * fill * GROW_MARGIN))
        lines = {(p, n): layout(fw, lw, c, max_grow) for p, n, c, fw, lw in rows}
        hits = set()
        for (page, n), above in lines.items():
            below = lines.get((page, n + 1))
            if not below:
                continue
            for l1, r1, _, d1, g1 in above:
                for l2, r2, t2, _, g2 in below:
                    if not (l1 < r2 and l2 < r1 and d1 + t2 > shape):
                        continue
                    if any(a0 < b1 and b0 < a1 and ad + bt > shape
                           for a0, a1, _, ad in g1 for b0, b1, bt, _ in g2):
                        hits.add((page, n))
        status = "ok" if not hits else f"COLLISIONS on {sorted(hits)[:5]}"
        print(f"{edition:24} {column:14} spacing {shape:.2f}x, grow up to {max_grow:.2f}: {status}",
              flush=True)
        failures += len(hits)
    return failures


failures = 0
for (edition, script) in db.execute("SELECT id, script FROM editions ORDER BY sort").fetchall():
    for column in (["madani"] if script == "madani" else ["indopak", "qpc_nastaleeq"]):
        failures += check(edition, column)
sys.exit(1 if failures else 0)
