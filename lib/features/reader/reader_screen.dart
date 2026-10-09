import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/image_editions.dart';
import '../../data/models.dart';
import '../../data/page_images.dart';
import '../../data/library.dart';
import '../../data/quran_db.dart';
import '../../data/reminders.dart';
import '../audio/recitation_controller.dart';
import '../audio/recitation_widgets.dart';
import '../home/new_session_sheet.dart';
import 'ayah_sheet.dart';
import 'display_sheet.dart';
import 'image_page.dart';
import 'scrubber.dart';
import 'mushaf_text_page.dart';
import 'page_snapshot.dart';
import 'reflow_page.dart';
import 'zoomable_page.dart';
import '../../l10n/l10n.dart';

/// The reader. Immersive by default: the page fills the screen and a tap
/// brings up the overlay (top bar and bottom sheet), which hides itself again
/// after a few seconds.
///
/// Pages turn right-to-left like a printed Mushaf. On wide screens two pages
/// are shown side by side (odd page on the right). Page numbers belong to the
/// active layout edition (see [Settings.layoutEdition]); switching edition or
/// mode keeps the reader on the same ayah.
class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key, required this.initialPage, this.sessionId});

  /// Page in the layout edition active when the reader opens.
  final int initialPage;

  /// The session this reading belongs to, or null for a free read
  /// ("Browsing"), which moves no session.
  final String? sessionId;

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen>
    with WidgetsBindingObserver {
  PageController? _controller;
  bool? _spread;
  late int _page = widget.initialPage;

  // ---- Vertical reading (Settings.verticalScroll) ----

  /// The page the vertical column is anchored at: it opens with this page at
  /// the top, pages before it above, pages after below. Moving it (a jump,
  /// a new layout) rebuilds the column there.
  late int _vAnchor = widget.initialPage;
  ScrollController? _vController;
  final _vView = GlobalKey();
  final _vKeys = <int, GlobalKey>{};
  final _vBuilt = <int, Widget>{};
  Object? _vBuiltFor;
  bool? _wasVertical;

  /// Session being read; null while browsing. Browsing can be saved into one.
  late String? _sessionId = widget.sessionId;
  late String _layout = ref.read(settingsProvider).layoutEdition;
  final _focus = FocusNode();

  bool _overlay = false;
  Timer? _hideTimer;
  bool _sheetOpen = false;

  /// The ayah whose sheet is open, highlighted on the page.
  (int, int)? _selected;

  /// The ayah being recited, highlighted and followed from page to page.
  (int, int)? _playing;

  /// The bottom sheet, measured so the player can sit just above it.
  final _sheetKey = GlobalKey();
  double _sheetHeight = 0;

  void _listenFrom(int surah, int ayah) {
    ref
        .read(recitationProvider.notifier)
        .playFrom(surah, ayah, language: context.l10n.localeName);
    _askToShowPlayer();
  }

  /// Android (13 and later) shows the recitation's player in the
  /// notifications and on the lock screen only if the app may notify. Asked
  /// once, the first time a recitation starts (reminders ask on their own).
  void _askToShowPlayer() {
    if (kIsWeb || !Platform.isAndroid) return;
    final prefs = ref.read(prefsProvider);
    if (prefs.getBool('askedNotifyForRecitation') ?? false) return;
    prefs.setBool('askedNotifyForRecitation', true);
    ReminderService.requestPermission();
  }

  /// Brings the page of the ayah being recited into view.
  void _follow((int, int) ayah) {
    final (surah, number) = ayah;
    final page = _db.pageOfAyah(_layout, surah, number);
    final settings = ref.read(settingsProvider);
    if (_vertical) {
      // Easy read lines bring themselves into view (see QuranParagraph).
      if (settings.mode == ReadingMode.text &&
          settings.textLayout == TextLayout.reflow) {
        return;
      }
      if (page == _page) return;
      final target = _vKeys[page]?.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        _jumpTo(page);
      }
      return;
    }
    final c = _controller;
    if (c == null || !c.hasClients || _spread == null) return;
    final target = _indexFor(page, _spread!);
    final current = _indexFor(_page, _spread!);
    if (target == current) return;
    if ((target - current).abs() > 1) return _jumpTo(page);
    _unzoom();
    _page = _pageFor(target);
    _target = target;
    c
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        )
        .whenComplete(() {
          if (_target == target) _target = null;
        });
  }

  Future<void> _onAyahLongPress(int surah, int ayah) async {
    HapticFeedback.selectionClick();
    setState(() => _selected = (surah, ayah));
    await _withSheet(
      () => showAyahSheet(
        context,
        surah,
        ayah,
        onListen: () => _listenFrom(surah, ayah),
      ),
    );
    if (mounted) setState(() => _selected = null);
  }

  /// Whether a page is pinched in: page turns wait until it's zoomed out, so
  /// a drag moves around the page instead.
  bool _zoomed = false;

  /// Zooms every page back out; fired when the reader moves to another page.
  final _zoomReset = ValueNotifier(0);

  void _unzoom() {
    _zoomReset.value++;
    if (_zoomed) setState(() => _zoomed = false);
  }

  /// The juz or surah under the finger while scrubbing, or null.
  int? _scrubbing;

  /// Built pages by PageView index, reused across rebuilds so that saving the
  /// reading position or toggling the overlay never re-lays-out a page.
  final _built = <int, Widget>{};
  Object? _builtFor;

  /// Index a keyboard page turn is animating towards. While set, the
  /// intermediate pages the animation passes don't count as reading position.
  int? _target;

  /// Read once (not a getter): the position is also saved from dispose,
  /// where [ref] can no longer be used.
  late final QuranDb _db = ref.read(quranDbProvider);
  int get _total => _db.edition(_layout).pages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _db;
    _library;
    // Opening a page counts as reading it, even before any page turn.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _savePosition();
      _prefetchAround();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_saveTimer != null) _commitPosition(later: true);
    _hideTimer?.cancel();
    _controller?.dispose();
    _vController?.dispose();
    _focus.dispose();
    _zoomReset.dispose();
    super.dispose();
  }

  // ---- Position ----

  /// Saves the reading position a moment after page turns stop, not on
  /// every turn: each save updates the library, which the home screen below
  /// rebuilds for. Saved at once when the reader closes or the app goes to
  /// the background.
  void _savePosition() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(seconds: 1), _commitPosition);
  }

  Timer? _saveTimer;

  /// Kept from initState: [ref] can't be used in dispose.
  late final _library = ref.read(libraryProvider.notifier);

  /// The typeface pages are drawn in, kept current by build: page lookups
  /// use it so each page is loaded and cached once, not once per typeface.
  late QuranTypeface _typeface = ref.read(settingsProvider).typeface;

  void _commitPosition({bool later = false}) {
    _saveTimer?.cancel();
    _saveTimer = null;
    final id = _sessionId;
    if (id == null) return; // browsing moves no session
    final (surah, ayah) = _db.page(_layout, _page, _typeface).firstAyah;
    // While the reader is being torn down, providers can't change; save
    // right after instead.
    if (later) {
      final library = _library;
      Future(() => library.setPosition(id, surah, ayah));
    } else {
      _library.setPosition(id, surah, ayah);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && _saveTimer != null) {
      _commitPosition();
    }
  }

  /// From a free read: carry the current session on from here, or start a
  /// new session at this page.
  Future<void> _saveBrowsing() => _withSheet(() async {
    final library = ref.read(libraryProvider);
    final current = library.current;
    final (surah, ayah) = _db.page(_layout, _page, _typeface).firstAyah;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        final t = context.tokens;
        final l = context.l10n;
        final name = context.sessionName(current);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Icon(LucideIcons.rotateCw, color: t.acc),
                  title: Text(l.continueFromHere(name)),
                  subtitle: Text(
                    l.movesTo(
                      name,
                      '${context.surahName(_db.surah(surah))} $surah:$ayah',
                    ),
                  ),
                  onTap: () => Navigator.pop(context, 'continue'),
                ),
                ListTile(
                  leading: Icon(LucideIcons.plus, color: t.acc),
                  title: Text(l.saveAsNew),
                  subtitle: Text(l.saveAsNewHint),
                  onTap: () => Navigator.pop(context, 'new'),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (!mounted || choice == null) return;
    if (choice == 'continue') {
      ref.read(libraryProvider.notifier).setPosition(current.id, surah, ayah);
      setState(() => _sessionId = current.id);
    } else {
      final id = await showNewSessionSheet(context, surah: surah, ayah: ayah);
      if (id != null && mounted) setState(() => _sessionId = id);
    }
  });

  /// Bookmarks the page (its first ayah), or clears every bookmark on it.
  /// The translation button: shows or hides the translation under each
  /// ayah. With none chosen yet (or none for the app's language), it turns
  /// on the one for the app's language, or English; the Aa sheet changes
  /// which.
  void _toggleTranslation(Settings settings) {
    final n = ref.read(settingsProvider.notifier);
    final locale = context.l10n.localeName;
    final chosen = settings.translationFor(locale);
    if (settings.reflowTranslation && chosen != null) {
      n.setReflowTranslation(false);
      return;
    }
    if (chosen == null) {
      n.setTranslation(locale == 'ur' ? 'ur-jalandhari' : 'en-sahih');
    }
    n.setReflowTranslation(true);
  }

  void _toggleBookmark() {
    final library = ref.read(libraryProvider);
    final notifier = ref.read(libraryProvider.notifier);
    final onPage = _ayahsOnPage();
    final marked = onPage.where((a) => library.isBookmarked(a.$1, a.$2));
    if (marked.isEmpty) {
      final (surah, ayah) = _db.page(_layout, _page, _typeface).firstAyah;
      notifier.toggleBookmark(surah, ayah);
    } else {
      for (final (surah, ayah) in marked.toList()) {
        notifier.toggleBookmark(surah, ayah);
      }
    }
    _scheduleHide();
  }

  Set<(int, int)> _ayahsOnPage() => {
    for (final w
        in _db.page(_layout, _page, _typeface).lines.expand((l) => l.words))
      (w.surah, w.ayah),
  };

  /// Whether any bookmarked ayah starts on the current page.
  bool _pageBookmarked(List<Bookmark> bookmarks) {
    final onPage = _ayahsOnPage();
    return bookmarks.any((b) => onPage.contains((b.surah, b.ayah)));
  }

  /// Keeps the reader on the same ayah when the layout edition changes.
  void _followLayout(String layout) {
    if (layout == _layout) return;
    final (surah, ayah) = _db.page(_layout, _page, _typeface).firstAyah;
    _layout = layout;
    _page = _db.pageOfAyah(layout, surah, ayah);
    _disposeLater(_controller);
    _controller = null;
    _reanchor();
    _zoomed = false; // the pages are built afresh, unzoomed
  }

  /// Rebuilds the vertical column with the current page at its top.
  void _reanchor() {
    _vAnchor = _page;
    _disposeLaterScroll(_vController);
    _vController = null;
    _vKeys.clear();
    _vBuilt.clear();
  }

  void _disposeLaterScroll(ScrollController? c) {
    if (c == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  bool get _vertical => ref.read(settingsProvider).verticalScroll;

  /// In the vertical column, the page under the top third of the screen is
  /// the one being read.
  void _vTrack() {
    final view = _vView.currentContext?.findRenderObject() as RenderBox?;
    if (view == null || !view.attached) return;
    final probe = view.localToGlobal(Offset.zero).dy + view.size.height * 0.3;
    for (final MapEntry(key: n, value: k) in _vKeys.entries) {
      final box = k.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      if (top <= probe && top + box.size.height > probe) {
        if (n != _page) {
          setState(() => _page = n);
          _savePosition();
          _prefetchAround();
        }
        return;
      }
    }
  }

  // ---- Paging ----

  int _indexFor(int page, bool spread) => spread ? (page - 1) ~/ 2 : page - 1;

  int _pageFor(int index) => _spread! ? index * 2 + 1 : index + 1;

  int _lastIndex(bool spread) => spread ? (_total + 1) ~/ 2 - 1 : _total - 1;

  /// Disposes a replaced controller after this frame: the PageView being
  /// rebuilt still holds it until then.
  void _disposeLater(PageController? c) {
    if (c == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => c.dispose());
  }

  /// Recreates the controller when switching between one- and two-page views,
  /// keeping the current page.
  PageController _controllerFor(bool spread) {
    if (_spread != spread || _controller == null) {
      _disposeLater(_controller);
      _controller = PageController(initialPage: _indexFor(_page, spread));
      _spread = spread;
    }
    return _controller!;
  }

  void _onIndexChanged(int index) {
    if (_target != null) {
      if (index != _target) return;
      _target = null;
    }
    setState(() => _page = _pageFor(index));
    _unzoom();
    _savePosition();
    _prefetchAround();
  }

  void _turn(int delta) {
    if (_vertical) {
      // A screen at a time, keeping a little of the last one in view.
      final c = _vController;
      if (c == null || !c.hasClients) return;
      final p = c.position;
      c.animateTo(
        (p.pixels + delta * p.viewportDimension * 0.9).clamp(
          p.minScrollExtent,
          p.maxScrollExtent,
        ),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    final c = _controller;
    if (c == null || !c.hasClients) return;
    // Step from the page we're heading to, so rapid key presses accumulate.
    final target = (_indexFor(_page, _spread!) + delta).clamp(
      0,
      _lastIndex(_spread!),
    );
    _page = _pageFor(target);
    _target = target;
    c
        .animateToPage(
          target,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        )
        .whenComplete(() {
          if (_target == target) _target = null;
        });
  }

  void _jumpTo(int page) {
    _unzoom();
    setState(() {
      _page = page.clamp(1, _total);
      if (_vertical) _reanchor();
    });
    if (!_vertical) _controller?.jumpToPage(_indexFor(_page, _spread!));
    _savePosition();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    if (e is! KeyDownEvent && e is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = e.logicalKey;
    // In a right-to-left book the next page is to the left.
    if (k == LogicalKeyboardKey.arrowLeft ||
        k == LogicalKeyboardKey.pageDown ||
        k == LogicalKeyboardKey.space ||
        (_vertical && k == LogicalKeyboardKey.arrowDown)) {
      _turn(1);
    } else if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.pageUp ||
        (_vertical && k == LogicalKeyboardKey.arrowUp)) {
      _turn(-1);
    } else if (k == LogicalKeyboardKey.home) {
      _jumpTo(1);
    } else if (k == LogicalKeyboardKey.end) {
      _jumpTo(_total);
    } else if (k == LogicalKeyboardKey.escape && _overlay) {
      _setOverlay(false);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  // ---- Overlay ----

  void _setOverlay(bool visible) {
    _hideTimer?.cancel();
    setState(() => _overlay = visible);
    if (visible) _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _scrubbing == null && !_sheetOpen) {
        setState(() => _overlay = false);
      }
    });
  }

  Future<void> _withSheet(Future<void> Function() open) async {
    _hideTimer?.cancel();
    _sheetOpen = true;
    await open();
    _sheetOpen = false;
    if (mounted) {
      _scheduleHide();
      _focus.requestFocus();
    }
  }

  void _commitScrub(ScrubberMode mode, int n) {
    _jumpTo(
      mode == ScrubberMode.juz
          ? _db.juzStarts(_layout)[n - 1].page
          : _db.surahStartPage(_layout, n),
    );
    _scheduleHide();
  }

  /// What a built page depends on: when it changes, pages are built afresh.
  Object _displayKey(Settings settings, bool spread) => (
    settings.mode,
    settings.textLayout,
    settings.textEdition,
    settings.imageEdition,
    settings.typeface,
    settings.reflowFontSize,
    settings.reflowWordSpacing,
    settings.reflowTranslation,
    settings.translation,
    context.l10n.localeName,
    // Colours: a page (and its prepared picture) must be rebuilt when the
    // theme changes, e.g. from the Day/Night switch in the Aa sheet.
    context.tokens.bg,
    context.tokens.ink,
    context.tokens.acc,
    _layout,
    spread,
    _selected,
    _playing,
    // Bookmarked ayahs are tinted on the page.
    ref.read(libraryProvider).bookmarks,
  );

  /// A page widget for [index], built once per display configuration.
  Widget _item(int index, bool spread, Settings settings, Size size) {
    final key = _displayKey(settings, spread);
    if (key != _builtFor) {
      _built.clear();
      _builtFor = key;
    }
    // Keep only pages near the one requested.
    _built.removeWhere((i, _) => (i - index).abs() > 3);
    return _built.putIfAbsent(
      index,
      () => RepaintBoundary(
        child: spread
            ? _Spread(
                // Easy read pages fill their half; others keep the print's
                // proportions.
                fill:
                    settings.mode == ReadingMode.text &&
                    settings.textLayout == TextLayout.reflow,
                right: _pageView(index * 2 + 1, settings),
                left: index * 2 + 2 <= _total
                    ? _pageView(index * 2 + 2, settings)
                    : null,
              )
            : _single(_pageView(index + 1, settings), size),
      ),
    );
  }

  // ---- Build ----

  @override
  Widget build(BuildContext context) {
    // Rebuild only when the display changes, not when the reading position is
    // saved on every page turn.
    ref.watch(
      settingsProvider.select(
        (s) => (
          s.mode,
          s.textLayout,
          s.textEdition,
          s.imageEdition,
          s.typeface,
          s.reflowFontSize,
          s.reflowWordSpacing,
          s.reflowTranslation,
          s.twoPages,
          s.verticalScroll,
          s.translation,
          s.scrubber,
          s.layoutEdition,
        ),
      ),
    );
    final settings = ref.read(settingsProvider);
    _typeface = settings.typeface;
    final db = ref.watch(quranDbProvider);
    _playing = ref.watch(recitationProvider.select((s) => s.current));
    ref.listen(recitationProvider.select((s) => s.current), (_, ayah) {
      if (ayah != null) _follow(ayah);
    });
    // The player sits just above the bottom sheet while that is shown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final h = _sheetKey.currentContext?.size?.height ?? 0;
      if (mounted && h != _sheetHeight) setState(() => _sheetHeight = h);
    });
    final t = context.tokens;
    _followLayout(settings.layoutEdition);
    final size = MediaQuery.sizeOf(context);
    // Two pages side by side whenever the window is landscape enough, unless
    // the reader prefers one. In Easy read each half scrolls on its own.
    final vertical = settings.verticalScroll;
    if (vertical != _wasVertical) {
      // Switching between turning and scrolling keeps the page.
      if (vertical) {
        _reanchor();
      } else {
        _disposeLater(_controller);
        _controller = null;
      }
      _wasVertical = vertical;
    }
    final spread = !vertical && settings.twoPages && _wide(size);
    final controller = vertical ? null : _controllerFor(spread);
    if (vertical) _spread = false;
    final page = db.page(_layout, _page, settings.typeface);
    final l = context.l10n;
    final appDirection = Directionality.of(context);

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: t.dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
        child: Scaffold(
          backgroundColor: t.bg,
          body: Stack(
            children: [
              // Saving the printed set in the background: a quiet line at
              // the top while it runs.
              if (settings.mode == ReadingMode.pages)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _SavingBar(ImageEdition.byId(settings.imageEdition)),
                ),
              Positioned.fill(
                child: SafeArea(
                  child: GestureDetector(
                    onTap: () => _setOverlay(!_overlay),
                    // Pages turn right to left whatever the app's language:
                    // a horizontal PageView would flip under Urdu/Arabic.
                    child: vertical
                        ? _verticalColumn(settings, size, appDirection)
                        : Directionality(
                            textDirection: TextDirection.ltr,
                            child: PageView.builder(
                              // A new controller (new page numbering, or one/two
                              // pages) needs a new PageView: an existing one would
                              // carry its old scroll offset over and show the
                              // wrong page until the next swipe.
                              key: ObjectKey(controller),
                              controller: controller,
                              reverse: true, // right-to-left page turning
                              // Keep the neighbouring pages built, so a swipe never
                              // waits for the next page to lay out.
                              allowImplicitScrolling: true,
                              itemCount: _lastIndex(spread) + 1,
                              onPageChanged: _onIndexChanged,
                              // While a page is zoomed, drags move around it.
                              physics: _zoomed
                                  ? const NeverScrollableScrollPhysics()
                                  : null,
                              // ...while each page keeps the app's direction.
                              itemBuilder: (_, index) => Directionality(
                                textDirection: appDirection,
                                child: _item(index, spread, settings, size),
                              ),
                            ),
                          ),
                  ),
                ),
              ),
              if (_scrubbing != null)
                Positioned.fill(
                  child: _ScrubPreview(
                    mode: settings.scrubber,
                    n: _scrubbing!,
                    layout: _layout,
                  ),
                ),
              _fade(
                Align(
                  alignment: Alignment.topCenter,
                  child: _TopBar(
                    title: _sessionId == null
                        ? l.browsing
                        : context.sessionName(
                            ref.watch(
                              libraryProvider.select(
                                (l) => l.session(_sessionId!),
                              ),
                            ),
                          ),
                    browsing: _sessionId == null,
                    bookmarked: _pageBookmarked(
                      ref.watch(libraryProvider.select((l) => l.bookmarks)),
                    ),
                    onBack: () => Navigator.of(context).maybePop(),
                    onBookmark: _toggleBookmark,
                    onSave: _saveBrowsing,
                  ),
                ),
                visible: _overlay && _scrubbing == null,
              ),
              _fade(
                Align(
                  alignment: Alignment.bottomCenter,
                  child: _BottomSheet(
                    key: _sheetKey,
                    listen: ListenButton(
                      onStart: () {
                        final (s, a) = page.firstAyah;
                        _listenFrom(s, a);
                      },
                    ),
                    surah: page.surahs
                        .map((s) => context.surahName(db.surah(s)))
                        .join(' · '),
                    meta: l.readerMeta(page.juz, _pageLabel(), _total),
                    mode: settings.scrubber,
                    current: settings.scrubber == ScrubberMode.juz
                        ? page.juz
                        : page.firstAyah.$1,
                    onScrub: (n) {
                      setState(() => _scrubbing = n);
                      if (n == null) _scheduleHide();
                    },
                    onCommit: (n) => _commitScrub(settings.scrubber, n),
                    onDisplay: () =>
                        _withSheet(() => showDisplaySheet(context)),
                    // Translations sit under each ayah in Easy read only.
                    translationOn:
                        settings.mode == ReadingMode.text &&
                            settings.textLayout == TextLayout.reflow
                        ? settings.reflowTranslation &&
                              settings.translationFor(l.localeName) != null
                        : null,
                    onTranslation: () => _toggleTranslation(settings),
                  ),
                ),
                visible: _overlay || _scrubbing != null,
              ),
              // Always there, so the player can slide in and out.
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                left: 12,
                right: 12,
                bottom: _overlay || _scrubbing != null ? _sheetHeight + 10 : 0,
                child: SafeArea(
                  top: false,
                  // Above the sheet, which already keeps clear of the
                  // screen's edge.
                  bottom: !(_overlay || _scrubbing != null),
                  minimum: EdgeInsets.only(
                    bottom: _overlay || _scrubbing != null ? 0 : 12,
                  ),
                  child: const Center(child: RecitationBar()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Wide enough for two pages side by side.
  static bool _wide(Size size) =>
      size.width >= 600 && size.width >= size.height * 1.1;

  String _pageLabel() {
    final first = _spread == true ? _pageFor(_indexFor(_page, true)) : _page;
    return _spread == true && first < _total ? '$first–${first + 1}' : '$first';
  }

  Widget _fade(Widget child, {required bool visible}) => IgnorePointer(
    ignoring: !visible,
    child: AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: Duration(milliseconds: visible ? 150 : 200),
      curve: Curves.easeOut,
      child: child,
    ),
  );

  /// One page. Phones fill the screen; wider windows keep print proportions.
  Widget _single(Widget page, Size size) {
    if (size.width / size.height < 0.75) return page;
    return Center(child: AspectRatio(aspectRatio: 0.64, child: page));
  }

  /// Vertical reading: every page in one column, anchored at [_vAnchor].
  /// Mushaf and printed pages are a screen tall; Easy read pages as tall as
  /// their text, so it runs on from one page into the next.
  Widget _verticalColumn(
    Settings settings,
    Size size,
    TextDirection appDirection,
  ) {
    final controller = _vController ??= ScrollController();
    final reflow =
        settings.mode == ReadingMode.text &&
        settings.textLayout == TextLayout.reflow;
    final t = context.tokens;
    return LayoutBuilder(
      builder: (context, box) {
        final height = box.maxHeight;
        final key = (_displayKey(settings, false), height, box.maxWidth);
        if (key != _vBuiltFor) {
          _vBuilt.clear();
          _vBuiltFor = key;
        }
        Widget item(int n) {
          _vBuilt.removeWhere((i, _) => (i - n).abs() > 4);
          _vKeys.removeWhere(
            (i, k) => (i - n).abs() > 8 && k.currentContext == null,
          );
          return KeyedSubtree(
            key: _vKeys.putIfAbsent(n, GlobalKey.new),
            child: _vBuilt.putIfAbsent(
              n,
              () => RepaintBoundary(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reflow)
                      _pageView(n, settings, scrolls: false)
                    else
                      SizedBox(
                        height: height,
                        child: _single(_pageView(n, settings), size),
                      ),
                    // Where one page ends and the next begins.
                    if (n < _total)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 6,
                        ),
                        child: Container(height: 1, color: t.line),
                      ),
                  ],
                ),
              ),
            ),
          );
        }

        const center = ValueKey('anchor');
        return NotificationListener<ScrollUpdateNotification>(
          onNotification: (_) {
            _vTrack();
            return false;
          },
          child: Directionality(
            key: _vView,
            textDirection: appDirection,
            child: CustomScrollView(
              // A new anchor comes with a new controller, and needs a new
              // scroll view: an existing one would keep its old offset.
              key: ObjectKey(controller),
              controller: controller,
              center: center,
              physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
              slivers: [
                // Pages before the anchor, growing upwards.
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => item(_vAnchor - 1 - i),
                    childCount: _vAnchor - 1,
                  ),
                ),
                SliverList(
                  key: center,
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => item(_vAnchor + i),
                    childCount: _total - _vAnchor + 1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pageView(int number, Settings settings, {bool scrolls = true}) {
    final db = ref.read(quranDbProvider);
    // Pinch to zoom Mushaf and printed pages (reflow has its own text size).
    Widget zoomable(Widget Function(BuildContext, bool zoomed) builder) =>
        ZoomablePage(
          reset: _zoomReset,
          onZoomChanged: (z) {
            if (z != _zoomed) setState(() => _zoomed = z);
          },
          builder: builder,
        );
    if (settings.mode == ReadingMode.pages) {
      return zoomable(
        (_, zoomed) => Padding(
          padding: const EdgeInsets.all(4),
          child: ImagePage(
            edition: ImageEdition.byId(settings.imageEdition),
            page: number,
            zoomed: zoomed,
          ),
        ),
      );
    }
    final page = db.page(_layout, number, settings.typeface);
    if (settings.textLayout == TextLayout.reflow) {
      return ReflowPage(
        page: page,
        db: db,
        juzLabel: context.l10n.runningHeadJuz(page.juz),
        marked: _marksOn(page),
        highlight: _playing,
        fontSize: settings.reflowFontSize,
        wordSpacing: settings.reflowWordSpacing,
        translation: settings.reflowTranslation
            ? db.translation(settings.translationFor(context.l10n.localeName))
            : null,
        onAyahLongPress: _onAyahLongPress,
        scrolls: scrolls,
      );
    }
    final juzLabel = context.l10n.runningHeadJuz(page.juz);
    final marked = _marksOn(page);
    // Shown as a prepared picture when available (see PageSnapshots), and as
    // live text while zoomed, so it stays sharp.
    return zoomable(
      (_, zoomed) => SnapshotPage(
        snapshotKey: _snapshotKey(number, settings, marked),
        page: () => MushafTextPage(
          page: page,
          db: db,
          juzLabel: juzLabel,
          marked: marked,
        ),
        label: _pageText(page),
        onAyahLongPress: _onAyahLongPress,
        highlight: _selected ?? _playing,
        live: zoomed,
      ),
    );
  }

  Object _snapshotKey(int number, Settings settings, Set<(int, int)> marked) {
    final t = context.tokens;
    return (
      // Sorted, so equal sets make equal keys.
      ([for (final (s, a) in marked) '$s:$a']..sort()).join(' '),
      _layout,
      number,
      settings.typeface,
      t.bg,
      t.ink,
      t.acc,
      t.mut,
      t.rule,
      context.l10n.localeName,
    );
  }

  /// The bookmarked ayahs with words on [page].
  Set<(int, int)> _marksOn(MushafPage page) {
    final bookmarks = ref.read(libraryProvider).bookmarks;
    if (bookmarks.isEmpty) return const {};
    final all = {for (final b in bookmarks) (b.surah, b.ayah)};
    return {
      for (final l in page.lines)
        if (l.kind == LineKind.text)
          for (final w in l.words)
            if (all.contains((w.surah, w.ayah))) (w.surah, w.ayah),
    };
  }

  static String _pageText(MushafPage page) => page.lines
      .expand((l) => l.words)
      .where((w) => !w.isAyahEnd)
      .map((w) => w.text)
      .join(' ');

  /// Prepares pictures of the pages two either side, so even quick
  /// consecutive swipes only slide pictures.
  void _prefetchAround() {
    final settings = ref.read(settingsProvider);
    if (settings.mode != ReadingMode.text ||
        settings.textLayout != TextLayout.mushaf) {
      return;
    }
    final db = ref.read(quranDbProvider);
    final l = context.l10n;
    for (final d in const [1, -1, 2, -2]) {
      final n = _page + d;
      if (n < 1 || n > _total) continue;
      final page = db.page(_layout, n, settings.typeface);
      final juzLabel = l.runningHeadJuz(page.juz);
      final marked = _marksOn(page);
      SnapshotPage.prefetch(
        _snapshotKey(n, settings, marked),
        () => MushafTextPage(
          page: page,
          db: db,
          juzLabel: juzLabel,
          marked: marked,
        ),
      );
    }
  }
}

/// Two pages side by side like an open book: odd page on the right, with a
/// thin spine between them.
class _Spread extends StatelessWidget {
  const _Spread({required this.right, required this.left, this.fill = false});

  final Widget right;
  final Widget? left;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    Widget page(Widget? child) => Expanded(
      child: fill
          ? child ?? const SizedBox.shrink()
          : Center(
              child: AspectRatio(
                aspectRatio: 0.64,
                child: child ?? const SizedBox.shrink(),
              ),
            ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          page(right),
          SizedBox(
            width: 28,
            child: Center(
              child: FractionallySizedBox(
                heightFactor: 0.84,
                child: Container(width: 1, color: t.line),
              ),
            ),
          ),
          page(left),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.browsing,
    required this.bookmarked,
    required this.onBack,
    required this.onBookmark,
    required this.onSave,
  });

  final String title;

  /// A free read: offer to save it into a session.
  final bool browsing;
  final bool bookmarked;
  final VoidCallback onBack;
  final VoidCallback onBookmark;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      color: t.bg,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: t.line2)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: IconButton(
                  tooltip: context.l10n.backToHome,
                  icon: Icon(
                    context.rtl
                        ? LucideIcons.arrowRight
                        : LucideIcons.arrowLeft,
                    color: t.ink,
                  ),
                  onPressed: onBack,
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      browsing ? LucideIcons.compass : LucideIcons.rotateCw,
                      size: 14,
                      color: t.acc,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.label(t.ink),
                      ),
                    ),
                  ],
                ),
              ),
              if (browsing)
                IconButton(
                  tooltip: context.l10n.saveAsSession,
                  icon: Icon(LucideIcons.listPlus, color: t.ink),
                  onPressed: onSave,
                ),
              SizedBox(
                width: 56,
                child: IconButton(
                  tooltip: bookmarked
                      ? context.l10n.removeBookmark
                      : context.l10n.bookmarkPage,
                  icon: Icon(
                    bookmarked
                        ? LucideIcons.bookmarkCheck
                        : LucideIcons.bookmark,
                    color: bookmarked ? t.acc : t.ink,
                  ),
                  onPressed: onBookmark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomSheet extends StatelessWidget {
  const _BottomSheet({
    super.key,
    required this.listen,
    required this.surah,
    required this.meta,
    required this.mode,
    required this.current,
    required this.onScrub,
    required this.onCommit,
    required this.onDisplay,
    required this.translationOn,
    required this.onTranslation,
  });

  /// Whether the translation shows under each ayah, or null where it can't
  /// (Mushaf and printed pages), which hides its button.
  final bool? translationOn;
  final VoidCallback onTranslation;

  final String surah;
  final String meta;
  final ScrubberMode mode;
  final int current;
  final ValueChanged<int?> onScrub;
  final ValueChanged<int> onCommit;
  final VoidCallback onDisplay;

  /// Starts or pauses the recitation (see ListenButton).
  final Widget listen;

  bool get juzMode => mode == ScrubberMode.juz;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    Widget round({
      required String tooltip,
      required Widget child,
      required VoidCallback onTap,
      bool selected = false,
    }) => Tooltip(
      message: tooltip,
      child: Material(
        color: selected ? t.acc : t.surf,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(dimension: 48, child: Center(child: child)),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: t.bg,
        border: Border(top: BorderSide(color: t.line2)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(22, 16, 16, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          surah,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.title(t.ink),
                        ),
                        const SizedBox(height: 2),
                        Text(meta, style: AppType.caption(t.mut)),
                      ],
                    ),
                  ),
                  if (translationOn case final on?) ...[
                    Semantics(
                      toggled: on,
                      child: round(
                        tooltip: on ? l.hideTranslation : l.showTranslation,
                        onTap: onTranslation,
                        selected: on,
                        child: Icon(
                          LucideIcons.languages,
                          size: 20,
                          color: on ? t.bg : t.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  listen,
                  const SizedBox(width: 8),
                  round(
                    tooltip: l.displayTooltip,
                    onTap: onDisplay,
                    child: Icon(LucideIcons.settings2, size: 20, color: t.ink),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Scrubber(
                count: juzMode ? 30 : 114,
                current: current,
                landmark: juzMode ? 5 : 10,
                unit: juzMode ? l.juz : l.surah,
                onScrub: onScrub,
                onCommit: onCommit,
              ),
              // The strip runs right to left, so the last is on the left
              // (in every language, so the row is fixed left to right).
              Row(
                textDirection: TextDirection.ltr,
                children: [
                  Text(
                    juzMode ? l.juzN(30) : l.surahN(114),
                    style: AppType.small(t.mut),
                  ),
                  const Spacer(),
                  Text(
                    juzMode ? l.juzN(1) : l.surahN(1),
                    style: AppType.small(t.mut),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown over the page while scrubbing: where the reader would land.
class _ScrubPreview extends ConsumerWidget {
  const _ScrubPreview({
    required this.mode,
    required this.n,
    required this.layout,
  });

  final ScrubberMode mode;
  final int n;
  final String layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final db = ref.watch(quranDbProvider);
    final typeface = ref.watch(settingsProvider).typeface;
    final juzMode = mode == ScrubberMode.juz;
    final start = juzMode ? db.juzStarts(layout)[n - 1] : null;
    final surah = db.surah(juzMode ? start!.surah : n);
    final page = juzMode ? start!.page : db.surahStartPage(layout, n);
    return ColoredBox(
      color: t.veil,
      child: Align(
        alignment: const Alignment(0, -0.3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                (juzMode ? context.l10n.juzN(n) : context.l10n.surahN(n))
                    .toUpperCase(),
                style: AppType.eyebrow(t.acc),
              ),
              const SizedBox(height: 12),
              FittedBox(
                child: Text(
                  // A juz is known by its opening words; a surah by its name.
                  juzMode ? db.juzName(n, typeface) : surah.nameArabic,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: juzMode
                        ? typeface.fontFamily
                        : AppType.arabicUi,
                    fontSize: 56,
                    height: 1.8,
                    color: t.ink,
                  ),
                ),
              ),
              // Under a juz's opening words, the surah it starts in; under a
              // surah's Arabic name, its transliteration (English only).
              if (juzMode || !context.arabicNames)
                Text(context.surahName(surah), style: AppType.titleLg(t.ink)),
              const SizedBox(height: 4),
              Text(
                context.l10n.pageOf(page, db.edition(layout).pages),
                style: AppType.body(t.mut).copyWith(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A thin progress line while a printed set saves in the background (see
/// askToSavePrinted); nothing otherwise.
class _SavingBar extends ConsumerWidget {
  const _SavingBar(this.edition);

  final ImageEdition edition;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      pageImageStoreProvider.select((m) => m[edition.id]),
    );
    if (status == null || !status.running) return const SizedBox.shrink();
    final total = ref.read(pageImageStoreProvider.notifier).pageCount(edition);
    return SafeArea(
      bottom: false,
      child: Semantics(
        label: context.l10n.printedDownloadingBar(status.cached, total),
        child: LinearProgressIndicator(
          value: status.cached / total,
          minHeight: 2,
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}
