import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';

class StudentStoryWorldScreen extends StatefulWidget {
  const StudentStoryWorldScreen({
    required this.apiClient,
    required this.identity,
    required this.palette,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final PrototypePalette palette;

  @override
  State<StudentStoryWorldScreen> createState() =>
      _StudentStoryWorldScreenState();
}

class _StudentStoryWorldScreenState extends State<StudentStoryWorldScreen> {
  final TextEditingController _answerController = TextEditingController();

  StoryWorldState? _state;
  StoryWorldScene? _scene;
  String? _selectedLocationId;
  String? _statusMessage;
  String? _statusMemory;
  List<String> _observedSignals = const [];
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLoadingScene = false;

  @override
  void initState() {
    super.initState();
    _loadStoryWorld();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _loadStoryWorld() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final state = await widget.apiClient.getStoryWorldState(
        identity: widget.identity,
      );
      final selectedLocationId = _resolveSelectedLocationId(state);
      final scene = await widget.apiClient.getStoryWorldScene(
        identity: widget.identity,
        locationId: selectedLocationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _state = state;
        _scene = scene;
        _selectedLocationId = selectedLocationId;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  String _resolveSelectedLocationId(StoryWorldState state) {
    final selected = _selectedLocationId;
    if (selected != null) {
      final existing = state.locations.where(
        (item) => item.locationId == selected,
      );
      if (existing.isNotEmpty && existing.first.unlocked) {
        return selected;
      }
    }
    return state.currentLocationId.isNotEmpty
        ? state.currentLocationId
        : (state.locations.isNotEmpty
              ? state.locations.first.locationId
              : 'home');
  }

  Future<void> _loadSceneForLocation(String locationId) async {
    if (_selectedLocationId == locationId && _scene != null) {
      return;
    }
    setState(() {
      _isLoadingScene = true;
      _selectedLocationId = locationId;
      _errorMessage = null;
      _statusMessage = null;
      _statusMemory = null;
      _observedSignals = const [];
    });
    try {
      final scene = await widget.apiClient.getStoryWorldScene(
        identity: widget.identity,
        locationId: locationId,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _scene = scene;
        _isLoadingScene = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isLoadingScene = false;
      });
    }
  }

  Future<void> _submitTurn() async {
    final state = _state;
    final scene = _scene;
    final location = _selectedLocation;
    final answer = _answerController.text.trim();
    if (state == null ||
        scene == null ||
        location == null ||
        answer.length < 2) {
      return;
    }
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final turn = await widget.apiClient.submitStoryWorldTurn(
        identity: widget.identity,
        request: StoryWorldTurnRequest(
          locationId: location.locationId,
          answer: answer,
          expectedChapter: scene.chapter,
        ),
      );
      if (!mounted) {
        return;
      }
      _answerController.clear();
      setState(() {
        _state = turn.state;
        _scene = turn.scene;
        _selectedLocationId = turn.scene.locationId;
        _statusMessage = turn.message;
        _statusMemory = turn.memory;
        _observedSignals = turn.observedSignals;
        _isSubmitting = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.toString();
        _isSubmitting = false;
      });
    }
  }

  StoryWorldLocationState? get _selectedLocation {
    final state = _state;
    final selectedLocationId = _selectedLocationId;
    if (state == null || selectedLocationId == null) {
      return null;
    }
    for (final location in state.locations) {
      if (location.locationId == selectedLocationId) {
        return location;
      }
    }
    return null;
  }

  StoryWorldNpcState? get _selectedNpc {
    final state = _state;
    final location = _selectedLocation;
    if (state == null || location == null) {
      return null;
    }
    for (final npc in state.npcs) {
      if (npc.npcId == location.npcId) {
        return npc;
      }
    }
    return null;
  }

  Color _locationColor(String locationId) {
    return switch (locationId) {
      'home' => const Color(0xFFFF8A65),
      'school' => const Color(0xFF42A5F5),
      'forest' => const Color(0xFF43A047),
      'castle' => const Color(0xFFAB47BC),
      'park' => const Color(0xFFEC407A),
      'beach' => const Color(0xFF00ACC1),
      _ => widget.palette.primary,
    };
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _StoryWorldTopBar(
              palette: palette,
              onBack: () => Navigator.of(context).pop(),
            ),
            HeroHeader(
              palette: palette,
              kicker: 'Story World',
              title: 'Every reply changes the path',
              subtitle:
                  'A backend-backed story game for confidence, teamwork, calm, and help-seeking. Your progress is saved to your student profile.',
              actions: [
                const Pill(
                  icon: Icons.cloud_done_rounded,
                  label: 'Backend live',
                ),
                Pill(
                  icon: Icons.stars_rounded,
                  label: '${_state?.stars ?? 0} stars',
                ),
                Pill(
                  icon: Icons.auto_awesome_rounded,
                  label: '${_state?.xp ?? 0} XP',
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (_isLoading) ...[
              GlassPanel(
                palette: palette,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                      title: 'Loading Story World',
                      subtitle:
                          'Fetching your saved game state and current scene.',
                    ),
                    LinearProgressIndicator(),
                  ],
                ),
              ),
            ] else if (_errorMessage != null && _state == null) ...[
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Could not load cleanly',
                      subtitle:
                          'The screen did not get a valid Story World response.',
                    ),
                    Text(_errorMessage!),
                    const SizedBox(height: 14),
                    AnimatedPrimaryButton(
                      label: 'Retry Story World',
                      icon: Icons.refresh_rounded,
                      onPressed: _loadStoryWorld,
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildStatsRow(palette),
              const SizedBox(height: 18),
              _buildLocationSelector(palette),
              const SizedBox(height: 18),
              _buildScenePanel(palette),
              if (_statusMessage != null) ...[
                const SizedBox(height: 18),
                _buildOutcomePanel(palette),
              ],
              const SizedBox(height: 18),
              _buildComposerPanel(palette),
              const SizedBox(height: 18),
              _buildCompanionPanel(palette),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(PrototypePalette palette) {
    final state = _state;
    if (state == null) {
      return const SizedBox.shrink();
    }
    return Row(
      children: [
        Expanded(
          child: _StoryWorldStatCard(
            palette: palette,
            title: 'Stars',
            value: '${state.stars}',
            subtitle: 'Unlock more worlds',
            icon: Icons.stars_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StoryWorldStatCard(
            palette: palette,
            title: 'Coins',
            value: '${state.coins}',
            subtitle: 'Demo progression',
            icon: Icons.toll_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StoryWorldStatCard(
            palette: palette,
            title: 'Completed',
            value: '${state.completedQuestCount}',
            subtitle: 'Worlds finished',
            icon: Icons.flag_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSelector(PrototypePalette palette) {
    final state = _state;
    if (state == null) {
      return const SizedBox.shrink();
    }
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Choose a world',
            subtitle:
                'Unlocked worlds are based on your progress. Locked worlds open as you earn stars.',
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: state.locations.map((location) {
              final selected = location.locationId == _selectedLocationId;
              final color = _locationColor(location.locationId);
              return GestureDetector(
                onTap: () {
                  if (!location.unlocked) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '${location.displayName} unlocks at ${location.unlockStars} stars.',
                        ),
                      ),
                    );
                    return;
                  }
                  _loadSceneForLocation(location.locationId);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 154,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: selected
                        ? color.withValues(alpha: .18)
                        : palette.surface.withValues(
                            alpha: palette.isDark ? .56 : .82,
                          ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: selected
                          ? color
                          : Colors.white.withValues(
                              alpha: palette.isDark ? .12 : .52,
                            ),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            location.unlocked
                                ? Icons.explore_rounded
                                : Icons.lock_rounded,
                            color: color,
                          ),
                          const Spacer(),
                          if (location.completed)
                            Icon(Icons.check_circle_rounded, color: color),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        location.displayName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        location.subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: palette.isDark
                              ? palette.text.withValues(alpha: .82)
                              : palette.muted,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        location.unlocked
                            ? 'Chapter ${location.chapter} • ${location.progressPercent.toStringAsFixed(0)}%'
                            : '${location.unlockStars} stars needed',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildScenePanel(PrototypePalette palette) {
    final scene = _scene;
    final location = _selectedLocation;
    final npc = _selectedNpc;
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: scene?.title ?? 'Loading scene',
            subtitle: location == null
                ? 'Select a world to begin.'
                : '${location.displayName} with ${npc?.npcName ?? location.npcName}',
          ),
          if (_isLoadingScene)
            const LinearProgressIndicator()
          else if (_errorMessage != null && scene == null)
            Text(_errorMessage!)
          else if (scene != null) ...[
            Text(scene.body),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.chat_bubble_rounded, color: palette.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      scene.prompt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOutcomePanel(PrototypePalette palette) {
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'What changed',
            subtitle: 'This is the immediate outcome from your last choice.',
          ),
          Text(_statusMessage ?? ''),
          if ((_statusMemory ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _statusMemory!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (_observedSignals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _observedSignals
                  .map(
                    (signal) => Chip(label: Text(signal.replaceAll('_', ' '))),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposerPanel(PrototypePalette palette) {
    final scene = _scene;
    final location = _selectedLocation;
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Type your next move',
            subtitle: location == null
                ? 'Choose an unlocked world first.'
                : 'You are replying to chapter ${scene?.chapter ?? location.chapter} in ${location.displayName}.',
          ),
          TextField(
            controller: _answerController,
            minLines: 3,
            maxLines: 5,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'Example: I would slow everyone down, help Maya breathe, and rebuild the volcano together.',
              filled: true,
              fillColor: palette.surface.withValues(
                alpha: palette.isDark ? .48 : .92,
              ),
            ),
          ),
          if (_errorMessage != null && _state != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.redAccent),
            ),
          ],
          const SizedBox(height: 14),
          AnimatedPrimaryButton(
            label: _isSubmitting ? 'Sending your move...' : 'Send my move',
            icon: _isSubmitting
                ? Icons.hourglass_top_rounded
                : Icons.send_rounded,
            onPressed: _isSubmitting ? () {} : _submitTurn,
          ),
        ],
      ),
    );
  }

  Widget _buildCompanionPanel(PrototypePalette palette) {
    final npc = _selectedNpc;
    final location = _selectedLocation;
    if (location == null || npc == null) {
      return const SizedBox.shrink();
    }
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: '${npc.npcName} remembers',
            subtitle:
                'Story World keeps a small, non-clinical memory trail for this world.',
          ),
          Text(
            'Friendship level: ${npc.friendshipLevel} • Mood: ${npc.currentMood}',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _locationColor(location.locationId),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (npc.memories.isEmpty)
            Text(
              'No saved memories yet. Your first few turns will start building the story.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.isDark
                    ? palette.text.withValues(alpha: .82)
                    : palette.muted,
              ),
            )
          else
            ...npc.memories.reversed
                .take(4)
                .map(
                  (memory) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('• $memory'),
                  ),
                ),
        ],
      ),
    );
  }
}

class _StoryWorldTopBar extends StatelessWidget {
  const _StoryWorldTopBar({required this.palette, required this.onBack});

  final PrototypePalette palette;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          IconButton.filledTonal(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const Spacer(),
          ThemeModeToggle(palette: palette),
        ],
      ),
    );
  }
}

class _StoryWorldStatCard extends StatelessWidget {
  const _StoryWorldStatCard({
    required this.palette,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final PrototypePalette palette;
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: palette.isDark
                  ? palette.text.withValues(alpha: .82)
                  : palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
