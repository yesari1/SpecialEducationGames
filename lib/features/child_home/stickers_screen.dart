import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/day_sticker.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/content/content_repository.dart';
import '../park/park_scaffold.dart';

/// Çıkartmalarım: the stickers theme by theme; the missing ones wait as faint
/// shadows. Tapping a sticker says its name. Daily stickers earned before the
/// themes had their own stay at the end.
class StickersScreen extends StatelessWidget {
  final AppState state;
  const StickersScreen({super.key, required this.state});

  static const _tile = 92.0;

  @override
  Widget build(BuildContext context) {
    final l10n = parkL10n(context, state);
    final byTheme = <String, List<Sticker>>{};
    for (final sticker in state.content.stickers) {
      byTheme.putIfAbsent(sticker.theme, () => []).add(sticker);
    }
    final days = state.dailyStickers.toList()..sort((a, b) => b.compareTo(a));
    return ParkScaffold(
      title: l10n.dailyPathMyStickers,
      background: 'assets/illustrations/home/bg_stories.jpg',
      onBack: () => context.go('/'),
      child: ListView(
        key: const ValueKey('stickers-list'),
        padding: const EdgeInsets.fromLTRB(
          SegSpace.s4,
          0,
          SegSpace.s4,
          SegSpace.s4,
        ),
        children: [
          for (final theme in state.orderedThemes)
            if (byTheme[theme.id] case final stickers?) ...[
              Padding(
                padding: const EdgeInsets.only(
                  top: SegSpace.s2,
                  bottom: SegSpace.s2,
                ),
                child: Text(theme.name(state.locale), style: SegText.heading),
              ),
              Wrap(
                spacing: SegSpace.s2,
                runSpacing: SegSpace.s2,
                children: [
                  for (final sticker in stickers)
                    _StickerTile(state: state, sticker: sticker, side: _tile),
                ],
              ),
            ],
          if (days.isNotEmpty) ...[
            const SizedBox(height: SegSpace.s3),
            Wrap(
              spacing: SegSpace.s2,
              runSpacing: SegSpace.s2,
              children: [
                for (final day in days) DaySticker(day: day, size: _tile),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StickerTile extends StatelessWidget {
  final AppState state;
  final Sticker sticker;
  final double side;
  const _StickerTile({
    required this.state,
    required this.sticker,
    required this.side,
  });
  @override
  Widget build(BuildContext context) {
    final earned = state.themeStickers.contains(sticker.id);
    final item = state.content.anyItem(sticker.item);
    final picture = Image.asset(
      sticker.image,
      key: ValueKey('sticker-${sticker.id}'),
      width: side,
      height: side,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    );
    if (!earned) {
      return ExcludeSemantics(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            SegColors.ink.withValues(alpha: .12),
            BlendMode.srcIn,
          ),
          child: picture,
        ),
      );
    }
    return Semantics(
      button: true,
      label: item?.name(state.locale),
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          UiSound.tap();
          final cue = item?.audioFor(state.locale);
          if (cue != null) unawaited(state.audio.playSequence([cue]));
        },
        child: picture,
      ),
    );
  }
}
