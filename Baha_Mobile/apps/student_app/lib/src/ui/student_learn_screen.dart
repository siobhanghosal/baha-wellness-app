import 'dart:async';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_content_renderer/baha_content_renderer.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_models.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';

class StudentLearnScreen extends StatefulWidget {
  const StudentLearnScreen({
    required this.apiClient,
    required this.identity,
    this.initialTheme,
    this.screenTitle,
    this.screenSubtitle,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String? initialTheme;
  final String? screenTitle;
  final String? screenSubtitle;

  @override
  State<StudentLearnScreen> createState() => _StudentLearnScreenState();
}

class _StudentLearnScreenState extends State<StudentLearnScreen> {
  static const _recentModuleIdsKey = 'baha.student.recent_module_ids';
  static const _recentContentIdsKey = 'baha.student.recent_content_ids';
  static const _practiceSelectionsPrefix = 'baha.student.practice.';

  late Future<_StudentLearnHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentLearnHubData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.listMobileContentFeed(
        identity: widget.identity,
        theme: widget.initialTheme,
      ),
      widget.apiClient.listStudentModules(
        identity: widget.identity,
        theme: widget.initialTheme,
      ),
      SharedPreferences.getInstance(),
    ]);
    final preferences = results[2] as SharedPreferences;
    return _StudentLearnHubData(
      contentFeed: results[0] as List<MobileContentSummary>,
      modules: results[1] as List<StudentModuleSummary>,
      recentModuleIds:
          preferences.getStringList(_recentModuleIdsKey) ?? const [],
      recentContentIds:
          preferences.getStringList(_recentContentIdsKey) ?? const [],
      practiceSelections: widget.initialTheme == null
          ? const []
          : (preferences.getStringList(
                  _practiceSelectionsKey(widget.initialTheme!),
                ) ??
                const []),
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openModule(StudentModuleSummary module) async {
    await _rememberRecentId(key: _recentModuleIdsKey, value: module.id);
    final updated = await _pushThemedRoute<bool>(
      builder: (context) => StudentModuleDetailScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        module: module,
      ),
    );
    if (updated == true) {
      await _refresh();
    }
  }

