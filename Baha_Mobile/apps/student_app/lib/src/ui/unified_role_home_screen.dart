import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../app_environment.dart';
import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import 'student_ready_screen.dart';

class UnifiedRoleHomeScreen extends StatelessWidget {
  const UnifiedRoleHomeScreen({
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
  Widget build(BuildContext context) {
    final resolvedActor = actor;
    if (resolvedActor == null) {
      return _RolePlaceholderScreen(
        title: 'Session is ready but no actor could be loaded',
        subtitle: 'Retry the session or switch identity.',
        onClearIdentity: onClearIdentity,
      );
    }
    switch (resolvedActor.primaryRole) {
      case 'student':
        return StudentReadyScreen(
          apiClient: apiClient,
          identity: identity,
          environment: environment,
          actor: resolvedActor,
          onboardingState: onboardingState,
          onRefresh: onRefresh,
          onClearIdentity: onClearIdentity,
        );
      case 'guardian':
        return GuardianReadyScreen(
          apiClient: apiClient,
          identity: identity,
          actor: resolvedActor,
          onboardingState: onboardingState,
          onClearIdentity: onClearIdentity,
        );
      case 'teacher':
      case 'counselor':
        return _RolePlaceholderScreen(
          title: '${resolvedActor.displayName} is signed in',
          subtitle:
              'The unified app structure is now role-based, but the ${resolvedActor.primaryRole} experience is still behind the student slice in implementation.',
          onClearIdentity: onClearIdentity,
        );
      default:
        return _RolePlaceholderScreen(
          title: 'Unsupported role',
          subtitle: 'This identity is not mapped to a supported mobile role.',
          onClearIdentity: onClearIdentity,
        );
    }
  }
}

class GuardianReadyScreen extends StatefulWidget {
  const GuardianReadyScreen({
    required this.apiClient,
    required this.identity,
    required this.actor,
    required this.onboardingState,
    required this.onClearIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileActor actor;
  final AuthOnboardingState? onboardingState;
  final Future<void> Function() onClearIdentity;

  @override
  State<GuardianReadyScreen> createState() => _GuardianReadyScreenState();
}

class _GuardianReadyScreenState extends State<GuardianReadyScreen> {
  final _studentCodeController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  String _relationship = 'Parent';
  bool _loading = true;
  bool _linking = false;
  String? _errorMessage;
  List<MobileLinkedStudentSummary> _students = const [];
  final Map<String, PlatformParticipationConsentStatus>
  _platformConsentByStudent = <String, PlatformParticipationConsentStatus>{};
  final Map<String, ParentSummaryConsentStatus> _summaryConsentByStudent =
      <String, ParentSummaryConsentStatus>{};
  final Set<String> _busyStudentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadGuardianHome();
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadGuardianHome() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final students = await widget.apiClient.listParentStudents(
        identity: widget.identity,
      );
      final platformConsentByStudent =
          <String, PlatformParticipationConsentStatus>{};
      final summaryConsentByStudent = <String, ParentSummaryConsentStatus>{};
      for (final student in students) {
        try {
          platformConsentByStudent[student.studentProfileId] = await widget
              .apiClient
              .getPlatformParticipationConsentStatus(
                identity: widget.identity,
                studentProfileId: student.studentProfileId,
              );
        } catch (_) {}
        try {
          summaryConsentByStudent[student.studentProfileId] = await widget
              .apiClient
              .getParentSummaryConsentStatus(
                identity: widget.identity,
                studentProfileId: student.studentProfileId,
              );
        } catch (_) {}
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _students = students;
        _platformConsentByStudent
          ..clear()
          ..addAll(platformConsentByStudent);
        _summaryConsentByStudent
          ..clear()
          ..addAll(summaryConsentByStudent);
      });
    } on BahaApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _linkStudent() async {
    if (_linking) {
      return;
    }
    final studentCode = _studentCodeController.text.trim();
    final verificationCode = _verificationCodeController.text.trim();
    if (studentCode.isEmpty || verificationCode.isEmpty) {
      _showMessage(
        'Enter both the student ID and the verification code first.',
      );
      return;
    }
    setState(() => _linking = true);
    try {
      await widget.apiClient.linkGuardianStudent(
        identity: widget.identity,
        request: GuardianLinkStudentRequest(
          studentCode: studentCode,
          verificationCode: verificationCode,
          relationshipToStudent: _relationship.toLowerCase(),
        ),
      );
      _studentCodeController.clear();
      _verificationCodeController.clear();
      await _loadGuardianHome();
      if (mounted) {
        _showMessage('Student linked successfully.');
      }
    } on BahaApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('Could not link student: $error');
    } finally {
      if (mounted) {
        setState(() => _linking = false);
      }
    }
  }

  Future<void> _grantPlatformConsent(MobileLinkedStudentSummary student) async {
    await _runStudentAction(student.studentProfileId, () async {
      await widget.apiClient.updatePlatformParticipationConsent(
        identity: widget.identity,
        request: PlatformParticipationConsentRequest(
          studentProfileId: student.studentProfileId,
        ),
      );
      final status = await widget.apiClient
          .getPlatformParticipationConsentStatus(
            identity: widget.identity,
            studentProfileId: student.studentProfileId,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _platformConsentByStudent[student.studentProfileId] = status;
      });
      _showMessage('${student.studentName} can now access the student side.');
    });
  }

