import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/theme.dart';
import '../l10n/l10n.dart';

// Small building blocks of the "Night" design system (see
// design_handoff_mushaf_night/README.md).

/// Uppercase section label ("OTHER SESSIONS", "BROWSE").
class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color, this.padding});

  final String text;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? const EdgeInsets.fromLTRB(24, 22, 24, 8),
    child: Text(
      text.toUpperCase(),
      style: AppType.eyebrow(color ?? context.tokens.mut),
    ),
  );
}

/// A rounded `surf` card with a hairline border, holding a list of rows.
class GroupedCard extends StatelessWidget {
  const GroupedCard({super.key, required this.children, this.padding});

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: padding ?? const EdgeInsetsDirectional.fromSTEB(16, 0, 6, 0),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: t.line2),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, color: t.line),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A [GroupedCard] of [ChoiceRow]s that keeps long lists short: only the
/// chosen row shows, with "Show all" to see the rest. Two rows or fewer
/// always show in full.
class ChoiceCard extends StatefulWidget {
  const ChoiceCard({super.key, required this.rows});

  final List<ChoiceRow> rows;

  @override
  State<ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<ChoiceCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final rows = widget.rows;
    if (rows.length <= 2) return GroupedCard(children: rows);
    final shown = _open ? rows : rows.where((r) => r.selected).toList();
    return GroupedCard(
      children: [
        ...shown,
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 10, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _open
                        ? context.l10n.showLess
                        : context.l10n.showAll(rows.length),
                    style: AppType.body(t.acc),
                  ),
                ),
                Icon(
                  _open ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: t.acc,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The numbered square used in surah and juz lists.
class NumberSquare extends StatelessWidget {
  const NumberSquare(this.n, {super.key});

  final int n;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.line),
      ),
      child: Text(
        '$n',
        style: AppType.caption(
          t.mut,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}

/// The handoff's segmented control: equal columns on a `surf` track, the
/// selected one raised on `bg`.
class Segmented<T> extends StatelessWidget {
  const Segmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.line2),
      ),
      child: Row(
        children: [
          for (final (v, text) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: v == value,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 40,
                    alignment: Alignment.center,
                    decoration: v == value
                        ? BoxDecoration(
                            color: t.bg,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: t.shadow,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          )
                        : null,
                    child: Text(
                      text,
                      style: AppType.label(v == value ? t.ink : t.mut).copyWith(
                        fontWeight: v == value
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact segmented control of icons, each with a tooltip (and the same
/// words for screen readers). For quick toggles where words would crowd.
class IconSegmented<T> extends StatelessWidget {
  const IconSegmented({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final T value;
  final List<(T, IconData, String)> options;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: t.surf,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: t.line2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (v, icon, label) in options)
            Tooltip(
              message: label,
              child: Semantics(
                button: true,
                selected: v == value,
                label: label,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 48,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: v == value
                        ? BoxDecoration(
                            color: t.bg,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: t.shadow,
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          )
                        : null,
                    child: Icon(
                      icon,
                      size: 19,
                      color: v == value ? t.ink : t.mut,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A selectable row in a grouped card.
class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.preview,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(0, 12, 10, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: AppType.title(t.ink)),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(subtitle, style: AppType.caption(t.mut)),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    selected ? LucideIcons.circleCheck : LucideIcons.circle,
                    size: 22,
                    color: selected ? t.acc : t.line,
                  ),
                ],
              ),
              ?preview,
            ],
          ),
        ),
      ),
    );
  }
}
