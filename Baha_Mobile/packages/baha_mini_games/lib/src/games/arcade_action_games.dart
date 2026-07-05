import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../core/game_shell.dart';
import '../core/models.dart';

const _tetrisPreviewSize = 4;

class TetrisScreen extends StatefulWidget {
  const TetrisScreen({
    super.key,
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  State<TetrisScreen> createState() => _TetrisScreenState();
}

class _TetrisScreenState extends State<TetrisScreen> {
  static const _rows = 20;
  static const _cols = 10;
  static const _lineScores = <int>[0, 100, 300, 500, 800];

  final _rng = math.Random(44);
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;

  late List<List<int>> _board;
  late List<int> _queue;
  int _currentType = 0;
  int _rotation = 0;
  int _row = 0;
  int _col = 3;
  int? _holdType;
  bool _holdUsed = false;
  bool _paused = false;
  bool _finished = false;
  int _score = 0;
  int _lines = 0;
  int _level = 1;
  int _moves = 0;
  int _combo = 0;
  int _longestCombo = 0;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _reset();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _reset() {
    _board = List.generate(_rows, (_) => List.filled(_cols, 0));
    _queue = <int>[];
    _currentType = 0;
    _rotation = 0;
    _row = 0;
    _col = 3;
    _holdType = null;
    _holdUsed = false;
    _paused = false;
    _finished = false;
    _score = 0;
    _lines = 0;
    _level = 1;
    _moves = 0;
    _combo = 0;
    _longestCombo = 0;
    _startedAt = DateTime.now();
    _fillQueue();
    _spawnPiece();
    _restartTimer();
    setState(() {});
  }

  void _fillQueue() {
    while (_queue.length < 5) {
      _queue.add(1 + _rng.nextInt(_tetrisPieces.length));
    }
  }

  void _restartTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_tickDuration, (_) => _step());
  }

  Duration get _tickDuration =>
      Duration(milliseconds: math.max(120, 700 - ((_level - 1) * 55)));

  void _spawnPiece() {
    _fillQueue();
    _currentType = _queue.removeAt(0);
    _rotation = 0;
    _row = 0;
    _col = 3;
    _holdUsed = false;
    if (!_canPlace(_currentType, _rotation, _row, _col)) {
      unawaited(_endGame());
    }
  }

  List<_TetrisCell> _cellsFor(int type, int rotation, int row, int col) {
    return _tetrisPieces[type - 1]
        .rotations[rotation % _tetrisPieces[type - 1].rotations.length]
        .map((cell) => _TetrisCell(row + cell.row, col + cell.col))
        .toList();
  }

  bool _canPlace(int type, int rotation, int row, int col) {
    for (final cell in _cellsFor(type, rotation, row, col)) {
      if (cell.row < 0 ||
          cell.row >= _rows ||
          cell.col < 0 ||
          cell.col >= _cols) {
        return false;
      }
      if (_board[cell.row][cell.col] != 0) {
        return false;
      }
    }
    return true;
  }

  void _step() {
    if (_paused || _finished) {
      return;
    }
    if (_canPlace(_currentType, _rotation, _row + 1, _col)) {
      setState(() => _row += 1);
      return;
    }
    _lockPiece();
  }

  void _lockPiece() {
    for (final cell in _cellsFor(_currentType, _rotation, _row, _col)) {
      _board[cell.row][cell.col] = _currentType;
    }
    final cleared = _clearLines();
    if (cleared > 0) {
      _combo += 1;
      _longestCombo = math.max(_longestCombo, _combo);
      _score += _lineScores[cleared] * _level;
      _lines += cleared;
      _level = (_lines ~/ 10) + 1;
      _restartTimer();
    } else {
      _combo = 0;
    }
    _spawnPiece();
    if (mounted) {
      setState(() {});
    }
  }

  int _clearLines() {
    var cleared = 0;
    final nextBoard = <List<int>>[];
    for (final row in _board) {
      if (row.every((cell) => cell != 0)) {
        cleared += 1;
      } else {
        nextBoard.add(List<int>.from(row));
      }
    }
    while (nextBoard.length < _rows) {
      nextBoard.insert(0, List.filled(_cols, 0));
    }
    _board = nextBoard;
    return cleared;
  }

