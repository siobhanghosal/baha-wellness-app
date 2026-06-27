import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_content_renderer/baha_content_renderer.dart';
import 'package:baha_design_system/baha_design_system.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

class StudentLearnScreen extends StatefulWidget {
  const StudentLearnScreen({
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<StudentLearnScreen> createState() => _StudentLearnScreenState();
}

class _StudentLearnScreenState extends State<StudentLearnScreen> {
  late Future<_StudentLearnHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentLearnHubData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.listMobileContentFeed(identity: widget.identity),
      widget.apiClient.listStudentModules(identity: widget.identity),
    ]);
    return _StudentLearnHubData(
      contentFeed: results[0] as List<MobileContentSummary>,
      modules: results[1] as List<StudentModuleSummary>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openModule(StudentModuleSummary module) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => StudentModuleDetailScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          module: module,
        ),
      ),
    );
    if (updated == true) {
      await _refresh();
    }
  }

  Future<void> _openContent(MobileContentSummary content) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => StudentContentDetailScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          contentItemId: content.id,
          titleOverride: content.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_StudentLearnHubData>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Could not load learning content',
                          style: theme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text('${snapshot.error}', style: theme.bodyLarge),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _refresh,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            final data = snapshot.data!;
            final moduleByContentId = <String, StudentModuleSummary>{
              for (final module in data.modules) module.contentItemId: module,
            };

            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recommended modules', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      if (data.modules.isEmpty)
                        Text(
                          'No student modules are available yet.',
                          style: theme.bodyLarge,
                        )
                      else
                        ...data.modules.map(
                          (module) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _openModule(module),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.auto_stories_outlined),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _ModuleSummaryTile(module: module),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Discover', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      if (data.contentFeed.isEmpty)
                        Text(
                          'No discovery content is published yet.',
                          style: theme.bodyLarge,
                        )
                      else
                        ...data.contentFeed.map((content) {
                          final linkedModule = moduleByContentId[content.id];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: linkedModule != null
                                  ? () => _openModule(linkedModule)
                                  : () => _openContent(content),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(content.title, style: theme.bodyLarge),
                                    const SizedBox(height: 6),
                                    Text(
                                      [
                                        if (content.theme != null &&
                                            content.theme!.isNotEmpty)
                                          content.theme!,
                                        content.contentType,
                                      ].join(' • '),
                                      style: theme.bodyMedium,
                                    ),
                                    if ((content.summary ?? '').isNotEmpty) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        content.summary!,
                                        style: theme.bodyLarge,
                                      ),
                                    ],
                                    if (linkedModule != null) ...[
                                      const SizedBox(height: 10),
                                      Text(
                                        'Progress: ${linkedModule.completionPercent.toStringAsFixed(0)}%',
                                        style: theme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
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
          lastActivityAt: response.lastActivityAt,
          moduleProgressId: response.id,
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
    final theme = Theme.of(context).textTheme;
    return PopScope<bool>(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          return;
        }
        Navigator.of(context).pop(_didUpdate);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Module'),
          backgroundColor: Colors.transparent,
        ),
        body: FutureBuilder<MobileContentDetail>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: BahaSurface(
                  child: Text('${snapshot.error}', style: theme.bodyLarge),
                ),
              );
            }
            final detail = snapshot.data!;
            final textBlocks = detail.blocks
                .where((block) => block.type == 'text')
                .toList();
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(detail.title, style: theme.titleLarge),
                      const SizedBox(height: 8),
                      Text(
                        [
                          if (detail.theme != null && detail.theme!.isNotEmpty)
                            detail.theme!,
                          if (_module.estimatedMinutes != null)
                            '${_module.estimatedMinutes} min',
                          'Progress ${_module.completionPercent.toStringAsFixed(0)}%',
                        ].join(' • '),
                        style: theme.bodyMedium,
                      ),
                      if ((detail.summary ?? '').isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(detail.summary!, style: theme.bodyLarge),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (textBlocks.isEmpty && (detail.plainText ?? '').isNotEmpty)
                  PlainTextBlock(
                    title: 'Module content',
                    body: detail.plainText!,
                  )
                else
                  ...textBlocks.map(
                    (block) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: PlainTextBlock(
                        title: detail.theme ?? 'Module content',
                        body: block.value ?? '',
                      ),
                    ),
                  ),
                const SizedBox(height: 18),
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Progress actions', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        'Use these actions to prove the mobile app can write learning progress back to the real backend.',
                        style: theme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _saveProgress(
                                status: 'in_progress',
                                completionPercent:
                                    _module.completionPercent < 50
                                    ? 50
                                    : _module.completionPercent,
                                currentSectionOrdinal: 1,
                                currentStepOrdinal: 1,
                              ),
                        child: const Text('Save In Progress'),
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
                        child: Text(_saving ? 'Saving...' : 'Mark Complete'),
                      ),
                      if (_module.lastActivityAt != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Last activity ${_formatDateTime(_module.lastActivityAt!)}',
                          style: theme.bodyMedium,
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
    );
  }
}

class StudentContentDetailScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn Detail'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<MobileContentDetail>(
        future: apiClient.getMobileContentDetail(
          identity: identity,
          contentItemId: contentItemId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: BahaSurface(
                child: Text('${snapshot.error}', style: theme.bodyLarge),
              ),
            );
          }
          final detail = snapshot.data!;
          final textBlocks = detail.blocks
              .where((block) => block.type == 'text')
              .toList();
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleOverride, style: theme.titleLarge),
                    if ((detail.summary ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(detail.summary!, style: theme.bodyLarge),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (textBlocks.isEmpty && (detail.plainText ?? '').isNotEmpty)
                PlainTextBlock(
                  title: detail.theme ?? 'Content',
                  body: detail.plainText!,
                )
              else
                ...textBlocks.map(
                  (block) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PlainTextBlock(
                      title: detail.theme ?? 'Content',
                      body: block.value ?? '',
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ModuleSummaryTile extends StatelessWidget {
  const _ModuleSummaryTile({required this.module});

  final StudentModuleSummary module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(module.title, style: theme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          [
            module.theme,
            if (module.estimatedMinutes != null)
              '${module.estimatedMinutes} min',
            '${module.completionPercent.toStringAsFixed(0)}%',
          ].join(' • '),
          style: theme.bodyMedium,
        ),
      ],
    );
  }
}

class _StudentLearnHubData {
  const _StudentLearnHubData({
    required this.contentFeed,
    required this.modules,
  });

  final List<MobileContentSummary> contentFeed;
  final List<StudentModuleSummary> modules;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}
