/// Recitation audio: the reciters, the translations' voices, and the order
/// an ayah's audio plays in.
///
/// Every file is EveryAyah's (everyayah.com), one per ayah, played exactly
/// as published: nothing is cut, joined or altered. Before a surah's first
/// ayah its Bismillah is played from Al-Fatihah 1:1, which is the Bismillah.
library;

/// One reciter, as EveryAyah publishes them: a folder of one file per ayah.
class Reciter {
  const Reciter(this.id, this.name, this.nameArabic, this.folder);

  final String id;
  final String name;
  final String nameArabic;

  /// The folder under https://everyayah.com/data/.
  final String folder;

  static const all = [
    Reciter(
      'alafasy',
      'Mishary Rashid Alafasy',
      'مشاري راشد العفاسي',
      'Alafasy_128kbps',
    ),
    Reciter(
      'abdulbasit-murattal',
      'Abdul Basit Abdus Samad (Murattal)',
      'عبد الباسط عبد الصمد (مرتل)',
      'Abdul_Basit_Murattal_192kbps',
    ),
    Reciter(
      'abdulbasit-mujawwad',
      'Abdul Basit Abdus Samad (Mujawwad)',
      'عبد الباسط عبد الصمد (مجود)',
      'Abdul_Basit_Mujawwad_128kbps',
    ),
    Reciter(
      'husary',
      'Mahmoud Khalil Al-Husary',
      'محمود خليل الحصري',
      'Husary_128kbps',
    ),
    Reciter(
      'husary-muallim',
      'Al-Husary (teaching)',
      'الحصري (المعلم)',
      'Husary_Muallim_128kbps',
    ),
    Reciter(
      'minshawi',
      'Muhammad Siddiq Al-Minshawi',
      'محمد صديق المنشاوي',
      'Minshawy_Murattal_128kbps',
    ),
    Reciter(
      'sudais',
      'Abdur-Rahman As-Sudais',
      'عبد الرحمن السديس',
      'Abdurrahmaan_As-Sudais_192kbps',
    ),
    Reciter(
      'shuraim',
      'Saud Ash-Shuraim',
      'سعود الشريم',
      'Saood_ash-Shuraym_128kbps',
    ),
    Reciter(
      'muaiqly',
      'Maher Al-Muaiqly',
      'ماهر المعيقلي',
      'MaherAlMuaiqly128kbps',
    ),
    Reciter('ghamdi', 'Saad Al-Ghamdi', 'سعد الغامدي', 'Ghamadi_40kbps'),
    Reciter(
      'shaatree',
      'Abu Bakr Ash-Shaatree',
      'أبو بكر الشاطري',
      'Abu_Bakr_Ash-Shaatree_128kbps',
    ),
    Reciter('hudhaify', 'Ali Al-Hudhaify', 'علي الحذيفي', 'Hudhaify_128kbps'),
    Reciter(
      'ayyoub',
      'Muhammad Ayyoub',
      'محمد أيوب',
      'Muhammad_Ayyoub_128kbps',
    ),
    Reciter(
      'dossary',
      'Yasser Ad-Dossary',
      'ياسر الدوسري',
      'Yasser_Ad-Dussary_128kbps',
    ),
    Reciter(
      'qatami',
      'Nasser Al-Qatami',
      'ناصر القطامي',
      'Nasser_Alqatami_128kbps',
    ),
    Reciter('rifai', 'Hani Ar-Rifai', 'هاني الرفاعي', 'Hani_Rifai_192kbps'),
    Reciter(
      'jibreel',
      'Muhammad Jibreel',
      'محمد جبريل',
      'Muhammad_Jibreel_128kbps',
    ),
    Reciter(
      'basfar',
      'Abdullah Basfar',
      'عبد الله بصفر',
      'Abdullah_Basfar_192kbps',
    ),
    Reciter(
      'ajamy',
      'Ahmed Al-Ajamy',
      'أحمد بن علي العجمي',
      'Ahmed_ibn_Ali_al-Ajamy_128kbps_ketaballah.net',
    ),
  ];