  void _moveHorizontal(int delta) {
    if (_paused || _finished) return;
    if (_canPlace(_currentType, _rotation, _row, _col + delta)) {
      setState(() {
        _col += delta;
        _moves += 1;
      });
    }
  }

  void _rotate() {
    if (_paused || _finished) return;
    final nextRotation =
        (_rotation + 1) % _tetrisPieces[_currentType - 1].rotations.length;
    for (final kick in const [0, -1, 1, -2, 2]) {
      if (_canPlace(_currentType, nextRotation, _row, _col + kick)) {
        setState(() {
          _rotation = nextRotation;
          _col += kick;
          _moves += 1;
        });
        return;
      }
    }
  }

  void _softDrop() {
    if (_paused || _finished) return;
    if (_canPlace(_currentType, _rotation, _row + 1, _col)) {
      setState(() {
        _row += 1;
        _score += 1;
        _moves += 1;
      });
    } else {
      _lockPiece();
    }
  }

  void _hardDrop() {
    if (_paused || _finished) return;
    var targetRow = _row;
    while (_canPlace(_currentType, _rotation, targetRow + 1, _col)) {
      targetRow += 1;
    }
    setState(() {
      _score += (targetRow - _row) * 2;
      _row = targetRow;
      _moves += 1;
    });
    _lockPiece();
  }

  void _hold() {
    if (_paused || _finished || _holdUsed) return;
    final current = _currentType;
    if (_holdType == null) {
      _holdType = current;
      _spawnPiece();
    } else {
      _currentType = _holdType!;
      _holdType = current;
      _rotation = 0;
      _row = 0;
      _col = 3;
      if (!_canPlace(_currentType, _rotation, _row, _col)) {
        unawaited(_endGame());
      }
    }
    _holdUsed = true;
    setState(() {});
  }

  int _ghostRow() {
    var ghostRow = _row;
    while (_canPlace(_currentType, _rotation, ghostRow + 1, _col)) {
      ghostRow += 1;
    }
    return ghostRow;
  }

