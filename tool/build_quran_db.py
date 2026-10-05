"""Builds assets/db/quran.db — the offline database bundled with the app.

All Quranic text, layouts and metadata come from QUL — the Quranic Universal
Library (qul.tarteel.ai), a proofread source. Files are downloaded by hand
(free login) into tool/qul/:
    <layout>.db            Mushaf layouts: which word ids sit on each line.
    scripts/*.db           Word-by-word Quran text, one row per word id.
    metadata/*/*.sqlite    Surah names, juz/hizb/rub/manzil/ruku/sajda.

The only non-QUL inputs (UI conveniences, not Quran text):
  api.quran.com v4     English meanings of surah names ("The Opener"); cached.
  GitHub API           File list of the Taj 16-line page images; cached.

Every source used is recorded in the `sources` table of the output.

Every QUL script shares the same word ids (1..83668, ayah-end markers
included), so one `words` table carries each script's text as a column.

Usage:  python tool/build_quran_db.py
"""

import json
import math
import os
import sqlite3
import sys
import time
import urllib.request

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
QUL = os.path.join(ROOT, "tool", "qul")
CACHE = os.path.join(ROOT, "tool", ".cache")
OUT = os.path.join(ROOT, "assets", "db", "quran.db")
API = "https://api.quran.com/api/v4"

# Word text columns -> (QUL script file, QUL resource page).
SCRIPTS = {
    "indopak": ("scripts/indopak-nastaleeq.db", "quran-script/59"),
    "qpc_nastaleeq": ("scripts/qpc-nastaleeq.db", "quran-script/52"),
    "madani": ("scripts/qpc-hafs-word-by-word.db", "quran-script/312"),
}

# QUL metadata files -> resource page.
METADATA = {
    "surahs": ("metadata/70/quran-metadata-surah-name.sqlite", "quran-metadata/70"),
    "ayahs": ("metadata/69/quran-metadata-ayah.sqlite", "quran-metadata/69"),
    "juz": ("metadata/68/quran-metadata-juz.sqlite", "quran-metadata/68"),
    "hizb": ("metadata/67/quran-metadata-hizb.sqlite", "quran-metadata/67"),
    "rub": ("metadata/63/quran-metadata-rub.sqlite", "quran-metadata/63"),
    "manzil": ("metadata/66/quran-metadata-manzil.sqlite", "quran-metadata/66"),
    "ruku": ("metadata/65/quran-metadata-ruku.sqlite", "quran-metadata/65"),
    "sajda": ("metadata/64/quran-metadata-sajda.sqlite", "quran-metadata/64"),
}

# Text editions: (id, display name, script, QUL layout file, QUL resource page).
EDITIONS = [
    ("indopak-15-qudratullah", "15-line · Qudratullah", "indopak", "qudratullah-indopak-15-lines.db", "mushaf-layout/12"),
    ("indopak-16-taj", "16-line · Taj Company", "indopak", "taj-indopak-16-lines.db", "mushaf-layout/11"),
    ("indopak-13-qudratullah", "13-line · Qudratullah", "indopak", "indopak-13-lines-layout-qudratullah.db", "mushaf-layout/236"),
    ("indopak-13-taj", "13-line · Taj Company", "indopak", "indopak-13-lines-taj-company.db", "mushaf-layout/313"),
    ("indopak-9-gaba", "9-line · Gaba (large print)", "indopak", "indopak-9-lines-gaba.db", "mushaf-layout/571"),
    ("madani-1405", "1405H · KFGQPC V1", "madani", "qpc-v1-15-lines.db", "mushaf-layout/15"),
    ("madani-1421", "1421H · KFGQPC V2", "madani", "qpc-v2-15-lines.db", "mushaf-layout/10"),
]

QUL_URL = "https://qul.tarteel.ai/resources/"

