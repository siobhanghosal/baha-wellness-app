import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';

class StudentJournalScreen extends StatefulWidget {
  const StudentJournalScreen({
    required this.externalAuthId,
    required this.ageBand,
    super.key,
  });

  final String externalAuthId;
  final String? ageBand;

  @override
  State<StudentJournalScreen> createState() => _StudentJournalScreenState();
}

class _StudentJournalScreenState extends State<StudentJournalScreen> {
  static const _entriesKeyPrefix = 'baha.student.journal.entries.';
  static const _remindersKeyPrefix = 'baha.student.journal.reminders.';

  final TextEditingController _searchController = TextEditingController();
  List<_JournalEntry> _entries = const [];
  String _filter = 'all';
  bool _remindersEnabled = true;
  bool _loading = true;

  String get _entriesKey => '$_entriesKeyPrefix${widget.externalAuthId}';
  String get _remindersKey => '$_remindersKeyPrefix${widget.externalAuthId}';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final rawEntries = preferences.getStringList(_entriesKey) ?? const [];
    final entries =
        rawEntries
            .map(
              (item) => _JournalEntry.fromJson(
                jsonDecode(item) as Map<String, dynamic>,
              ),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = entries;
      _remindersEnabled = preferences.getBool(_remindersKey) ?? true;
      _loading = false;
    });
  }

  Future<void> _saveEntries(List<_JournalEntry> entries) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(
      _entriesKey,
      entries.map((entry) => jsonEncode(entry.toJson())).toList(),
    );
  }

  Future<void> _setReminders(bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_remindersKey, value);
    if (!mounted) {
      return;
    }
    setState(() {
      _remindersEnabled = value;
    });
  }

  Future<void> _openEditor({
    required _JournalMode mode,
    _JournalEntry? existing,
  }) async {
    final entry = await Navigator.of(context).push<_JournalEntry>(
      MaterialPageRoute<_JournalEntry>(
        builder: (context) => _JournalEditorScreen(
          mode: mode,
          initialEntry: existing,
          ageBand: widget.ageBand,
        ),
      ),
    );
    if (entry == null) {
      return;
    }
    final next = [..._entries.where((item) => item.id != entry.id), entry]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveEntries(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = next;
    });
  }

  Future<void> _deleteEntry(_JournalEntry entry) async {
    final next = _entries.where((item) => item.id != entry.id).toList();
    await _saveEntries(next);
    if (!mounted) {
      return;
    }
    setState(() {
      _entries = next;
    });
  }

  List<_JournalEntry> get _visibleEntries {
    final query = _searchController.text.trim().toLowerCase();
    return _entries.where((entry) {
      final matchesFilter = switch (_filter) {
        'guided' => entry.mode == _JournalMode.guided,
        'favorite' => entry.isFavorite,
        _ => true,
      };
      if (!matchesFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack = [
        entry.title,
        entry.body,
        entry.prompt ?? '',
        entry.moodLabel,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  int get _streakDays {
    if (_entries.isEmpty) {
      return 0;
    }
    final uniqueDays =
        _entries
            .map(
              (entry) => DateTime(
                entry.updatedAt.year,
                entry.updatedAt.month,
                entry.updatedAt.day,
              ),
            )
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));
    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);
    for (final day in uniqueDays) {
      if (day == cursor) {
        streak += 1;
        cursor = cursor.subtract(const Duration(days: 1));
        continue;
      }
      if (streak == 0 && day == cursor.subtract(const Duration(days: 1))) {
        streak += 1;
        cursor = day.subtract(const Duration(days: 1));
        continue;
      }
      break;
    }
    return streak;
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    final visibleEntries = _visibleEntries;
    final favoriteCount = _entries.where((entry) => entry.isFavorite).length;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: _loading
            ? ListView(
                padding: const EdgeInsets.all(22),
                children: [ShimmerBlock(palette: palette)],
              )
            : ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      ThemeModeToggle(palette: palette),
                    ],
                  ),
                  HeroHeader(
                    palette: palette,
                    kicker: 'Journal',
                    title: 'A private place to sort out your thoughts',
                    subtitle:
                        'Write freely, use a guided prompt, and come back to what matters later.',
                    actions: [
                      const Pill(icon: Icons.lock_rounded, label: 'Private'),
                      Pill(
                        icon: Icons.auto_stories_rounded,
                        label: '${_entries.length} entries',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _JournalStatCard(
                          palette: palette,
                          title: 'Entries',
                          value: '${_entries.length}',
                          subtitle: 'Saved reflections',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _JournalStatCard(
                          palette: palette,
                          title: 'Streak',
                          value:
                              '$_streakDays day${_streakDays == 1 ? '' : 's'}',
                          subtitle: 'Recent writing rhythm',
                          icon: Icons.local_fire_department_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _JournalStatCard(
                          palette: palette,
                          title: 'Favorites',
                          value: '$favoriteCount',
                          subtitle: 'Worth revisiting',
                          icon: Icons.star_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Start a new entry',
                          subtitle:
                              'Choose a writing style that matches your day.',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () =>
                                  _openEditor(mode: _JournalMode.freeWrite),
                              icon: const Icon(Icons.edit_rounded),
                              label: const Text('Free write'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _openEditor(mode: _JournalMode.guided),
                              icon: const Icon(Icons.lightbulb_rounded),
                              label: const Text('Guided prompt'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () =>
                                  _openEditor(mode: _JournalMode.gratitude),
                              icon: const Icon(Icons.favorite_outline_rounded),
                              label: const Text('Gratitude note'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Journal preferences',
                          subtitle:
                              'Keep the habit gentle and easy to return to.',
                        ),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Gentle reminder'),
                          subtitle: const Text(
                            'Keep a soft prompt ready for days when you want help starting.',
                          ),
                          value: _remindersEnabled,
                          onChanged: _setReminders,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Your entries',
                          subtitle:
                              'Search old reflections or keep favorite ones close.',
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search_rounded),
                            hintText: 'Search entries, prompts, or moods',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _JournalFilterChip(
                              label: 'All',
                              selected: _filter == 'all',
                              onTap: () => setState(() => _filter = 'all'),
                            ),
                            _JournalFilterChip(
                              label: 'Guided',
                              selected: _filter == 'guided',
                              onTap: () => setState(() => _filter = 'guided'),
                            ),
                            _JournalFilterChip(
                              label: 'Favorites',
                              selected: _filter == 'favorite',
                              onTap: () => setState(() => _filter = 'favorite'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (visibleEntries.isEmpty)
                          Text(
                            _entries.isEmpty
                                ? 'No entries yet. Start with a free write or guided prompt.'
                                : 'No entries match your current filter.',
                          )
                        else
                          ...visibleEntries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _JournalEntryCard(
                                palette: palette,
                                entry: entry,
                                onOpen: () => _openEditor(
                                  mode: entry.mode,
                                  existing: entry,
                                ),
                                onDelete: () => _deleteEntry(entry),
                              ),
                            ),
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

class _JournalEditorScreen extends StatefulWidget {
  const _JournalEditorScreen({
    required this.mode,
    required this.ageBand,
    this.initialEntry,
  });

  final _JournalMode mode;
  final _JournalEntry? initialEntry;
  final String? ageBand;

  @override
  State<_JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<_JournalEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _bodyController;
  late _JournalMood _mood;
  late bool _isFavorite;
  late String? _selectedPrompt;

  List<String> get _prompts => _journalPromptsForAgeBand(widget.ageBand);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.initialEntry?.title ?? '',
    );
    _bodyController = TextEditingController(
      text: widget.initialEntry?.body ?? '',
    );
    _mood = widget.initialEntry?.mood ?? _JournalMood.calm;
    _isFavorite = widget.initialEntry?.isFavorite ?? false;
    _selectedPrompt =
        widget.initialEntry?.prompt ??
        (widget.mode == _JournalMode.guided ? _prompts.first : null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _save() {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      return;
    }
    final now = DateTime.now();
    Navigator.of(context).pop(
      _JournalEntry(
        id: widget.initialEntry?.id ?? now.microsecondsSinceEpoch.toString(),
        title: _titleController.text.trim().isEmpty
            ? _defaultTitleForMode(widget.mode)
            : _titleController.text.trim(),
        body: body,
        mode: widget.mode,
        mood: _mood,
        prompt: _selectedPrompt,
        isFavorite: _isFavorite,
        createdAt: widget.initialEntry?.createdAt ?? now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    final title = switch (widget.mode) {
      _JournalMode.freeWrite => 'Free write',
      _JournalMode.guided => 'Guided reflection',
      _JournalMode.gratitude => 'Gratitude note',
    };
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => setState(() => _isFavorite = !_isFavorite),
                  icon: Icon(
                    _isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: _isFavorite ? Colors.amber : null,
                  ),
                ),
              ],
            ),
            HeroHeader(
              palette: palette,
              kicker: 'Journal entry',
              title: title,
              subtitle:
                  'Keep it honest, short if you want, and easy to revisit later.',
              actions: [
                Pill(icon: Icons.mood_rounded, label: _mood.label),
                Pill(
                  icon: widget.mode == _JournalMode.guided
                      ? Icons.lightbulb_rounded
                      : Icons.edit_note_rounded,
                  label: widget.mode.label,
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (widget.mode == _JournalMode.guided ||
                widget.mode == _JournalMode.gratitude)
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Prompt',
                      subtitle: 'Pick one that feels useful right now.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _prompts.map((prompt) {
                        final selected = _selectedPrompt == prompt;
                        return ChoiceChip(
                          label: Text(prompt),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedPrompt = prompt),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (widget.mode == _JournalMode.guided ||
                widget.mode == _JournalMode.gratitude)
              const SizedBox(height: 18),
            GlassPanel(
              palette: palette,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(
                    title: 'How are you writing today?',
                    subtitle:
                        'Choose a mood so later entries are easier to scan.',
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _JournalMood.values.map((mood) {
                      return ChoiceChip(
                        label: Text(mood.label),
                        selected: _mood == mood,
                        onSelected: (_) => setState(() => _mood = mood),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Give this entry a short name',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _bodyController,
                    maxLines: 12,
                    decoration: InputDecoration(
                      labelText: 'Your words',
                      hintText:
                          _selectedPrompt ??
                          'Write what is on your mind, what happened, or what you need next.',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Save entry'),
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

class _JournalStatCard extends StatelessWidget {
  const _JournalStatCard({
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
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _JournalFilterChip extends StatelessWidget {
  const _JournalFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  const _JournalEntryCard({
    required this.palette,
    required this.entry,
    required this.onOpen,
    required this.onDelete,
  });

  final PrototypePalette palette;
  final _JournalEntry entry;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      padding: const EdgeInsets.all(16),
      onTap: onOpen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (entry.isFavorite)
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.star_rounded, color: Colors.amber),
                ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'delete') {
                    onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<String>(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(icon: Icons.mood_rounded, label: entry.moodLabel),
              Pill(icon: Icons.auto_stories_rounded, label: entry.mode.label),
              Pill(
                icon: Icons.schedule_rounded,
                label: _formatJournalDate(entry.updatedAt),
              ),
            ],
          ),
          if ((entry.prompt ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              entry.prompt!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: palette.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Text(
            entry.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }
}

enum _JournalMode {
  freeWrite('Free write'),
  guided('Guided'),
  gratitude('Gratitude');

  const _JournalMode(this.label);

  final String label;
}

enum _JournalMood {
  calm('Calm'),
  hopeful('Hopeful'),
  mixed('Mixed'),
  low('Low'),
  stressed('Stressed');

  const _JournalMood(this.label);

  final String label;
}

class _JournalEntry {
  const _JournalEntry({
    required this.id,
    required this.title,
    required this.body,
    required this.mode,
    required this.mood,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.prompt,
  });

  final String id;
  final String title;
  final String body;
  final _JournalMode mode;
  final _JournalMood mood;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? prompt;

  String get moodLabel => mood.label;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'mode': mode.name,
      'mood': mood.name,
      'is_favorite': isFavorite,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'prompt': prompt,
    };
  }

  factory _JournalEntry.fromJson(Map<String, dynamic> json) {
    return _JournalEntry(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      mode: _JournalMode.values.firstWhere(
        (mode) => mode.name == json['mode'],
        orElse: () => _JournalMode.freeWrite,
      ),
      mood: _JournalMood.values.firstWhere(
        (mood) => mood.name == json['mood'],
        orElse: () => _JournalMood.calm,
      ),
      isFavorite: json['is_favorite'] as bool? ?? false,
      createdAt:
          DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ??
          DateTime.now(),
      prompt: json['prompt'] as String?,
    );
  }
}

List<String> _journalPromptsForAgeBand(String? ageBand) {
  return switch (ageBand) {
    '9_12' => const [
      'What felt easy today?',
      'What felt tricky today?',
      'Who helped you today?',
      'What do you want tomorrow to feel like?',
    ],
    '13_14' => const [
      'What took the most energy today?',
      'What helped you stay steady, even a little?',
      'What do you wish someone understood about today?',
      'What is one small thing you want to handle better tomorrow?',
    ],
    '18_plus' => const [
      'What is sitting with you most strongly right now?',
      'What pattern from this week do you want to understand better?',
      'What helped, even if only a little?',
      'What is one next step that feels realistic tonight?',
    ],
    _ => const [
      'What felt heavier than it looked from the outside?',
      'What helped you stay steady today?',
      'What do you want to let go of before tomorrow?',
      'What is one next step that actually feels manageable?',
    ],
  };
}

String _defaultTitleForMode(_JournalMode mode) {
  return switch (mode) {
    _JournalMode.freeWrite => 'New reflection',
    _JournalMode.guided => 'Guided reflection',
    _JournalMode.gratitude => 'Gratitude note',
  };
}

String _formatJournalDate(DateTime value) {
  final month = switch (value.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    _ => 'Dec',
  };
  final hour = value.hour == 0
      ? 12
      : (value.hour > 12 ? value.hour - 12 : value.hour);
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$month ${value.day} • $hour:$minute $suffix';
}
