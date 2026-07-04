import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_models.dart';
import '../prototype/theme_manager.dart';
import 'story_game_state.dart';

class StoryWorldScreen extends StatefulWidget {
  const StoryWorldScreen({
    required this.baseUrl,
    this.initialAgeGroup,
    this.initialGender,
    super.key,
  });

  final String baseUrl;
  final StudentAgeGroup? initialAgeGroup;
  final StudentGender? initialGender;

  @override
  State<StoryWorldScreen> createState() => _StoryWorldScreenState();
}

class _StoryWorldScreenState extends State<StoryWorldScreen> {
  late final StoryGameState _game;
  final TextEditingController _answerController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _game = StoryGameState()..addListener(_refresh);
    _game.load(
      baseUrl: widget.baseUrl,
      hostAgeGroup: widget.initialAgeGroup,
      hostGender: widget.initialGender,
    );
  }

  @override
  void dispose() {
    _game
      ..removeListener(_refresh)
      ..dispose();
    _answerController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _openLocation(WorldLocation location) async {
    if (!_game.isUnlocked(location)) {
      final remaining = location.unlockStars - _game.stars;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Collect $remaining more star${remaining == 1 ? '' : 's'} to unlock ${location.name}.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    await _game.selectLocation(location.id, forceRefresh: true);
  }

  Future<void> _submit() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty || _game.isSubmitting) {
      return;
    }
    _answerController.clear();
    final result = await _game.submitAnswer(answer);
    if (!mounted || result == null) {
      return;
    }
    if (!_game.backendOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Story server is offline, so Story World used local mode.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = studentPalette(
      _game.ageGroup,
      _game.gender,
      isDark: ThemeScope.of(context).isDark,
    );
    final theme = buildTheme(palette);
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: palette.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: const Text('Story World'),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: _SyncBadge(
                  online: _game.backendOnline,
                  palette: palette,
                ),
              ),
            ),
          ],
        ),
        body: !_game.isLoaded
            ? Center(child: CircularProgressIndicator(color: palette.primary))
            : SafeArea(
                top: false,
                child: RefreshIndicator(
                  onRefresh: () => _game.selectLocation(
                    _game.selectedLocationId,
                    forceRefresh: true,
                  ),
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _HeroPanel(game: _game, palette: palette),
                              if (_game.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                _MessageBanner(
                                  text: _game.errorMessage!,
                                  palette: palette,
                                ),
                              ],
                              const SizedBox(height: 18),
                              _SectionTitle(
                                title: 'Choose a world',
                                subtitle:
                                    'Every reply changes the story. No fixed options.',
                                palette: palette,
                              ),
                              const SizedBox(height: 12),
                              _WorldSelector(
                                palette: palette,
                                game: _game,
                                onOpenLocation: _openLocation,
                              ),
                              const SizedBox(height: 18),
                              _SectionTitle(
                                title:
                                    '${_game.selectedLocation.name} chat story',
                                subtitle:
                                    'Type any answer you want. The next turn grows from it.',
                                palette: palette,
                              ),
                              const SizedBox(height: 12),
                              _StoryPanel(
                                palette: palette,
                                game: _game,
                                controller: _answerController,
                                onSubmit: _submit,
                              ),
                              const SizedBox(height: 18),
                              _SectionTitle(
                                title: 'Story dashboard',
                                subtitle:
                                    'Safe, non-diagnostic signals and memory from the child’s choices.',
                                palette: palette,
                              ),
                              const SizedBox(height: 12),
                              _DashboardPanel(game: _game, palette: palette),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.game, required this.palette});

  final StoryGameState game;
  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    final darkScrim = palette.isDark
        ? const Color(0xCC091724)
        : const Color(0x88243B53);
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: Stack(
        children: [
          SizedBox(
            height: 240,
            width: double.infinity,
            child: Image.asset(
              'assets/illustrations/growing_world.png',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, darkScrim, darkScrim],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeroChip(
                        label: game.styleTitle,
                        background: Colors.white.withValues(alpha: .18),
                      ),
                      _HeroChip(
                        label:
                            '${game.selfReportedMood.emoji} ${game.selfReportedMood.label}',
                        background: Colors.white.withValues(alpha: .18),
                      ),
                      _HeroChip(
                        label: 'Level ${game.level}',
                        background: Colors.white.withValues(alpha: .18),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Infinite story, one message at a time',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    game.styleHint,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: .92),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _StatTile(
                        label: 'Stars',
                        value: '${game.stars}',
                        accent: const Color(0xFFFBBF24),
                      ),
                      _StatTile(
                        label: 'Coins',
                        value: '${game.coins}',
                        accent: const Color(0xFFFB7185),
                      ),
                      _StatTile(
                        label: 'Turns',
                        value: '${game.allRecords.length}',
                        accent: const Color(0xFF38BDF8),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorldSelector extends StatelessWidget {
  const _WorldSelector({
    required this.palette,
    required this.game,
    required this.onOpenLocation,
  });

  final PrototypePalette palette;
  final StoryGameState game;
  final ValueChanged<WorldLocation> onOpenLocation;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final location = worldLocations[index];
          final selected = location.id == game.selectedLocationId;
          final unlocked = game.isUnlocked(location);
          return SizedBox(
            width: 210,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => onOpenLocation(location),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: selected
                      ? location.color.withValues(
                          alpha: palette.isDark ? .30 : .18,
                        )
                      : palette.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: selected
                        ? location.color
                        : palette.text.withValues(alpha: .08),
                    width: selected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: palette.isDark ? .24 : .06,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          location.emoji,
                          style: const TextStyle(fontSize: 26),
                        ),
                        const Spacer(),
                        Icon(
                          unlocked
                              ? Icons.lock_open_rounded
                              : Icons.lock_rounded,
                          color: unlocked ? location.color : palette.muted,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      location.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      location.subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: palette.muted,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        _MiniTag(
                          label: 'Ch ${game.chapterFor(location.id)}',
                          color: location.color,
                        ),
                        const SizedBox(width: 8),
                        _MiniTag(
                          label: unlocked
                              ? location.npc
                              : '${location.unlockStars}⭐',
                          color: palette.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        separatorBuilder: (_, index) => const SizedBox(width: 12),
        itemCount: worldLocations.length,
      ),
    );
  }
}

class _StoryPanel extends StatelessWidget {
  const _StoryPanel({
    required this.palette,
    required this.game,
    required this.controller,
    required this.onSubmit,
  });

  final PrototypePalette palette;
  final StoryGameState game;
  final TextEditingController controller;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final scene = game.currentScene;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? .24 : .07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: game.selectedLocation.color.withValues(
                  alpha: .16,
                ),
                child: Text(game.selectedLocation.emoji),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.selectedLocation.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Chat-style story with ${game.selectedLocation.npc}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (game.isLoadingScene) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              minHeight: 4,
              color: game.selectedLocation.color,
              backgroundColor: game.selectedLocation.color.withValues(
                alpha: .12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          if (scene != null) ...[
            _NpcBubble(
              palette: palette,
              speaker: game.selectedLocation.npc,
              title: scene.title,
              text: '${scene.body}\n\n${scene.prompt}',
            ),
            const SizedBox(height: 12),
          ],
          ...game.recentRecordsForSelected.expand(
            (record) => [
              _PlayerBubble(palette: palette, text: record.answer),
              const SizedBox(height: 10),
              _NpcBubble(
                palette: palette,
                speaker: record.npcName,
                title: 'Chapter ${record.chapter}',
                text: record.response,
                footer: record.memory,
              ),
              const SizedBox(height: 12),
            ],
          ),
          Text(
            'The child can type any answer. No buttons, no preset options.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: palette.muted),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: 'Write what the child says or does next...',
              filled: true,
              fillColor: palette.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: game.isSubmitting ? null : onSubmit,
              icon: Icon(
                game.isSubmitting
                    ? Icons.hourglass_top_rounded
                    : Icons.send_rounded,
              ),
              label: Text(
                game.isSubmitting ? 'Growing the story...' : 'Send answer',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardPanel extends StatelessWidget {
  const _DashboardPanel({required this.game, required this.palette});

  final StoryGameState game;
  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: palette.isDark ? .24 : .07),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DashboardMetric(
                label: 'Turns played',
                value: '${game.allRecords.length}',
                detail: 'Total story replies',
                color: palette.primary,
              ),
              _DashboardMetric(
                label: 'Favorite world',
                value: game.favoriteLocationLabel,
                detail: 'Most visited location',
                color: palette.secondary,
              ),
              _DashboardMetric(
                label: 'Mood now',
                value:
                    '${game.selfReportedMood.emoji} ${game.selfReportedMood.label}',
                detail: 'From recent wording',
                color: palette.accent,
              ),
              _DashboardMetric(
                label: 'Sync',
                value: game.backendOnline ? 'Live backend' : 'Offline mode',
                detail: 'Auto fallback enabled',
                color: game.backendOnline
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFF59E0B),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Safe pattern signals',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: game.safeSignals
                .map(
                  (signal) => Chip(
                    label: Text(signal),
                    backgroundColor: palette.background,
                    side: BorderSide(
                      color: palette.text.withValues(alpha: .08),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Text(
            'Context graph',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.background,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: game.contextGraphLines
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        line,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(height: 1.35),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _NpcBubble extends StatelessWidget {
  const _NpcBubble({
    required this.palette,
    required this.speaker,
    required this.title,
    required this.text,
    this.footer,
  });

  final PrototypePalette palette;
  final String speaker;
  final String title;
  final String text;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 620),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.text.withValues(alpha: .08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$speaker • $title',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(height: 1.45),
            ),
            if (footer != null) ...[
              const SizedBox(height: 10),
              Text(
                footer!,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: palette.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PlayerBubble extends StatelessWidget {
  const _PlayerBubble({required this.palette, required this.text});

  final PrototypePalette palette;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 560),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: palette.gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.palette,
  });

  final String title;
  final String subtitle;
  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: palette.muted),
        ),
      ],
    );
  }
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(detail, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, required this.background});

  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: .16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.online, required this.palette});

  final bool online;
  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    final color = online ? const Color(0xFF16A34A) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            online ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            online ? 'Live' : 'Offline',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: palette.text,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({required this.text, required this.palette});

  final String text;
  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: .24),
        ),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: palette.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