# Translations (QUL "simple" JSON: {"surah:ayah": {"t": text}}, no footnotes):
# id, language, translator, QUL resource id, file under tool/qul/translations.
# Saheeh International is under publisher copyright: fine for development;
# confirm the publisher's permission before any public release.
TRANSLATIONS = [
    ("en-sahih", "en", "Saheeh International", 193,
     "193/simple/en-sahih-international-simple.json"),
    ("ur-jalandhari", "ur", "Fateh Muhammad Jalandhari", 218,
     "218/simple/ur-fatah-muhammad-jalandhari-simple.json"),
]

# Bundled font for each word-text column (must match lib/core/settings.dart).
FONTS = {
    "indopak": "assets/fonts/IndoPakNastaleeq.ttf",
    "qpc_nastaleeq": "assets/fonts/KFGQPCNastaleeq.ttf",
    "madani": "assets/fonts/UthmanicHafs.ttf",
}
# Columns whose ayah-end markers the app draws (U+06DD ornament + digits).
DRAWN_MARKERS = {"qpc_nastaleeq"}
# Smallest space between words, as a share of the font size
# (QuranLinePainter._gap in lib/features/reader/quran_line.dart).
WORD_GAP = 0.18
# Some words' signs reach past the word's edge (a waqf sign after an inner
# space, a long madd, a returning tail); where that ink meets the next word's
# ink at the same height, the pair gets this much clear space (em) instead of
# the plain gap. Less between a word and its own ayah marker, which sits close
# to it in print. Heights are compared in bands of WORD_BAND em.
WORD_CLEAR = 0.12
MARKER_CLEAR = 0.04
WORD_BAND = 0.1
# Reference size the widths are stored at.
REF_SIZE = 100.0

LINE_KIND = {"ayah": 0, "surah_name": 1, "basmallah": 2}

TAJ_IMAGES_TREE = (
    "https://api.github.com/repos/legeRise/quran-indopak-ayah-coordinates/git/trees/main?recursive=1"
)


def fetch_json(url, cache_name):
    path = os.path.join(CACHE, cache_name)
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    for attempt in range(5):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": "mushaf15-build"})
            with urllib.request.urlopen(req, timeout=60) as r:
                data = json.load(r)
            break
        except Exception as e:  # noqa: BLE001 - retry any transient failure
            if attempt == 4:
                raise
            print(f"  retry {cache_name}: {e}", file=sys.stderr)
            time.sleep(2 * (attempt + 1))
    os.makedirs(CACHE, exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False)
    return data


def qul(rel):
    return sqlite3.connect(os.path.join(QUL, rel))


def ayah_metadata():
    """(surah, ayah) -> [juz, hizb, rub, ruku, manzil, sajdah], from QUL."""
    keys = [
        tuple(map(int, k.split(":")))
        for (k,) in qul(METADATA["ayahs"][0]).execute("SELECT verse_key FROM verses ORDER BY id")
    ]
    assert len(keys) == 6236, len(keys)
    meta = {k: [None] * 6 for k in keys}
    groups = [("juz", "juz", 0), ("hizb", "hizbs", 1), ("rub", "rub", 2),
              ("ruku", "ruku", 3), ("manzil", "manzil", 4)]
    for name, table, col in groups:
        rows = qul(METADATA[name][0]).execute(f"SELECT {name}_number, verse_mapping FROM {table}")
        for number, mapping in rows:
            for surah, span in json.loads(mapping).items():
                lo, hi = map(int, span.split("-")) if "-" in span else (int(span), int(span))
                for ayah in range(lo, hi + 1):
                    meta[(int(surah), ayah)][col] = number
    for number, key in qul(METADATA["sajda"][0]).execute("SELECT sajdah_number, verse_key FROM sajdah"):
        meta[tuple(map(int, key.split(":")))][5] = number
    missing = [k for k, v in meta.items() if None in v[:5]]
    assert not missing, f"ayahs without metadata: {missing[:5]}"
    return meta


