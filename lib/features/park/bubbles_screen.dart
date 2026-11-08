import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/content/content_repository.dart';
import 'park_scaffold.dart';

/// Baloncuklar: slowly rising bubbles, each holding a picture. A tap pops the
/// bubble softly, the picture grows and its name is said. No timer, no score.
class BubblesScreen extends StatefulWidget {
  final AppState state;
  const BubblesScreen({super.key, required this.state});
  @override
  State<BubblesScreen> createState() => _BubblesScreenState();
}

class _Bubble {
  final int id;
  final ContentItem item;
  final double x, size, sway;
  final int bornMs;
  _Bubble(this.id, this.item, this.x, this.size, this.sway, this.bornMs);
}

class _BubblesScreenState extends State<BubblesScreen>
    with SingleTickerProviderStateMixin {
  static const _riseMs = 13000;
  static const _spawnEveryMs = 2600;
  static const _maxBubbles = 5;

  AppState get s => widget.state;
  final _random = math.Random();
  late final Ticker _ticker = createTicker(_tick);
  final _bubbles = <_Bubble>[];
  late final List<ContentItem> _pool;
  int _nowMs = 0, _lastSpawnMs = -_spawnEveryMs, _nextId = 0;
  ContentItem? _shown;
  int _shownKey = 0;
  Timer? _hide;

  @override
  void initState() {
    super.initState();
    s.enterGame();
    _pool = [
      for (final item in s.content.items)
        if (item.images.isNotEmpty && item.audioFor(s.locale) != null) item,
    ]..shuffle(_random);
    _ticker.start();
  }

  void _tick(Duration elapsed) {
    _nowMs = elapsed.inMilliseconds;
    _bubbles.removeWhere((b) => _nowMs - b.bornMs > _riseMs);
    if (_nowMs - _lastSpawnMs >= _spawnEveryMs &&
        _bubbles.length < _maxBubbles &&
        _pool.isNotEmpty) {
      _lastSpawnMs = _nowMs;
      _bubbles.add(
        _Bubble(
          _nextId,
          _pool[_nextId % _pool.length],
          .1 + _random.nextDouble() * .8,
          .24 + _random.nextDouble() * .1,
          _random.nextDouble() * math.pi * 2,
          _nowMs,
        ),
      );
      _nextId++;
    }
    setState(() {});
  }

  void _pop(_Bubble bubble) {
    UiSound.tap();
    final cue = bubble.item.audioFor(s.locale);
    if (cue != null) unawaited(s.audio.playSequence([cue]));
    setState(() {
      _bubbles.remove(bubble);
      _shown = bubble.item;
      _shownKey++;
    });
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _shown = null);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    _hide?.cancel();
    s.leaveGame();
    if (!s.inGame) s.audio.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = parkL10n(context, s);
    return ParkScaffold(
      title: l10n.parkBubbles,
      background: 'assets/illustrations/home/bg_park.jpg',
      onBack: () => context.go('/'),
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth, h = box.maxHeight;
          final reduced =
              s.reducedMotion || MediaQuery.disableAnimationsOf(context);
          return Stack(
            children: [
              for (final b in _bubbles)
                _bubbleAt(b, w, h, reduced),
              if (_shown case final item?)
                Center(
                  child: IgnorePointer(
                    child: SizedBox.square(
                      dimension: h * .78,
                      child: HopIn(
                        key: ValueKey('bubble-picture-$_shownKey'),
                        animate: !reduced,
                        child: ItemVisual(item),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _bubbleAt(_Bubble b, double w, double h, bool reduced) {
    final t = ((_nowMs - b.bornMs) / _riseMs).clamp(0.0, 1.0);
    final size = b.size * h;
    final sway = reduced ? 0 : math.sin(t * math.pi * 3 + b.sway) * w * .025;
    return Positioned(
      key: ValueKey('bubble-${b.id}'),
      left: (b.x * (w - size)) + sway,
      top: h - t * (h + size),
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pop(b),
        child: Semantics(
          button: true,
          label: b.item.name(s.locale),
          excludeSemantics: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: .32),
              border: Border.all(
                color: Colors.white.withValues(alpha: .9),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: SegColors.sky.withValues(alpha: .35),
                  blurRadius: 14,
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(size * .08),
              child: ItemVisual(b.item),
            ),
          ),
        ),
      ),
    );
  }
}