  Future<void> _endGame() async {
    if (_finished) {
      return;
    }
    _finished = true;
    _timer?.cancel();
    final durationMs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inMilliseconds;
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: _score,
        completed: false,
        durationMs: durationMs,
        retryCount: 0,
        reactionTimeMs: 180,
        averageDecisionTimeMs: _moves == 0 ? 0 : durationMs ~/ _moves,
        levelReached: _level,
        difficultyPlayed: 'marathon',
        moves: _moves,
        comboCount: _combo,
        longestCombo: _longestCombo,
        metadata: <String, dynamic>{'lines': _lines},
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {});
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Score $_score • Lines $_lines • Level $_level'),
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
            child: const Text('Restart'),
          ),
        ],
      ),
    );
  }

  void _togglePause() {
    setState(() {
      _paused = !_paused;
    });
  }

  KeyEventResult _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft) {
      _moveHorizontal(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      _moveHorizontal(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.keyX) {
      _rotate();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _softDrop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.space) {
      _hardDrop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyC) {
      _hold();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      _togglePause();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ghostRow = _ghostRow();
    final currentCells = _cellsFor(_currentType, _rotation, _row, _col);
    final ghostCells = _cellsFor(_currentType, _rotation, ghostRow, _col);
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: _togglePause,
      onRestart: _reset,
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('Level $_level'),
                  const SizedBox(width: 12),
                  Text('Lines $_lines'),
                  const Spacer(),
                  Text(_paused ? 'Paused' : 'Falling'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 92,
                      child: Column(
                        children: [
                          _TetrisPanel(
                            title: 'Hold',
                            child: _TetrisPreview(type: _holdType),
                          ),
                          const SizedBox(height: 12),
                          _TetrisPanel(
                            title: 'Next',
                            child: Column(
                              children: _queue
                                  .take(3)
                                  .map(
                                    (type) => _TetrisPreview(
                                      type: type,
                                      compact: true,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: _cols / _rows,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(6),
                            itemCount: _rows * _cols,
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: _cols,
                                  crossAxisSpacing: 2,
                                  mainAxisSpacing: 2,
                                ),
                            itemBuilder: (context, index) {
                              final row = index ~/ _cols;
                              final col = index % _cols;
                              final boardValue = _board[row][col];
                              final pieceCell = currentCells.any(
                                (cell) => cell.row == row && cell.col == col,
                              );
                              final ghostCell = ghostCells.any(
                                (cell) => cell.row == row && cell.col == col,
                              );
                              final color = boardValue != 0
                                  ? _tetrisPieces[boardValue - 1].color
                                  : pieceCell
                                  ? _tetrisPieces[_currentType - 1].color
                                  : ghostCell
                                  ? _tetrisPieces[_currentType - 1].color
                                        .withValues(alpha: 0.22)
                                  : Theme.of(context).colorScheme.surface;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 80),
                                decoration: BoxDecoration(
                                  color: color,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _TetrisControl(
                    icon: Icons.keyboard_double_arrow_left_rounded,
                    label: 'Left',
                    onPressed: () => _moveHorizontal(-1),
                  ),
                  _TetrisControl(
                    icon: Icons.rotate_right_rounded,
                    label: 'Rotate',
                    onPressed: _rotate,
                  ),
                  _TetrisControl(
                    icon: Icons.keyboard_double_arrow_right_rounded,
                    label: 'Right',
                    onPressed: () => _moveHorizontal(1),
                  ),
                  _TetrisControl(
                    icon: Icons.arrow_downward_rounded,
                    label: 'Soft',
                    onPressed: _softDrop,
                  ),
                  _TetrisControl(
                    icon: Icons.vertical_align_bottom_rounded,
                    label: 'Hard',
                    onPressed: _hardDrop,
                  ),
                  _TetrisControl(
                    icon: Icons.inventory_2_rounded,
                    label: 'Hold',
                    onPressed: _hold,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TowerStackScreen extends StatelessWidget {
  const TowerStackScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Tower Stack',
    prompt: 'Tap when the moving platform lines up with the tower.',
    icon: Icons.layers_rounded,
    accent: definition.accent,
    tapLabel: 'Stack',
  );
}

class BrickBreakerScreen extends StatelessWidget {
  const BrickBreakerScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Brick Breaker',
    prompt: 'Tap the paddle when the ball is centered.',
    icon: Icons.sports_baseball_rounded,
    accent: definition.accent,
    tapLabel: 'Hit',
  );
}

class BubbleShooterScreen extends StatelessWidget {
  const BubbleShooterScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Bubble Shooter',
    prompt: 'Time each shot when the aiming line is centered.',
    icon: Icons.bubble_chart_rounded,
    accent: definition.accent,
    tapLabel: 'Shoot',
  );
}

class ArcheryScreen extends StatelessWidget {
  const ArcheryScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Archery',
    prompt: 'Release the arrow when the aim line hits the bullseye.',
    icon: Icons.my_location_rounded,
    accent: definition.accent,
    tapLabel: 'Release',
  );
}

class AirHockeyScreen extends StatelessWidget {
  const AirHockeyScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Air Hockey',
    prompt: 'Tap when the puck crosses the strike zone.',
    icon: Icons.sports_hockey_rounded,
    accent: definition.accent,
    tapLabel: 'Strike',
  );
}

class SnakeScreen extends StatelessWidget {
  const SnakeScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickPuzzleChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Snake',
    prompt: 'Follow the glowing path in the right order.',
    icon: Icons.hexagon_rounded,
    accent: definition.accent,
  );
}

class MazeEscapeScreen extends StatelessWidget {
  const MazeEscapeScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickPuzzleChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Maze Escape',
    prompt: 'Trace the route from start to exit without missing a step.',
    icon: Icons.route_rounded,
    accent: definition.accent,
  );
}

class HelicopterEscapeScreen extends StatelessWidget {
  const HelicopterEscapeScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Helicopter Escape',
    prompt: 'Tap to stay in the safe altitude band.',
    icon: Icons.airplanemode_active_rounded,
    accent: definition.accent,
    tapLabel: 'Lift',
  );
}

class DartsScreen extends StatelessWidget {
  const DartsScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Darts',
    prompt: 'Time the throw to land on the center ring.',
    icon: Icons.adjust_rounded,
    accent: definition.accent,
    tapLabel: 'Throw',
  );
}

class RhythmTapScreen extends StatelessWidget {
  const RhythmTapScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Rhythm Tap',
    prompt: 'Tap exactly on beat for combo bonuses.',
    icon: Icons.music_note_rounded,
    accent: definition.accent,
    tapLabel: 'Tap',
  );
}

class BubbleRunScreen extends StatelessWidget {
  const BubbleRunScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickActionChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Bubble Run',
    prompt: 'Stay in the glowing lane and stack streaks.',
    icon: Icons.circle_notifications_rounded,
    accent: definition.accent,
    tapLabel: 'Dash',
  );
}