  Future<void> _grantSummaryConsent(MobileLinkedStudentSummary student) async {
    await _runStudentAction(student.studentProfileId, () async {
      final status = await widget.apiClient.updateParentSummaryConsent(
        identity: widget.identity,
        request: ParentSummaryConsentRequest(
          studentProfileId: student.studentProfileId,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _summaryConsentByStudent[student.studentProfileId] = status;
      });
      _showMessage('Weekly trend summaries are now enabled.');
    });
  }

  Future<void> _runStudentAction(
    String studentProfileId,
    Future<void> Function() action,
  ) async {
    setState(() => _busyStudentIds.add(studentProfileId));
    try {
      await action();
    } on BahaApiException catch (error) {
      _showMessage(error.message);
    } catch (error) {
      _showMessage('$error');
    } finally {
      if (mounted) {
        setState(() => _busyStudentIds.remove(studentProfileId));
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openStudentSummary(MobileLinkedStudentSummary student) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => GuardianStudentSummaryScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          student: student,
        ),
      ),
    );
    await _loadGuardianHome();
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(AppColorTheme.growth);
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
                  DashboardTopBar(palette: palette),
                  HeroHeader(
                    palette: palette,
                    kicker: 'Parent or guardian',
                    title: _students.isEmpty
                        ? 'Link your child in one short step'
                        : 'Family overview',
                    subtitle: _students.isEmpty
                        ? 'Enter the student ID and verification code from your child’s BAHA app, then approve access and view privacy-safe trends.'
                        : 'This view shows only weekly patterns, watch areas, and alerts. It does not expose individual student entries.',
                    actions: [
                      const Pill(
                        icon: Icons.family_restroom_rounded,
                        label: 'Guardian',
                      ),
                      Pill(
                        icon: Icons.verified_user_rounded,
                        label: '${_students.length} linked',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_errorMessage != null) ...[
                    GlassPanel(palette: palette, child: Text(_errorMessage!)),
                    const SizedBox(height: 18),
                  ],
                  _GuardianLinkPanel(
                    palette: palette,
                    studentCodeController: _studentCodeController,
                    verificationCodeController: _verificationCodeController,
                    relationship: _relationship,
                    linking: _linking,
                    onRelationshipChanged: (value) {
                      setState(() => _relationship = value);
                    },
                    onLink: _linkStudent,
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'How this parent view works',
                          subtitle:
                              'The flow is intentionally simple and privacy-safe.',
                        ),
                        const _GuardianChecklistRow(
                          icon: Icons.link_rounded,
                          title: '1. Link with student ID + verification code',
                          subtitle:
                              'This proves the child initiated the connection.',
                        ),
                        const SizedBox(height: 10),
                        const _GuardianChecklistRow(
                          icon: Icons.approval_rounded,
                          title: '2. Approve access for under-18 students',
                          subtitle:
                              'The student app stays gated until the parent grants participation.',
                        ),
                        const SizedBox(height: 10),
                        const _GuardianChecklistRow(
                          icon: Icons.insights_rounded,
                          title: '3. View summary trends, not private answers',
                          subtitle:
                              'BAHA only shows high-level patterns, alerts, and support nudges here.',
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
                          title: 'Linked students',
                          subtitle:
                              'Approve access, enable summaries, and open the family summary view.',
                        ),
                        if (_students.isEmpty)
                          Text(
                            'No students are linked yet. Ask your child to open BAHA and share their student ID and verification code from the waiting screen.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        else
                          ..._students.map((student) {
                            final platformConsent =
                                _platformConsentByStudent[student
                                    .studentProfileId];
                            final summaryConsent =
                                _summaryConsentByStudent[student
                                    .studentProfileId];
                            final busy = _busyStudentIds.contains(
                              student.studentProfileId,
                            );
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _GuardianStudentCard(
                                palette: palette,
                                student: student,
                                platformStatus:
                                    platformConsent?.status ?? 'pending',
                                summaryStatus:
                                    summaryConsent?.status ?? 'pending',
                                busy: busy,
                                onGrantPlatform: () =>
                                    _grantPlatformConsent(student),
                                onGrantSummary: () =>
                                    _grantSummaryConsent(student),
                                onOpenSummary: () =>
                                    _openStudentSummary(student),
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: _loadGuardianHome,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh guardian view'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: widget.onClearIdentity,
                    icon: const Icon(Icons.switch_account_rounded),
                    label: const Text('Switch account'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GuardianLinkPanel extends StatelessWidget {
  const _GuardianLinkPanel({
    required this.palette,
    required this.studentCodeController,
    required this.verificationCodeController,
    required this.relationship,
    required this.linking,
    required this.onRelationshipChanged,
    required this.onLink,
  });

  final PrototypePalette palette;
  final TextEditingController studentCodeController;
  final TextEditingController verificationCodeController;
  final String relationship;
  final bool linking;
  final ValueChanged<String> onRelationshipChanged;
  final VoidCallback onLink;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Link a child account',
            subtitle:
                'Use the student ID and the one-time verification code shown in the student app.',
          ),
          TextField(
            controller: studentCodeController,
            decoration: const InputDecoration(
              labelText: 'Student ID',
              hintText: 'STU-ABC1234567',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: verificationCodeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Verification code',
              hintText: '6-digit code',
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: relationship,
            items: const [
              DropdownMenuItem(value: 'Parent', child: Text('Parent')),
              DropdownMenuItem(value: 'Guardian', child: Text('Guardian')),
              DropdownMenuItem(value: 'Caregiver', child: Text('Caregiver')),
            ],
            onChanged: (value) {
              if (value != null) {
                onRelationshipChanged(value);
              }
            },
            decoration: const InputDecoration(labelText: 'Relationship'),
          ),
          const SizedBox(height: 16),
          AnimatedPrimaryButton(
            label: linking ? 'Linking...' : 'Link child account',
            icon: Icons.link_rounded,
            onPressed: onLink,
          ),
        ],
      ),
    );
  }
}

class _GuardianChecklistRow extends StatelessWidget {
  const _GuardianChecklistRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(subtitle),
            ],
          ),
        ),
      ],
    );
  }
}

