import 'package:baha_design_system/baha_design_system.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';

class MiniGameShell extends StatefulWidget {
  const MiniGameShell({
    super.key,
    required this.controller,
    required this.definition,
    required this.child,
    required this.score,
    required this.onPause,
    required this.onRestart,
    this.onShowResult,
  });

  final MiniGamesController controller;
  final MiniGameDefinition definition;
  final Widget child;
  final int score;
  final VoidCallback onPause;
  final VoidCallback onRestart;
  final VoidCallback? onShowResult;

  @override
  State<MiniGameShell> createState() => _MiniGameShellState();
}

class _MiniGameShellState extends State<MiniGameShell> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = theme.colorScheme;
    final progress = widget.controller.progressFor(widget.definition.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.definition.title),
        actions: [
          IconButton(
            tooltip: 'Pause',
            onPressed: widget.onPause,
            icon: const Icon(Icons.pause_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Restart',
            onPressed: widget.onRestart,
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: 'Results',
            onPressed: widget.onShowResult,
            icon: const Icon(Icons.emoji_events_outlined),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [palette.surface, palette.surface.withValues(alpha: 0.92)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BahaSurface(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: widget.definition.accent.withValues(
                          alpha: 0.16,
                        ),
                        child: Icon(
                          widget.definition.icon,
                          color: widget.definition.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.definition.subtitle,
                              style: theme.textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.definition.expectedMinutes} minute arcades',
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      _MetricPill(
                        label: 'Score',
                        value: '${widget.score}',
                        color: widget.definition.accent,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: widget.child),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: BahaSurface(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: _MetricBlock(
                          label: 'Best',
                          value: '${progress.bestScore}',
                        ),
                      ),
                      Expanded(
                        child: _MetricBlock(
                          label: 'Plays',
                          value: '${progress.playCount}',
                        ),
                      ),
                      Expanded(
                        child: _MetricBlock(
                          label: 'Coins',
                          value: '${progress.coins}',
                        ),
                      ),
                      Expanded(
                        child: _MetricBlock(
                          label: 'XP',
                          value: '${progress.xp}',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showPanel(
                  context,
                  title: 'Settings',
                  child: _SettingsSheet(controller: widget.controller),
                ),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Settings'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showPanel(
                  context,
                  title: 'Statistics',
                  child: _StatisticsSheet(
                    controller: widget.controller,
                    gameId: widget.definition.id,
                  ),
                ),
                icon: const Icon(Icons.bar_chart_rounded),
                label: const Text('Statistics'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showPanel(
                  context,
                  title: 'Achievements',
                  child: _AchievementsSheet(
                    controller: widget.controller,
                    gameId: widget.definition.id,
                  ),
                ),
                icon: const Icon(Icons.shield_rounded),
                label: const Text('Achievements'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showPanel(
                  context,
                  title: 'Daily Challenge',
                  child: _DailyChallengeSheet(
                    challenge: widget.controller.dailyChallengeFor(
                      widget.definition,
                    ),
                  ),
                ),
                icon: const Icon(Icons.today_rounded),
                label: const Text('Daily'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPanel(
    BuildContext context, {
    required String title,
    required Widget child,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.controller});
  final MiniGamesController controller;
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final settings = controller.settings;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SwitchListTile(
              value: settings.soundEnabled,
              onChanged: (_) => controller.toggleSound(),
              title: const Text('Sound'),
            ),
            SwitchListTile(
              value: settings.musicEnabled,
              onChanged: (_) => controller.toggleMusic(),
              title: const Text('Music'),
            ),
            SwitchListTile(
              value: settings.hapticsEnabled,
              onChanged: (_) => controller.toggleHaptics(),
              title: const Text('Haptics'),
            ),
            SwitchListTile(
              value: settings.darkMode,
              onChanged: (_) => controller.toggleDarkMode(),
              title: const Text('Dark mode'),
            ),
          ],
        );
      },
    );
  }
}

class _StatisticsSheet extends StatelessWidget {
  const _StatisticsSheet({required this.controller, required this.gameId});
  final MiniGamesController controller;
  final String gameId;
  @override
  Widget build(BuildContext context) {
    final stats = controller.statisticsFor(gameId);
    final rows = <(String, String)>[
      ('Sessions', '${stats.sessionsPlayed}'),
      ('Completions', '${stats.completions}'),
      ('Best score', '${stats.bestScore}'),
      ('Average score', stats.averageScore.toStringAsFixed(1)),
      ('Accuracy', '${(stats.averageAccuracy * 100).toStringAsFixed(0)}%'),
      ('Duration', '${stats.averageDurationMs ~/ 1000}s'),
      ('Coins', '${stats.totalCoins}'),
      ('XP', '${stats.totalXp}'),
    ];
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: rows
          .map(
            (row) => SizedBox(
              width: 150,
              child: BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.$1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      row.$2,
                      style: Theme.of(context).textTheme.titleMedium,
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

class _AchievementsSheet extends StatelessWidget {
  const _AchievementsSheet({required this.controller, required this.gameId});
  final MiniGamesController controller;
  final String gameId;
  @override
  Widget build(BuildContext context) {
    final achievements = controller.achievementsFor(gameId);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: achievements
          .map(
            (achievement) => ListTile(
              leading: CircleAvatar(
                backgroundColor: achievement.unlocked
                    ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.14)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  achievement.icon,
                  color: achievement.unlocked
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).disabledColor,
                ),
              ),
              title: Text(achievement.title),
              subtitle: Text(achievement.description),
              trailing: Icon(
                achievement.unlocked
                    ? Icons.check_circle_rounded
                    : Icons.lock_outline_rounded,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DailyChallengeSheet extends StatelessWidget {
  const _DailyChallengeSheet({required this.challenge});
  final MiniGameDailyChallenge challenge;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(challenge.label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Target score: ${challenge.targetScore}'),
        const SizedBox(height: 4),
        Text(
          'Seed: ${challenge.seed}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelSmall),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(label, style: theme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