class SokobanScreen extends StatelessWidget {
  const SokobanScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickPuzzleChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Sokoban',
    prompt: 'Push the crates to the marked targets in sequence.',
    icon: Icons.view_in_ar_rounded,
    accent: definition.accent,
  );
}

class LaserMirrorScreen extends StatelessWidget {
  const LaserMirrorScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickPuzzleChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Laser Mirror',
    prompt: 'Rotate mirrors to route the beam to the exit.',
    icon: Icons.radar_rounded,
    accent: definition.accent,
  );
}

class CircuitBuilderScreen extends StatelessWidget {
  const CircuitBuilderScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickPuzzleChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Circuit Builder',
    prompt: 'Connect the power nodes in the correct order.',
    icon: Icons.electrical_services_rounded,
    accent: definition.accent,
  );
}

class ChessScreen extends StatelessWidget {
  const ChessScreen({
    super.key,
    required this.controller,
    required this.definition,
  });
  final MiniGamesController controller;
  final MiniGameDefinition definition;
  @override
  Widget build(BuildContext context) => _QuickPuzzleChallengeScreen(
    controller: controller,
    definition: definition,
    title: 'Chess',
    prompt: 'Choose the strongest move from the highlighted options.',
    icon: Icons.grid_4x4_rounded,
    accent: definition.accent,
  );
}

