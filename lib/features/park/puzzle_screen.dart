import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/app_state.dart';
import '../../app/theme/tokens.dart';
import '../../app/ui/components.dart';
import '../../core/audio/audio_service.dart' show UiSound;
import '../../core/content/content_repository.dart';
import 'park_scaffold.dart';

/// Yapboz: the child picks a picture (and how many pieces: 4, 6 or 9), and
/// it comes cut into real jigsaw pieces, with tabs that lock into their
/// neighbours. A piece let go near its place slides in;
/// let go anywhere else it slides back. The finished picture says its name.
class PuzzleScreen extends StatefulWidget {
  final AppState state;
  const PuzzleScreen({super.key, required this.state});
  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

/// How the picture is cut: which way the tab of every inner edge points.
class PuzzleCut {
  final int cols, rows;

  /// [across] row, col: the edge to the right of that cell (+1 the tab points
  /// right). [down] row, col: the edge under that cell (+1 it points down).
  final List<List<int>> across, down;
  PuzzleCut(this.cols, this.rows, math.Random random)
    : across = [
        for (var r = 0; r < rows; r++)
          [for (var c = 0; c < cols - 1; c++) random.nextBool() ? 1 : -1],
      ],
      down = [
        for (var r = 0; r < rows - 1; r++)
          [for (var c = 0; c < cols; c++) random.nextBool() ? 1 : -1],
      ];

  /// How far a tab sticks out, as a part of a cell's side.
  static const tab = .22;

  /// The outline of piece [i] for cells of [side]; the cell itself starts
  /// at ([side] * [tab], [side] * [tab]) so the tabs fit in the box.
  Path path(int i, double side) {
    final col = i % cols, row = i ~/ cols;
    final t = side * tab;
    final a = Offset(t, t), b = Offset(t + side, t);
    final c = Offset(t + side, t + side), d = Offset(t, t + side);
    final path = Path()..moveTo(a.dx, a.dy);
    // Along each side; the bump is positive when it leaves the cell.
    _edge(
      path,
      a,
      b,
      const Offset(0, -1),
      row > 0 ? -down[row - 1][col] : 0,
      t,
    );
    _edge(
      path,
      b,
      c,
      const Offset(1, 0),
      col < cols - 1 ? across[row][col] : 0,
      t,
    );
    _edge(
      path,
      c,
      d,
      const Offset(0, 1),
      row < rows - 1 ? down[row][col] : 0,
      t,
    );
    _edge(
      path,
      d,
      a,
      const Offset(-1, 0),
      col > 0 ? -across[row][col - 1] : 0,
      t,
    );
    return path..close();
  }

  static void _edge(
    Path path,
    Offset from,
    Offset to,
    Offset outward,
    int bump,
    double height,
  ) {
    if (bump == 0) {
      path.lineTo(to.dx, to.dy);
      return;
    }
    final along = to - from;
    final out = outward * (height * bump);
    Offset at(double part, double lift) => from + along * part + out * lift;
    void curve(Offset c1, Offset c2, Offset end) =>
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
    // A narrow neck and a round head, like a real jigsaw tab.
    final neck = at(.37, 0);
    path.lineTo(neck.dx, neck.dy);
    curve(at(.44, .08), at(.24, .98), at(.5, 1));
    curve(at(.76, .98), at(.56, .08), at(.63, 0));
    path.lineTo(to.dx, to.dy);
  }
}

class _PieceClipper extends CustomClipper<Path> {
  final Path path;
  const _PieceClipper(this.path);
  @override
  Path getClip(Size size) => path;
  @override
  bool shouldReclip(_PieceClipper old) => old.path != path;
}

class _OutlinePainter extends CustomPainter {
  final Path path;
  final Color color;
  final double width;
  const _OutlinePainter(this.path, this.color, this.width);
  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(
    path,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeJoin = StrokeJoin.round
      ..color = color,
  );
  @override
  bool shouldRepaint(_OutlinePainter old) =>
      old.path != path || old.color != color || old.width != width;
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  AppState get s => widget.state;
  final _random = math.Random();
  final _area = GlobalKey();
  late final List<ContentItem> _pool;
  Difficulty _level = Difficulty.easy;

  /// The picture being put together; null while the child is choosing.
  ContentItem? _chosen;
  ContentItem get _item => _chosen!;
  late PuzzleCut _cut;

  /// Where each piece waits: the tray's places in order, fixed for the round.
  late List<int> _tray;
  final Set<int> _placed = {};
  int _round = 0;
  Timer? _next;

  // The piece under the finger and its middle, in the play area.
  int? _drag;
  Offset _dragAt = Offset.zero;

  (int, int) get _grid => switch (_level) {
    Difficulty.easy => (2, 2),
    Difficulty.medium => (3, 2),
    Difficulty.hard => (3, 3),
  };
  bool get _finished => _placed.length == _tray.length;

