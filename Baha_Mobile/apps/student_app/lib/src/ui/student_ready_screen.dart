import 'dart:async';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_design_system/baha_design_system.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../app_environment.dart';
import 'student_learn_screen.dart';

class StudentReadyScreen extends StatefulWidget {
  const StudentReadyScreen({
    required this.apiClient,
    required this.identity,
    required this.environment,
    required this.actor,
    required this.onboardingState,
    required this.onRefresh,
    required this.onClearIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final StudentAppEnvironment environment;
  final MobileActor? actor;
  final AuthOnboardingState? onboardingState;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onClearIdentity;

  @override
  State<StudentReadyScreen> createState() => _StudentReadyScreenState();
}

class _StudentReadyScreenState extends State<StudentReadyScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      StudentDashboardScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        actor: widget.actor,
        onboardingState: widget.onboardingState,
        environment: widget.environment,
        onClearIdentity: widget.onClearIdentity,
      ),
      StudentCheckinsScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
      StudentLearnScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Check-In',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Learn',
          ),
        ],
      ),
    );
  }
}

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({
    required this.apiClient,
    required this.identity,
    required this.actor,
    required this.onboardingState,
    required this.environment,
    required this.onClearIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileActor? actor;
  final AuthOnboardingState? onboardingState;
  final StudentAppEnvironment environment;
  final Future<void> Function() onClearIdentity;

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
  late Future<_StudentDashboardData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentDashboardData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.getStudentWeeklySummary(identity: widget.identity),
      widget.apiClient.listStudentCheckins(identity: widget.identity, limit: 5),
    ]);
    return _StudentDashboardData(
      summary: results[0] as StudentWeeklySummary,
      checkins: results[1] as List<StudentCheckinSummary>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF6F0E6), Color(0xFFE4EEF2)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StudentDashboardData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text('Student dashboard', style: theme.headlineMedium),
                    const SizedBox(height: 16),
                    BahaSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Could not load dashboard data',
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
              final actor = widget.actor;
              final onboardingState = widget.onboardingState;
              final headline =
                  data.summary.summary['headline']?.toString() ??
                  'Summary unavailable';
              final moodTrend =
                  data.summary.summary['mood_trend']?.toString() ?? '-';
              final sleepTrend =
                  data.summary.summary['sleep_trend']?.toString() ?? '-';
              final moduleProgress =
                  data.summary.summary['module_progress']?.toString() ?? '-';
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Hi ${actor?.displayName ?? onboardingState?.displayName ?? 'there'}',
                    style: theme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This is the first real student feature slice running on the BAHA backend.',
                    style: theme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('This week', style: theme.titleLarge),
                        const SizedBox(height: 12),
                        Text(headline, style: theme.bodyLarge),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _MetricChip(label: 'Mood', value: moodTrend),
                            _MetricChip(label: 'Sleep', value: sleepTrend),
                            _MetricChip(
                              label: 'Modules',
                              value: '$moduleProgress%',
                            ),
                            _MetricChip(
                              label: 'Check-ins',
                              value:
                                  '${data.summary.sourceWindow['checkins'] ?? 0}',
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Week ${_formatDate(data.summary.weekStart)} to ${_formatDate(data.summary.weekEnd)}',
                          style: theme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Account and runtime', style: theme.titleLarge),
                        const SizedBox(height: 12),
                        _InfoRow(
                          label: 'Age cohort',
                          value: actor?.ageCohort ?? '-',
                        ),
                        _InfoRow(
                          label: 'Role',
                          value: actor?.primaryRole ?? 'student',
                        ),
                        _InfoRow(
                          label: 'API URL',
                          value: widget.environment.apiBaseUrl,
                        ),
                        _InfoRow(
                          label: 'Privacy tier',
                          value: data.summary.privacyTierApplied,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent check-ins', style: theme.titleLarge),
                        const SizedBox(height: 12),
                        if (data.checkins.isEmpty)
                          Text(
                            'No submitted check-ins yet. Use the Check-In tab to start the first one.',
                            style: theme.bodyLarge,
                          )
                        else
                          ...data.checkins.map(
                            (checkin) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _CheckinSummaryTile(summary: checkin),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton(
                    onPressed: widget.onClearIdentity,
                    child: const Text('Switch development identity'),
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

class StudentCheckinsScreen extends StatefulWidget {
  const StudentCheckinsScreen({
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<StudentCheckinsScreen> createState() => _StudentCheckinsScreenState();
}

class _StudentCheckinsScreenState extends State<StudentCheckinsScreen> {
  late Future<_StudentCheckinHubData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentCheckinHubData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.listStudentCheckinTemplates(identity: widget.identity),
      widget.apiClient.listStudentCheckins(
        identity: widget.identity,
        limit: 10,
      ),
    ]);
    return _StudentCheckinHubData(
      templates: results[0] as List<MobileCheckinTemplateSummary>,
      history: results[1] as List<StudentCheckinSummary>,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openTemplate(MobileCheckinTemplateSummary template) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudentCheckinFormScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          templateId: template.id,
        ),
      ),
    );
    unawaited(_refresh());
  }

  Future<void> _openHistory(StudentCheckinSummary summary) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudentCheckinDetailScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          responseSetId: summary.id,
          titleOverride: summary.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In'),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_StudentCheckinHubData>(
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
                          'Could not load check-ins',
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
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Available check-ins', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      ...data.templates.map(
                        (template) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _openTemplate(template),
                            borderRadius: BorderRadius.circular(16),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                children: [
                                  const Icon(Icons.favorite_border),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          template.title,
                                          style: theme.bodyLarge,
                                        ),
                                        Text(
                                          '${template.cadence} • ${template.questionCount} questions',
                                          style: theme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                  ),
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
                      Text('Submitted history', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      if (data.history.isEmpty)
                        Text(
                          'No check-ins submitted yet.',
                          style: theme.bodyLarge,
                        )
                      else
                        ...data.history.map(
                          (summary) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              onTap: () => _openHistory(summary),
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Row(
                                  children: [
                                    const Icon(Icons.history),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _CheckinSummaryTile(
                                        summary: summary,
                                      ),
                                    ),
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
              ],
            );
          },
        ),
      ),
    );
  }
}

