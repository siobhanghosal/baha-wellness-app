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

              final data = snapshot.data!;
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
              final title =
                  widget.screenTitle ??
                  widget.initialTheme ??
                  'Explore learning that feels made for you.';
              final subtitle =
                  widget.screenSubtitle ??
                  (widget.initialTheme == null
                      ? 'Published modules and guides are now organized into a real course hub inside the reference student UI.'
                      : 'This lane is filtered to $title so the card you choose opens matching learning content instead of a generic list.');
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
                                'Themes help the learning library feel intentional, even as the demo corpus grows.',
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
                                ? 'No student modules are available yet.'
                                : 'No modules are published for this theme yet.',
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
                            subtitle:
                                'A simple resume lane stored locally on the device.',
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
                              'Shorter backend-published items for fast wins, resets, and reflection.',
                        ),
                        if (quickGuides.isEmpty)
                          Text(
                            widget.initialTheme == null
                                ? 'No quick guides are published yet. Student modules will continue to power the core Learn experience.'
                                : 'No quick guides are published for this theme yet.',
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Progress saved: ${response.completionPercent.toStringAsFixed(0)}%',
          ),
        ),
      );
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
                final nextSectionCompletion = hasStructuredSections
                    ? (nextSection / _module.totalSections) * 100
                    : (_module.completionPercent == 0
                          ? 50.0
                          : _module.completionPercent);
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
                            subtitle:
                                'A guided course card built from live backend content.',
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
                                'The content below is rendered from backend blocks instead of plain raw text.',
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
                                'Progress now follows the module structure instead of arbitrary demo percentages.',
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton(
                            onPressed: _saving
                                ? null
                                : () => _saveProgress(
                                    status: 'in_progress',
                                    completionPercent: nextSectionCompletion,
                                    currentSectionOrdinal: nextSection,
                                    currentStepOrdinal: _module.totalSteps > 0
                                        ? 1
                                        : null,
                                  ),
                            child: Text(
                              _module.completionPercent == 0
                                  ? 'Start Module'
                                  : hasStructuredSections &&
                                        completedSections <
                                            _module.totalSections
                                  ? 'Complete Next Section'
                                  : 'Save In Progress',
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: _saving
                                ? null
                                : () => _saveProgress(
                                    status: 'completed',
                                    completionPercent: 100,
                                    currentSectionOrdinal: 1,
                                    currentStepOrdinal: 1,
                                  ),
                            child: Text(
                              _saving ? 'Saving...' : 'Mark Complete',
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
  });

  final List<MobileContentSummary> contentFeed;
  final List<StudentModuleSummary> modules;
  final List<String> recentModuleIds;
  final List<String> recentContentIds;
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
