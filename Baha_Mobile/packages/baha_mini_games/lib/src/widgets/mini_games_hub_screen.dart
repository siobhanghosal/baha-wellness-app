import 'dart:math' as math;

import 'package:baha_design_system/baha_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/controller.dart';
import '../core/models.dart';

class MiniGamesHubScreen extends StatelessWidget {
  const MiniGamesHubScreen({
    super.key,
    required this.controller,
    required this.games,
  });

  final MiniGamesController controller;
  final List<MiniGameDefinition> games;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = controller.progressFor(games.first.id);
        final totalXp = games.fold<int>(
          0,
          (sum, game) => sum + controller.progressFor(game.id).xp,
        );
        final totalCoins = games.fold<int>(
          0,
          (sum, game) => sum + controller.progressFor(game.id).coins,
        );
        final daily = controller.dailyChallengeFor(games.first);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mini Games'),
            actions: [
              IconButton(
                tooltip: 'Analytics',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => _MiniGamesAnalyticsScreen(
                      controller: controller,
                      games: games,
                    ),
                  ),
                ),
                icon: const Icon(Icons.insights_rounded),
              ),
              IconButton(
                tooltip: 'Settings',
                onPressed: () => _showGlobalSettings(context),
                icon: const Icon(Icons.tune_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Offline arcade', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Twenty compact, skill-based games with local XP, coins, daily challenges, and telemetry.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _StatChip(label: 'XP', value: '$totalXp'),
                        _StatChip(label: 'Coins', value: '$totalCoins'),
                        _StatChip(
                          label: 'Best tile',
                          value: '${progress.bestScore}',
                        ),
                        _StatChip(
                          label: 'Daily',
                          value: '${daily.targetScore}',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => _MiniGamesAnalyticsScreen(
                            controller: controller,
                            games: games,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.auto_graph_rounded),
                      label: const Text('Open analytics dashboard'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily challenge', style: theme.textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(daily.label, style: theme.textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Text(
                      'Target score ${daily.targetScore}',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: games.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemBuilder: (context, index) {
                  final game = games[index];
                  final snapshot = controller.progressFor(game.id);
                  final unlocked = snapshot.playCount > 0;
                  return InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (context) => _MiniGamePlayerScreen(
                          controller: controller,
                          definition: game,
                        ),
                      ),
                    ),
                    child: BahaSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: game.accent.withValues(
                              alpha: 0.15,
                            ),
                            child: Icon(game.icon, color: game.accent),
                          ),
                          const SizedBox(height: 12),
                          Text(game.title, style: theme.textTheme.titleMedium),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              game.subtitle,
                              style: theme.textTheme.bodySmall,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                unlocked
                                    ? Icons.emoji_events_rounded
                                    : Icons.lock_outline_rounded,
                                size: 18,
                                color: unlocked
                                    ? game.accent
                                    : theme.disabledColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${snapshot.bestScore} best',
                                style: theme.textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showGlobalSettings(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final settings = controller.settings;
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SwitchListTile(
                    value: settings.soundEnabled,
                    title: const Text('Sound effects'),
                    onChanged: (_) => controller.toggleSound(),
                  ),
                  SwitchListTile(
                    value: settings.musicEnabled,
                    title: const Text('Music'),
                    onChanged: (_) => controller.toggleMusic(),
                  ),
                  SwitchListTile(
                    value: settings.hapticsEnabled,
                    title: const Text('Haptics'),
                    onChanged: (_) => controller.toggleHaptics(),
                  ),
                  SwitchListTile(
                    value: settings.darkMode,
                    title: const Text('Dark mode'),
                    onChanged: (_) => controller.toggleDarkMode(),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MiniGamePlayerScreen extends StatelessWidget {
  const _MiniGamePlayerScreen({
    required this.controller,
    required this.definition,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => definition.builder(context, controller, definition),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}

class _MiniGamesAnalyticsScreen extends StatelessWidget {
  const _MiniGamesAnalyticsScreen({
    required this.controller,
    required this.games,
  });

  final MiniGamesController controller;
  final List<MiniGameDefinition> games;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.dashboardSummary(games);
        return Scaffold(
          appBar: AppBar(
            title: const Text('Arcade Analytics'),
            actions: [
              IconButton(
                tooltip: 'Export JSON',
                onPressed: () => _exportJson(context),
                icon: const Icon(Icons.download_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gameplay-derived behavioural indicators',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These scores are derived only from play sessions and should be read as gameplay patterns, not health predictions.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _OverviewGrid(summary: summary),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Behaviour radar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 260,
                      child: _RadarChart(
                        indicators: summary.behaviourIndicators,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: summary.behaviourIndicators
                          .map(
                            (indicator) => _IndicatorCard(indicator: indicator),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 180,
                      child: _BarChart(
                        values: summary.weeklyActivity.values.toList(),
                        labels: summary.weeklyActivity.keys.toList(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Favourite games',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...summary.favouriteGames.map(
                      (game) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _FavouriteGameRow(game: game),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recent activity',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...summary.recentActivity.map(
                      (entry) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          games
                                  .where((game) => game.id == entry.gameId)
                                  .map((game) => game.title)
                                  .firstOrNull ??
                              entry.gameId,
                        ),
                        subtitle: Text(
                          '${entry.score} score • ${(entry.sessionDurationMs / 1000).toStringAsFixed(0)}s • ${entry.difficultyPlayed}',
                        ),
                        trailing: Icon(
                          entry.completed
                              ? Icons.check_circle_rounded
                              : Icons.timelapse_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile summary',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    ...summary.summaryLines.map(
                      (line) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          line,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _exportJson(BuildContext context) async {
    final json = await controller.exportTelemetryJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Telemetry JSON copied to clipboard.')),
    );
  }
}

class _OverviewGrid extends StatelessWidget {
  const _OverviewGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = <(String, String)>[
      ('Games played', '${summary.totalSessions}'),
      ('Total play time', _formatMs(summary.totalPlayTimeMs)),
      ('Average session', _formatMs(summary.averageSessionMs)),
      ('Best score', '${summary.bestScore}'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (item) => SizedBox(
              width: 160,
              child: BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _IndicatorCard extends StatelessWidget {
  const _IndicatorCard({required this.indicator});

  final BehaviourIndicator indicator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: BahaSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              indicator.label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: indicator.score / 100),
            const SizedBox(height: 8),
            Text(
              '${indicator.score.toStringAsFixed(0)} / 100',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Text(
              'Confidence ${(indicator.confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _FavouriteGameRow extends StatelessWidget {
  const _FavouriteGameRow({required this.game});

  final DashboardGameSnapshot game;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                game.title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text('${game.sessions} sessions'),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: (game.completionRate).clamp(0.0, 1.0)),
        const SizedBox(height: 6),
        Text(
          'Best ${game.bestScore} • Avg ${game.averageScore.toStringAsFixed(0)} • ${_formatMs(game.totalPlayTimeMs)}',
        ),
      ],
    );
  }
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values, required this.labels});

  final List<int> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<int>(0, math.max);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (index) {
        final ratio = maxValue == 0 ? 0.0 : values[index] / maxValue;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('${values[index]}'),
                const SizedBox(height: 8),
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      heightFactor: ratio.clamp(0.0, 1.0),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(labels[index]),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _RadarChart extends StatelessWidget {
  const _RadarChart({required this.indicators});

  final List<BehaviourIndicator> indicators;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RadarChartPainter(
        indicators: indicators,
        color: Theme.of(context).colorScheme.primary,
        textStyle: Theme.of(context).textTheme.labelSmall!,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  _RadarChartPainter({
    required this.indicators,
    required this.color,
    required this.textStyle,
  });

  final List<BehaviourIndicator> indicators;
  final Color color;
  final TextStyle textStyle;

  @override
  void paint(Canvas canvas, Size size) {
    if (indicators.isEmpty) {
      return;
    }
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.32;
    final angleStep = (math.pi * 2) / indicators.length;
    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke;
    for (var ring = 1; ring <= 4; ring++) {
      final ringPath = Path();
      for (var i = 0; i < indicators.length; i++) {
        final angle = (-math.pi / 2) + (angleStep * i);
        final point = Offset(
          center.dx + math.cos(angle) * radius * (ring / 4),
          center.dy + math.sin(angle) * radius * (ring / 4),
        );
        if (i == 0) {
          ringPath.moveTo(point.dx, point.dy);
        } else {
          ringPath.lineTo(point.dx, point.dy);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }
    final dataPath = Path();
    for (var i = 0; i < indicators.length; i++) {
      final angle = (-math.pi / 2) + (angleStep * i);
      final point = Offset(
        center.dx + math.cos(angle) * radius * (indicators[i].score / 100),
        center.dy + math.sin(angle) * radius * (indicators[i].score / 100),
      );
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
      canvas.drawLine(center, point, gridPaint);
      final labelPoint = Offset(
        center.dx + math.cos(angle) * (radius + 28),
        center.dy + math.sin(angle) * (radius + 28),
      );
      final painter = TextPainter(
        text: TextSpan(text: indicators[i].label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 80);
      painter.paint(
        canvas,
        Offset(
          labelPoint.dx - painter.width / 2,
          labelPoint.dy - painter.height / 2,
        ),
      );
    }
    dataPath.close();
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      dataPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) =>
      oldDelegate.indicators != indicators || oldDelegate.color != color;
}

String _formatMs(int milliseconds) {
  if (milliseconds <= 0) {
    return '0m';
  }
  final seconds = milliseconds ~/ 1000;
  final minutes = seconds ~/ 60;
  final remainderSeconds = seconds % 60;
  if (minutes == 0) {
    return '${remainderSeconds}s';
  }
  return '${minutes}m ${remainderSeconds}s';
}