class _GuardianStudentCard extends StatelessWidget {
  const _GuardianStudentCard({
    required this.palette,
    required this.student,
    required this.platformStatus,
    required this.summaryStatus,
    required this.busy,
    required this.onGrantPlatform,
    required this.onGrantSummary,
    required this.onOpenSummary,
  });

  final PrototypePalette palette;
  final MobileLinkedStudentSummary student;
  final String platformStatus;
  final String summaryStatus;
  final bool busy;
  final VoidCallback onGrantPlatform;
  final VoidCallback onGrantSummary;
  final VoidCallback onOpenSummary;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.studentName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${student.relationshipToStudent} • ${student.schoolName ?? 'BAHA student'}',
                    ),
                  ],
                ),
              ),
              if (student.isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: palette.primary.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Primary',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: palette.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _GuardianStatusPill(
                label: 'Access ${_titleCase(platformStatus)}',
                ok: platformStatus == 'granted',
              ),
              _GuardianStatusPill(
                label: 'Summaries ${_titleCase(summaryStatus)}',
                ok: summaryStatus == 'granted',
              ),
              if ((student.ageCohort ?? '').isNotEmpty)
                _GuardianStatusPill(
                  label: student.ageCohort!.replaceAll('_', ' '),
                  ok: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (platformStatus != 'granted')
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onGrantPlatform,
                  icon: const Icon(Icons.approval_rounded),
                  label: const Text('Approve access'),
                ),
              if (summaryStatus != 'granted')
                FilledButton.tonalIcon(
                  onPressed: busy ? null : onGrantSummary,
                  icon: const Icon(Icons.visibility_rounded),
                  label: const Text('Enable summaries'),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onOpenSummary,
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Open summary'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleCase(String value) {
    if (value.isEmpty) {
      return value;
    }
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }
}

