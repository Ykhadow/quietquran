const _urduDigits = '۰۱۲۳۴۵۶۷۸۹';

/// 12 -> ۱۲ (Urdu/Persian digits, as printed in IndoPak Mushafs; the IndoPak
/// font has no glyphs for U+0660-0669).
String urduDigits(int n) =>
    n.toString().split('').map((d) => _urduDigits[int.parse(d)]).join();

const _arabicIndic = '٠١٢٣٤٥٦٧٨٩';

/// 12 -> ١٢ (Arabic-Indic digits, as printed in Madani Mushafs).
String arabicDigits(int n) =>
    n.toString().split('').map((d) => _arabicIndic[int.parse(d)]).join();
