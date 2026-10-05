import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/library.dart';
import '../../data/models.dart';
import '../../data/quran_db.dart';
import '../../data/reminders.dart';
import '../../widgets/night.dart';
import 'library_sheets.dart';
import 'new_session_sheet.dart';
import 'surah_search.dart';
import '../reader/quran_word.dart';
import '../reader/reader_screen.dart';
import '../settings/settings_screen.dart';
import '../../l10n/l10n.dart';

enum _Browse { surahs, juz, bookmarks }

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  _Browse _tab = _Browse.surahs;
  String _query = '';

  /// Opens [screen] over home. The search box lets go of focus first:
  /// otherwise it gets it back on return and brings up the keyboard.
  void _push(Widget screen) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  /// A free read ("Browsing"): moves no session.
  void _open(int page) => _push(ReaderScreen(initialPage: page));

  /// Opens a session where it should open, and makes it the current one.
  void _openSession(Session session) {
    final db = ref.read(quranDbProvider);
    final layout = ref.read(settingsProvider).layoutEdition;
    ref.read(libraryProvider.notifier).setCurrent(session.id);
    final page = session.kind == SessionKind.restart
        ? db.surahStartPage(layout, session.openAt.$1)
        : db.pageOfAyah(layout, session.surah, session.ayah);
    _push(ReaderScreen(initialPage: page, sessionId: session.id));
  }

  @override
  void initState() {
    super.initState();
    ReminderService.tappedSession.addListener(_openTapped);
    // Opened from a reminder: open its session once home is on screen.
    WidgetsBinding.instance.addPostFrameCallback((_) => _openTapped());
  }

  @override
  void dispose() {
    ReminderService.tappedSession.removeListener(_openTapped);
    super.dispose();
  }

  /// Opens the session of a tapped reminder, over whatever was open.
  void _openTapped() {
    final id = ReminderService.tappedSession.value;
    if (id == null || !mounted) return;
    ReminderService.tappedSession.value = null;
    final session = ref
        .read(libraryProvider)
        .sessions
        .where((s) => s.id == id)
        .firstOrNull;
    if (session == null) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    _openSession(session);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final s = ref.watch(settingsProvider);
    final db = ref.watch(quranDbProvider);
    final layout = s.layoutEdition;
    final surahs = searchSurahs(db.surahs, _query);
    final library = ref.watch(libraryProvider);

    final list = switch (_tab) {
      _Browse.surahs => SliverList.builder(
        itemCount: surahs.length,
        itemBuilder: (context, i) {
          final surah = surahs[i];
          final page = db.surahStartPage(layout, surah.id);
          return _SurahRow(surah: surah, page: page, onTap: () => _open(page));
        },
      ),
      _Browse.juz => SliverList.builder(
        itemCount: 30,
        itemBuilder: (context, i) {
          final j = db.juzStarts(layout)[i];
          return _JuzRow(
            juz: j,
            name: db.juzName(j.juz, s.typeface),
            fontFamily: s.typeface.fontFamily,
            surahName: context.surahName(db.surah(j.surah)),
            onTap: () => _open(j.page),
          );
        },
      ),
      _Browse.bookmarks =>
        library.bookmarks.isEmpty
            ? const SliverToBoxAdapter(child: _NoBookmarks())
            : SliverList.builder(
                itemCount: library.bookmarks.length,
                itemBuilder: (context, i) {
                  final b = library.bookmarks[i];
                  final page = db.pageOfAyah(layout, b.surah, b.ayah);
                  return _BookmarkRow(
                    bookmark: b,
                    page: page,
                    onTap: () => _open(page),
                  );
                },
              ),
    };
    // The daily reading always leads; other sessions stay in their list,
    // whichever was opened last.
    final featured = library.session(Session.dailyId);
    final others = library.sessions.where((x) => !x.isDaily).toList();
    final l = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(22, 4, 10, 0),
                    child: Row(
                      children: [
                        // The mark in the palette's accent, so it suits every
                        // palette; lifted a little, as the arches' feet reach
                        // below the baseline.
                        Transform.translate(
                          offset: const Offset(0, -2),
                          child: SvgPicture.asset(
                            'assets/brand/mark_day.svg',
                            width: 28,
                            height: 28,
                            excludeFromSemantics: true,
                            colorFilter: ColorFilter.mode(
                              t.acc,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(l.appTitle, style: AppType.wordmark(t.ink)),
                        const Spacer(),
                        // Day or Night at a tap (the app follows the device
                        // until then).
                        IconButton(
                          tooltip: t.dark ? l.switchToDay : l.switchToNight,
                          icon: Icon(
                            t.dark ? LucideIcons.sun : LucideIcons.moon,
                          ),
                          onPressed: () => ref
                              .read(settingsProvider.notifier)
                              .setAppearance(t.dark ? 'day' : 'night'),
                        ),
                        IconButton(
                          tooltip: l.settings,
                          icon: const Icon(LucideIcons.slidersHorizontal),
                          onPressed: () => _push(const SettingsScreen()),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _SessionCard(
                    session: featured,
                    onResume: () => _openSession(featured),
                    onEdit: () => showEditSessionSheet(context, featured),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(
                      24,
                      22,
                      10,
                      6,
                    ),
                    child: Row(
                      children: [
                        Text(
                          l.otherSessions.toUpperCase(),
                          style: AppType.eyebrow(t.mut),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final id = await showNewSessionSheet(context);
                            if (id != null && mounted) {
                              _openSession(
                                ref.read(libraryProvider).session(id),
                              );
                            }
                          },
                          icon: const Icon(LucideIcons.plus, size: 16),
                          label: Text(l.newLabel),
                        ),
                      ],
                    ),
                  ),
                ),
                if (others.isNotEmpty)
                  SliverToBoxAdapter(
                    child: GroupedCard(
                      children: [
                        for (final o in others)
                          _SessionRow(
                            session: o,
                            page: db.pageOfAyah(layout, o.surah, o.ayah),
                            onTap: () => _openSession(o),
                            onEdit: () => showEditSessionSheet(context, o),
                          ),
                      ],
                    ),
                  )
                else
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        l.sessionsHint,
                        style: AppType.caption(t.mut),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(child: Eyebrow(l.browse)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Segmented<_Browse>(
                      value: _tab,
                      onChanged: (v) => setState(() => _tab = v),
                      options: [
                        (_Browse.surahs, l.surahs),
                        (_Browse.juz, l.juz),
                        (_Browse.bookmarks, l.bookmarks),
                      ],
                    ),
                  ),
                ),
                if (_tab == _Browse.surahs)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                      child: TextField(
                        onChanged: (v) => setState(() => _query = v),
                        onTapOutside: (_) =>
                            FocusManager.instance.primaryFocus?.unfocus(),
                        textInputAction: TextInputAction.search,
                        style: AppType.body(t.ink),
                        decoration: InputDecoration(
                          hintText: l.searchHint,
                          hintStyle: AppType.body(t.mut),
                          prefixIcon: Icon(
                            LucideIcons.search,
                            size: 18,
                            color: t.mut,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: t.line2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: t.line2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(22),
                            borderSide: BorderSide(color: t.acc),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 6)),
                if (_tab == _Browse.surahs && surahs.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        l.noSurahMatches(_query),
                        textAlign: TextAlign.center,
                        style: AppType.caption(t.mut),
                      ),
                    ),
                  ),
                list,
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The raised card for a session: the words where the reader stopped, and a
/// Resume button. Hold to edit the session.
class _SessionCard extends ConsumerWidget {
  const _SessionCard({
    required this.session,
    required this.onResume,
    required this.onEdit,
  });

  final Session session;
  final VoidCallback onResume;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final s = ref.watch(settingsProvider);
    final db = ref.watch(quranDbProvider);
    final layout = s.layoutEdition;
    final (surah, ayah) = session.kind == SessionKind.restart
        ? session.openAt
        : (session.surah, session.ayah);
    final page = db.pageOfAyah(layout, surah, ayah);
    final juz = db.page(layout, page, s.typeface).juz;
    final restart = session.kind == SessionKind.restart;
    // The whole ayah; the card shows its end, as far back as fits.
    final words = restart
        ? const <Word>[]
        : db.ayahTail(surah, ayah, s.typeface, count: 1000);
    final quran = TextStyle(
      fontFamily: s.typeface.fontFamily,
      fontSize: 32,
      height: 1.9,
      color: t.ink,
    );

    return GestureDetector(
      onLongPress: onEdit,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          color: t.surf,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: t.line2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(LucideIcons.rotateCw, size: 13, color: t.acc),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.sessionName(session).toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: AppType.eyebrow(t.acc),
                  ),
                ),
                if (ReminderService.supported)
                  _ReminderButton(session: session),
              ],
            ),
            if (words.isNotEmpty) ...[
              const SizedBox(height: 10),
              _AyahEnd(
                words: words,
                typeface: s.typeface,
                style: quran,
                markerStyle: quran.copyWith(color: t.acc),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: context.surahName(db.surah(surah)),
                              style: AppType.titleLg(
                                t.ink,
                              ).copyWith(fontSize: 20),
                            ),
                            TextSpan(
                              text: restart ? '' : '  $surah:$ayah',
                              style: AppType.body(t.mut),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        restart
                            ? context.l10n.opensAtStart(page)
                            : context.l10n.pageJuz(page, juz),
                        style: AppType.caption(t.mut),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: onResume,
                  child: Text(
                    restart ? context.l10n.open : context.l10n.resume,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionRow extends ConsumerWidget {
  const _SessionRow({
    required this.session,
    required this.page,
    required this.onTap,
    required this.onEdit,
  });

  final Session session;
  final int page;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      onLongPress: onEdit,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(LucideIcons.rotateCw, size: 15, color: t.mut),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.sessionName(session),
                style: AppType.title(t.ink),
              ),
            ),
            if (ReminderService.supported) _ReminderButton(session: session),
            Text(
              session.kind == SessionKind.restart
                  ? context.l10n.sessionStart
                  : context.l10n.pageShort(page),
              style: AppType.caption(t.mut),
            ),
            SizedBox(
              width: 36,
              height: 44,
              child: Icon(
                context.rtl
                    ? LucideIcons.chevronLeft
                    : LucideIcons.chevronRight,
                size: 18,
                color: t.mut,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookmarkRow extends ConsumerWidget {
  const _BookmarkRow({
    required this.bookmark,
    required this.page,
    required this.onTap,
  });

  final Bookmark bookmark;
  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final db = ref.watch(quranDbProvider);
    final typeface = ref.watch(settingsProvider).typeface;
    final opening = db
        .ayahTail(bookmark.surah, bookmark.ayah, typeface, count: 400)
        .where((w) => !w.isAyahEnd)
        .take(5)
        .toList();
    final quran = TextStyle(
      fontFamily: typeface.fontFamily,
      fontSize: 20,
      height: 1.8,
      color: t.ink,
    );
    return InkWell(
      onTap: onTap,
      onLongPress: () => showBookmarkSheet(context, bookmark),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 22),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.bookmark, size: 18, color: t.acc),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${context.surahName(db.surah(bookmark.surah))} ${bookmark.surah}:${bookmark.ayah}',
                    style: AppType.title(t.ink),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    bookmark.note.isEmpty
                        ? context.l10n.pageShort(page)
                        : '${bookmark.note} · ${context.l10n.pageShort(page)}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.caption(t.mut),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // The ayah's opening words, word by word (bidi-safe).
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    for (final (i, w) in opening.indexed) ...[
                      if (i > 0) const SizedBox(width: 5),
                      QuranWord(
                        word: w,
                        typeface: typeface,
                        style: quran,
                        markerStyle: quran,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({
    required this.surah,
    required this.page,
    required this.onTap,
  });

  final Surah surah;
  final int page;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        margin: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(
          children: [
            NumberSquare(surah.id),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.surahName(surah),
                      style: AppType.title(t.ink).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.versesPage(surah.versesCount, page),
                      style: AppType.caption(t.mut),
                    ),
                  ],
                ),
              ),
            ),
            // Urdu and Arabic already show the Arabic name as the title.
            if (!context.arabicNames) ...[
              const SizedBox(width: 12),
              Text(
                surah.nameArabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppType.arabicUi,
                  fontSize: 23,
                  color: t.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _JuzRow extends StatelessWidget {
  const _JuzRow({
    required this.juz,
    required this.name,
    required this.fontFamily,
    required this.surahName,
    required this.onTap,
  });

  final JuzStart juz;
  final String name;
  final String fontFamily;
  final String surahName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        margin: const EdgeInsets.symmetric(horizontal: 22),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.line)),
        ),
        child: Row(
          children: [
            NumberSquare(juz.juz),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.juzN(juz.juz),
                      style: AppType.title(t.ink).copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$surahName ${juz.surah}:${juz.ayah} · ${context.l10n.pageShort(juz.page)}',
                      style: AppType.caption(t.mut),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // The juz's opening words, in the reader's own Quran typeface.
            Text(
              name,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: fontFamily,
                fontSize: 21,
                height: 1.8,
                color: t.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoBookmarks extends StatelessWidget {
  const _NoBookmarks();

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 48, 40, 24),
      child: Column(
        children: [
          Icon(LucideIcons.bookmark, size: 28, color: t.mut),
          const SizedBox(height: 14),
          Text(context.l10n.noBookmarks, style: AppType.title(t.ink)),
          const SizedBox(height: 6),
          Text(
            context.l10n.noBookmarksHint,
            textAlign: TextAlign.center,
            style: AppType.caption(t.mut),
          ),
        ],
      ),
    );
  }
}

/// A bell that opens the session's reminder: filled in the accent colour
/// when one is set.
class _ReminderButton extends StatelessWidget {
  const _ReminderButton({required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final on = session.reminder != null;
    return IconButton(
      tooltip: context.l10n.remindMe,
      visualDensity: VisualDensity.compact,
      onPressed: () => showReminderSheet(context, session),
      icon: Icon(
        on ? LucideIcons.bellRing : LucideIcons.bell,
        size: 17,
        color: on ? t.acc : t.mut,
      ),
    );
  }
}

/// The end of an ayah on one line, with its marker: the whole ayah when it
/// fits; otherwise its last words, the line fading in from where the ayah
/// begins (on the right, reading right to left), so it plainly continues
/// from before.
class _AyahEnd extends StatelessWidget {
  const _AyahEnd({
    required this.words,
    required this.typeface,
    required this.style,
    required this.markerStyle,
  });

  final List<Word> words;
  final QuranTypeface typeface;
  final TextStyle style;
  final TextStyle markerStyle;

  static const _gap = 8.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth;
      // Words back from the end while they fit, plus the one that runs past
      // the right edge (shown fading in).
      final shown = <Word>[];
      var used = 0.0;
      for (final w in words.reversed) {
        used +=
            (shown.isEmpty ? 0 : _gap) +
            QuranWord.widthOf(w, typeface, w.isAyahEnd ? markerStyle : style);
        shown.insert(0, w);
        if (used > width) break;
      }
      final whole = shown.length == words.length && used <= width;
      final row = Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.rtl,
        children: [
          for (final (i, w) in shown.indexed) ...[
            if (i > 0) const SizedBox(width: _gap),
            QuranWord(
              word: w,
              typeface: typeface,
              style: style,
              markerStyle: markerStyle,
            ),
          ],
        ],
      );
      if (whole) {
        return Align(alignment: Alignment.centerRight, child: row);
      }
      return ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) => const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Colors.white, Colors.white, Colors.transparent],
          stops: [0, 0.62, 1],
        ).createShader(rect),
        child: ClipRect(
          child: SizedBox(
            width: width,
            height: style.fontSize! * (style.height ?? 1),
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              maxWidth: double.infinity,
              child: row,
            ),
          ),
        ),
      );
    },
  );
}
