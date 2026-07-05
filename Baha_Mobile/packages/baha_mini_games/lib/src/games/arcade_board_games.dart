import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../core/game_shell.dart';
import '../core/models.dart';

class Game2048Screen extends StatefulWidget {
  const Game2048Screen({
    super.key,
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  State<Game2048Screen> createState() => _Game2048ScreenState();
}

class _Game2048ScreenState extends State<Game2048Screen> {
  static const _size = 4;
  late List<List<int>> _board;
  int _score = 0;
  int _undoScore = 0;
  List<List<int>>? _undoBoard;
  bool _paused = false;
  bool _finished = false;
  int _moves = 0;
  final _rng = math.Random(2048);
  DateTime? _startedAt;
  bool _gameOverDialogVisible = false;
  int _lastHighestTile = 0;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(_size, (_) => List.filled(_size, 0));
    _score = 0;
    _moves = 0;
    _finished = false;
    _paused = false;
    _undoBoard = null;
    _startedAt = DateTime.now();
    _gameOverDialogVisible = false;
    _lastHighestTile = 0;
    _spawn();
    _spawn();
  }

  void _spawn() {
    final cells = <Offset>[];
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        if (_board[r][c] == 0) {
          cells.add(Offset(c.toDouble(), r.toDouble()));
        }
      }
    }
    if (cells.isEmpty) {
      return;
    }
    final pick = cells[_rng.nextInt(cells.length)];
    _board[pick.dy.toInt()][pick.dx.toInt()] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _collapse(List<int> line) {
    final compressed = line.where((v) => v != 0).toList();
    final result = <int>[];
    var bonus = 0;
    for (var i = 0; i < compressed.length; i++) {
      if (i + 1 < compressed.length && compressed[i] == compressed[i + 1]) {
        final merged = compressed[i] * 2;
        result.add(merged);
        bonus += merged;
        i++;
      } else {
        result.add(compressed[i]);
      }
    }
    while (result.length < _size) {
      result.add(0);
    }
    _score += bonus;
    return result;
  }

  void _move(Direction direction) {
    if (_paused || _finished) {
      return;
    }
    final previous = _copyBoard();
    final previousScore = _score;
    var changed = false;
    switch (direction) {
      case Direction.left:
        for (var r = 0; r < _size; r++) {
          final line = _collapse(_board[r]);
          if (!_listEquals(_board[r], line)) {
            changed = true;
            _board[r] = line;
          }
        }
      case Direction.right:
        for (var r = 0; r < _size; r++) {
          final line = _collapse(_board[r].reversed.toList()).reversed.toList();
          if (!_listEquals(_board[r], line)) {
            changed = true;
            _board[r] = line;
          }
        }
      case Direction.up:
        for (var c = 0; c < _size; c++) {
          final line = _collapse(List.generate(_size, (r) => _board[r][c]));
          for (var r = 0; r < _size; r++) {
            if (_board[r][c] != line[r]) {
              changed = true;
              _board[r][c] = line[r];
            }
          }
        }
      case Direction.down:
        for (var c = 0; c < _size; c++) {
          final line = _collapse(
            List.generate(_size, (r) => _board[_size - 1 - r][c]),
          ).reversed.toList();
          for (var r = 0; r < _size; r++) {
            if (_board[r][c] != line[r]) {
              changed = true;
              _board[r][c] = line[r];
            }
          }
        }
    }
    if (changed) {
      _undoBoard = previous;
      _undoScore = previousScore;
      _moves += 1;
      _spawn();
      _lastHighestTile = _highestTile();
      HapticFeedback.selectionClick();
      setState(() {});
      _finishIfNeeded();
    }
  }