  Future<void> _openContent(MobileContentSummary content) async {
    await _rememberRecentId(key: _recentContentIdsKey, value: content.id);
    await _pushThemedRoute<void>(
      builder: (context) => StudentContentDetailScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        contentItemId: content.id,
        titleOverride: content.title,
      ),
    );
    await _refresh();
  }

  Future<void> _rememberRecentId({
    required String key,
    required String value,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getStringList(key) ?? const <String>[];
    final updated = <String>[
      value,
      ...existing.where((item) => item != value),
    ].take(6).toList();
    await preferences.setStringList(key, updated);
  }

  String _practiceSelectionsKey(String theme) =>
      '$_practiceSelectionsPrefix${theme.toLowerCase().replaceAll(' ', '_')}';

  Future<void> _openPractice(_LearnLaneConfig lane) async {
    final result = await _pushThemedRoute<List<String>>(
      builder: (context) => _LanePracticeScreen(
        lane: lane,
        storageKey: _practiceSelectionsKey(lane.theme),
      ),
    );
    if (result != null) {
      await _refresh();
    }
  }

  Future<T?> _pushThemedRoute<T>({required WidgetBuilder builder}) async {
    final controller = ThemeScope.of(context);
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
        builder: (context) => ThemeScope(
          controller: controller,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => builder(context),
          ),
        ),
      ),
    );
  }

  Future<void> _openThemeLane(String theme) async {
    await _pushThemedRoute<void>(
      builder: (context) => StudentLearnScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        initialTheme: theme,
        screenTitle: theme,
        screenSubtitle:
            'A focused learning lane built from published BAHA content for $theme.',
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StudentLearnHubData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [ShimmerBlock(palette: palette)],
                );
              }
              if (snapshot.hasError) {
                return ListView(
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
                      kicker: 'Learn',
                      title: 'Could not load learning content',
                      subtitle: '${snapshot.error}',
                      actions: const [
                        Pill(icon: Icons.warning_rounded, label: 'Retry'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedPrimaryButton(
                      label: 'Reload learning hub',
                      icon: Icons.refresh_rounded,
                      onPressed: () => unawaited(_refresh()),
                    ),
                  ],
                );
              }

              final rawData = snapshot.data!;
              final visibleAgeBand = _resolveLearnAgeBand(rawData);
              final allowedThemes = _allowedLearnThemesForAgeBand(
                visibleAgeBand,
              );
              final data = _StudentLearnHubData(
                contentFeed: rawData.contentFeed
                    .where(
                      (content) =>
                          content.theme == null ||
                          content.theme!.trim().isEmpty ||
                          allowedThemes.contains(content.theme),
                    )
                    .toList(),
                modules: rawData.modules
                    .where((module) => allowedThemes.contains(module.theme))
                    .toList(),
                recentModuleIds: rawData.recentModuleIds,
                recentContentIds: rawData.recentContentIds,
                practiceSelections: rawData.practiceSelections,
              );
              final moduleByContentId = <String, StudentModuleSummary>{
                for (final module in data.modules) module.contentItemId: module,
              };
              final inProgressModules = data.modules
                  .where(
                    (module) =>
                        module.completionPercent > 0 &&
                        module.completionPercent < 100,
                  )
                  .toList();
              final recommendedModules = data.modules
                  .where((module) => module.completionPercent < 100)
                  .toList();
              final completedModules = data.modules
                  .where((module) => module.completionPercent >= 100)
                  .toList();
              final quickGuides = data.contentFeed
                  .where(
                    (content) => !moduleByContentId.containsKey(content.id),
                  )
                  .toList();
              final recentModules = data.recentModuleIds
                  .map((id) => _findModuleById(data.modules, id))
                  .whereType<StudentModuleSummary>()
                  .toList();
              final recentContent = data.recentContentIds
                  .map((id) => _findContentById(data.contentFeed, id))
                  .whereType<MobileContentSummary>()
                  .toList();
              final featuredThemes = {
                ...data.modules
                    .map((module) => module.theme)
                    .where((item) => item.trim().isNotEmpty),
                ...data.contentFeed
                    .map((content) => content.theme ?? '')
                    .where((item) => item.trim().isNotEmpty),
              }.toList();
              final lane = widget.initialTheme == null
                  ? null
                  : _learnLaneForTheme(widget.initialTheme!, visibleAgeBand);
              if (lane != null) {
                return _StructuredLearnLaneView(
                  palette: palette,
                  lane: lane,
                  data: data,
                  onBack: () => Navigator.of(context).pop(),
                  onOpenModule: _openModule,
                  onOpenContent: _openContent,
                  onOpenPractice: () => _openPractice(lane),
                );
              }
              final title =
                  widget.screenTitle ??
                  widget.initialTheme ??
                  'Explore learning that fits your life.';
              final subtitle =
                  widget.screenSubtitle ??
                  (widget.initialTheme == null
                      ? 'Short lessons, guided modules, and quick tools to help you learn at your own pace.'
                      : 'Everything here is focused on $title so it stays clear and easy to follow.');
              final kicker = widget.initialTheme == null
                  ? 'Discover'
                  : 'Focused Learn';

              return ListView(
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
                    kicker: kicker,
                    title: title,
                    subtitle: subtitle,
                    actions: [
                      Pill(
                        icon: Icons.auto_stories_rounded,
                        label: widget.initialTheme == null
                            ? 'Learn'
                            : 'Theme lane',
                      ),
                      Pill(
                        icon: Icons.cloud_done_rounded,
                        label:
                            '${data.modules.length} modules • ${quickGuides.length} guides',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _LearnStatCard(
                          palette: palette,
                          title: 'Continue',
                          value: '${inProgressModules.length}',
                          subtitle: 'Active modules',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LearnStatCard(
                          palette: palette,
                          title: 'Completed',
                          value: '${completedModules.length}',
                          subtitle: 'Finished modules',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (featuredThemes.isNotEmpty)
                    GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Browse by theme',
                            subtitle:
                                'Pick a topic to focus on what matters most right now.',
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: featuredThemes
                                .map(
                                  (theme) => ActionChip(
                                    onPressed: () => _openThemeLane(theme),
                                    label: Text(theme),
                                    avatar: const Icon(
                                      Icons.local_offer_rounded,
                                      size: 18,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  if (featuredThemes.isNotEmpty) const SizedBox(height: 18),
                  if (inProgressModules.isNotEmpty) ...[
                    GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Continue learning',
                            subtitle:
                                'Resume the modules you already started, with progress shown clearly.',
                          ),
                          ...inProgressModules.map(
                            (module) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModuleFeatureCard(
                                palette: palette,
                                module: module,
                                actionLabel: 'Resume',
                                onTap: () => _openModule(module),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Recommended modules',
                          subtitle:
                              'Core student course content, organized as guided modules.',
                        ),
                        if (recommendedModules.isEmpty && data.modules.isEmpty)
                          Text(
                            widget.initialTheme == null
                                ? 'No modules are available right now.'
                                : 'No modules are available for this topic right now.',
                          )
                        else if (recommendedModules.isEmpty)
                          ...completedModules.map(
                            (module) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModuleFeatureCard(
                                palette: palette,
                                module: module,
                                actionLabel: 'Review again',
                                onTap: () => _openModule(module),
                              ),
                            ),
                          )
                        else
                          ...recommendedModules.map(
                            (module) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModuleFeatureCard(
                                palette: palette,
                                onTap: () => _openModule(module),
                                module: module,
                                actionLabel: module.completionPercent > 0
                                    ? 'Continue'
                                    : 'Start',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (recentModules.isNotEmpty || recentContent.isNotEmpty) ...[
                    GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SectionTitle(
                            title: 'Recently opened',
                            subtitle: 'Pick up where you left off.',
                          ),
                          ...recentModules.map(
                            (module) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModuleMiniCard(
                                palette: palette,
                                title: module.title,
                                subtitle:
                                    '${module.theme} • ${module.completionPercent.toStringAsFixed(0)}%',
                                onTap: () => _openModule(module),
                              ),
                            ),
                          ),
                          ...recentContent.map(
                            (content) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ModuleMiniCard(
                                palette: palette,
                                title: content.title,
                                subtitle: _contentBadgeLabel(content),
                                onTap: () => _openContent(content),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Quick guides and prompts',
                          subtitle:
                              'Short reads and prompts for quick support.',
                        ),
                        if (quickGuides.isEmpty)
                          Text(
                            widget.initialTheme == null
                                ? 'No quick guides are available right now.'
                                : 'No quick guides are available for this topic right now.',
                          )
                        else
                          ...quickGuides.map((content) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ContentFeatureCard(
                                palette: palette,
                                content: content,
                                onTap: () => _openContent(content),
                              ),
                            );
                          }),
                      ],
                    ),
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

class StudentModuleDetailScreen extends StatefulWidget {
  const StudentModuleDetailScreen({
    required this.apiClient,
    required this.identity,
    required this.module,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final StudentModuleSummary module;

  @override
  State<StudentModuleDetailScreen> createState() =>
      _StudentModuleDetailScreenState();
}

class _StudentModuleDetailScreenState extends State<StudentModuleDetailScreen> {
  late Future<MobileContentDetail> _future;
  late StudentModuleSummary _module;
  bool _saving = false;
  bool _didUpdate = false;

  @override
  void initState() {
    super.initState();
    _module = widget.module;
    _future = widget.apiClient.getMobileContentDetail(
      identity: widget.identity,
      contentItemId: widget.module.contentItemId,
    );
  }

  Future<void> _saveProgress({
    required String status,
    required double completionPercent,
    int? currentSectionOrdinal,
    int? currentStepOrdinal,
  }) async {
    setState(() => _saving = true);
    try {
      final response = await widget.apiClient.upsertStudentModuleProgress(
        identity: widget.identity,
        moduleId: _module.id,
        request: ModuleProgressUpsertRequest(
          status: status,
          completionPercent: completionPercent,
          currentSectionOrdinal: currentSectionOrdinal,
          currentStepOrdinal: currentStepOrdinal,
        ),
      );
      setState(() {
        _didUpdate = true;
        _module = StudentModuleSummary(
          id: _module.id,
          contentItemId: _module.contentItemId,
          moduleCode: _module.moduleCode,
          title: _module.title,
          theme: _module.theme,
          ageCohort: _module.ageCohort,
          estimatedMinutes: _module.estimatedMinutes,
          sortOrder: _module.sortOrder,
          progressStatus: response.status,
          completionPercent: response.completionPercent,
          currentSectionOrdinal: response.currentSectionOrdinal,
          currentStepOrdinal: response.currentStepOrdinal,
          lastActivityAt: response.lastActivityAt,
          moduleProgressId: response.id,
          totalSections: _module.totalSections,
          totalSteps: _module.totalSteps,
        );
      });
      if (!mounted) {
        return;
      }
      final shouldCloseAfterSave =
          status == 'completed' && response.completionPercent >= 100;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progress saved: ${response.completionPercent.toStringAsFixed(0)}%',
          ),
        ),
      );
      if (shouldCloseAfterSave) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return PopScope<bool>(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_didUpdate);
      },
      child: Scaffold(
        body: Theme(
          data: buildTheme(palette),
          child: AnimatedGradientScaffold(
            palette: palette,
            child: FutureBuilder<MobileContentDetail>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return ListView(
                    padding: const EdgeInsets.all(22),
                    children: [ShimmerBlock(palette: palette)],
                  );
                }
                if (snapshot.hasError) {
                  return ListView(
                    padding: const EdgeInsets.all(22),
                    children: [
                      Row(
                        children: [
                          IconButton(
                            onPressed: () =>
                                Navigator.of(context).pop(_didUpdate),
                            icon: const Icon(Icons.arrow_back_rounded),
                          ),
                          const Spacer(),
                          ThemeModeToggle(palette: palette),
                        ],
                      ),
                      GlassPanel(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Could not load this module.',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text('${snapshot.error}'),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _future = widget.apiClient
                                      .getMobileContentDetail(
                                        identity: widget.identity,
                                        contentItemId:
                                            widget.module.contentItemId,
                                      );
                                });
                              },
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                final detail = snapshot.data!;
                final completedSections = (_module.currentSectionOrdinal ?? 0)
                    .clamp(0, _module.totalSections)
                    .toInt();
                final nextSection = _module.totalSections <= 0
                    ? 1
                    : (completedSections + 1)
                          .clamp(1, _module.totalSections)
                          .toInt();
                final hasStructuredSections = _module.totalSections > 0;
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () =>
                              Navigator.of(context).pop(_didUpdate),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        ThemeModeToggle(palette: palette),
                      ],
                    ),
                    HeroHeader(
                      palette: palette,
                      kicker: 'Module',
                      title: detail.title,
                      subtitle:
                          detail.summary ??
                          'Real module detail from the backend.',
                      actions: [
                        Pill(
                          icon: Icons.auto_stories_rounded,
                          label: _module.theme,
                        ),
                        Pill(
                          icon: Icons.insights_rounded,
                          label:
                              '${_module.completionPercent.toStringAsFixed(0)}%',
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
                            title: 'Module overview',
                            subtitle: 'A short overview before you begin.',
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetadataChip(
                                label: _module.theme,
                                icon: Icons.local_offer_rounded,
                              ),
                              if (_module.estimatedMinutes != null)
                                _MetadataChip(
                                  label: '${_module.estimatedMinutes} min',
                                  icon: Icons.schedule_rounded,
                                ),
                              _MetadataChip(
                                label:
                                    '${_module.completionPercent.toStringAsFixed(0)}% complete',
                                icon: Icons.insights_rounded,
                              ),
                              if (_module.totalSections > 0)
                                _MetadataChip(
                                  label:
                                      'Section ${completedSections == 0 ? 1 : completedSections} of ${_module.totalSections}',
                                  icon: Icons.format_list_numbered_rounded,
                                ),
                            ],
                          ),
                          if (_module.totalSections > 0) ...[
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: _module.completionPercent <= 0
                                  ? 0
                                  : ((_module.completionPercent / 100).clamp(
                                      0,
                                      1,
                                    )).toDouble(),
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ],
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
                            title: 'Learning flow',
                            subtitle:
                                'Read through the steps at your own pace.',
                          ),
                          MobileContentBodyView(
                            blocks: detail.blocks,
                            plainText: detail.plainText,
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
                            title: 'Progress actions',
                            subtitle:
                                'Opening a module already means you started it. Finish it when you are done reading.',
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed:
                                _saving || _module.completionPercent >= 100
                                ? null
                                : () => _saveProgress(
                                    status: 'completed',
                                    completionPercent: 100,
                                    currentSectionOrdinal: hasStructuredSections
                                        ? _module.totalSections
                                        : nextSection,
                                    currentStepOrdinal: _module.totalSteps > 0
                                        ? _module.totalSteps
                                        : null,
                                  ),
                            child: Text(
                              _saving
                                  ? 'Saving...'
                                  : _module.completionPercent >= 100
                                  ? 'Module completed'
                                  : 'Finish module',
                            ),
                          ),
                          if (_module.lastActivityAt != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              'Last activity ${_formatDateTime(_module.lastActivityAt!)}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: palette.muted),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class StudentContentDetailScreen extends StatefulWidget {
  const StudentContentDetailScreen({
    required this.apiClient,
    required this.identity,
    required this.contentItemId,
    required this.titleOverride,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String contentItemId;
  final String titleOverride;

  @override
  State<StudentContentDetailScreen> createState() =>
      _StudentContentDetailScreenState();
}

class _StudentContentDetailScreenState
    extends State<StudentContentDetailScreen> {
  late Future<MobileContentDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getMobileContentDetail(
      identity: widget.identity,
      contentItemId: widget.contentItemId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: FutureBuilder<MobileContentDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [ShimmerBlock(palette: palette)],
              );
            }
            if (snapshot.hasError) {
              return ListView(
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
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Could not load this content item.',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}'),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            setState(() {
                              _future = widget.apiClient.getMobileContentDetail(
                                identity: widget.identity,
                                contentItemId: widget.contentItemId,
                              );
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            final detail = snapshot.data!;
            return ListView(
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
                  kicker: 'Learn Detail',
                  title: widget.titleOverride,
                  subtitle:
                      detail.summary ?? 'Published BAHA learning content.',
                  actions: const [
                    Pill(icon: Icons.menu_book_rounded, label: 'Reviewed'),
                    Pill(icon: Icons.cloud_done_rounded, label: 'Live content'),
                  ],
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Overview',
                        subtitle:
                            'Reference detail layout with backend-driven copy.',
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          if ((detail.theme ?? '').isNotEmpty)
                            _MetadataChip(
                              label: detail.theme!,
                              icon: Icons.local_offer_rounded,
                            ),
                          _MetadataChip(
                            label: _contentTypeLabel(detail.contentType),
                            icon: Icons.menu_book_rounded,
                          ),
                          if (detail.reviewedBy != null &&
                              detail.reviewedBy!.trim().isNotEmpty)
                            _MetadataChip(
                              label: 'Reviewed',
                              icon: Icons.verified_rounded,
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
                        title: 'Content',
                        subtitle:
                            'Structured presentation of the live backend content blocks.',
                      ),
                      MobileContentBodyView(
                        blocks: detail.blocks,
                        plainText: detail.plainText,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LearnStatCard extends StatelessWidget {
  const _LearnStatCard({
    required this.palette,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final PrototypePalette palette;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ModuleFeatureCard extends StatelessWidget {
  const _ModuleFeatureCard({
    required this.palette,
    required this.module,
    required this.actionLabel,
    required this.onTap,
  });

  final PrototypePalette palette;
  final StudentModuleSummary module;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.auto_stories_outlined,
                  color: palette.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      module.theme,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: palette.muted),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (module.completionPercent / 100).clamp(0, 1),
              minHeight: 10,
              backgroundColor: palette.primary.withValues(alpha: .10),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _MetadataChip(
                label: '${module.completionPercent.toStringAsFixed(0)}%',
                icon: Icons.insights_rounded,
              ),
              if (module.estimatedMinutes != null)
                _MetadataChip(
                  label: '${module.estimatedMinutes} min',
                  icon: Icons.schedule_rounded,
                ),
              _MetadataChip(label: actionLabel, icon: Icons.play_arrow_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContentFeatureCard extends StatelessWidget {
  const _ContentFeatureCard({
    required this.palette,
    required this.content,
    required this.onTap,
  });

  final PrototypePalette palette;
  final MobileContentSummary content;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionCard(
      palette: palette,
      item: UiCardItem(
        title: content.title,
        subtitle:
            content.summary ??
            'Backend-published content available for this audience.',
        tag: _contentBadgeLabel(content),
        icon: _contentIcon(content.contentType),
        color: palette.secondary,
      ),
      onTap: onTap,
    );
  }
}

class _ModuleMiniCard extends StatelessWidget {
  const _ModuleMiniCard({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final PrototypePalette palette;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.secondary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.bookmark_added_rounded, color: palette.secondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetadataChip extends StatelessWidget {
  const _MetadataChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _StudentLearnHubData {
  const _StudentLearnHubData({
    required this.contentFeed,
    required this.modules,
    required this.recentModuleIds,
    required this.recentContentIds,
    required this.practiceSelections,
  });

  final List<MobileContentSummary> contentFeed;
  final List<StudentModuleSummary> modules;
  final List<String> recentModuleIds;
  final List<String> recentContentIds;
  final List<String> practiceSelections;
}

String? _resolveLearnAgeBand(_StudentLearnHubData data) {
  if (data.modules.isNotEmpty) {
    return data.modules.first.ageCohort;
  }
  if (data.contentFeed.isNotEmpty) {
    return data.contentFeed.first.ageCohort;
  }
  return null;
}

Set<String> _allowedLearnThemesForAgeBand(String? ageBand) {
  return const {
    'Sleep',
    'Stress',
    'Bullying',
    'Healthy Gaming',
    'Alcohol Safety',
  };
}

class _LearnLaneConfig {
  const _LearnLaneConfig({
    required this.theme,
    required this.displayTitle,
    required this.displaySubtitle,
    required this.rewardTitle,
    required this.rewardSummary,
    required this.practiceTitle,
    required this.practiceSubtitle,
    required this.practiceCta,
    required this.practiceOptions,
    required this.icon,
  });

  final String theme;
  final String displayTitle;
  final String displaySubtitle;
  final String rewardTitle;
  final String rewardSummary;
  final String practiceTitle;
  final String practiceSubtitle;
  final String practiceCta;
  final List<String> practiceOptions;
  final IconData icon;
}

_LearnLaneConfig? _learnLaneForTheme(String theme, String? ageBand) {
  if (ageBand == '9_12') {
    return switch (theme) {
      'Sleep' => const _LearnLaneConfig(
        theme: 'Sleep',
        displayTitle: 'Sleep and Recharge',
        displaySubtitle:
            'A guided lane for bedtime habits, better rest, and calmer nights.',
        rewardTitle: 'Sleep Hero',
        rewardSummary:
            'Finish this lane and your child-friendly sleep badge is unlocked.',
        practiceTitle: 'Build my bedtime routine',
        practiceSubtitle:
            'Pick the bedtime steps you want in your own routine and save them for later.',
        practiceCta: 'Save bedtime routine',
        practiceOptions: [
          'Brush my teeth',
          'Read a quiet story or book',
          'Put screens away before bed',
          'Dim the lights',
          'Drink water earlier, not right before bed',
          'Go to bed around the same time',
        ],
        icon: Icons.bedtime_rounded,
      ),
      'Stress' => const _LearnLaneConfig(
        theme: 'Stress',
        displayTitle: 'Calm Through Stress',
        displaySubtitle:
            'A guided lane for noticing stress, calming your body, and asking for help.',
        rewardTitle: 'Calm Toolbox Builder',
        rewardSummary:
            'Finish this lane and you unlock your calm-toolbox badge.',
        practiceTitle: 'Build my calm toolbox',
        practiceSubtitle:
            'Choose the calming tools you want to remember when your body feels busy or worried.',
        practiceCta: 'Save calm toolbox',
        practiceOptions: [
          'Slow breathing',
          'Drawing or coloring',
          'Reading quietly',
          'Taking a short walk with an adult',
          'Listening to calm music',
          'Talking to someone I trust',
        ],
        icon: Icons.self_improvement_rounded,
      ),
      'Bullying' => const _LearnLaneConfig(
        theme: 'Bullying',
        displayTitle: 'Bullying and Kindness',
        displaySubtitle:
            'A guided lane for safety, trusted-adult help, and kind bystander choices.',
        rewardTitle: 'Kindness Shield',
        rewardSummary:
            'Finish this lane and unlock a badge for safe, kind action.',
        practiceTitle: 'Choose my safe actions',
        practiceSubtitle:
            'Save the safe actions you want to remember if bullying happens around you.',
        practiceCta: 'Save safe actions',
        practiceOptions: [
          'Walk to a safe place',
          'Tell a teacher or trusted adult',
          'Stay with supportive friends',
          'Invite someone to join my group',
          'Do not laugh along',
          'Keep speaking up if it continues',
        ],
        icon: Icons.shield_rounded,
      ),
      'Healthy Gaming' => const _LearnLaneConfig(
        theme: 'Healthy Gaming',
        displayTitle: 'Healthy Gaming',
        displaySubtitle:
            'A guided lane for balance, online safety, and making room for real life too.',
        rewardTitle: 'Balance Builder',
        rewardSummary: 'Finish this lane and unlock your healthy-gaming badge.',
        practiceTitle: 'Build my balanced day',
        practiceSubtitle:
            'Choose the habits that help games stay fun without taking over your whole day.',
        practiceCta: 'Save balanced-day plan',
        practiceOptions: [
          'Finish homework before gaming',
          'Take movement breaks',
          'Eat meals away from the screen',
          'Keep time for outside play',
          'Protect my personal information',
          'Stop in time for sleep',
        ],
        icon: Icons.sports_esports_rounded,
      ),
      'Alcohol Safety' => const _LearnLaneConfig(
        theme: 'Alcohol Safety',
        displayTitle: 'Alcohol Safety',
        displaySubtitle:
            'A guided lane for safe choices, trusted-adult help, and saying no with confidence.',
        rewardTitle: 'Safe Choice Star',
        rewardSummary: 'Finish this lane and unlock your safe-choice badge.',
        practiceTitle: 'Practice safe response lines',
        practiceSubtitle:
            'Pick the short response lines you want to remember if something feels unsafe.',
        practiceCta: 'Save my response lines',
        practiceOptions: [
          'No thank you',
          'I do not want that',
          'I am going to find my parent or teacher',
          'Let us do something else',
          'I am not taking a drink I do not know',
          'Tell a trusted adult right away',
        ],
        icon: Icons.no_drinks_rounded,
      ),
      _ => null,
    };
  }
  if (ageBand == '13_14') {
    return switch (theme) {
      'Sleep' => const _LearnLaneConfig(
        theme: 'Sleep',
        displayTitle: 'Sleep Reset',
        displaySubtitle:
            'A guided lane for steadier nights, calmer screens, and better daytime energy.',
        rewardTitle: 'Sleep Reset Badge',
        rewardSummary:
            'Finish this lane and you unlock your sleep-reset progress badge.',
        practiceTitle: 'Build my better-night plan',
        practiceSubtitle:
            'Save the sleep habits you want to stick with this week.',
        practiceCta: 'Save sleep plan',
        practiceOptions: [
          'Put my phone away before bed',
          'Start winding down earlier',
          'Keep a steadier bedtime',
          'Avoid long late-night gaming',
          'Get ready for tomorrow before bed',
          'Use one calming bedtime habit',
        ],
        icon: Icons.bedtime_rounded,
      ),
      'Stress' => const _LearnLaneConfig(
        theme: 'Stress',
        displayTitle: 'Stress Reset',
        displaySubtitle:
            'A guided lane for noticing pressure early and using one calm next step.',
        rewardTitle: 'Stress Reset Badge',
        rewardSummary:
            'Finish this lane and you unlock your stress-reset badge.',
        practiceTitle: 'Build my calm plan',
        practiceSubtitle:
            'Choose the tools you want available when things feel heavier.',
        practiceCta: 'Save calm plan',
        practiceOptions: [
          'Break the task into smaller steps',
          'Take a short breathing break',
          'Talk to someone I trust',
          'Write down the next step only',
          'Step away from the screen for a bit',
          'Ask for help earlier',
        ],
        icon: Icons.self_improvement_rounded,
      ),
      'Bullying' => const _LearnLaneConfig(
        theme: 'Bullying',
        displayTitle: 'Bullying and Boundaries',
        displaySubtitle:
            'A guided lane for spotting repeated harm, staying safe, and getting help.',
        rewardTitle: 'Boundary Builder',
        rewardSummary:
            'Finish this lane and you unlock your bullying-and-boundaries badge.',
        practiceTitle: 'Choose my safe responses',
        practiceSubtitle:
            'Save the safe moves you want to remember if things get hurtful or unsafe.',
        practiceCta: 'Save safe responses',
        practiceOptions: [
          'Tell a trusted adult',
          'Keep evidence of messages if needed',
          'Move toward safe people',
          'Block or report online harm',
          'Do not handle it alone',
          'Check in on someone safely',
        ],
        icon: Icons.shield_rounded,
      ),
      'Healthy Gaming' => const _LearnLaneConfig(
        theme: 'Healthy Gaming',
        displayTitle: 'Healthy Gaming',
        displaySubtitle:
            'A guided lane for keeping gaming fun without losing sleep, school, or balance.',
        rewardTitle: 'Balance Builder',
        rewardSummary:
            'Finish this lane and you unlock your healthy-gaming badge.',
        practiceTitle: 'Build my balanced-week plan',
        practiceSubtitle:
            'Pick the habits that help gaming stay fun and manageable.',
        practiceCta: 'Save balanced-week plan',
        practiceOptions: [
          'Finish key work before gaming',
          'Take movement breaks',
          'Stop before bedtime',
          'Keep meals screen-free',
          'Protect my privacy online',
          'Make time for offline hobbies too',
        ],
        icon: Icons.sports_esports_rounded,
      ),
      'Alcohol Safety' => const _LearnLaneConfig(
        theme: 'Alcohol Safety',
        displayTitle: 'Alcohol Safety',
        displaySubtitle:
            'A guided lane for safer choices, peer pressure, and fast support if something feels wrong.',
        rewardTitle: 'Safe Choice Badge',
        rewardSummary:
            'Finish this lane and you unlock your safe-choice badge.',
        practiceTitle: 'Save my safe-choice plan',
        practiceSubtitle:
            'Pick the responses and trusted-help steps you want to remember.',
        practiceCta: 'Save safe-choice plan',
        practiceOptions: [
          'Say no clearly',
          'Leave if the situation feels off',
          'Call or message a trusted adult',
          'Stay with safe friends',
          'Do not accept unknown drinks',
          'Put safety before fitting in',
        ],
        icon: Icons.no_drinks_rounded,
      ),
      _ => null,
    };
  }
  if (ageBand == '15_18' || ageBand == '18_plus') {
    return switch (theme) {
      'Sleep' => const _LearnLaneConfig(
        theme: 'Sleep',
        displayTitle: 'Sleep and Recovery',
        displaySubtitle:
            'A guided lane for sleep protection, late-night habits, and better recovery.',
        rewardTitle: 'Recovery Builder',
        rewardSummary:
            'Finish this lane and you unlock your recovery-builder badge.',
        practiceTitle: 'Build my recovery routine',
        practiceSubtitle:
            'Save the habits that help rest support mood, focus, and performance.',
        practiceCta: 'Save recovery routine',
        practiceOptions: [
          'Protect a steadier bedtime',
          'Reduce late-night scrolling',
          'Plan study earlier when I can',
          'Keep devices out of bed',
          'Use one reliable wind-down routine',
          'Treat sleep like part of performance',
        ],
        icon: Icons.bedtime_rounded,
      ),
      'Stress' => const _LearnLaneConfig(
        theme: 'Stress',
        displayTitle: 'Stress Under Pressure',
        displaySubtitle:
            'A guided lane for workload, pressure, and getting support before things pile up.',
        rewardTitle: 'Pressure Plan Badge',
        rewardSummary:
            'Finish this lane and you unlock your pressure-plan badge.',
        practiceTitle: 'Build my pressure plan',
        practiceSubtitle:
            'Choose the habits that help you stay steadier during heavier weeks.',
        practiceCta: 'Save pressure plan',
        practiceOptions: [
          'Break one large task down first',
          'Protect a short reset between tasks',
          'Ask for clarity sooner',
          'Lower the pressure for perfect output',
          'Talk to one trusted person',
          'Use a smaller next step when stuck',
        ],
        icon: Icons.self_improvement_rounded,
      ),
      'Bullying' => const _LearnLaneConfig(
        theme: 'Bullying',
        displayTitle: 'Bullying and Boundaries',
        displaySubtitle:
            'A guided lane for repeated harm, clear boundaries, and practical escalation.',
        rewardTitle: 'Boundary Strength Badge',
        rewardSummary:
            'Finish this lane and you unlock your boundary-strength badge.',
        practiceTitle: 'Build my boundary plan',
        practiceSubtitle:
            'Save the moves that help you stay safe and respond clearly.',
        practiceCta: 'Save boundary plan',
        practiceOptions: [
          'Name the pattern clearly',
          'Keep evidence if it is online',
          'Loop in trusted adults sooner',
          'Do not normalize repeated harm',
          'Check in on others safely',
          'Protect distance from unsafe people',
        ],
        icon: Icons.shield_rounded,
      ),
      'Healthy Gaming' => const _LearnLaneConfig(
        theme: 'Healthy Gaming',
        displayTitle: 'Healthy Gaming',
        displaySubtitle:
            'A guided lane for keeping gaming aligned with goals, relationships, and sleep.',
        rewardTitle: 'Digital Balance Badge',
        rewardSummary:
            'Finish this lane and you unlock your digital-balance badge.',
        practiceTitle: 'Build my gaming-balance plan',
        practiceSubtitle:
            'Choose the guardrails that keep gaming enjoyable and in proportion.',
        practiceCta: 'Save gaming-balance plan',
        practiceOptions: [
          'Set a realistic stop point',
          'Protect sleep even on busy weeks',
          'Finish core responsibilities first',
          'Keep one offline hobby active',
          'Take real breaks, not endless queues',
          'Avoid using gaming as my only coping tool',
        ],
        icon: Icons.sports_esports_rounded,
      ),
      'Alcohol Safety' => const _LearnLaneConfig(
        theme: 'Alcohol Safety',
        displayTitle: 'Alcohol Safety',
        displaySubtitle:
            'A guided lane for peer pressure, independence, and getting out of risky situations safely.',
        rewardTitle: 'Safe Decisions Badge',
        rewardSummary:
            'Finish this lane and you unlock your safe-decisions badge.',
        practiceTitle: 'Build my safe-decisions plan',
        practiceSubtitle:
            'Save the lines, exit steps, and support moves you want ready beforehand.',
        practiceCta: 'Save safe-decisions plan',
        practiceOptions: [
          'Use a simple refusal line',
          'Plan a safe way home',
          'Do not ride with someone impaired',
          'Tell someone if a situation turns unsafe',
          'Stay close to trusted people',
          'Choose safety over social pressure',
        ],
        icon: Icons.no_drinks_rounded,
      ),
      _ => null,
    };
  }
  return null;
}

class _StructuredLearnLaneView extends StatelessWidget {
  const _StructuredLearnLaneView({
    required this.palette,
    required this.lane,
    required this.data,
    required this.onBack,
    required this.onOpenModule,
    required this.onOpenContent,
    required this.onOpenPractice,
  });

  final PrototypePalette palette;
  final _LearnLaneConfig lane;
  final _StudentLearnHubData data;
  final VoidCallback onBack;
  final ValueChanged<StudentModuleSummary> onOpenModule;
  final ValueChanged<MobileContentSummary> onOpenContent;
  final VoidCallback onOpenPractice;

  @override
  Widget build(BuildContext context) {
    final modules = [...data.modules]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final quickGuides = data.contentFeed
        .where(
          (content) =>
              !modules.any((module) => module.contentItemId == content.id),
        )
        .toList();
    final completionAverage = modules.isEmpty
        ? 0.0
        : modules
                  .map((module) => module.completionPercent)
                  .reduce((a, b) => a + b) /
              modules.length;
    final completedCount = modules
        .where((module) => module.completionPercent >= 100)
        .length;
    final rewardUnlocked = modules.isNotEmpty && completionAverage >= 100;
    final savedPractice = data.practiceSelections;

    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const Spacer(),
            ThemeModeToggle(palette: palette),
          ],
        ),
        HeroHeader(
          palette: palette,
          kicker: 'Learning lane',
          title: lane.displayTitle,
          subtitle: lane.displaySubtitle,
          actions: [
            Pill(icon: lane.icon, label: lane.theme),
            Pill(
              icon: rewardUnlocked
                  ? Icons.verified_rounded
                  : Icons.workspace_premium_rounded,
              label: rewardUnlocked ? 'Badge unlocked' : lane.rewardTitle,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _LearnStatCard(
                palette: palette,
                title: 'Path progress',
                value: '${completionAverage.toStringAsFixed(0)}%',
                subtitle: '$completedCount/${modules.length} modules complete',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _LearnStatCard(
                palette: palette,
                title: 'Practice saved',
                value: '${savedPractice.length}',
                subtitle: savedPractice.isEmpty
                    ? 'No plan saved yet'
                    : 'Tools in your saved plan',
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
                title: 'Your path',
                subtitle: 'Move through the lane step by step.',
              ),
              if (modules.isEmpty)
                const Text('No modules are available for this topic right now.')
              else
                ...modules.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderedPathCard(
                      palette: palette,
                      position: entry.key + 1,
                      total: modules.length,
                      module: entry.value,
                      onTap: () => onOpenModule(entry.value),
                    ),
                  ),
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
              SectionTitle(
                title: lane.practiceTitle,
                subtitle: lane.practiceSubtitle,
              ),
              if (savedPractice.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: savedPractice
                      .map(
                        (item) =>
                            Pill(icon: Icons.check_circle_rounded, label: item),
                      )
                      .toList(),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                savedPractice.isEmpty
                    ? 'Save a few ideas you want to remember and try.'
                    : 'These are the ideas you chose to keep in your plan.',
              ),
              const SizedBox(height: 14),
              AnimatedPrimaryButton(
                label: savedPractice.isEmpty
                    ? lane.practiceCta
                    : 'Edit saved practice',
                icon: Icons.edit_note_rounded,
                onPressed: onOpenPractice,
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
                title: 'Quick support cards',
                subtitle: 'Short extras for quick support.',
              ),
              if (quickGuides.isEmpty)
                const Text(
                  'No quick support cards are available for this topic right now.',
                )
              else
                ...quickGuides.map(
                  (content) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ContentFeatureCard(
                      palette: palette,
                      content: content,
                      onTap: () => onOpenContent(content),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _LaneRewardCard(
          palette: palette,
          lane: lane,
          rewardUnlocked: rewardUnlocked,
        ),
      ],
    );
  }
}

class _OrderedPathCard extends StatelessWidget {
  const _OrderedPathCard({
    required this.palette,
    required this.position,
    required this.total,
    required this.module,
    required this.onTap,
  });

  final PrototypePalette palette;
  final int position;
  final int total;
  final StudentModuleSummary module;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '$position',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: palette.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  module.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  module.completionPercent > 0
                      ? 'Step $position of $total • ${module.completionPercent.toStringAsFixed(0)}% complete'
                      : 'Step $position of $total • not started yet',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (module.completionPercent / 100).clamp(0, 1),
                    minHeight: 8,
                    backgroundColor: palette.primary.withValues(alpha: .10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.chevron_right_rounded, color: palette.muted),
        ],
      ),
    );
  }
}

class _LaneRewardCard extends StatelessWidget {
  const _LaneRewardCard({
    required this.palette,
    required this.lane,
    required this.rewardUnlocked,
  });

  final PrototypePalette palette;
  final _LearnLaneConfig lane;
  final bool rewardUnlocked;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(title: lane.rewardTitle, subtitle: lane.rewardSummary),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: rewardUnlocked
                      ? palette.secondary.withValues(alpha: .18)
                      : palette.muted.withValues(alpha: .16),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  rewardUnlocked
                      ? Icons.workspace_premium_rounded
                      : Icons.lock_outline_rounded,
                  color: rewardUnlocked ? palette.secondary : palette.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  rewardUnlocked
                      ? 'You unlocked this badge by finishing the full path.'
                      : 'Complete the full path to unlock this badge.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LanePracticeScreen extends StatefulWidget {
  const _LanePracticeScreen({required this.lane, required this.storageKey});

  final _LearnLaneConfig lane;
  final String storageKey;

  @override
  State<_LanePracticeScreen> createState() => _LanePracticeScreenState();
}

class _LanePracticeScreenState extends State<_LanePracticeScreen> {
  static const _maxCustomItems = 3;
  static const _maxSelectedItems = 8;

  final Set<String> _selected = <String>{};
  final List<String> _customOptions = <String>[];
  final List<String> _selectedOrder = <String>[];
  final TextEditingController _customPointController = TextEditingController();
  bool _loaded = false;
  bool _saving = false;
  bool _showCustomComposer = false;

  String get _customStorageKey => '${widget.storageKey}.custom';
  String get _orderStorageKey => '${widget.storageKey}.order';

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _customPointController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(widget.storageKey) ?? const [];
    final storedCustom =
        preferences.getStringList(_customStorageKey) ?? const [];
    final storedOrder = preferences.getStringList(_orderStorageKey) ?? stored;
    if (!mounted) {
      return;
    }
    setState(() {
      _customOptions
        ..clear()
        ..addAll(storedCustom);
      _selected
        ..clear()
        ..addAll(stored);
      _selectedOrder
        ..clear()
        ..addAll(storedOrder.where(_selected.contains));
      for (final item in stored) {
        if (!_selectedOrder.contains(item)) {
          _selectedOrder.add(item);
        }
      }
      _loaded = true;
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(widget.storageKey, _selectedOrder);
    await preferences.setStringList(_customStorageKey, _customOptions);
    await preferences.setStringList(_orderStorageKey, _selectedOrder);
    if (!mounted) {
      return;
    }
    setState(() => _saving = false);
    Navigator.of(context).pop(_selected.toList());
  }

  void _toggleCustomComposer() {
    if (_customOptions.length >= _maxCustomItems) {
      _showMessage('You can add up to $_maxCustomItems custom points.');
      return;
    }
    setState(() {
      _showCustomComposer = !_showCustomComposer;
      if (!_showCustomComposer) {
        _customPointController.clear();
      }
    });
  }

  void _addCustomPoint() {
    final value = _customPointController.text.trim();
    if (value.isEmpty) {
      return;
    }
    final existingOptions = {
      ...widget.lane.practiceOptions,
      ..._customOptions,
    }.map((item) => item.toLowerCase()).toSet();
    if (existingOptions.contains(value.toLowerCase())) {
      _showMessage('That point already exists in this plan.');
      return;
    }
    if (_selected.length >= _maxSelectedItems) {
      _showMessage('You can save up to $_maxSelectedItems checklist points.');
      return;
    }
    setState(() {
      _customOptions.add(value);
      _selected.add(value);
      _selectedOrder.add(value);
      _showCustomComposer = false;
    });
    _customPointController.clear();
  }

  void _toggleOption(String option, bool enabled) {
    if (enabled &&
        !_selected.contains(option) &&
        _selected.length >= _maxSelectedItems) {
      _showMessage('You can save up to $_maxSelectedItems checklist points.');
      return;
    }
    setState(() {
      if (enabled) {
        _selected.add(option);
        if (!_selectedOrder.contains(option)) {
          _selectedOrder.add(option);
        }
      } else {
        _selected.remove(option);
        _selectedOrder.remove(option);
      }
    });
  }

  void _removeCustomOption(String option) {
    setState(() {
      _customOptions.remove(option);
      _selected.remove(option);
      _selectedOrder.remove(option);
    });
  }

  void _reorderSelected(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedOrder.removeAt(oldIndex);
      _selectedOrder.insert(newIndex, item);
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = <String>[
      ...widget.lane.practiceOptions,
      ..._customOptions,
    ];
    final orderedSelected = _selectedOrder.where(_selected.contains).toList();
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: !_loaded
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
                    kicker: 'Practice',
                    title: widget.lane.practiceTitle,
                    subtitle: widget.lane.practiceSubtitle,
                    actions: [
                      Pill(icon: widget.lane.icon, label: widget.lane.theme),
                      Pill(
                        icon: Icons.checklist_rounded,
                        label: '${_selected.length} saved',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (orderedSelected.isNotEmpty) ...[
                          const SectionTitle(
                            title: 'Your saved order',
                            subtitle:
                                'Press and drag to rearrange the order that feels right for you.',
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            buildDefaultDragHandles: false,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orderedSelected.length,
                            onReorderItem: _reorderSelected,
                            itemBuilder: (context, index) {
                              final option = orderedSelected[index];
                              return Padding(
                                key: ValueKey('selected-$option'),
                                padding: const EdgeInsets.only(bottom: 8),
                                child: GlassPanel(
                                  palette: palette,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    children: [
                                      ReorderableDragStartListener(
                                        index: index,
                                        child: Icon(
                                          Icons.drag_indicator_rounded,
                                          color: palette.muted,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(child: Text(option)),
                                      IconButton(
                                        tooltip: 'Remove',
                                        onPressed: () =>
                                            _toggleOption(option, false),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 18),
                        ],
                        Row(
                          children: [
                            const Expanded(
                              child: SectionTitle(
                                title: 'Choose what fits you',
                                subtitle:
                                    'Choose the ideas you want to keep in your plan.',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: _toggleCustomComposer,
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Add point'),
                            ),
                          ],
                        ),
                        Text(
                          '${_selected.length}/$_maxSelectedItems saved • ${_customOptions.length}/$_maxCustomItems custom',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: palette.muted),
                        ),
                        if (_showCustomComposer) ...[
                          const SizedBox(height: 12),
                          GlassPanel(
                            palette: palette,
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _customPointController,
                                  autofocus: true,
                                  maxLength: 60,
                                  decoration: const InputDecoration(
                                    hintText:
                                        'Type a routine step or personal reminder',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _showCustomComposer = false;
                                          });
                                          _customPointController.clear();
                                        },
                                        child: const Text('Cancel'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FilledButton(
                                        onPressed: _addCustomPoint,
                                        child: const Text('Add to checklist'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        ...allOptions.map((option) {
                          final isCustom = _customOptions.contains(option);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: GlassPanel(
                              palette: palette,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: _selected.contains(option),
                                    onChanged: (value) =>
                                        _toggleOption(option, value ?? false),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(option),
                                        if (isCustom)
                                          Text(
                                            'Added by you',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: palette.muted,
                                                ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (isCustom)
                                    IconButton(
                                      tooltip: 'Remove custom point',
                                      onPressed: () =>
                                          _removeCustomOption(option),
                                      icon: const Icon(Icons.close_rounded),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  AnimatedPrimaryButton(
                    label: _saving ? 'Saving...' : widget.lane.practiceCta,
                    icon: Icons.save_rounded,
                    onPressed: _saving ? () {} : () => unawaited(_save()),
                  ),
                ],
              ),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}

String _contentBadgeLabel(MobileContentSummary content) {
  final type = _contentTypeLabel(content.contentType);
  final theme = content.theme?.trim();
  if (theme != null && theme.isNotEmpty) {
    return '$theme • $type';
  }
  return type;
}

String _contentTypeLabel(String contentType) {
  return switch (contentType) {
    'learning_module' => 'Module',
    'learning_card' => 'Quick card',
    'reflection_prompt' => 'Reflection',
    'checklist' => 'Checklist',
    'article' => 'Article',
    _ => contentType.replaceAll('_', ' '),
  };
}

IconData _contentIcon(String contentType) {
  return switch (contentType) {
    'checklist' => Icons.checklist_rounded,
    'reflection_prompt' => Icons.psychology_alt_rounded,
    'learning_card' => Icons.flash_on_rounded,
    'article' => Icons.article_rounded,
    _ => Icons.menu_book_rounded,
  };
}

StudentModuleSummary? _findModuleById(
  List<StudentModuleSummary> modules,
  String id,
) {
  for (final module in modules) {
    if (module.id == id) {
      return module;
    }
  }
  return null;
}

MobileContentSummary? _findContentById(
  List<MobileContentSummary> contentItems,
  String id,
) {
  for (final content in contentItems) {
    if (content.id == id) {
      return content;
    }
  }
  return null;
}