class _GuardianStatusPill extends StatelessWidget {
  const _GuardianStatusPill({required this.label, required this.ok});

  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? const Color(0xFF239B72) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class GuardianStudentSummaryScreen extends StatefulWidget {
  const GuardianStudentSummaryScreen({
    required this.apiClient,
    required this.identity,
    required this.student,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileLinkedStudentSummary student;

  @override
  State<GuardianStudentSummaryScreen> createState() =>
      _GuardianStudentSummaryScreenState();
}

class _GuardianStudentSummaryScreenState
    extends State<GuardianStudentSummaryScreen> {
  late Future<_GuardianStudentSummaryViewModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_GuardianStudentSummaryViewModel> _load() async {
    final platform = await widget.apiClient
        .getPlatformParticipationConsentStatus(
          identity: widget.identity,
          studentProfileId: widget.student.studentProfileId,
        );
    final summaryConsent = await widget.apiClient.getParentSummaryConsentStatus(
      identity: widget.identity,
      studentProfileId: widget.student.studentProfileId,
    );
    ParentWeeklySummary? summary;
    String? summaryError;
    if (summaryConsent.status == 'granted') {
      try {
        summary = await widget.apiClient.getParentWeeklySummary(
          identity: widget.identity,
          studentProfileId: widget.student.studentProfileId,
        );
      } on BahaApiException catch (error) {
        summaryError = error.message;
      }
    }
    return _GuardianStudentSummaryViewModel(
      platform: platform,
      summaryConsent: summaryConsent,
      summary: summary,
      summaryError: summaryError,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(AppColorTheme.growth);
    return Theme(
      data: buildTheme(palette),
      child: Scaffold(
        appBar: AppBar(title: Text(widget.student.studentName)),
        body: FutureBuilder<_GuardianStudentSummaryViewModel>(
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
                children: [Text('${snapshot.error}')],
              );
            }
            final data = snapshot.data;
            if (data == null) {
              return const SizedBox.shrink();
            }
            final summaryMap =
                data.summary?.summary ?? const <String, dynamic>{};
            final flags =
                (summaryMap['risk_flags'] as List<dynamic>? ?? const [])
                    .map((value) => value.toString())
                    .toList();
            final trends =
                (summaryMap['trend_labels'] as List<dynamic>? ?? const [])
                    .map((value) => value.toString())
                    .toList();
            final accessGranted = data.platform.status == 'granted';
            final summaryGranted = data.summaryConsent.status == 'granted';
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                HeroHeader(
                  palette: palette,
                  kicker: 'Parent summary',
                  title: widget.student.studentName,
                  subtitle:
                      'This view is intentionally high-level. It shows weekly trends and concern signals without exposing private daily answers.',
                  actions: [
                    Pill(
                      icon: Icons.approval_rounded,
                      label: 'Access ${data.platform.status}',
                    ),
                    Pill(
                      icon: Icons.visibility_rounded,
                      label: 'Summaries ${data.summaryConsent.status}',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (!accessGranted)
                  GlassPanel(
                    palette: palette,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Student access is still pending approval',
                          subtitle:
                              'Grant platform participation first. Until then, the student account remains blocked from the live student experience.',
                        ),
                      ],
                    ),
                  )
                else if (!summaryGranted)
                  GlassPanel(
                    palette: palette,
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle(
                          title: 'Weekly summaries are not enabled yet',
                          subtitle:
                              'Turn on parent summary sharing from the parent home screen to unlock weekly trends and alerts.',
                        ),
                      ],
                    ),
                  )
                else if (data.summary == null)
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'No weekly summary available yet',
                          subtitle:
                              'This usually means the student has not built enough recent check-in history for a meaningful pattern summary.',
                        ),
                        if (data.summaryError != null) Text(data.summaryError!),
                      ],
                    ),
                  )
                else ...[
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'This week at a glance',
                          subtitle:
                              'The main narrative, the strongest positive sign, and the main watch area.',
                        ),
                        _SummaryBlock(
                          title: 'Headline',
                          value: '${summaryMap['headline'] ?? 'No headline'}',
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'Week story',
                          value:
                              '${summaryMap['week_story'] ?? 'No weekly story yet.'}',
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'Best progress',
                          value:
                              '${summaryMap['best_progress'] ?? 'No clear improvement signal yet.'}',
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'Watch area',
                          value:
                              '${summaryMap['watch_area'] ?? 'No watch area detected this week.'}',
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'Support nudge',
                          value:
                              '${summaryMap['support_nudge'] ?? 'No support suggestion yet.'}',
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
                          title: 'Trends and alerts',
                          subtitle:
                              'These labels are the safe parent-facing signals BAHA has derived so far.',
                        ),
                        if (trends.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: trends
                                .map(
                                  (trend) => _GuardianStatusPill(
                                    label: trend,
                                    ok: true,
                                  ),
                                )
                                .toList(),
                          )
                        else
                          const Text('No stable trend labels yet.'),
                        const SizedBox(height: 12),
                        if (flags.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: flags
                                .map(
                                  (flag) => _GuardianStatusPill(
                                    label: flag,
                                    ok: false,
                                  ),
                                )
                                .toList(),
                          )
                        else
                          const Text(
                            'No concern alerts were raised this week.',
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                GlassPanel(
                  palette: palette,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionTitle(
                        title: 'Privacy boundary',
                        subtitle:
                            'Parents see only patterns and alerts. Individual answers, journal-like details, and message-level content stay hidden here.',
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

class _SummaryBlock extends StatelessWidget {
  const _SummaryBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    );
  }
}

class _GuardianStudentSummaryViewModel {
  const _GuardianStudentSummaryViewModel({
    required this.platform,
    required this.summaryConsent,
    required this.summary,
    required this.summaryError,
  });

  final PlatformParticipationConsentStatus platform;
  final ParentSummaryConsentStatus summaryConsent;
  final ParentWeeklySummary? summary;
  final String? summaryError;
}

class _RolePlaceholderScreen extends StatelessWidget {
  const _RolePlaceholderScreen({
    required this.title,
    required this.subtitle,
    required this.onClearIdentity,
  });

  final String title;
  final String subtitle;
  final Future<void> Function() onClearIdentity;

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(AppColorTheme.growth);
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
              palette: palette,
              kicker: 'BAHA',
              title: title,
              subtitle: subtitle,
              actions: const [
                Pill(icon: Icons.build_circle_rounded, label: 'In progress'),
              ],
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: onClearIdentity,
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text('Switch account'),
            ),
          ],
        ),
      ),
    );
  }
}
