import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:just_audio_media_kit/just_audio_media_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/settings.dart';
import 'core/theme.dart';
import 'data/quran_db.dart';
import 'features/home/home_screen.dart';
import 'data/library.dart';
import 'data/reminders.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/reader/page_snapshot.dart';
import 'features/reader/quran_line.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Decoded images (printed pages) share this budget; Flutter's default of
  // 100 MB is a lot for a 2 GB phone.
  PaintingBinding.instance.imageCache.maximumSizeBytes = 48 << 20;
  WidgetsBinding.instance.addObserver(_MemoryPressure());
  final (prefs, db, _, _, _) = await (
    SharedPreferences.getInstance(),
    QuranDb.open(),
    ReminderService.init(),
    _initAudio(),
    _initDownloads(),
  ).wait;
  runApp(
    ProviderScope(
      overrides: [
        prefsProvider.overrideWithValue(prefs),
        quranDbProvider.overrideWithValue(db),
      ],
      child: const MushafApp(),
    ),
  );
}

/// Saving a whole printed set runs in the system's background downloader:
/// six pages at a time, polite to the host and quick on a phone. Starting
/// it picks up sets still saving from before the app last closed.
Future<void> _initDownloads() async {
  await FileDownloader().configure(
    globalConfig: (Config.holdingQueue, (6, null, null)),
  );
  await FileDownloader().start();
}

/// Recitation keeps playing with the screen off, with controls in the
/// notification and on the lock screen (Android, iOS, macOS); Windows and
/// Linux play through media_kit.
Future<void> _initAudio() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android || TargetPlatform.iOS || TargetPlatform.macOS
        when !kIsWeb:
      await JustAudioBackground.init(
        androidNotificationChannelId: 'com.quietquran.recitation',
        androidNotificationChannelName: 'Recitation',
        androidNotificationIcon: 'drawable/ic_notification',
        androidNotificationOngoing: true,
      );
    case TargetPlatform.windows || TargetPlatform.linux when !kIsWeb:
      JustAudioMediaKit.ensureInitialized();
    default:
  }
}

/// When the phone runs low on memory, drops what can be rebuilt on demand:
/// page pictures, shaped words and decoded images.
class _MemoryPressure with WidgetsBindingObserver {
  @override
  void didHaveMemoryPressure() {
    PageSnapshots.clear();
    WordShapes.clear();
    PaintingBinding.instance.imageCache.clear();
  }
}

/// The notifications for every session's reading reminder, in the app's
/// language (recomputed when sessions, reminders or the language change).
final reminderPlanProvider = Provider<List<PlannedReminder>>((ref) {
  final sessions = ref.watch(libraryProvider.select((l) => l.sessions));
  final chosen = ref.watch(settingsProvider.select((s) => s.locale));
  final locale = chosen ?? _deviceLocale();
  final l = lookupAppLocalizations(locale);
  return planReminders(
    sessions,
    title: (s) => s.isDaily && s.name == Session.dailyDefaultName
        ? l.dailyReading
        : s.name,
    body: l.reminderBody,
  );
});

/// The device's language if the app has it, else English.
Locale _deviceLocale() {
  final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  return AppLocalizations.supportedLocales.firstWhere(
    (l) => l.languageCode == code,
    orElse: () => const Locale('en'),
  );
}

class MushafApp extends ConsumerStatefulWidget {
  const MushafApp({super.key});

  @override
  ConsumerState<MushafApp> createState() => _MushafAppState();
}

class _MushafAppState extends ConsumerState<MushafApp> {
  @override
  void initState() {
    super.initState();
    // Keep the phone's scheduled reminders in step with the sessions (the
    // service skips plans it has already scheduled).
    ref.listenManual(
      reminderPlanProvider,
      (_, plan) => ReminderService.schedule(plan),
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Only what the app shell needs, so other settings (text size, the
    // translation, …) don't rebuild the whole app.
    final (light, dark, locale, onboarded) = ref.watch(
      settingsProvider.select(
        (s) => (
          s.palette(Brightness.light),
          s.palette(Brightness.dark),
          s.locale,
          s.onboarded,
        ),
      ),
    );
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appTitle,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      debugShowCheckedModeBanner: false,
      theme: themeFor(light),
      darkTheme: themeFor(dark),
      themeMode: ThemeMode.system,
      // Switch colours at once: a blended transition would redraw every page
      // (and prepare page pictures) for each in-between colour.
      themeAnimationDuration: Duration.zero,
      builder: (context, child) => _PrivacyCover(child: child!),
      home: onboarded ? const HomeScreen() : const OnboardingScreen(),
    );
  }
}

/// On iPhone, a plain cover in the app's colours while the app is in the
/// background, so the app switcher shows that and not the page being read.
/// (Android does this itself; see MainActivity.)
class _PrivacyCover extends StatefulWidget {
  const _PrivacyCover({required this.child});

  final Widget child;

  @override
  State<_PrivacyCover> createState() => _PrivacyCoverState();
}

class _PrivacyCoverState extends State<_PrivacyCover> {
  late final AppLifecycleListener _listener;
  bool _covered = false;

  static bool get _applies =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onStateChange: (state) {
        final cover = _applies && state != AppLifecycleState.resumed;
        if (cover != _covered) setState(() => _covered = cover);
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_covered) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        ColoredBox(color: context.tokens.bg),
      ],
    );
  }
}
