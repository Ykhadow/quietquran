import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/settings.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/quran_db.dart';
import '../../l10n/l10n.dart';
import '../../widgets/night.dart';
import 'surah_search.dart';

/// The box for finding a surah by name, meaning or number (see
/// [searchSurahs]), as on home.
class SurahSearchField extends StatelessWidget {
  const SurahSearchField({super.key, required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: t.line2),
    );
    return TextField(
      onChanged: onChanged,
      onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      textInputAction: TextInputAction.search,
      style: AppType.body(t.ink),
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        hintStyle: AppType.body(t.mut),
        prefixIcon: Icon(LucideIcons.search, size: 18, color: t.mut),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: BorderSide(color: t.acc)),
      ),
    );
  }
}

/// A surah in a list: its number, name, verses and page, and its Arabic
/// name. [selected] marks the one already chosen.
class SurahRow extends StatelessWidget {
  const SurahRow({
    super.key,
    required this.surah,
    required this.page,
    required this.onTap,
    this.selected = false,
  });

  final Surah surah;
  final int page;
  final VoidCallback onTap;
  final bool selected;

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
                      style: AppType.title(
                        selected ? t.acc : t.ink,
                      ).copyWith(fontSize: 18),
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
            if (selected) ...[
              const SizedBox(width: 12),
              Icon(LucideIcons.check, size: 18, color: t.acc),
            ],
            // Urdu and Arabic already show the Arabic name as the title.
            if (!context.arabicNames) ...[
              const SizedBox(width: 12),
              Text(
                surah.nameArabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: AppType.arabicUi,
                  fontSize: 23,
                  color: selected ? t.acc : t.ink,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Picks a surah from a list that can be searched, as on home. Returns its
/// number, or null if dismissed.
Future<int?> showSurahPicker(BuildContext context, {int? selected}) =>
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SurahPicker(selected: selected),
    );

class _SurahPicker extends ConsumerStatefulWidget {
  const _SurahPicker({this.selected});

  final int? selected;

  @override
  ConsumerState<_SurahPicker> createState() => _SurahPickerState();
}

class _SurahPickerState extends ConsumerState<_SurahPicker> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(quranDbProvider);
    final layout = ref.watch(settingsProvider.select((s) => s.layoutEdition));
    final surahs = searchSurahs(db.surahs, _query);
    final t = context.tokens;
    // Most of the screen; while searching, what's left above the keyboard,
    // so the search box (under the sheet's handle) stays clear of the
    // status bar.
    final screen = MediaQuery.sizeOf(context).height;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final statusBar = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: SizedBox(
        height: math.min(screen * 0.85, screen - keyboard - statusBar - 80),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: SurahSearchField(
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: surahs.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        context.l10n.noSurahMatches(_query.trim()),
                        textAlign: TextAlign.center,
                        style: AppType.caption(t.mut),
                      ),
                    )
                  : ListView.builder(
                      itemCount: surahs.length,
                      // Keeps the keyboard out of the way of the results.
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemBuilder: (context, i) {
                        final s = surahs[i];
                        return SurahRow(
                          surah: s,
                          page: db.surahStartPage(layout, s.id),
                          selected: s.id == widget.selected,
                          onTap: () => Navigator.pop(context, s.id),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