class StudentCheckinFormScreen extends StatefulWidget {
  const StudentCheckinFormScreen({
    required this.apiClient,
    required this.identity,
    required this.templateId,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String templateId;

  @override
  State<StudentCheckinFormScreen> createState() =>
      _StudentCheckinFormScreenState();
}

class _StudentCheckinFormScreenState extends State<StudentCheckinFormScreen> {
  late Future<MobileCheckinTemplateDetail> _future;
  final Map<String, double> _scaleAnswers = <String, double>{};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getStudentCheckinTemplateDetail(
      identity: widget.identity,
      templateId: widget.templateId,
    );
  }

  Future<void> _submit(MobileCheckinTemplateDetail detail) async {
    setState(() => _submitting = true);
    try {
      final answers = detail.questions
          .where((question) => _scaleAnswers.containsKey(question.id))
          .map(
            (question) => CheckinAnswerInput(
              questionId: question.id,
              numericValue: _scaleAnswers[question.id],
            ),
          )
          .toList();
      if (answers.isEmpty) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Answer at least one question before submitting.'),
          ),
        );
        return;
      }
      final submission = await widget.apiClient.submitStudentCheckin(
        identity: widget.identity,
        request: CheckinSubmissionRequest(
          templateId: detail.id,
          answers: answers,
        ),
      );
      if (!mounted) {
        return;
      }
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => StudentCheckinDetailScreen(
            apiClient: widget.apiClient,
            identity: widget.identity,
            responseSetId: submission.id,
            titleOverride: submission.title,
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
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Check-In'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<MobileCheckinTemplateDetail>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Could not load form', style: theme.titleLarge),
                    const SizedBox(height: 12),
                    Text('${snapshot.error}', style: theme.bodyLarge),
                  ],
                ),
              ),
            );
          }
          final detail = snapshot.data!;
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
                      '${detail.cadence} check-in • ${detail.questions.length} questions',
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...detail.questions.map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(question.prompt, style: theme.bodyLarge),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: question.scaleValues.map((value) {
                            final selected =
                                _scaleAnswers[question.id] == value.toDouble();
                            return ChoiceChip(
                              label: Text('$value'),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _scaleAnswers[question.id] = value.toDouble();
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: _submitting ? null : () => _submit(detail),
                child: Text(_submitting ? 'Submitting...' : 'Submit check-in'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StudentCheckinDetailScreen extends StatelessWidget {
  const StudentCheckinDetailScreen({
    required this.apiClient,
    required this.identity,
    required this.responseSetId,
    required this.titleOverride,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String responseSetId;
  final String titleOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-In Detail'),
        backgroundColor: Colors.transparent,
      ),
      body: FutureBuilder<StudentCheckinDetail>(
        future: apiClient.getStudentCheckinDetail(
          identity: identity,
          responseSetId: responseSetId,
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
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titleOverride, style: theme.titleLarge),
                    const SizedBox(height: 8),
                    Text(
                      'Submitted ${detail.submittedAt == null ? 'recently' : _formatDateTime(detail.submittedAt!)}',
                      style: theme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...detail.answers.map(
                (answer) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(answer.prompt, style: theme.bodyLarge),
                        const SizedBox(height: 10),
                        Text(_answerLabel(answer), style: theme.titleLarge),
                      ],
                    ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value, style: theme.bodyLarge)),
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF1F4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: theme.bodyMedium),
          const SizedBox(height: 4),
          Text(value, style: theme.titleLarge),
        ],
      ),
    );
  }
}

class _CheckinSummaryTile extends StatelessWidget {
  const _CheckinSummaryTile({required this.summary});

  final StudentCheckinSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(summary.title, style: theme.bodyLarge),
        const SizedBox(height: 4),
        Text(
          '${summary.responseCount} answers • ${summary.submittedAt == null ? 'pending' : _formatDateTime(summary.submittedAt!)}',
          style: theme.bodyMedium,
        ),
      ],
    );
  }
}

class _StudentDashboardData {
  const _StudentDashboardData({required this.summary, required this.checkins});

  final StudentWeeklySummary summary;
  final List<StudentCheckinSummary> checkins;
}

class _StudentCheckinHubData {
  const _StudentCheckinHubData({
    required this.templates,
    required this.history,
  });

  final List<MobileCheckinTemplateSummary> templates;
  final List<StudentCheckinSummary> history;
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}

String _answerLabel(StudentCheckinAnswer answer) {
  if (answer.numericValue != null) {
    return answer.numericValue!.toStringAsFixed(
      answer.numericValue! % 1 == 0 ? 0 : 1,
    );
  }
  if (answer.textValue != null && answer.textValue!.isNotEmpty) {
    return answer.textValue!;
  }
  if (answer.booleanValue != null) {
    return answer.booleanValue! ? 'Yes' : 'No';
  }
  if (answer.selectedOptions.isNotEmpty) {
    return answer.selectedOptions.join(', ');
  }
  return 'No answer captured';
}