class _TetrisPanel extends StatelessWidget {
  const _TetrisPanel({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _TetrisPreview extends StatelessWidget {
  const _TetrisPreview({required this.type, this.compact = false});

  final int? type;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final piece = type == null ? null : _tetrisPieces[type! - 1];
    return SizedBox(
      width: double.infinity,
      height: compact ? 44 : 72,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _tetrisPreviewSize * _tetrisPreviewSize,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _tetrisPreviewSize,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (context, index) {
          final row = index ~/ _tetrisPreviewSize;
          final col = index % _tetrisPreviewSize;
          final active =
              piece?.rotations.first.any(
                (cell) => cell.row == row && cell.col == col,
              ) ??
              false;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: active
                  ? piece!.color
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}

class _TetrisControl extends StatelessWidget {
  const _TetrisControl({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _TetrisPieceData {
  const _TetrisPieceData({required this.color, required this.rotations});

  final Color color;
  final List<List<_TetrisCell>> rotations;
}

class _TetrisCell {
  const _TetrisCell(this.row, this.col);

  final int row;
  final int col;
}

const List<_TetrisPieceData> _tetrisPieces = <_TetrisPieceData>[
  _TetrisPieceData(
    color: Color(0xFF06B6D4),
    rotations: [
      [
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(1, 3),
      ],
      [
        _TetrisCell(0, 2),
        _TetrisCell(1, 2),
        _TetrisCell(2, 2),
        _TetrisCell(3, 2),
      ],
    ],
  ),
  _TetrisPieceData(
    color: Color(0xFFF59E0B),
    rotations: [
      [
        _TetrisCell(0, 1),
        _TetrisCell(1, 1),
        _TetrisCell(2, 1),
        _TetrisCell(2, 2),
      ],
      [
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(2, 0),
      ],
      [
        _TetrisCell(0, 0),
        _TetrisCell(0, 1),
        _TetrisCell(1, 1),
        _TetrisCell(2, 1),
      ],
      [
        _TetrisCell(0, 2),
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
      ],
    ],
  ),
  _TetrisPieceData(
    color: Color(0xFF3B82F6),
    rotations: [
      [
        _TetrisCell(0, 1),
        _TetrisCell(1, 1),
        _TetrisCell(2, 1),
        _TetrisCell(2, 0),
      ],
      [
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(2, 2),
      ],
      [
        _TetrisCell(0, 1),
        _TetrisCell(0, 2),
        _TetrisCell(1, 1),
        _TetrisCell(2, 1),
      ],
      [
        _TetrisCell(0, 0),
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
      ],
    ],
  ),
  _TetrisPieceData(
    color: Color(0xFFEAB308),
    rotations: [
      [
        _TetrisCell(0, 1),
        _TetrisCell(0, 2),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
      ],
    ],
  ),
  _TetrisPieceData(
    color: Color(0xFF22C55E),
    rotations: [
      [
        _TetrisCell(0, 1),
        _TetrisCell(0, 2),
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
      ],
      [
        _TetrisCell(0, 1),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(2, 2),
      ],
    ],
  ),
  _TetrisPieceData(
    color: Color(0xFFA855F7),
    rotations: [
      [
        _TetrisCell(0, 1),
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
      ],
      [
        _TetrisCell(0, 1),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(2, 1),
      ],
      [
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(2, 1),
      ],
      [
        _TetrisCell(0, 1),
        _TetrisCell(1, 0),
        _TetrisCell(1, 1),
        _TetrisCell(2, 1),
      ],
    ],
  ),
  _TetrisPieceData(
    color: Color(0xFFEF4444),
    rotations: [
      [
        _TetrisCell(0, 0),
        _TetrisCell(0, 1),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
      ],
      [
        _TetrisCell(0, 2),
        _TetrisCell(1, 1),
        _TetrisCell(1, 2),
        _TetrisCell(2, 1),
      ],
    ],
  ),
];

class _QuickActionChallengeScreen extends StatefulWidget {
  const _QuickActionChallengeScreen({
    required this.controller,
    required this.definition,
    required this.title,
    required this.prompt,
    required this.icon,
    required this.accent,
    required this.tapLabel,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;
  final String title;
  final String prompt;
  final IconData icon;
  final Color accent;
  final String tapLabel;

  @override
  State<_QuickActionChallengeScreen> createState() =>
      _QuickActionChallengeScreenState();
}

class _QuickActionChallengeScreenState
    extends State<_QuickActionChallengeScreen> {
  static const _roundDuration = Duration(seconds: 75);
  final _rng = math.Random(19);
  Timer? _timer;
  DateTime? _startedAt;
  double _phase = 0;
  int _score = 0;
  int _streak = 0;
  int _hits = 0;
  int _misses = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 24), _tick);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _tick(Timer timer) {
    if (!mounted || _finished) {
      return;
    }
    setState(() {
      _phase += 0.05 + (_rng.nextDouble() * 0.01);
      if (DateTime.now().difference(_startedAt!) > _roundDuration) {
        _endGame(completed: false);
      }
    });
  }

  void _tap() {
    if (_finished) return;
    final position = (math.sin(_phase) + 1) / 2;
    final distance = (position - 0.5).abs();
    final bonus = distance < 0.08
        ? 60
        : distance < 0.18
        ? 30
        : 10;
    final hit = distance < 0.25;
    setState(() {
      if (hit) {
        _hits += 1;
        _streak += 1;
        _score += bonus + (_streak * 4);
        HapticFeedback.lightImpact();
      } else {
        _misses += 1;
        _streak = 0;
        _score = math.max(0, _score - 8);
      }
      if (_score >= 450) {
        _endGame(completed: true);
      }
    });
  }

  Future<void> _endGame({required bool completed}) async {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    final durationMs = DateTime.now()
        .difference(_startedAt ?? DateTime.now())
        .inMilliseconds;
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: _score,
        completed: completed,
        durationMs: durationMs,
        retryCount: _misses,
        reactionTimeMs: 180,
        accuracy: _hits / math.max(1, _hits + _misses),
        averageDecisionTimeMs: 250,
        levelReached: _hits + _misses,
        difficultyPlayed: 'reactive',
        improvementCurve: (_streak / math.max(1, _hits + _misses))
            .clamp(0.0, 1.0)
            .toDouble(),
        consecutiveWins: completed ? 1 : 0,
        consecutiveLosses: completed ? 0 : 1,
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_startedAt == null)
        ? 0.0
        : DateTime.now().difference(_startedAt!).inMilliseconds /
              _roundDuration.inMilliseconds;
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: () => setState(() => _timer?.cancel()),
      onRestart: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => widget.definition.builder(
              context,
              widget.controller,
              widget.definition,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.prompt,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1.8,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 18,
                        right: 18,
                        top: 0,
                        bottom: 0,
                        child: CustomPaint(
                          painter: _TrackPainter(
                            progress: progress.clamp(0.0, 1.0).toDouble(),
                            accent: widget.accent,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment(
                            math.sin(_phase).clamp(-1.0, 1.0).toDouble(),
                            0,
                          ),
                          child: Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accent.withValues(alpha: 0.16),
                              border: Border.all(
                                color: widget.accent,
                                width: 3,
                              ),
                            ),
                            child: Icon(widget.icon, color: widget.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _tap,
                    child: Text(widget.tapLabel),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text('Hits $_hits  Misses $_misses  Streak $_streak'),
          ),
        ],
      ),
    );
  }
}

class _QuickPuzzleChallengeScreen extends StatefulWidget {
  const _QuickPuzzleChallengeScreen({
    required this.controller,
    required this.definition,
    required this.title,
    required this.prompt,
    required this.icon,
    required this.accent,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;
  final String title;
  final String prompt;
  final IconData icon;
  final Color accent;

  @override
  State<_QuickPuzzleChallengeScreen> createState() =>
      _QuickPuzzleChallengeScreenState();
}

class _QuickPuzzleChallengeScreenState
    extends State<_QuickPuzzleChallengeScreen> {
  static const _patternSize = 4;
  late List<int> _sequence;
  late int _targetIndex;
  int _score = 0;
  int _moves = 0;
  int _mistakes = 0;
  bool _finished = false;
  final _rng = math.Random(73);
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _sequence = List<int>.generate(
      _patternSize * _patternSize,
      (index) => index,
    );
    _sequence.shuffle(_rng);
    _targetIndex = 0;
  }

  void _tap(int index) {
    if (_finished) return;
    final expected = _sequence[_targetIndex];
    setState(() {
      _moves += 1;
      if (index == expected) {
        _targetIndex += 1;
        _score += 45;
        HapticFeedback.selectionClick();
        if (_targetIndex >= _sequence.length) {
          _end(true);
        }
      } else {
        _mistakes += 1;
        _score = math.max(0, _score - 10);
      }
    });
  }

  Future<void> _end(bool completed) async {
    if (_finished) return;
    _finished = true;
    await widget.controller.recordSession(
      gameId: widget.definition.id,
      result: MiniGameResult(
        score: _score,
        completed: completed,
        durationMs: DateTime.now()
            .difference(_startedAt ?? DateTime.now())
            .inMilliseconds,
        retryCount: _mistakes,
        accuracy: _targetIndex / math.max(1, _moves),
        averageDecisionTimeMs: 320,
        levelReached: _targetIndex,
        difficultyPlayed: 'sequence',
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return MiniGameShell(
      controller: widget.controller,
      definition: widget.definition,
      score: _score,
      onPause: () {},
      onRestart: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => widget.definition.builder(
              context,
              widget.controller,
              widget.definition,
            ),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              widget.prompt,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sequence.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final expected = _sequence[_targetIndex];
                final selected = index == expected;
                final completed = index < _targetIndex;
                return InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _tap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    decoration: BoxDecoration(
                      color: completed
                          ? widget.accent.withValues(alpha: 0.2)
                          : selected
                          ? widget.accent.withValues(alpha: 0.32)
                          : Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Moves $_moves  Mistakes $_mistakes'),
          ),
        ],
      ),
    );
  }
}

class _TrackPainter extends CustomPainter {
  _TrackPainter({required this.progress, required this.accent});

  final double progress;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final trackPaint = Paint()
      ..color = accent.withValues(alpha: 0.12)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final line =
        Offset(size.width * 0.5, size.height * 0.2) &
        Size(0, size.height * 0.6);
    canvas.drawLine(line.topCenter, line.bottomCenter, trackPaint);
    final markerPaint = Paint()..color = accent;
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * (0.2 + 0.6 * progress)),
      10,
      markerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TrackPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.accent != accent;
}
