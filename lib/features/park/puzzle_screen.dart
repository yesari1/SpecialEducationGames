import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/content/content_repository.dart';
import 'park_scaffold.dart';

/// Yapboz: a theme picture cut into 4, 6 or 9 pieces. A piece dropped near
/// its place snaps in; the finished picture says its name.
class PuzzleScreen extends StatefulWidget {
  final AppState state;
  const PuzzleScreen({super.key, required this.state});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  AppState get s => widget.state;
  final _random = math.Random();
  late final List<ContentItem> _pool;
  Difficulty _level = Difficulty.easy;
  late ContentItem _item;
  late List<int> _tray;
  final Set<int> _placed = {};
  int _round = 0;
  Timer? _next;

  (int, int) get _grid => switch (_level) {
    Difficulty.easy => (2, 2),
    Difficulty.medium => (3, 2),
    Difficulty.hard => (3, 3),
  };

  @override
  void initState() {
    super.initState();
    s.enterGame();
    _pool = [
      for (final item in s.content.items)
        if (item.images.isNotEmpty && item.audioFor(s.locale) != null) item,
    ];
    _newPuzzle();
  }

  void _newPuzzle() {
    _item = _pool[_random.nextInt(_pool.length)];
    final (cols, rows) = _grid;
    _tray = List.generate(cols * rows, (i) => i)..shuffle(_random);
    _placed.clear();
    _round++;
  }

  @override
  void dispose() {
    _next?.cancel();
    s.leaveGame();
    if (!s.inGame) s.audio.stop();
    super.dispose();
  }

  void _drop(int piece, int slot) {
    if (piece != slot) return;
    UiSound.basketDrop();
    setState(() {
      _placed.add(piece);
      _tray.remove(piece);
    });
    if (_tray.isNotEmpty) return;
    final cue = _item.audioFor(s.locale);
    if (cue != null) unawaited(s.audio.playSequence([cue]));
    _next = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(_newPuzzle);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = parkL10n(context, s);
    final (cols, rows) = _grid;
    return ParkScaffold(
      title: l10n.parkPuzzle,
      background: 'assets/illustrations/home/bg_park.jpg',
      onBack: () => context.go('/'),
      trailing: FittedBox(
        child: PillToggle<Difficulty>(
          key: const ValueKey('puzzle-level'),
          values: Difficulty.values,
          selected: _level,
          label: (d) => d.label(s.locale),
          onChanged: (d) => setState(() {
            _level = d;
            _next?.cancel();
            _newPuzzle();
          }),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          SegSpace.s4,
          0,
          SegSpace.s4,
          SegSpace.s3,
        ),
        child: LayoutBuilder(
          builder: (context, box) {
            final boardH = box.maxHeight;
            final side = boardH / rows;
            final boardW = side * cols;
            return Row(
              children: [
                SizedBox(
                  width: boardW,
                  height: boardH,
                  child: _board(cols, rows, boardW, boardH, side),
                ),
                const SizedBox(width: SegSpace.s4),
                Expanded(
                  child: _trayView(cols, rows, boardW, boardH, side),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _picture(double w, double h) => SizedBox(
    width: w,
    height: h,
    child: ColoredBox(
      color: const Color(0xFFFFF6EA),
      child: Padding(
        padding: EdgeInsets.all(h * .04),
        child: ItemVisual(_item),
      ),
    ),
  );

  /// One cut of the picture, for slot [i].
  Widget _piece(int i, int cols, int rows, double w, double h, double side) {
    final col = i % cols, row = i ~/ cols;
    return SizedBox.square(
      dimension: side,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxWidth: w,
          maxHeight: h,
          minWidth: w,
          minHeight: h,
          child: Transform.translate(
            offset: Offset(-col * side, -row * side),
            child: _picture(w, h),
          ),
        ),
      ),
    );
  }

  Widget _board(int cols, int rows, double w, double h, double side) =>
      DecoratedBox(
        key: ValueKey('puzzle-board-$_round'),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(SegRadius.sm),
        ),
        child: Stack(
          children: [
            for (var i = 0; i < cols * rows; i++)
              Positioned(
                left: (i % cols) * side,
                top: (i ~/ cols) * side,
                width: side,
                height: side,
                child: DragTarget<int>(
                  key: ValueKey('puzzle-slot-$i'),
                  // Close is close enough: the slot under the piece's middle.
                  onAcceptWithDetails: (d) => _drop(d.data, i),
                  builder: (context, _, _) => _placed.contains(i)
                      ? _piece(i, cols, rows, w, h, side)
                      : DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: SegColors.line,
                              width: 1.5,
                            ),
                          ),
                        ),
                ),
              ),
          ],
        ),
      );

  Widget _trayView(int cols, int rows, double w, double h, double side) {
    if (_tray.isEmpty) {
      return Center(
        child: Text(
          _item.name(s.locale),
          key: const ValueKey('puzzle-name'),
          style: SegText.title,
          textAlign: TextAlign.center,
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, box) {
        final count = _tray.length;
        final perRow = math.max(2, (count / 2).ceil());
        final tile = math.min(
          (box.maxWidth - SegSpace.s2 * (perRow - 1)) / perRow,
          (box.maxHeight - SegSpace.s2) / ((count / perRow).ceil()),
        ).clamp(40.0, side);
        return Center(
          child: Wrap(
            spacing: SegSpace.s2,
            runSpacing: SegSpace.s2,
            alignment: WrapAlignment.center,
            children: [
              for (final i in _tray)
                Draggable<int>(
                  key: ValueKey('puzzle-piece-$i'),
                  data: i,
                  dragAnchorStrategy: pointerDragAnchorStrategy,
                  feedback: Transform.translate(
                    offset: Offset(-side / 2, -side / 2),
                    child: Material(
                      type: MaterialType.transparency,
                      child: _piece(i, cols, rows, w, h, side),
                    ),
                  ),
                  childWhenDragging: SizedBox.square(dimension: tile),
                  child: SizedBox.square(
                    dimension: tile,
                    child: FittedBox(
                      child: _piece(i, cols, rows, w, h, side),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