  @override
  void initState() {
    super.initState();
    s.enterGame();
    // A shelf of pictures to choose from: a few from every kind of thing.
    final byTheme = <String, List<ContentItem>>{};
    for (final item in s.content.items) {
      if (item.images.isNotEmpty && item.audioFor(s.locale) != null) {
        byTheme.putIfAbsent(item.theme, () => []).add(item);
      }
    }
    _pool = [
      for (final theme in const [
        'animals',
        'vehicles',
        'produce',
        'food',
        'nature',
        'home',
        'music',
        'clothes',
      ])
        ...?byTheme[theme]?.take(3),
    ];
    _level = s.pickedDifficulty ?? Difficulty.easy;
  }

  void _start(ContentItem item) {
    _chosen = item;
    final (cols, rows) = _grid;
    _cut = PuzzleCut(cols, rows, _random);
    _tray = List.generate(cols * rows, (i) => i)..shuffle(_random);
    _placed.clear();
    _drag = null;
    _round++;
  }

  @override
  void dispose() {
    _next?.cancel();
    s.leaveGame();
    if (!s.inGame) s.audio.stop();
    super.dispose();
  }

  void _place(int piece) {
    UiSound.puzzleSnap();
    _placed.add(piece);
    if (!_finished) return;
    final cue = _item.audioFor(s.locale);
    if (cue != null) unawaited(s.audio.playSequence([cue]));
    // The finished picture stays a moment, then the shelf comes back.
    _next = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _chosen = null);
    });
  }

  Offset _local(Offset global) {
    final box = _area.currentContext?.findRenderObject();
    return box is RenderBox ? box.globalToLocal(global) : global;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = parkL10n(context, s);
    final (cols, rows) = _grid;
    final choosing = _chosen == null;
    return ParkScaffold(
      title: l10n.parkPuzzle,
      background: 'assets/illustrations/home/bg_park.jpg',
      onBack: () {
        if (choosing) return context.go('/');
        _next?.cancel();
        setState(() => _chosen = null);
      },
      // How many pieces is chosen with the picture, not in the middle of a
      // puzzle.
      trailing: !choosing
          ? null
          : FittedBox(
              child: PillToggle<Difficulty>(
                key: const ValueKey('puzzle-level'),
                values: Difficulty.values,
                selected: _level,
                label: (d) => switch (d) {
                  Difficulty.easy => '4',
                  Difficulty.medium => '6',
                  Difficulty.hard => '9',
                },
                icon: (_) => Icons.extension_rounded,
                onChanged: (d) => setState(() => _level = d),
              ),
            ),
      child: choosing
          ? _shelf()
          : Padding(
              padding: const EdgeInsets.fromLTRB(
                SegSpace.s4,
                0,
                SegSpace.s4,
                SegSpace.s3,
              ),
              child: LayoutBuilder(
                builder: (context, box) {
                  // The board takes the height, but leaves the tray at least
                  // 40%.
                  final side = math.min(
                    box.maxHeight / rows,
                    box.maxWidth * .58 / cols,
                  );
                  final boardW = side * cols, boardH = side * rows;
                  final board = Rect.fromLTWH(
                    0,
                    (box.maxHeight - boardH) / 2,
                    boardW,
                    boardH,
                  );
                  final tray = Rect.fromLTRB(
                    boardW + SegSpace.s4,
                    0,
                    box.maxWidth,
                    box.maxHeight,
                  );
                  return _play(board, tray, side, cols, rows);
                },
              ),
            ),
    );
  }

  /// The pictures to choose from, side by side.
  Widget _shelf() => LayoutBuilder(
    builder: (context, box) {
      final side = (box.maxHeight - SegSpace.s5).clamp(120.0, 280.0);
      return Center(
        child: SizedBox(
          height: side,
          child: ListView.separated(
            key: const ValueKey('puzzle-shelf'),
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: SegSpace.s5),
            itemCount: _pool.length,
            separatorBuilder: (_, _) => const SizedBox(width: SegSpace.s4),
            itemBuilder: (context, i) => GestureDetector(
              key: ValueKey('puzzle-pick-${_pool[i].id}'),
              onTap: () {
                UiSound.tap();
                setState(() => _start(_pool[i]));
              },
              child: Container(
                width: side,
                padding: const EdgeInsets.all(SegSpace.s3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFFD9F0FF), Color(0xFFFFF6EA)],
                  ),
                  borderRadius: BorderRadius.circular(SegRadius.lg),
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C73DF).withValues(alpha: .22),
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ItemVisual(_pool[i]),
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _play(Rect board, Rect tray, double side, int cols, int rows) {
    final tab = side * PuzzleCut.tab;
    final full = side + tab * 2;
    final count = cols * rows;

    // The tray: rows of equal cells, each piece shrunk to fit its cell.
    final perRow = count <= 4 ? 2 : 3;
    final trayRows = (count / perRow).ceil();
    final cell = math.min(tray.width / perRow, tray.height / trayRows);
    final shown = math.min(cell * .94, full);
    final left = tray.left + (tray.width - cell * perRow) / 2;
    final top = tray.top + (tray.height - cell * trayRows) / 2;
    Rect home(int piece) {
      final at = _tray.indexOf(piece);
      return Rect.fromCenter(
        center: Offset(
          left + cell * (at % perRow + .5),
          top + cell * (at ~/ perRow + .5),
        ),
        width: shown,
        height: shown,
      );
    }

    Rect slot(int piece) => Rect.fromLTWH(
      board.left + (piece % cols) * side - tab,
      board.top + (piece ~/ cols) * side - tab,
      full,
      full,
    );

    Widget piece(int i, {bool outline = true}) {
      final path = _cut.path(i, side);
      return SizedBox.square(
        dimension: full,
        child: CustomPaint(
          foregroundPainter: outline
              ? _OutlinePainter(path, Colors.white, math.max(2, side * .02))
              : null,
          child: ClipPath(
            clipper: _PieceClipper(path),
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: board.width,
              maxWidth: board.width,
              minHeight: board.height,
              maxHeight: board.height,
              child: Transform.translate(
                offset: Offset(
                  tab - (i % cols) * side,
                  tab - (i ~/ cols) * side,
                ),
                child: _picture(board.width, board.height),
              ),
            ),
          ),
        ),
      );
    }

    Widget moving(int i) {
      final placed = _placed.contains(i);
      final dragging = _drag == i;
      final rect = placed
          ? slot(i)
          : dragging
          ? Rect.fromCenter(center: _dragAt, width: full, height: full)
          : home(i);
      return AnimatedPositioned(
        key: ValueKey('puzzle-piece-$_round-$i'),
        // Under the finger it follows at once; let go, it slides to its
        // place or back to the tray from where it is.
        duration: dragging ? Duration.zero : const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        left: rect.left,
        top: rect.top,
        width: rect.width,
        height: rect.height,
        child: IgnorePointer(
          ignoring: placed || _finished,
          child: GestureDetector(
            key: ValueKey('puzzle-piece-$i'),
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanStart: (d) => setState(() {
              _drag = i;
              _dragAt = _local(d.globalPosition);
            }),
            onPanUpdate: (d) {
              if (_drag != i) return;
              setState(() => _dragAt = _local(d.globalPosition));
            },
            onPanEnd: (_) => _letGo(i, slot(i).center, side),
            onPanCancel: () => _letGo(i, slot(i).center, side),
            child: FittedBox(child: piece(i, outline: !_finished)),
          ),
        ),
      );
    }

    // The carried piece is drawn last, over everything else.
    final carried = _placed.contains(_drag) ? null : _drag;
    final order = [
      for (var i = 0; i < count; i++)
        if (_placed.contains(i)) i,
      for (var i = 0; i < count; i++)
        if (!_placed.contains(i) && carried != i) i,
      ?carried,
    ];

    return Stack(
      key: _area,
      clipBehavior: Clip.none,
      children: [
        Positioned.fromRect(
          rect: board,
          child: DecoratedBox(
            key: ValueKey('puzzle-board-$_round'),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .8),
              borderRadius: BorderRadius.circular(SegRadius.sm),
              boxShadow: [
                BoxShadow(
                  color: SegColors.ink.withValues(alpha: .08),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(SegRadius.sm),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // A faint picture shows what is being made.
                  Opacity(
                    opacity: .16,
                    child: _picture(board.width, board.height),
                  ),
                  // Every piece's place, drawn as its own shape.
                  for (var i = 0; i < count; i++)
                    Positioned(
                      key: ValueKey('puzzle-slot-$i'),
                      left: (i % cols) * side - tab,
                      top: (i ~/ cols) * side - tab,
                      width: full,
                      height: full,
                      child: CustomPaint(
                        painter: _OutlinePainter(
                          _cut.path(i, side),
                          const Color(0xFFB9C9D6),
                          1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_finished)
          Positioned.fromRect(
            rect: tray,
            child: Center(
              child: Text(
                _item.name(s.locale),
                key: const ValueKey('puzzle-name'),
                style: SegText.title,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        for (final i in order) moving(i),
      ],
    );
  }

  void _letGo(int piece, Offset place, double side) {
    if (_drag != piece) return;
    setState(() {
      _drag = null;
      // Close is close enough for a small hand.
      if ((_dragAt - place).distance <= side * .6) _place(piece);
    });
  }

  Widget _picture(double w, double h) => SizedBox(
    width: w,
    height: h,
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFD9F0FF), Color(0xFFFFF6EA)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(h * .05),
        child: ItemVisual(_item),
      ),
    ),
  );
}
