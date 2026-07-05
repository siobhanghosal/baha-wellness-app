import 'package:flutter/material.dart';

import 'core/controller.dart';
import 'core/models.dart';
import 'games/arcade_action_games.dart';
import 'games/arcade_board_games.dart';
import 'widgets/mini_games_hub_screen.dart';

class MiniGamesModuleScreen extends StatefulWidget {
  const MiniGamesModuleScreen({super.key});

  @override
  State<MiniGamesModuleScreen> createState() => _MiniGamesModuleScreenState();
}

class _MiniGamesModuleScreenState extends State<MiniGamesModuleScreen> {
  late final MiniGamesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = MiniGamesController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MiniGamesScope(
      controller: _controller,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final settings = _controller.settings;
          return Theme(
            data: theme.copyWith(
              brightness: settings.darkMode
                  ? Brightness.dark
                  : theme.brightness,
            ),
            child: MiniGamesHubScreen(
              controller: _controller,
              games: miniGameRegistry,
            ),
          );
        },
      ),
    );
  }
}

List<MiniGameDefinition> get miniGameRegistry => <MiniGameDefinition>[
  MiniGameDefinition(
    id: '2048',
    title: '2048',
    subtitle: 'Slide and merge tiles to build the highest number.',
    icon: Icons.grid_view_rounded,
    accent: const Color(0xFF2563EB),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        Game2048Screen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'tetris',
    title: 'Tetris',
    subtitle: 'Stack falling pieces with ghost previews and hard drops.',
    icon: Icons.view_comfy_alt_rounded,
    accent: const Color(0xFF7C3AED),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        TetrisScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'sliding-puzzle',
    title: 'Sliding Puzzle',
    subtitle: 'Rebuild the picture with the fewest moves.',
    icon: Icons.view_module_rounded,
    accent: const Color(0xFF0EA5E9),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        SlidingPuzzleScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'tower-stack',
    title: 'Tower Stack',
    subtitle: 'Tap to stack with precision and combo rhythm.',
    icon: Icons.layers_rounded,
    accent: const Color(0xFFF97316),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        TowerStackScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'brick-breaker',
    title: 'Brick Breaker',
    subtitle: 'Keep the ball alive and clear the field.',
    icon: Icons.sports_baseball_rounded,
    accent: const Color(0xFF14B8A6),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        BrickBreakerScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'bubble-shooter',
    title: 'Bubble Shooter',
    subtitle: 'Shoot deterministic clusters and chain combos.',
    icon: Icons.bubble_chart_rounded,
    accent: const Color(0xFFEC4899),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        BubbleShooterScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'connect-four',
    title: 'Connect Four',
    subtitle: 'Outplay a local AI in classic column tactics.',
    icon: Icons.view_week_rounded,
    accent: const Color(0xFFEF4444),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        ConnectFourScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'chess',
    title: 'Chess',
    subtitle: 'A compact tactical chess drill with hints.',
    icon: Icons.casino_rounded,
    accent: const Color(0xFF111827),
    expectedMinutes: 5,
    builder: (context, controller, definition) =>
        ChessScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'othello',
    title: 'Othello',
    subtitle: 'Flip discs with adaptive local AI.',
    icon: Icons.circle_outlined,
    accent: const Color(0xFF16A34A),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        OthelloScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'archery',
    title: 'Archery',
    subtitle: 'Lead moving targets with fixed physics.',
    icon: Icons.my_location_rounded,
    accent: const Color(0xFFF59E0B),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        ArcheryScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'air-hockey',
    title: 'Air Hockey',
    subtitle: 'Slide, defend, and score with local AI.',
    icon: Icons.sports_hockey_rounded,
    accent: const Color(0xFF38BDF8),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        AirHockeyScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'memory-flip',
    title: 'Memory Flip',
    subtitle: 'Match pairs with the fewest turns.',
    icon: Icons.style_rounded,
    accent: const Color(0xFFA855F7),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        MemoryFlipScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'snake',
    title: 'Snake',
    subtitle: 'Guide the snake through a growing speed curve.',
    icon: Icons.hexagon_rounded,
    accent: const Color(0xFF22C55E),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        SnakeScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'maze-escape',
    title: 'Maze Escape',
    subtitle: 'Navigate handcrafted paths before time runs out.',
    icon: Icons.route_rounded,
    accent: const Color(0xFF0F766E),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        MazeEscapeScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'helicopter-escape',
    title: 'Helicopter Escape',
    subtitle: 'Tap to hover through deterministic obstacles.',
    icon: Icons.airplanemode_active_rounded,
    accent: const Color(0xFF0284C7),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        HelicopterEscapeScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'darts',
    title: 'Darts',
    subtitle: 'Hit concentric scoring rings and build accuracy.',
    icon: Icons.adjust_rounded,
    accent: const Color(0xFF8B5CF6),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        DartsScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'sokoban',
    title: 'Sokoban',
    subtitle: 'Push boxes through handcrafted challenge rooms.',
    icon: Icons.view_in_ar_rounded,
    accent: const Color(0xFFB45309),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        SokobanScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'laser-mirror',
    title: 'Laser Mirror',
    subtitle: 'Reflect beams toward the target in fewer moves.',
    icon: Icons.radar_rounded,
    accent: const Color(0xFF14B8A6),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        LaserMirrorScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'circuit-builder',
    title: 'Circuit Builder',
    subtitle: 'Route power through increasing logic layouts.',
    icon: Icons.electrical_services_rounded,
    accent: const Color(0xFF2563EB),
    expectedMinutes: 3,
    builder: (context, controller, definition) =>
        CircuitBuilderScreen(controller: controller, definition: definition),
  ),
  MiniGameDefinition(
    id: 'rhythm-tap',
    title: 'Rhythm Tap',
    subtitle: 'Tap in time and chase perfect timing windows.',
    icon: Icons.music_note_rounded,
    accent: const Color(0xFFFB7185),
    expectedMinutes: 2,
    builder: (context, controller, definition) =>
        RhythmTapScreen(controller: controller, definition: definition),
  ),
];
