import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/quran_db.dart';
import '../../data/recitation.dart';
import '../../l10n/l10n.dart';
import '../../widgets/night.dart';
import 'recitation_controller.dart';

/// The reciter's name in the app's language.
String reciterName(BuildContext context, Reciter r) =>
    context.arabicNames ? r.nameArabic : r.name;

/// The reader's round "listen" button: starts reciting from [onStart]'s
/// ayah, or pauses and resumes a recitation under way.
class ListenButton extends ConsumerWidget {
  const ListenButton({super.key, required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final (active, playing) = ref.watch(
      recitationProvider.select((s) => (s.active, s.playing)),
    );
    return Tooltip(
      message: playing ? l.pause : l.listen,
      child: Material(
        color: t.surf,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => active
              ? ref.read(recitationProvider.notifier).toggle()
              : onStart(),
          child: SizedBox.square(
            dimension: 48,
            child: Icon(
              playing ? LucideIcons.pause : LucideIcons.play,
              size: 20,
              color: t.ink,
            ),
          ),
        ),
      ),
    );
  }
}

/// The floating player while a recitation is under way: the ayah being
/// heard and by whom (with the round, when repeating), previous /
/// play-pause / next, stop, and a line filling as the ayah plays. Tapping
/// the title opens the recitation options. It slides in and out.
class RecitationBar extends ConsumerWidget {
  const RecitationBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(recitationProvider);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0, 0.4),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: state.active
          ? _card(context, ref, state)
          : const SizedBox.shrink(key: ValueKey('none')),
    );
  }

  Widget _card(BuildContext context, WidgetRef ref, RecitationState state) {
    final t = context.tokens;
    final l = context.l10n;
    final db = ref.watch(quranDbProvider);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(recitationProvider.notifier);
    final surah = context.surahName(db.surah(state.surah));
    final title = state.failed
        ? l.recitationFailed
        : state.ayah == 0
        ? '$surah · ${l.bismillah}'
        : '$surah ${state.surah}:${state.ayah}';
    final voice = TranslationVoice.forTranslation(
      settings.translationFor(l.localeName),
    );
    final reciter = reciterName(context, Reciter.byId(settings.reciter));
    final by = state.part == AudioPart.translation && voice != null
        ? voice.name
        : state.rounds > 1
        ? '$reciter · ${l.roundOf(state.round, state.rounds)}'
        : reciter;

    Widget skip(IconData icon, String tooltip, VoidCallback onTap) => Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 40,
          child: Icon(icon, size: 20, color: t.ink),
        ),
      ),
    );

    final waiting = state.loading && state.playing && !state.failed;
    final play = Tooltip(
      message: state.failed
          ? l.tryAgain
          : state.playing
          ? l.pause
          : l.listen,
      child: SizedBox.square(
        dimension: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // While the audio arrives, a ring turns around the button.
            if (waiting)
              SizedBox.square(
                dimension: 48,
                child: CircularProgressIndicator(strokeWidth: 2, color: t.acc),
              ),
            Material(
              color: t.acc,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: state.failed ? controller.resume : controller.toggle,
                child: SizedBox.square(
                  dimension: 40,
                  child: Icon(
                    state.failed
                        ? LucideIcons.rotateCcw
                        : state.playing
                        ? LucideIcons.pause
                        : LucideIcons.play,
                    size: 18,
                    color: t.bg,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return ConstrainedBox(
      key: const ValueKey('player'),
      constraints: const BoxConstraints(maxWidth: 440),
      // A soft, wide shadow: lifted off the page, not outlined.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: t.dark ? 0.45 : 0.12),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: t.bg,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: t.line2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(6, 6, 4, 4),
                child: Row(
                  children: [
                    // Media controls read left to right in every language.
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          skip(
                            LucideIcons.skipBack,
                            l.previousAyah,
                            controller.previous,
                          ),
                          play,
                          skip(
                            LucideIcons.skipForward,
                            l.nextAyah,
                            controller.next,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => showRecitationSheet(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppType.title(t.ink),
                              ),
                              // The reciter is a choice: the chevron says so.
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      by,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppType.caption(t.mut),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    LucideIcons.chevronDown,
                                    size: 14,
                                    color: t.mut,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    skip(LucideIcons.x, l.stopRecitation, controller.stop),
                  ],
                ),
              ),
              // How far through the ayah, filling in reading direction.
              SizedBox(
                height: 3,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(end: state.failed ? 0 : state.progress),
                  duration: const Duration(milliseconds: 250),
                  builder: (_, v, _) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: v,
                      heightFactor: 1,
                      child: ColoredBox(color: t.acc),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The recitation options in a sheet (from the player).
Future<void> showRecitationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: const SingleChildScrollView(
          padding: EdgeInsets.only(bottom: 16),
          child: SafeArea(child: RecitationOptions()),
        ),
      ),
    );

/// The reciter and repeats, and when the translation is read aloud.
/// Shown in Settings and from the player.
class RecitationOptions extends ConsumerWidget {
  const RecitationOptions({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final l = context.l10n;
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final voice = TranslationVoice.forTranslation(
      s.translationFor(l.localeName),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // One heading: the reciter list is the section's first choice.
        Eyebrow(l.recitation),
        ChoiceCard(
          rows: [
            for (final r in Reciter.all)
              ChoiceRow(
                title: reciterName(context, r),
                subtitle: context.arabicNames ? r.name : r.nameArabic,
                selected: s.reciter == r.id,
                onTap: () => n.setReciter(r.id),
              ),
          ],
        ),
        // Read aloud when shown: the translation's own switch (in Aa and
        // Settings) decides both.
        if (voice != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
            child: Text(l.translationAudioHint, style: AppType.caption(t.mut)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(l.repeatAyah, style: AppType.body(t.ink)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Segmented<int>(
            // 0 stands for the reader's own number.
            value: _presetRepeats.contains(s.ayahRepeat) ? s.ayahRepeat : 0,
            onChanged: (v) async {
              if (v != 0) return n.setAyahRepeat(v);
              final chosen = await showDialog<int>(
                context: context,
                builder: (_) => _RepeatDialog(initial: s.ayahRepeat),
              );
              if (chosen != null) n.setAyahRepeat(chosen);
            },
            options: [
              for (final k in _presetRepeats) (k, '$k×'),
              (
                0,
                _presetRepeats.contains(s.ayahRepeat)
                    ? l.custom
                    : '${s.ayahRepeat}×',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Text(l.recitationHint, style: AppType.caption(t.mut)),
        ),
      ],
    );
  }
}

const _presetRepeats = [1, 2, 3, 5];

/// Most a reader can ask an ayah to be recited.
const maxAyahRepeat = 99;

/// Any number of recitations of each ayah, typed or stepped.
class _RepeatDialog extends StatefulWidget {
  const _RepeatDialog({required this.initial});

  final int initial;

  @override
  State<_RepeatDialog> createState() => _RepeatDialogState();
}

class _RepeatDialogState extends State<_RepeatDialog> {
  late final _field = TextEditingController(text: '${widget.initial}');

  int get _value =>
      (int.tryParse(_field.text) ?? 1).clamp(1, maxAyahRepeat).toInt();

  void _step(int by) {
    final v = (_value + by).clamp(1, maxAyahRepeat);
    _field.value = TextEditingValue(
      text: '$v',
      selection: TextSelection.collapsed(offset: '$v'.length),
    );
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.repeatAyah),
      content: Directionality(
        // Minus on the left, plus on the right, in every language.
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.minus),
              onPressed: () => _step(-1),
            ),
            SizedBox(
              width: 84,
              child: TextField(
                controller: _field,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                style: AppType.titleLg(t.ink),
                decoration: const InputDecoration(suffixText: '×'),
                onSubmitted: (_) => Navigator.pop(context, _value),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.plus),
              onPressed: () => _step(1),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _value),
          child: Text(l.save),
        ),
      ],
    );
  }
}