def build():
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    if os.path.exists(OUT):
        os.remove(OUT)
    db = sqlite3.connect(OUT)
    db.executescript(
        """
        CREATE TABLE meta(key TEXT PRIMARY KEY, value TEXT);
        CREATE TABLE surahs(
          id INTEGER PRIMARY KEY, name_arabic TEXT, name_simple TEXT,
          name_translated TEXT, revelation_place TEXT, verses_count INTEGER);
        CREATE TABLE ayahs(
          surah INTEGER, ayah INTEGER, juz INTEGER, hizb INTEGER, rub INTEGER,
          ruku INTEGER, manzil INTEGER, sajdah INTEGER,
          first_word INTEGER, last_word INTEGER,
          PRIMARY KEY(surah, ayah));
        -- One row per word id; the last word of every ayah is its end marker.
        -- One text column per QUL script.
        CREATE TABLE words(
          id INTEGER PRIMARY KEY, surah INTEGER, ayah INTEGER, is_end INTEGER,
          indopak TEXT, qpc_nastaleeq TEXT, madani TEXT);
        -- Provenance of every table: what came from where.
        CREATE TABLE sources(part TEXT, source TEXT, url TEXT);
        CREATE TABLE editions(
          id TEXT PRIMARY KEY, name TEXT, script TEXT, lines_per_page INTEGER,
          pages INTEGER, sort INTEGER);
        -- kind: 0 = text, 1 = surah header, 2 = bismillah.
        -- bismillah_inline = 1 on a header whose surah has no bismillah line of
        -- its own (Taj 16-line, Gaba): the bismillah is drawn inside the header.
        CREATE TABLE lines(
          edition TEXT, page INTEGER, line INTEGER, kind INTEGER,
          centered INTEGER, first_word INTEGER, last_word INTEGER,
          surah INTEGER, bismillah_inline INTEGER,
          PRIMARY KEY(edition, page, line));
        -- Per edition and text column: the natural width (at REF_SIZE, words plus
        -- gaps) that 99% of the edition's justified lines fit in. The app sizes
        -- the text so this width fills the page, giving one font size for the
        -- whole edition; the rare longer line is squeezed slightly.
        CREATE TABLE line_fit(edition TEXT, column_name TEXT, width REAL, max_width REAL,
          PRIMARY KEY(edition, column_name));
        -- Explicit image paths for page sets without a simple URL pattern.
        CREATE TABLE image_paths(image_edition TEXT, page INTEGER, path TEXT,
          PRIMARY KEY(image_edition, page));
        -- Extra space (em) after word [id] and before the next, for pairs whose
        -- ink would otherwise touch; pairs not listed need none.
        CREATE TABLE word_gap(column_name TEXT, id INTEGER, extra REAL,
          PRIMARY KEY(column_name, id)) WITHOUT ROWID;
        -- How close each word and the next may come before their ink touches:
        -- one byte per word (byte i is word i + 1): 128 + the space between
        -- them, in hundredths of an em, at which their ink would just meet; 0
        -- where it can't meet at any height. Lets Easy read set words closer
        -- than the Mushaf pages do.
        CREATE TABLE word_need(column_name TEXT PRIMARY KEY, data BLOB);
        -- How far each word's ink reaches past its box: two bytes per word
        -- (bytes 2i and 2i + 1 are word i + 1), past its left edge and past
        -- its right, in hundredths of an em, rounded up. Lines keep that
        -- room at their ends, so no ink is ever cut off at a page's edge.
        CREATE TABLE word_ink(column_name TEXT PRIMARY KEY, data BLOB);
        -- Translations of the meanings, one text per ayah, used as published.
        CREATE TABLE translations(id TEXT PRIMARY KEY, language TEXT, translator TEXT,
          sort INTEGER);
        CREATE TABLE translation_text(translation TEXT, surah INTEGER, ayah INTEGER,
          text TEXT, PRIMARY KEY(translation, surah, ayah)) WITHOUT ROWID;
        """
    )

    sources = []

    # --- surahs & ayah metadata (QUL; English meanings from Quran.com) ---
    meanings = {
        c["id"]: c["translated_name"]["name"]
        for c in fetch_json(f"{API}/chapters?language=en", "chapters.json")["chapters"]
    }
    db.executemany(
        "INSERT INTO surahs VALUES(?,?,?,?,?,?)",
        [
            (i, name_ar, name_simple, meanings[i], place, count)
            for i, name_simple, name_ar, place, count in qul(METADATA["surahs"][0]).execute(
                "SELECT id, name_simple, name_arabic, revelation_place, verses_count FROM chapters"
            )
        ],
    )
    meta = ayah_metadata()
    for name, (rel, page) in METADATA.items():
        sources.append((f"metadata:{name}", f"QUL {rel}", QUL_URL + page))
    sources.append(("surahs.name_translated", "Quran.com API v4 /chapters (English)",
                    f"{API}/chapters?language=en"))

    # --- words (QUL scripts) ---
    texts = {}
    locations = None
    for column, (rel, page) in SCRIPTS.items():
        rows = qul(rel).execute("SELECT id, surah, ayah, text FROM words ORDER BY id").fetchall()
        locs = [(r[0], r[1], r[2]) for r in rows]
        if locations is None:
            locations = locs
        assert locs == locations, f"{rel}: word ids differ from the other scripts"
        # Trim stray whitespace (e.g. two NBSPs after 6:1:1 in qpc-nastaleeq).
        texts[column] = [r[3].strip() for r in rows]
        sources.append((f"words.{column}", f"QUL {rel}", QUL_URL + page))
    first_word, last_word = {}, {}
    for wid, s, a in locations:
        first_word.setdefault((s, a), wid)
        last_word[(s, a)] = wid
    db.executemany(
        "INSERT INTO words VALUES(?,?,?,?,?,?,?)",
        [
            (wid, s, a, int(last_word[(s, a)] == wid),
             texts["indopak"][i], texts["qpc_nastaleeq"][i], texts["madani"][i])
            for i, (wid, s, a) in enumerate(locations)
        ],
    )
    db.executemany(
        "INSERT INTO ayahs VALUES(?,?,?,?,?,?,?,?,?,?)",
        [(s, a, *meta[(s, a)], first_word[(s, a)], last_word[(s, a)]) for (s, a) in sorted(meta)],
    )
    word_surah = {wid: s for wid, s, _ in locations}

    # --- layouts (QUL) ---
    for sort, (eid, name, script, rel, qul_page) in enumerate(EDITIONS):
        src = qul(rel)
        sources.append((f"lines:{eid}", f"QUL {rel}", QUL_URL + qul_page))
        pages, lpp = src.execute("SELECT number_of_pages, lines_per_page FROM info").fetchone()
        rows = src.execute(
            "SELECT page_number, line_number, line_type, is_centered, first_word_id, "
            "last_word_id, surah_number FROM pages ORDER BY page_number, line_number"
        ).fetchall()
        out = []
        current_surah = None
        for i, (p, l, t, c, fw, lw, s) in enumerate(rows):
            kind = LINE_KIND[t]
            fw = fw if fw != "" else None
            lw = lw if lw != "" else None
            surah = s if s != "" else None
            inline = 0
            if kind == 0:
                surah = word_surah[fw]
            elif kind == 1:
                current_surah = surah
                nxt = rows[i + 1][2] if i + 1 < len(rows) else None
                inline = int(surah not in (1, 9) and nxt != "basmallah")
            else:  # bismillah belongs to the surah whose header precedes it
                surah = current_surah
            out.append((eid, p, l, kind, int(c or 0), fw, lw, surah, inline))
        db.executemany("INSERT INTO lines VALUES(?,?,?,?,?,?,?,?,?)", out)
        db.execute("INSERT INTO editions VALUES(?,?,?,?,?,?)", (eid, name, script, lpp, pages, sort))
        covered = sum(r[6] - r[5] + 1 for r in out if r[3] == 0)
        assert covered == len(locations), f"{eid}: layout covers {covered} words"
        print(f"  {eid}: {pages} pages x {lpp} lines")

    # --- Taj 16-line page images (legeRise): file page_N is layout page N-1 ---
    tree = fetch_json(TAJ_IMAGES_TREE, "legerise_tree.json")["tree"]
    taj = []
    for item in tree:
        path = item["path"]
        if path.startswith("all_paras/para_") and path.endswith(".webp"):
            n = int(path.rsplit("page_", 1)[1].split(".")[0])
            if n >= 2:
                taj.append(("indopak-16-taj-scan", n - 1, path))
    assert len(taj) == 548, len(taj)
    db.executemany("INSERT INTO image_paths VALUES(?,?,?)", taj)
    sources.append(("image_paths:indopak-16-taj-scan",
                    "GitHub legeRise/quran-indopak-ayah-coordinates", TAJ_IMAGES_TREE))
    db.executemany("INSERT INTO sources VALUES(?,?,?)", sources)

    # --- one font size per edition: measure every justified line (HarfBuzz) ---
    import uharfbuzz as hb

    widths = {}
    for column, font_path in FONTS.items():
        face = hb.Face(hb.Blob.from_file_path(os.path.join(ROOT, font_path)))
        font = hb.Font(face)
        scale = REF_SIZE / face.upem
        cache = {}

        def measure(text):
            """Advance (at REF_SIZE), and per height band the ink's leftmost
            x and its reach past the right edge (em, from the word's box)."""
            if text not in cache:
                buf = hb.Buffer()
                buf.add_str(text)
                buf.guess_segment_properties()
                hb.shape(font, buf, {})
                adv = 0
                boxes = []
                for info, pos in zip(buf.glyph_infos, buf.glyph_positions):
                    e = font.get_glyph_extents(info.codepoint)
                    if e is not None and e.width:
                        x0 = (adv + pos.x_offset + e.x_bearing) / face.upem
                        top = (pos.y_offset + e.y_bearing) / face.upem
                        boxes.append((x0, x0 + e.width / face.upem, top, top + e.height / face.upem))
                    adv += pos.x_advance
                em = adv / face.upem
                left, right = {}, {}
                for x0, x1, top, bottom in boxes:
                    for band in range(math.floor(bottom / WORD_BAND), math.floor(top / WORD_BAND) + 1):
                        left[band] = min(left.get(band, 9.0), x0)
                        right[band] = max(right.get(band, -9.0), x1 - em)
                cache[text] = (adv * scale, left, right)
            return cache[text]

        is_end = {wid: last_word[(s, a)] == wid for wid, s, a in locations}
        word_w = []
        for i, (wid, s, a) in enumerate(locations):
            t = texts[column][i]
            if is_end[wid] and column in DRAWN_MARKERS:
                digits = len(t) - len(t.lstrip("٠١٢٣٤٥٦٧٨٩"))
                t = "۝" + t[digits:]
            word_w.append(measure(t))
        # Extra space after each word so its ink stays clear of the next's:
        # at every height where both have ink (give or take a band), the
        # right word's leftmost ink and the left word's rightmost ink must be
        # the clearance apart. (Words read right to left: word i sits to the
        # right of word i + 1.)
        extras = []
        touch = []  # space at which the pair's ink would just touch (em)
        for i in range(len(word_w) - 1):
            _, left_a, _ = word_w[i]
            _, _, right_b = word_w[i + 1]
            clear = MARKER_CLEAR if is_end[locations[i + 1][0]] else WORD_CLEAR
            need = -9.0
            meet = None
            for band, la in left_a.items():
                rb = max(right_b.get(band - 1, -9.0), right_b.get(band, -9.0),
                         right_b.get(band + 1, -9.0))
                if rb > -9.0:
                    need = max(need, clear + rb - la)
                    meet = rb - la if meet is None else max(meet, rb - la)
            extras.append(max(0.0, need - WORD_GAP))
            touch.append(meet)
        extras.append(0.0)
        touch.append(None)
        db.execute("INSERT INTO word_need VALUES(?,?)", (column, bytes(
            0 if t is None else max(1, min(255, round(t * 100) + 128))
            for t in touch)))
        ink = bytearray()
        for _, left, right in word_w:
            past_left = max(0.0, -min(left.values(), default=0.0))
            past_right = max(0.0, max(right.values(), default=0.0))
            ink.append(min(255, math.ceil(past_left * 100)))
            ink.append(min(255, math.ceil(past_right * 100)))
        db.execute("INSERT INTO word_ink VALUES(?,?)", (column, bytes(ink)))
        print(f"  ink past the box {column}: "
              f"{sum(1 for i in range(0, len(ink), 2) if ink[i] or ink[i + 1])} words")
        db.executemany("INSERT INTO word_gap VALUES(?,?,?)", [
            (column, locations[i][0], round(e, 4)) for i, e in enumerate(extras) if e > 0.005])
        print(f"  word gaps {column}: {sum(1 for e in extras if e > 0.005)} pairs need extra space")
        widths[column] = [(w[0], extras[i] * REF_SIZE) for i, w in enumerate(word_w)]

    for eid, name, script, rel, qul_page in EDITIONS:
        columns = [c for c in FONTS if (c == "madani") == (script == "madani")]
        rows = db.execute(
            "SELECT first_word, last_word FROM lines WHERE edition = ? AND kind = 0 "
            "AND centered = 0 AND page > 2", (eid,)
        ).fetchall()
        for column in columns:
            ww = widths[column]
            lens = sorted(
                sum(ww[i - 1][0] for i in range(fw, lw + 1))
                + sum(ww[i - 1][1] for i in range(fw, lw))  # extra space inside the line
                + REF_SIZE * WORD_GAP * (lw - fw)
                for fw, lw in rows
            )
            p99 = lens[int(len(lens) * 0.99)]
            db.execute("INSERT INTO line_fit VALUES(?,?,?,?)", (eid, column, p99, lens[-1]))
            print(f"  line fit {eid}/{column}: p99 {p99:.0f}, max {lens[-1]:.0f}")
    db.execute("INSERT INTO sources VALUES('line_fit', 'Computed with HarfBuzz from the bundled fonts', '')")
    db.execute("INSERT INTO sources VALUES('word_gap', 'Computed with HarfBuzz from the bundled fonts', '')")
    db.execute("INSERT INTO sources VALUES('word_ink', 'Computed with HarfBuzz from the bundled fonts', '')")

    # --- translations: every ayah, exactly as QUL publishes them ---
    ayah_keys = {f"{s}:{a}" for s, a in db.execute("SELECT surah, ayah FROM ayahs")}
    for sort, (tid, language, translator, qul_id, rel) in enumerate(TRANSLATIONS):
        with open(os.path.join(QUL, "translations", rel), encoding="utf-8") as f:
            data = json.load(f)
        assert set(data) == ayah_keys, f"{tid}: ayahs differ from the Quran text"
        rows = []
        for key, value in data.items():
            text = value["t"]
            assert text.strip() and text == text.strip() and "<" not in text, (tid, key)
            s, a = map(int, key.split(":"))
            rows.append((tid, s, a, text))
        db.execute("INSERT INTO translations VALUES(?,?,?,?)", (tid, language, translator, sort))
        db.executemany("INSERT INTO translation_text VALUES(?,?,?,?)", rows)
        sources.append((f"translation:{tid}", f"QUL translation/{qul_id} ({translator})",
                        f"{QUL_URL}translation/{qul_id}"))
        print(f"  translation {tid}: {len(rows)} ayahs")
    db.executemany("INSERT INTO sources VALUES(?,?,?)",
                   [s for s in sources if s[0].startswith("translation:")])

    db.execute("CREATE INDEX lines_words ON lines(edition, first_word)")
    db.execute("INSERT INTO meta VALUES('schema_version','3')")
    db.commit()
    db.execute("VACUUM")
    db.close()
    print(f"Wrote {OUT} ({os.path.getsize(OUT) / 1e6:.1f} MB)")


if __name__ == "__main__":
    build()