  bool _canMove() {
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        final value = _board[r][c];
        if (value == 0) {
          return true;
        }
        if (r + 1 < _size && _board[r + 1][c] == value) return true;
        if (c + 1 < _size && _board[r][c + 1] == value) return true;
      }
    }
    return false;
  }

  void _finishIfNeeded() {
    if (!_canMove()) {
      _finished = true;
      unawaited(_recordAndPresentGameOver());
    }
  }

  Future<void> _recordAndPresentGameOver() async {
    final durationMs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inMilliseconds;
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: _score,
        completed: false,
        durationMs: durationMs,
        retryCount: _moves,
        accuracy:
            _highestTile() / math.max(2, _score == 0 ? 2 : _highestTile()),
        levelReached: _highestTile(),
        difficultyPlayed: 'classic',
        moves: _moves,
        metadata: <String, dynamic>{
          'highestTile': _highestTile(),
          'game': '2048',
        },
      ),
    );
    if (!mounted || _gameOverDialogVisible) {
      return;
    }
    _gameOverDialogVisible = true;
    await Future<void>.delayed(const Duration(milliseconds: 240));
    if (!mounted) {
      return;
    }
    final progress = widget.controller.progressFor(widget.definition.id);
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Game Over'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Final score $_score'),
            Text('Highest tile ${_highestTile()}'),
            Text('Best score ${math.max(progress.bestScore, _score)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Home'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(_reset);
            },
            child: const Text('Restart'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(_reset);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
    _gameOverDialogVisible = false;
  }

  int _highestTile() {
    var maxValue = 0;
    for (final row in _board) {
      for (final cell in row) {
        maxValue = math.max(maxValue, cell);
      }
    }
    return maxValue;
  }

  List<List<int>> _copyBoard() =>
      _board.map((row) => List<int>.from(row)).toList();

  bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _undo() {
    if (_undoBoard == null) return;
    setState(() {
      _board = _copy(_undoBoard!);
      _score = _undoScore;
    });
  }

  List<List<int>> _copy(List<List<int>> value) =>
      value.map((row) => List<int>.from(row)).toList();

  @override
  Widget build(BuildContext context) {
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: () => setState(() => _paused = !_paused),
      onRestart: () => setState(_reset),
      onShowResult: () => _showResult(context),
      child: GestureDetector(
        onPanEnd: (details) {
          final velocity = details.velocity.pixelsPerSecond;
          if (velocity.dx.abs() > velocity.dy.abs()) {
            _move(velocity.dx > 0 ? Direction.right : Direction.left);
          } else {
            _move(velocity.dy > 0 ? Direction.down : Direction.up);
          }
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Score $_score',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const Spacer(),
                  Text(
                    'Best ${widget.controller.progressFor(widget.definition.id).bestScore}',
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Moves $_moves',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  TextButton(onPressed: _undo, child: const Text('Undo')),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _size * _size,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _size,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                          ),
                      itemBuilder: (context, index) {
                        final row = index ~/ _size;
                        final col = index % _size;
                        final value = _board[row][col];
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          decoration: BoxDecoration(
                            color: value == 0
                                ? Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest
                                : Color.lerp(
                                    widget.definition.accent.withValues(
                                      alpha: 0.2,
                                    ),
                                    Colors.white,
                                    (math.log(value) / math.ln2 / 11).clamp(
                                      0.0,
                                      1.0,
                                    ),
                                  ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: value == _lastHighestTile && value != 0
                                ? [
                                    BoxShadow(
                                      color: widget.definition.accent
                                          .withValues(alpha: 0.22),
                                      blurRadius: 16,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            value == 0 ? '' : '$value',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
            if (_paused)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Paused',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResult(BuildContext context) async {
    final bestScore = widget.controller
        .progressFor(widget.definition.id)
        .bestScore;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('2048 session', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Score $_score, highest tile ${_highestTile()}'),
            const SizedBox(height: 6),
            Text('Best score $bestScore, moves $_moves'),
          ],
        ),
      ),
    );
  }
}

enum Direction { left, right, up, down }

class SlidingPuzzleScreen extends StatefulWidget {
  const SlidingPuzzleScreen({
    super.key,
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  State<SlidingPuzzleScreen> createState() => _SlidingPuzzleScreenState();
}

class _SlidingPuzzleScreenState extends State<SlidingPuzzleScreen> {
  late List<int> _tiles;
  late int _size;
  int _moves = 0;
  final _rng = math.Random(31);
  DateTime? _startedAt;
  bool _finished = false;
  bool _showCelebration = false;
  late _PuzzleArtwork _artwork;
  static const _spacing = 8.0;

  final List<_PuzzleArtwork> _artworks = const <_PuzzleArtwork>[
    _PuzzleArtwork(
      id: 'animals',
      title: 'Animals',
      icon: Icons.pets_rounded,
      gradient: [Color(0xFF22C55E), Color(0xFF84CC16)],
    ),
    _PuzzleArtwork(
      id: 'nature',
      title: 'Nature',
      icon: Icons.park_rounded,
      gradient: [Color(0xFF0EA5E9), Color(0xFF14B8A6)],
    ),
    _PuzzleArtwork(
      id: 'space',
      title: 'Space',
      icon: Icons.rocket_launch_rounded,
      gradient: [Color(0xFF312E81), Color(0xFF7C3AED)],
    ),
    _PuzzleArtwork(
      id: 'cars',
      title: 'Cars',
      icon: Icons.directions_car_filled_rounded,
      gradient: [Color(0xFFEA580C), Color(0xFFF97316)],
    ),
    _PuzzleArtwork(
      id: 'cartoons',
      title: 'Cartoons',
      icon: Icons.sentiment_very_satisfied_rounded,
      gradient: [Color(0xFFF43F5E), Color(0xFFF59E0B)],
    ),
    _PuzzleArtwork(
      id: 'cities',
      title: 'Cities',
      icon: Icons.location_city_rounded,
      gradient: [Color(0xFF2563EB), Color(0xFF0F172A)],
    ),
    _PuzzleArtwork(
      id: 'landscapes',
      title: 'Landscapes',
      icon: Icons.landscape_rounded,
      gradient: [Color(0xFF0F766E), Color(0xFF22C55E)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _size = 3;
    _artwork = _artworks.first;
    _reset();
  }

  void _reset() {
    _tiles = List<int>.generate(_size * _size, (index) => index + 1);
    _tiles[_tiles.length - 1] = 0;
    for (var i = 0; i < _size * _size * 12; i++) {
      _shuffleOnce();
    }
    _moves = 0;
    _finished = false;
    _showCelebration = false;
    _startedAt = DateTime.now();
  }

  void _shuffleOnce() {
    final blank = _tiles.indexOf(0);
    final r = blank ~/ _size;
    final c = blank % _size;
    final neighbors = <int>[
      if (r > 0) blank - _size,
      if (r + 1 < _size) blank + _size,
      if (c > 0) blank - 1,
      if (c + 1 < _size) blank + 1,
    ];
    final chosen = neighbors[_rng.nextInt(neighbors.length)];
    _tiles[blank] = _tiles[chosen];
    _tiles[chosen] = 0;
  }

  bool _isSolved() {
    for (var i = 0; i < _tiles.length - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles.last == 0;
  }

  void _tap(int index) {
    if (_finished) return;
    final blank = _tiles.indexOf(0);
    final row = index ~/ _size;
    final col = index % _size;
    final blankRow = blank ~/ _size;
    final blankCol = blank % _size;
    final adjacent =
        (row == blankRow && (col - blankCol).abs() == 1) ||
        (col == blankCol && (row - blankRow).abs() == 1);
    if (!adjacent) return;
    setState(() {
      _tiles[blank] = _tiles[index];
      _tiles[index] = 0;
      _moves += 1;
      if (_isSolved()) {
        _finished = true;
        _showCelebration = true;
        unawaited(_finishSolvedGame());
      }
    });
  }

  Future<void> _finishSolvedGame() async {
    final durationMs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inMilliseconds;
    final score = math.max(200, 1800 - (_moves * 18) - (durationMs ~/ 250));
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: score,
        completed: true,
        durationMs: durationMs,
        accuracy: 1,
        averageDecisionTimeMs: _moves == 0 ? 0 : durationMs ~/ _moves,
        retryCount: 0,
        levelReached: _size,
        difficultyPlayed: '${_size}x$_size',
        moves: _moves,
        comboCount: 3,
        longestCombo: 3,
        metadata: <String, dynamic>{'artwork': _artwork.id, 'gridSize': _size},
      ),
    );
    if (!mounted) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Puzzle Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Artwork ${_artwork.title}'),
            Text('Moves $_moves'),
            Text('Time ${_formatDuration(durationMs)}'),
            const SizedBox(height: 10),
            Row(
              children: const [
                Icon(Icons.star_rounded, color: Colors.amber),
                Icon(Icons.star_rounded, color: Colors.amber),
                Icon(Icons.star_half_rounded, color: Colors.amber),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              setState(_reset);
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
    if (mounted) {
      setState(() => _showCelebration = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = widget.controller.progressFor(widget.definition.id);
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: math.max(0, 1800 - _moves * 18),
      onPause: () {},
      onRestart: () => setState(_reset),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Moves $_moves'),
                    const Spacer(),
                    Text(
                      'Best ${_formatDuration(progress.personalBestTimeMs)}',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final dimension in const [3, 4, 5])
                      ChoiceChip(
                        label: Text('${dimension}x$dimension'),
                        selected: _size == dimension,
                        onSelected: (_) => setState(() {
                          _size = dimension;
                          _reset();
                        }),
                      ),
                    ActionChip(
                      label: const Text('Random image'),
                      avatar: const Icon(Icons.shuffle_rounded, size: 18),
                      onPressed: () => setState(() {
                        _artwork = _artworks[_rng.nextInt(_artworks.length)];
                        _reset();
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final artwork = _artworks[index];
                      final selected = artwork.id == _artwork.id;
                      return ChoiceChip(
                        avatar: Icon(artwork.icon, size: 18),
                        label: Text(artwork.title),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _artwork = artwork;
                          _reset();
                        }),
                      );
                    },
                    separatorBuilder: (_, index) => const SizedBox(width: 8),
                    itemCount: _artworks.length,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final boardExtent = constraints.maxWidth;
                      final tileExtent =
                          (boardExtent - (_spacing * (_size - 1))) / _size;
                      return Stack(
                        children: [
                          GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _tiles.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _size,
                                  crossAxisSpacing: _spacing,
                                  mainAxisSpacing: _spacing,
                                ),
                            itemBuilder: (context, index) {
                              final value = _tiles[index];
                              if (value == 0) {
                                return DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                );
                              }
                              final solvedIndex = value - 1;
                              final solvedRow = solvedIndex ~/ _size;
                              final solvedCol = solvedIndex % _size;
                              return InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _tap(index),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Transform.translate(
                                        offset: Offset(
                                          -solvedCol * tileExtent,
                                          -solvedRow * tileExtent,
                                        ),
                                        child: SizedBox(
                                          width: boardExtent,
                                          height: boardExtent,
                                          child: _PuzzleArtworkScene(
                                            artwork: _artwork,
                                          ),
                                        ),
                                      ),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: Container(
                                          margin: const EdgeInsets.all(6),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.48,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              99,
                                            ),
                                          ),
                                          child: Text(
                                            '$value',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          if (_showCelebration)
                            Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(
                                  painter: _ConfettiPainter(
                                    accent: _artwork.gradient.first,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
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

class _PuzzleArtwork {
  const _PuzzleArtwork({
    required this.id,
    required this.title,
    required this.icon,
    required this.gradient,
  });

  final String id;
  final String title;
  final IconData icon;
  final List<Color> gradient;
}

class _PuzzleArtworkScene extends StatelessWidget {
  const _PuzzleArtworkScene({required this.artwork});

  final _PuzzleArtwork artwork;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: artwork.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: 20,
            top: 20,
            child: Icon(
              artwork.icon,
              size: 90,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          Positioned(
            right: 24,
            top: 40,
            child: Icon(
              artwork.icon,
              size: 44,
              color: Colors.white.withValues(alpha: 0.34),
            ),
          ),
          Positioned(
            right: 18,
            bottom: 22,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 22,
            bottom: 22,
            child: Text(
              artwork.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({required this.accent});

  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (var i = 0; i < 36; i++) {
      final x = (size.width / 36) * i;
      final y = (size.height * ((i * 37) % 100) / 100);
      paint.color = Color.lerp(
        accent,
        Colors.white,
        (i % 5) / 5,
      )!.withValues(alpha: 0.9);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, 10 + (i % 6), 6 + (i % 4)),
          const Radius.circular(4),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

String _formatDuration(int milliseconds) {
  if (milliseconds <= 0) {
    return '0s';
  }
  final totalSeconds = milliseconds ~/ 1000;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  if (minutes == 0) {
    return '${seconds}s';
  }
  return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
}

class MemoryFlipScreen extends StatefulWidget {
  const MemoryFlipScreen({
    super.key,
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  State<MemoryFlipScreen> createState() => _MemoryFlipScreenState();
}

class _MemoryFlipScreenState extends State<MemoryFlipScreen> {
  late List<_MemoryCard> _cards;
  int _score = 0;
  int _flips = 0;
  int? _first;
  int? _second;
  bool _locked = false;
  DateTime? _startedAt;
  final _icons = <IconData>[
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.spa_rounded,
    Icons.bolt_rounded,
    Icons.music_note_rounded,
    Icons.rocket_launch_rounded,
    Icons.sports_rounded,
    Icons.self_improvement_rounded,
  ];

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _cards = [
      for (final icon in _icons) ...[_MemoryCard(icon), _MemoryCard(icon)],
    ];
    _cards.shuffle(math.Random(91));
    _score = 0;
    _flips = 0;
    _first = null;
    _second = null;
    _locked = false;
    _startedAt = DateTime.now();
    setState(() {});
  }

  void _tap(int index) async {
    if (_locked || _cards[index].matched || _cards[index].visible) return;
    setState(() {
      _cards[index].visible = true;
      _flips += 1;
      if (_first == null) {
        _first = index;
      } else {
        _second = index;
        _locked = true;
      }
    });
    if (_first != null && _second != null) {
      await Future<void>.delayed(const Duration(milliseconds: 480));
      final first = _first!;
      final second = _second!;
      final match = _cards[first].icon == _cards[second].icon;
      setState(() {
        if (match) {
          _cards[first].matched = true;
          _cards[second].matched = true;
          _score += 80;
        } else {
          _cards[first].visible = false;
          _cards[second].visible = false;
          _score = math.max(0, _score - 15);
        }
        _first = null;
        _second = null;
        _locked = false;
      });
      if (_cards.every((card) => card.matched)) {
        unawaited(
          widget.controller.recordSession(
            gameId: widget.definition.id,
            result: MiniGameResult(
              score: _score + 200,
              completed: true,
              durationMs: DateTime.now()
                  .difference(_startedAt ?? DateTime.now())
                  .inMilliseconds,
              accuracy: _cards.length / _flips,
              averageDecisionTimeMs: 0,
              retryCount: 0,
              difficultyPlayed: 'classic',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: () {},
      onRestart: () => _reset(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('Flips $_flips'),
                const Spacer(),
                Text(
                  'Matched ${_cards.where((card) => card.matched).length ~/ 2}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _cards.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemBuilder: (context, index) {
                final card = _cards[index];
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _tap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    decoration: BoxDecoration(
                      color: card.visible || card.matched
                          ? widget.definition.accent.withValues(alpha: 0.16)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: card.visible || card.matched ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Icon(card.icon, size: 34),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ConnectFourScreen extends StatefulWidget {
  const ConnectFourScreen({
    super.key,
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  State<ConnectFourScreen> createState() => _ConnectFourScreenState();
}

class _ConnectFourScreenState extends State<ConnectFourScreen> {
  static const rows = 6;
  static const cols = 7;
  late List<List<int>> _grid;
  int _currentPlayer = 1;
  int _score = 0;
  bool _finished = false;
  DateTime? _startedAt;
  int _turns = 0;
  bool _thinking = false;
  String _difficulty = 'Medium';
  Offset? _lastMove;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _grid = List.generate(rows, (_) => List.filled(cols, 0));
    _currentPlayer = 1;
    _score = 0;
    _turns = 0;
    _finished = false;
    _thinking = false;
    _lastMove = null;
    _startedAt = DateTime.now();
    setState(() {});
  }

  int _drop(int column, int player) {
    for (var row = rows - 1; row >= 0; row--) {
      if (_grid[row][column] == 0) {
        _grid[row][column] = player;
        _lastMove = Offset(column.toDouble(), row.toDouble());
        return row;
      }
    }
    return -1;
  }

  bool _wins(int player) {
    bool four(int r, int c, int dr, int dc) {
      for (var i = 0; i < 4; i++) {
        final rr = r + dr * i;
        final cc = c + dc * i;
        if (rr < 0 ||
            rr >= rows ||
            cc < 0 ||
            cc >= cols ||
            _grid[rr][cc] != player) {
          return false;
        }
      }
      return true;
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (_grid[r][c] != player) continue;
        if (four(r, c, 1, 0) ||
            four(r, c, 0, 1) ||
            four(r, c, 1, 1) ||
            four(r, c, 1, -1)) {
          return true;
        }
      }
    }
    return false;
  }

  int _aiMove() {
    final depth = switch (_difficulty) {
      'Easy' => 1,
      'Medium' => 3,
      'Hard' => 4,
      _ => 5,
    };
    final (_, column) = _minimax(_cloneGrid(), depth, -1000000, 1000000, true);
    return column ?? _availableColumns(_grid).first;
  }

  List<List<int>> _cloneGrid() =>
      _grid.map((row) => List<int>.from(row)).toList();

  List<int> _availableColumns(List<List<int>> board) {
    return List<int>.generate(
      cols,
      (index) => index,
    ).where((column) => board[0][column] == 0).toList();
  }

  bool _winsOn(List<List<int>> grid, int player) {
    bool four(int r, int c, int dr, int dc) {
      for (var i = 0; i < 4; i++) {
        final rr = r + dr * i;
        final cc = c + dc * i;
        if (rr < 0 ||
            rr >= rows ||
            cc < 0 ||
            cc >= cols ||
            grid[rr][cc] != player) {
          return false;
        }
      }
      return true;
    }

    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c] != player) continue;
        if (four(r, c, 1, 0) ||
            four(r, c, 0, 1) ||
            four(r, c, 1, 1) ||
            four(r, c, 1, -1)) {
          return true;
        }
      }
    }
    return false;
  }

  (int, int?) _minimax(
    List<List<int>> board,
    int depth,
    int alpha,
    int beta,
    bool maximizing,
  ) {
    final validColumns = _availableColumns(board);
    final aiWin = _winsOn(board, 2);
    final playerWin = _winsOn(board, 1);
    if (depth == 0 || aiWin || playerWin || validColumns.isEmpty) {
      if (aiWin) {
        return (100000 + depth, null);
      }
      if (playerWin) {
        return (-100000 - depth, null);
      }
      if (validColumns.isEmpty) {
        return (0, null);
      }
      return (_evaluateBoard(board), null);
    }
    if (maximizing) {
      var bestScore = -1000000;
      int? bestColumn;
      for (final column in validColumns) {
        final next = _copyGrid(board);
        _dropOn(next, column, 2);
        final (score, _) = _minimax(next, depth - 1, alpha, beta, false);
        if (score > bestScore) {
          bestScore = score;
          bestColumn = column;
        }
        alpha = math.max(alpha, bestScore);
        if (alpha >= beta) {
          break;
        }
      }
      return (bestScore, bestColumn);
    }
    var bestScore = 1000000;
    int? bestColumn;
    for (final column in validColumns) {
      final next = _copyGrid(board);
      _dropOn(next, column, 1);
      final (score, _) = _minimax(next, depth - 1, alpha, beta, true);
      if (score < bestScore) {
        bestScore = score;
        bestColumn = column;
      }
      beta = math.min(beta, bestScore);
      if (alpha >= beta) {
        break;
      }
    }
    return (bestScore, bestColumn);
  }

  int _dropOn(List<List<int>> board, int column, int player) {
    for (var row = rows - 1; row >= 0; row--) {
      if (board[row][column] == 0) {
        board[row][column] = player;
        return row;
      }
    }
    return -1;
  }

  List<List<int>> _copyGrid(List<List<int>> board) {
    return board.map((row) => List<int>.from(row)).toList();
  }

  int _evaluateBoard(List<List<int>> board) {
    var score = 0;
    final centerColumn = List<int>.generate(
      rows,
      (row) => board[row][cols ~/ 2],
    );
    score += centerColumn.where((cell) => cell == 2).length * 6;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols - 3; col++) {
        score += _evaluateWindow([
          board[row][col],
          board[row][col + 1],
          board[row][col + 2],
          board[row][col + 3],
        ]);
      }
    }
    for (var row = 0; row < rows - 3; row++) {
      for (var col = 0; col < cols; col++) {
        score += _evaluateWindow([
          board[row][col],
          board[row + 1][col],
          board[row + 2][col],
          board[row + 3][col],
        ]);
      }
    }
    for (var row = 0; row < rows - 3; row++) {
      for (var col = 0; col < cols - 3; col++) {
        score += _evaluateWindow([
          board[row][col],
          board[row + 1][col + 1],
          board[row + 2][col + 2],
          board[row + 3][col + 3],
        ]);
      }
    }
    for (var row = 0; row < rows - 3; row++) {
      for (var col = 3; col < cols; col++) {
        score += _evaluateWindow([
          board[row][col],
          board[row + 1][col - 1],
          board[row + 2][col - 2],
          board[row + 3][col - 3],
        ]);
      }
    }
    return score;
  }

  int _evaluateWindow(List<int> window) {
    final aiCount = window.where((cell) => cell == 2).length;
    final playerCount = window.where((cell) => cell == 1).length;
    final emptyCount = window.where((cell) => cell == 0).length;
    if (aiCount == 4) return 200;
    if (aiCount == 3 && emptyCount == 1) return 16;
    if (aiCount == 2 && emptyCount == 2) return 5;
    if (playerCount == 3 && emptyCount == 1) return -14;
    if (playerCount == 4) return -200;
    return 0;
  }

  void _play(int column) async {
    if (_finished ||
        _thinking ||
        _currentPlayer != 1 ||
        _grid[0][column] != 0) {
      return;
    }
    final row = _drop(column, 1);
    if (row < 0) return;
    _turns += 1;
    _score += 10;
    _currentPlayer = 2;
    setState(() {});
    if (_wins(1)) {
      await _endGame(playerWon: true, draw: false);
      return;
    }
    if (_grid.every((row) => row.every((cell) => cell != 0))) {
      await _endGame(playerWon: false, draw: true);
      return;
    }
    _thinking = true;
    setState(() {});
    await Future<void>.delayed(const Duration(milliseconds: 260));
    final aiColumn = _aiMove();
    _drop(aiColumn, 2);
    _thinking = false;
    _currentPlayer = 1;
    if (_wins(2)) {
      await _endGame(playerWon: false, draw: false);
      return;
    }
    if (_grid.every((row) => row.every((cell) => cell != 0))) {
      await _endGame(playerWon: false, draw: true);
      return;
    }
    setState(() {});
  }

  Future<void> _endGame({required bool playerWon, required bool draw}) async {
    _finished = true;
    final durationMs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inMilliseconds;
    final completed = playerWon;
    final finalScore = draw ? _score + 50 : _score + (playerWon ? 220 : 20);
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: finalScore,
        completed: completed,
        durationMs: durationMs,
        accuracy: playerWon ? 1 : 0.5,
        averageDecisionTimeMs: _turns == 0 ? 0 : durationMs ~/ _turns,
        retryCount: 0,
        levelReached: _turns,
        difficultyPlayed: _difficulty.toLowerCase(),
        moves: _turns,
        metadata: <String, dynamic>{'draw': draw, 'difficulty': _difficulty},
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          draw
              ? 'Draw'
              : playerWon
              ? 'You Win'
              : 'AI Wins',
        ),
        content: Text(
          draw
              ? 'No more legal drops remain.'
              : playerWon
              ? 'Great connect four.'
              : 'The AI found the winning line.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _reset();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: () {},
      onRestart: () => _reset(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Turns $_turns'),
                    const Spacer(),
                    Text(
                      _thinking
                          ? 'AI thinking…'
                          : _currentPlayer == 1
                          ? 'Your turn'
                          : 'AI turn',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final level in const [
                      'Easy',
                      'Medium',
                      'Hard',
                      'Expert',
                    ])
                      ChoiceChip(
                        label: Text(level),
                        selected: _difficulty == level,
                        onSelected: (_) => setState(() {
                          _difficulty = level;
                          _reset();
                        }),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: cols / rows,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rows * cols,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ cols;
                    final col = index % cols;
                    final cell = _grid[row][col];
                    return InkWell(
                      onTap: () => _play(col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _lastMove?.dx == col && _lastMove?.dy == row
                              ? widget.definition.accent.withValues(alpha: 0.16)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: cell == 0 ? 18 : 24,
                            height: cell == 0 ? 18 : 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cell == 0
                                  ? Theme.of(context).colorScheme.surface
                                  : cell == 1
                                  ? widget.definition.accent
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OthelloScreen extends StatefulWidget {
  const OthelloScreen({
    super.key,
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  State<OthelloScreen> createState() => _OthelloScreenState();
}

class _OthelloScreenState extends State<OthelloScreen> {
  static const size = 8;
  late List<List<int>> _board;
  int _score = 0;
  bool _finished = false;
  DateTime? _startedAt;
  int _currentPlayer = 1;
  String _status = 'Your move';
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    _board = List.generate(size, (_) => List.filled(size, 0));
    _board[3][3] = -1;
    _board[4][4] = -1;
    _board[3][4] = 1;
    _board[4][3] = 1;
    _score = 0;
    _finished = false;
    _currentPlayer = 1;
    _status = 'Your move';
    _thinking = false;
    _startedAt = DateTime.now();
    setState(() {});
  }

  List<Offset> _flips(int row, int col, int player, List<List<int>> board) {
    if (board[row][col] != 0) return const [];
    final directions = <Offset>[
      const Offset(-1, -1),
      const Offset(-1, 0),
      const Offset(-1, 1),
      const Offset(0, -1),
      const Offset(0, 1),
      const Offset(1, -1),
      const Offset(1, 0),
      const Offset(1, 1),
    ];
    final toFlip = <Offset>[];
    for (final direction in directions) {
      final path = <Offset>[];
      var r = row + direction.dy.toInt();
      var c = col + direction.dx.toInt();
      while (r >= 0 &&
          r < size &&
          c >= 0 &&
          c < size &&
          board[r][c] == -player) {
        path.add(Offset(c.toDouble(), r.toDouble()));
        r += direction.dy.toInt();
        c += direction.dx.toInt();
      }
      if (path.isNotEmpty &&
          r >= 0 &&
          r < size &&
          c >= 0 &&
          c < size &&
          board[r][c] == player) {
        toFlip.addAll(path);
      }
    }
    return toFlip;
  }

  bool _play(int row, int col, int player) {
    final flips = _flips(row, col, player, _board);
    if (flips.isEmpty) return false;
    _board[row][col] = player;
    for (final flip in flips) {
      _board[flip.dy.toInt()][flip.dx.toInt()] = player;
    }
    return true;
  }

  List<math.Point<int>> _validMoves(int player) {
    final moves = <math.Point<int>>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (_flips(r, c, player, _board).isNotEmpty) {
          moves.add(math.Point(c, r));
        }
      }
    }
    return moves;
  }

  void _aiTurn() {
    _thinking = true;
    final moves = _validMoves(-1);
    if (moves.isEmpty) {
      _thinking = false;
      return;
    }
    moves.sort((a, b) {
      final aScore = _moveScore(a.y, a.x, -1);
      final bScore = _moveScore(b.y, b.x, -1);
      return bScore.compareTo(aScore);
    });
    _play(moves.first.y, moves.first.x, -1);
    _thinking = false;
  }

  int _moveScore(int row, int col, int player) {
    final flips = _flips(row, col, player, _board).length;
    final cornerBonus =
        ((row == 0 || row == size - 1) && (col == 0 || col == size - 1))
        ? 12
        : 0;
    final edgeBonus =
        (row == 0 || row == size - 1 || col == 0 || col == size - 1) ? 4 : 0;
    return flips + cornerBonus + edgeBonus;
  }

  Future<void> _tap(int row, int col) async {
    if (_finished || _thinking || _currentPlayer != 1) return;
    if (_play(row, col, 1)) {
      _score += 20;
      setState(() {});
      await _resolveTurnFlow(afterPlayerTurn: true);
    }
  }

  Future<void> _resolveTurnFlow({required bool afterPlayerTurn}) async {
    final aiMoves = _validMoves(-1);
    final playerMoves = _validMoves(1);
    if (aiMoves.isEmpty && playerMoves.isEmpty) {
      await _finishGame();
      return;
    }
    if (afterPlayerTurn) {
      if (aiMoves.isEmpty) {
        _currentPlayer = 1;
        _status = 'AI passes. Your move';
        setState(() {});
        return;
      }
      _currentPlayer = -1;
      _status = 'AI thinking…';
      setState(() {});
      await Future<void>.delayed(const Duration(milliseconds: 280));
      _aiTurn();
      final updatedPlayerMoves = _validMoves(1);
      final updatedAiMoves = _validMoves(-1);
      if (updatedPlayerMoves.isEmpty && updatedAiMoves.isEmpty) {
        await _finishGame();
        return;
      }
      if (updatedPlayerMoves.isEmpty && updatedAiMoves.isNotEmpty) {
        _status = 'No move available. AI keeps the turn';
        setState(() {});
        await Future<void>.delayed(const Duration(milliseconds: 240));
        _aiTurn();
      }
      _currentPlayer = 1;
      _status = 'Your move';
      setState(() {});
    }
  }

  Future<void> _finishGame() async {
    _finished = true;
    final playerCount = _board.expand((row) => row).where((v) => v == 1).length;
    final aiCount = _board.expand((row) => row).where((v) => v == -1).length;
    final durationMs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inMilliseconds;
    final playerWon = playerCount > aiCount;
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: _score + (playerWon ? 180 : 40),
        completed: playerWon,
        durationMs: durationMs,
        accuracy: playerCount / math.max(1, playerCount + aiCount),
        difficultyPlayed: 'adaptive',
        levelReached: playerCount,
        moves: playerCount + aiCount,
        metadata: <String, dynamic>{
          'playerCount': playerCount,
          'aiCount': aiCount,
        },
      ),
    );
    if (!mounted) {
      return;
    }
    _status = playerWon
        ? 'You win'
        : playerCount == aiCount
        ? 'Draw'
        : 'AI wins';
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(_status),
        content: Text('Player $playerCount • AI $aiCount'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              Navigator.of(context).maybePop();
            },
            child: const Text('Home'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _reset();
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validMoves = _validMoves(1);
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: () {},
      onRestart: () => _reset(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Player ${_board.expand((row) => row).where((v) => v == 1).length}',
                ),
                const Spacer(),
                Text(
                  'AI ${_board.expand((row) => row).where((v) => v == -1).length}',
                ),
                const SizedBox(width: 12),
                Text(_status),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AspectRatio(
                aspectRatio: 1,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: size * size,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: size,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (context, index) {
                    final row = index ~/ size;
                    final col = index % size;
                    final cell = _board[row][col];
                    final isValidMove = validMoves.contains(
                      math.Point(col, row),
                    );
                    return InkWell(
                      onTap: () => _tap(row, col),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isValidMove
                              ? widget.definition.accent.withValues(alpha: 0.12)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: cell == 0 ? (isValidMove ? 10 : 0) : 26,
                            height: cell == 0 ? (isValidMove ? 10 : 0) : 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cell == 0
                                  ? widget.definition.accent.withValues(
                                      alpha: 0.42,
                                    )
                                  : cell == 1
                                  ? widget.definition.accent
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MemoryCard {
  _MemoryCard(this.icon);
  final IconData icon;
  bool visible = false;
  bool matched = false;
}
