import '../core/settings.dart';

enum ImageFormat { svg, raster }

/// A set of printed Mushaf page images. Each set follows one of the text
/// layouts page for page, which gives it surah/juz navigation for free.
///
/// Hosts are third-party for now; move [url] to our own CDN later.
class ImageEdition {
  const ImageEdition({
    required this.id,
    required this.script,
    required this.title,
    required this.description,
    required this.layout,
    required this.approxTotalMb,
    required this.format,
    required this.host,
    required this.hostUrl,
    this.credit,
    this.creditUrl,
    this.thanks,
    this.colourCoded = false,
    this.pageUrl,
    this.pathBase,
  });

  final String id;
  final QuranScript script;
  final String title;
  final String description;

  /// Text edition id whose pagination this set follows.
  final String layout;
  final int approxTotalMb;
  final ImageFormat format;

  /// Who publishes the images, for the Sources page.
  final String host;
  final String hostUrl;

  /// Who made the pages, credited on the Sources page in place of [host]
  /// where the host isn't the publisher.
  final String? credit;
  final String? creditUrl;

  /// Someone thanked alongside the credit.
  final String? thanks;
  final bool colourCoded;

  /// URL pattern for sets with predictable file names.
  final String Function(int page)? pageUrl;

  /// For sets whose file names don't follow a pattern: base URL joined with
  /// the per-page path stored in the database (table image_paths).
  final String? pathBase;

  bool get usesPathTable => pathBase != null;

  /// URL of [page] (1-based, in [layout]'s numbering). [path] is required for
  /// sets that use the path table.
  String url(int page, {String? path}) =>
      usesPathTable ? '$pathBase$path' : pageUrl!(page);

  String get fileExtension => switch (format) {
    ImageFormat.svg => 'svg.gz',
    ImageFormat.raster => 'img',
  };

  static String _pad3(int n) => n.toString().padLeft(3, '0');

  /// The printed sets the app offers.
  static final all = <ImageEdition>[
    ImageEdition(
      id: 'indopak-15-plain',
      script: QuranScript.indopak,
      title: '15-line · King Fahd Complex',
      description:
          "The King Fahd Complex's IndoPak 15-line Mushaf (610 pages).",
      layout: 'indopak-15-qudratullah',
      approxTotalMb: 195,
      format: ImageFormat.raster,
      host: 'Quiet Quran · pages.quietquran.com',
      hostUrl: 'https://pages.quietquran.com/indopak-15-kfgqpc/manifest.json',
      // The King Fahd Complex's own pages, extracted unchanged from their
      // Mushaf PDF (tool/kfgqpc_indopak15.py, which checks the PDF's
      // fingerprint) and served exactly as extracted: file N is page N. The
      // manifest beside them records the PDF and its fingerprint.
      credit: 'King Fahd Glorious Quran Printing Complex, Madinah',
      creditUrl: 'https://qurancomplex.gov.sa/',
      thanks: 'Lucid (github.com/1uc1d23)',
      pageUrl: (p) =>
          'https://pages.quietquran.com/indopak-15-kfgqpc/page${_pad3(p)}.png',
    ),
    ImageEdition(
      id: 'madani-15-kfgqpc',
      script: QuranScript.madani,
      title: '15-line · King Fahd Complex',
      description:
          "The King Fahd Complex's Madinah Mushaf, Mumtaz print (604 pages).",
      layout: 'madani-1405',
      approxTotalMb: 340,
      format: ImageFormat.raster,
      host: 'Quiet Quran · pages.quietquran.com',
      hostUrl: 'https://pages.quietquran.com/madani-15-kfgqpc/manifest.json',
      // The King Fahd Complex's own pages, extracted unchanged from their
      // Mumtaz Mushaf PDF (tool/kfgqpc_madani.py, which checks the PDF's
      // fingerprint) and served exactly as extracted: file N is page N. Their
      // revised print: each page holds the 1405H layout's ayahs, though some
      // lines break at different words.
      credit: 'King Fahd Glorious Quran Printing Complex, Madinah',
      creditUrl: 'https://qurancomplex.gov.sa/',
      pageUrl: (p) =>
          'https://pages.quietquran.com/madani-15-kfgqpc/page${_pad3(p)}.png',
    ),
  ];

  /// Sets kept for later, not offered: third-party scans, until their
  /// publishers agree or readers ask for them.
  static final withheld = <ImageEdition>[
    const ImageEdition(
      id: 'indopak-16-taj-scan',
      script: QuranScript.indopak,
      title: '16-line · Taj Company',
      description: 'Scan of the Taj Company 16-line print (548 pages).',
      layout: 'indopak-16-taj',
      approxTotalMb: 130,
      format: ImageFormat.raster,
      host: 'GitHub · legeRise/quran-indopak-ayah-coordinates',
      hostUrl: 'https://github.com/legeRise/quran-indopak-ayah-coordinates',
      pathBase:
          'https://raw.githubusercontent.com/legeRise/quran-indopak-ayah-coordinates/main/',
    ),
    ImageEdition(
      id: 'indopak-13-qudratullah-scan',
      script: QuranScript.indopak,
      title: '13-line · Qudratullah',
      description: 'Scan of the Qudratullah 13-line print (849 pages).',
      layout: 'indopak-13-qudratullah',
      approxTotalMb: 700,
      format: ImageFormat.raster,
      host: 'archive.org · AlQuran13LinesQudratUllahCompany',
      hostUrl: 'https://archive.org/details/AlQuran13LinesQudratUllahCompany',
      // archive.org: image n{N+1} is page N.
      pageUrl: (p) =>
          'https://archive.org/download/AlQuran13LinesQudratUllahCompany/page/n${p + 1}_w1300.jpg',
    ),
    ImageEdition(
      id: 'indopak-15-colour',
      script: QuranScript.indopak,
      title: '15-line · colour-coded tajweed',
      description: 'Tajweed rules in colour on every page (610 pages).',
      layout: 'indopak-15-qudratullah',
      approxTotalMb: 300,
      format: ImageFormat.raster,
      host: 'archive.org · quran_202301',
      hostUrl: 'https://archive.org/details/quran_202301',
      colourCoded: true,
      // archive.org quran_202301: image n{N} is page N.
      pageUrl: (p) =>
          'https://archive.org/download/quran_202301/page/n${p}_w1300.jpg',
    ),
  ];

  static ImageEdition byId(String id) =>
      all.firstWhere((e) => e.id == id, orElse: () => all.first);

  static bool exists(String id) => all.any((e) => e.id == id);

  static List<ImageEdition> forScript(QuranScript s) =>
      all.where((e) => e.script == s).toList();
}