  static Reciter byId(String id) =>
      all.firstWhere((r) => r.id == id, orElse: () => all.first);
}

/// The voice reading a translation of the meanings, ayah by ayah.
class TranslationVoice {
  const TranslationVoice(this.translationId, this.name, this.folder);

  /// The translation it reads (see QuranDb.translations).
  final String translationId;
  final String name;
  final String folder;

  static const all = [
    TranslationVoice(
      'en-sahih',
      'Ibrahim Walk',
      'English/Sahih_Intnl_Ibrahim_Walk_192kbps',
    ),
    // Reads Fateh Muhammad Jalandhari's translation, the one the app shows.
    TranslationVoice(
      'ur-jalandhari',
      'Shamshad Ali Khan',
      'translations/urdu_shamshad_ali_khan_46kbps',
    ),
  ];

  static TranslationVoice? forTranslation(String? id) {
    for (final v in all) {
      if (v.translationId == id) return v;
    }
    return null;
  }
}

enum AudioPart { recitation, translation }

/// One file in the queue.
class AudioItem {
  const AudioItem({
    required this.folder,
    required this.surah,
    required this.ayah,
    required this.part,
    this.bismillah = false,
    this.times = 1,
  });

  final String folder;

  /// The ayah this is heard as: for a Bismillah, the surah it opens and
  /// ayah 0.
  final int surah;
  final int ayah;
  final AudioPart part;

  /// The Bismillah before a surah (played from 1:1).
  final bool bismillah;

  /// How many times it plays before the next (an ayah repeated for
  /// memorising): the player loops the one file, so the queue stays short
  /// however many repeats are asked for.
  final int times;

  /// The file's own surah and ayah.
  (int, int) get file => bismillah ? (1, 1) : (surah, ayah);

  String get fileName {
    final (s, a) = file;
    return '${s.toString().padLeft(3, '0')}${a.toString().padLeft(3, '0')}.mp3';
  }

  Uri get url => Uri.parse('https://everyayah.com/data/$folder/$fileName');

  @override
  bool operator ==(Object other) =>
      other is AudioItem &&
      other.folder == folder &&
      other.surah == surah &&
      other.ayah == ayah &&
      other.part == part &&
      other.bismillah == bismillah &&
      other.times == times;

  @override
  int get hashCode => Object.hash(folder, surah, ayah, part, bismillah, times);

  @override
  String toString() =>
      '${part.name} $surah:$ayah${bismillah ? ' (bismillah)' : ''}'
      '${times > 1 ? ' ×$times' : ''}';
}

/// What plays for [surah] from [fromAyah] to its end: the Bismillah first
/// when starting at ayah 1 (not for Al-Fatihah, whose first ayah it is, nor
/// At-Tawbah, which has none), then each ayah recited [repeat] times and,
/// with a [voice], its translation once.
List<AudioItem> surahQueue({
  required Reciter reciter,
  required int surah,
  required int fromAyah,
  required int ayahCount,
  TranslationVoice? voice,
  int repeat = 1,
}) {
  List<AudioItem> ayah(int a, {bool bismillah = false}) => [
    AudioItem(
      folder: reciter.folder,
      surah: surah,
      ayah: a,
      part: AudioPart.recitation,
      bismillah: bismillah,
      times: bismillah ? 1 : repeat,
    ),
    if (voice != null)
      AudioItem(
        folder: voice.folder,
        surah: surah,
        ayah: a,
        part: AudioPart.translation,
        bismillah: bismillah,
      ),
  ];
  return [
    if (fromAyah == 1 && surah != 1 && surah != 9) ...ayah(0, bismillah: true),
    for (var a = fromAyah; a <= ayahCount; a++) ...ayah(a),
  ];
}
