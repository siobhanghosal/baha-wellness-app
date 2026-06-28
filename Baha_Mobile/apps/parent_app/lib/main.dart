import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_auth_session/baha_auth_session.dart';
import 'package:baha_content_renderer/baha_content_renderer.dart';
import 'package:baha_design_system/baha_design_system.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const ParentApp());
}

class ParentAppEnvironment {
  const ParentAppEnvironment({
    required this.apiBaseUrl,
    required this.defaultExternalAuthId,
    required this.defaultAuthEmail,
  });

  final String apiBaseUrl;
  final String defaultExternalAuthId;
  final String defaultAuthEmail;

  factory ParentAppEnvironment.fromDefines() {
    return const ParentAppEnvironment(
      apiBaseUrl: String.fromEnvironment(
        'BAHA_API_BASE_URL',
        defaultValue: 'http://10.0.2.2:8000',
      ),
      defaultExternalAuthId: String.fromEnvironment(
        'BAHA_DEV_EXTERNAL_AUTH_ID',
        defaultValue: '',
      ),
      defaultAuthEmail: String.fromEnvironment(
        'BAHA_DEV_AUTH_EMAIL',
        defaultValue: '',
      ),
    );
  }
}

class ParentApp extends StatefulWidget {
  const ParentApp({super.key});

  @override
  State<ParentApp> createState() => _ParentAppState();
}

class _ParentAppState extends State<ParentApp> {
  late final ParentAppEnvironment _environment;
  late final BahaApiClient _apiClient;
  late final AppSessionController _sessionController;

  @override
  void initState() {
    super.initState();
    _environment = ParentAppEnvironment.fromDefines();
    _apiClient = BahaApiClient(baseUrl: _environment.apiBaseUrl);
    _sessionController = AppSessionController(apiClient: _apiClient)
      ..restoreSession();
  }

  @override
  void dispose() {
    _sessionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAHA Parent',
      debugShowCheckedModeBanner: false,
      theme: BahaTheme.light(),
      home: AnimatedBuilder(
        animation: _sessionController,
        builder: (context, child) {
          switch (_sessionController.stage) {
            case SessionStage.splash:
              return const _ParentSplashScreen();
            case SessionStage.requiresIdentity:
              return ParentIdentityScreen(
                defaultExternalAuthId: _environment.defaultExternalAuthId,
                defaultAuthEmail: _environment.defaultAuthEmail,
                apiBaseUrl: _environment.apiBaseUrl,
                onSubmit: (identity) =>
                    _sessionController.saveIdentity(identity),
              );
            case SessionStage.requiresBootstrap:
              return ParentBootstrapScreen(
                identity: _sessionController.identity,
                onboardingState: _sessionController.onboardingState,
                onResetIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.waiting:
              return ParentWaitingScreen(
                onboardingState: _sessionController.onboardingState,
                onRefresh: _sessionController.refreshOnboarding,
                onChangeIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.ready:
              return ParentHomeScreen(
                apiClient: _apiClient,
                identity: _sessionController.identity!,
                actor: _sessionController.actor,
                environment: _environment,
                onClearIdentity: _sessionController.clearIdentity,
              );
            case SessionStage.failure:
              return ParentErrorScreen(
                errorMessage: _sessionController.errorMessage,
                onRetry: _sessionController.refreshOnboarding,
                onResetIdentity: _sessionController.clearIdentity,
              );
          }
        },
      ),
    );
  }
}

class _ParentSplashScreen extends StatelessWidget {
  const _ParentSplashScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7F1E2), Color(0xFFDCE8EE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(height: 20),
              Text('BAHA Parent', style: theme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Restoring session and checking guardian access.',
                style: theme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentIdentityScreen extends StatefulWidget {
  const ParentIdentityScreen({
    required this.defaultExternalAuthId,
    required this.defaultAuthEmail,
    required this.apiBaseUrl,
    required this.onSubmit,
    super.key,
  });

  final String defaultExternalAuthId;
  final String defaultAuthEmail;
  final String apiBaseUrl;
  final Future<void> Function(DevelopmentIdentity identity) onSubmit;

  @override
  State<ParentIdentityScreen> createState() => _ParentIdentityScreenState();
}

class _ParentIdentityScreenState extends State<ParentIdentityScreen> {
  late final TextEditingController _externalAuthIdController;
  late final TextEditingController _emailController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _externalAuthIdController = TextEditingController(
      text: widget.defaultExternalAuthId,
    );
    _emailController = TextEditingController(text: widget.defaultAuthEmail);
  }

  @override
  void dispose() {
    _externalAuthIdController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(
        DevelopmentIdentity(
          externalAuthId: _externalAuthIdController.text.trim(),
          authEmail: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
        ),
      );
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text('Parent app bootstrap', style: theme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'This build uses the backend development identity bridge until hosted auth is provisioned.',
                style: theme.bodyLarge,
              ),
              const SizedBox(height: 24),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('API target', style: theme.titleLarge),
                    const SizedBox(height: 8),
                    Text(widget.apiBaseUrl, style: theme.bodyLarge),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _externalAuthIdController,
                      decoration: const InputDecoration(
                        labelText: 'External auth ID',
                        hintText: 'supabase-guardian-demo',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Auth email (optional)',
                        hintText: 'guardian.demo@baha.local',
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Connecting...' : 'Continue'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Use a seeded ID like `supabase-guardian-demo` to open the linked parent demo immediately.',
                style: theme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentBootstrapScreen extends StatelessWidget {
  const ParentBootstrapScreen({
    required this.identity,
    required this.onboardingState,
    required this.onResetIdentity,
    super.key,
  });

  final DevelopmentIdentity? identity;
  final AuthOnboardingState? onboardingState;
  final Future<void> Function() onResetIdentity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Parent bootstrap not wired yet',
                style: theme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'The current parent slice assumes the seeded guardian demo account is already onboarded. This screen appears only if the backend says the guardian account still needs bootstrap work.',
                style: theme.bodyLarge,
              ),
              const SizedBox(height: 24),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backend status', style: theme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      'next_step: ${onboardingState?.nextStep ?? 'unknown'}',
                      style: theme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'identity: ${identity?.externalAuthId ?? 'none'}',
                      style: theme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onResetIdentity,
                child: const Text('Switch development identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentWaitingScreen extends StatelessWidget {
  const ParentWaitingScreen({
    required this.onboardingState,
    required this.onRefresh,
    required this.onChangeIdentity,
    super.key,
  });

  final AuthOnboardingState? onboardingState;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChangeIdentity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(
                'Waiting on the next parent step',
                style: theme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                onboardingState?.detail ??
                    'The guardian account is not fully ready yet. This app respects the server-side onboarding and consent state.',
                style: theme.bodyLarge,
              ),
              const SizedBox(height: 24),
              BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Backend status', style: theme.titleLarge),
                    const SizedBox(height: 12),
                    Text(
                      'next_step: ${onboardingState?.nextStep ?? 'unknown'}',
                      style: theme.bodyLarge,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'linked_student_count: ${onboardingState?.linkedStudentCount ?? 0}',
                      style: theme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onRefresh,
                child: const Text('Refresh onboarding state'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onChangeIdentity,
                child: const Text('Switch development identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentErrorScreen extends StatelessWidget {
  const ParentErrorScreen({
    required this.errorMessage,
    required this.onRetry,
    required this.onResetIdentity,
    super.key,
  });

  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Future<void> Function() onResetIdentity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Text('Session failed', style: theme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'The app could not complete the startup flow.',
                style: theme.bodyLarge,
              ),
              const Spacer(),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onResetIdentity,
                child: const Text('Reset development identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentHomeScreen extends StatefulWidget {
  const ParentHomeScreen({
    required this.apiClient,
    required this.identity,
    required this.actor,
    required this.environment,
    required this.onClearIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileActor? actor;
  final ParentAppEnvironment environment;
  final Future<void> Function() onClearIdentity;

  @override
  State<ParentHomeScreen> createState() => _ParentHomeScreenState();
}

class _ParentHomeScreenState extends State<ParentHomeScreen> {
  int _currentIndex = 0;
  String? _selectedStudentProfileId;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      ParentSummaryTab(
        apiClient: widget.apiClient,
        identity: widget.identity,
        actor: widget.actor,
        selectedStudentProfileId: _selectedStudentProfileId,
        onSelectedStudentChanged: (value) {
          setState(() => _selectedStudentProfileId = value);
        },
      ),
      ParentConsentTab(
        apiClient: widget.apiClient,
        identity: widget.identity,
        selectedStudentProfileId: _selectedStudentProfileId,
        onSelectedStudentChanged: (value) {
          setState(() => _selectedStudentProfileId = value);
        },
      ),
      ParentResourcesTab(
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
      ParentSettingsTab(
        apiClient: widget.apiClient,
        identity: widget.identity,
        environment: widget.environment,
        onClearIdentity: widget.onClearIdentity,
      ),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (value) {
          setState(() => _currentIndex = value);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.verified_user_outlined),
            selectedIcon: Icon(Icons.verified_user),
            label: 'Consent',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_stories_outlined),
            selectedIcon: Icon(Icons.auto_stories),
            label: 'Resources',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class ParentSummaryTab extends StatefulWidget {
  const ParentSummaryTab({
    required this.apiClient,
    required this.identity,
    required this.actor,
    required this.selectedStudentProfileId,
    required this.onSelectedStudentChanged,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileActor? actor;
  final String? selectedStudentProfileId;
  final ValueChanged<String?> onSelectedStudentChanged;

  @override
  State<ParentSummaryTab> createState() => _ParentSummaryTabState();
}

class _ParentSummaryTabState extends State<ParentSummaryTab> {
  late Future<_ParentSummaryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant ParentSummaryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStudentProfileId != widget.selectedStudentProfileId) {
      _future = _load();
    }
  }

  Future<_ParentSummaryData> _load() async {
    final students = await widget.apiClient.listParentStudents(
      identity: widget.identity,
    );
    if (students.isEmpty) {
      return const _ParentSummaryData(students: []);
    }
    final selected =
        students.any(
          (item) => item.studentProfileId == widget.selectedStudentProfileId,
        )
        ? widget.selectedStudentProfileId!
        : students.first.studentProfileId;
    if (selected != widget.selectedStudentProfileId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectedStudentChanged(selected);
      });
    }
    final summary = await widget.apiClient.getParentWeeklySummary(
      identity: widget.identity,
      studentProfileId: selected,
    );
    return _ParentSummaryData(students: students, summary: summary);
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
          colors: [Color(0xFFF7F1E2), Color(0xFFDCE8EE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_ParentSummaryData>(
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
                            'Could not load parent home',
                            style: theme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text('${snapshot.error}', style: theme.bodyLarge),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final data = snapshot.data!;
              if (data.students.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    BahaSurface(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No linked students yet',
                            style: theme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'This parent app slice expects an active guardian-student link. Use the seeded guardian demo for the current real flow.',
                            style: theme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
              final summary = data.summary!;
              final selectedStudent = data.students.firstWhere(
                (item) => item.studentProfileId == summary.studentProfileId,
              );
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'Hi ${widget.actor?.displayName ?? 'Parent'}',
                    style: theme.headlineMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'This parent slice reads role-safe weekly summaries and guardian consent state from the real backend.',
                    style: theme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  ParentStudentPicker(
                    students: data.students,
                    selectedStudentProfileId: summary.studentProfileId,
                    onChanged: widget.onSelectedStudentChanged,
                  ),
                  const SizedBox(height: 18),
                  BahaSurface(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedStudent.studentName,
                          style: theme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          [
                            selectedStudent.relationshipToStudent,
                            if (selectedStudent.schoolName != null)
                              selectedStudent.schoolName!,
                            if (selectedStudent.ageCohort != null)
                              selectedStudent.ageCohort!,
                          ].join(' • '),
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
                        Text('This week', style: theme.titleLarge),
                        const SizedBox(height: 12),
                        Text(
                          summary.summary['headline']?.toString() ??
                              'No parent-safe summary headline available.',
                          style: theme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          summary.summary['safe_talking_point']?.toString() ??
                              'No safe talking point available.',
                          style: theme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _ParentMetricChip(
                              label: 'Consent',
                              value: summary.consentStatus,
                            ),
                            _ParentMetricChip(
                              label: 'Access',
                              value: summary.access.mode,
                            ),
                            _ParentMetricChip(
                              label: 'Visible tiers',
                              value: summary.visibleTiers.join(', '),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Week ${_formatDate(summary.weekStart)} to ${_formatDate(summary.weekEnd)}',
                          style: theme.bodyMedium,
                        ),
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

class ParentConsentTab extends StatefulWidget {
  const ParentConsentTab({
    required this.apiClient,
    required this.identity,
    required this.selectedStudentProfileId,
    required this.onSelectedStudentChanged,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String? selectedStudentProfileId;
  final ValueChanged<String?> onSelectedStudentChanged;

  @override
  State<ParentConsentTab> createState() => _ParentConsentTabState();
}

class _ParentConsentTabState extends State<ParentConsentTab> {
  late Future<_ParentConsentData> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant ParentConsentTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedStudentProfileId != widget.selectedStudentProfileId) {
      _future = _load();
    }
  }

  Future<_ParentConsentData> _load() async {
    final students = await widget.apiClient.listParentStudents(
      identity: widget.identity,
    );
    if (students.isEmpty) {
      return const _ParentConsentData(students: []);
    }
    final selected =
        students.any(
          (item) => item.studentProfileId == widget.selectedStudentProfileId,
        )
        ? widget.selectedStudentProfileId!
        : students.first.studentProfileId;
    if (selected != widget.selectedStudentProfileId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onSelectedStudentChanged(selected);
      });
    }
    final consent = await widget.apiClient.getParentSummaryConsentStatus(
      identity: widget.identity,
      studentProfileId: selected,
    );
    return _ParentConsentData(students: students, consent: consent);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _updateConsent(String status) async {
    final studentProfileId = widget.selectedStudentProfileId;
    if (studentProfileId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.apiClient.updateParentSummaryConsent(
        identity: widget.identity,
        request: ParentSummaryConsentRequest(
          studentProfileId: studentProfileId,
          status: status,
        ),
      );
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summary sharing consent updated to $status.')),
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

  Future<void> _grantPlatformParticipation() async {
    final studentProfileId = widget.selectedStudentProfileId;
    if (studentProfileId == null) {
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.apiClient.updatePlatformParticipationConsent(
        identity: widget.identity,
        request: PlatformParticipationConsentRequest(
          studentProfileId: studentProfileId,
        ),
      );
      await _refresh();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Platform participation marked granted.')),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consent'),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<_ParentConsentData>(
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
                    child: Text('${snapshot.error}', style: theme.bodyLarge),
                  ),
                ],
              );
            }
            final data = snapshot.data!;
            if (data.students.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  BahaSurface(
                    child: Text(
                      'No linked students available for guardian consent work.',
                      style: theme.bodyLarge,
                    ),
                  ),
                ],
              );
            }
            final consent = data.consent!;
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                ParentStudentPicker(
                  students: data.students,
                  selectedStudentProfileId: consent.studentProfileId,
                  onChanged: widget.onSelectedStudentChanged,
                ),
                const SizedBox(height: 18),
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Summary-sharing consent', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      _ConsentInfoRow(label: 'Status', value: consent.status),
                      _ConsentInfoRow(label: 'Scope', value: consent.scope),
                      _ConsentInfoRow(
                        label: 'Relationship',
                        value: consent.actorRelationship ?? '-',
                      ),
                      _ConsentInfoRow(
                        label: 'Granted',
                        value: consent.grantedAt == null
                            ? '-'
                            : _formatDateTime(consent.grantedAt!),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'This controls whether parent-safe weekly summaries can be shown in the parent app.',
                        style: theme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saving
                            ? null
                            : () => _updateConsent('granted'),
                        child: const Text('Grant summary sharing'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => _updateConsent('withdrawn'),
                        child: const Text('Withdraw summary sharing'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform participation', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        'Use this only if the guardian still needs to activate participation for a minor student flow.',
                        style: theme.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _saving ? null : _grantPlatformParticipation,
                        child: const Text('Grant platform participation'),
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

class ParentSettingsTab extends StatefulWidget {
  const ParentSettingsTab({
    required this.apiClient,
    required this.identity,
    required this.environment,
    required this.onClearIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final ParentAppEnvironment environment;
  final Future<void> Function() onClearIdentity;

  @override
  State<ParentSettingsTab> createState() => _ParentSettingsTabState();
}

class _ParentSettingsTabState extends State<ParentSettingsTab> {
  late Future<List<MobileSupportContact>> _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = widget.apiClient.listSupportContacts(
      identity: widget.identity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          BahaSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Runtime', style: theme.titleLarge),
                const SizedBox(height: 12),
                _ConsentInfoRow(
                  label: 'API URL',
                  value: widget.environment.apiBaseUrl,
                ),
                _ConsentInfoRow(
                  label: 'Identity',
                  value: widget.identity.externalAuthId,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<MobileSupportContact>>(
            future: _contactsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return BahaSurface(
                  child: Text('${snapshot.error}', style: theme.bodyLarge),
                );
              }
              final contacts = snapshot.data ?? const <MobileSupportContact>[];
              return BahaSurface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Support contacts', style: theme.titleLarge),
                    const SizedBox(height: 12),
                    if (contacts.isEmpty)
                      Text(
                        'No support contacts available.',
                        style: theme.bodyLarge,
                      )
                    else
                      ...contacts.map(
                        (contact) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${contact.label}${contact.phone == null ? '' : ' • ${contact.phone}'}',
                            style: theme.bodyLarge,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: widget.onClearIdentity,
            child: const Text('Switch development identity'),
          ),
        ],
      ),
    );
  }
}

class ParentResourcesTab extends StatefulWidget {
  const ParentResourcesTab({
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<ParentResourcesTab> createState() => _ParentResourcesTabState();
}

class _ParentResourcesTabState extends State<ParentResourcesTab> {
  late Future<List<MobileContentSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<MobileContentSummary>> _load() {
    return widget.apiClient.listMobileContentFeed(identity: widget.identity);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _openContent(MobileContentSummary content) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => ParentContentDetailScreen(
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
        title: const Text('Resources'),
        backgroundColor: Colors.transparent,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<MobileContentSummary>>(
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
                          'Could not load parent resources',
                          style: theme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Text('${snapshot.error}', style: theme.bodyLarge),
                      ],
                    ),
                  ),
                ],
              );
            }

            final contentFeed = snapshot.data ?? const <MobileContentSummary>[];
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                BahaSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Parent resources', style: theme.titleLarge),
                      const SizedBox(height: 12),
                      Text(
                        'Published, role-safe content for parent conversations and guidance.',
                        style: theme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (contentFeed.isEmpty)
                  BahaSurface(
                    child: Text(
                      'No parent resources are published yet.',
                      style: theme.bodyLarge,
                    ),
                  )
                else
                  ...contentFeed.map(
                    (content) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        onTap: () => _openContent(content),
                        borderRadius: BorderRadius.circular(18),
                        child: BahaSurface(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(content.title, style: theme.titleLarge),
                              const SizedBox(height: 8),
                              Text(
                                [
                                  if ((content.theme ?? '').isNotEmpty)
                                    content.theme!,
                                  content.contentType,
                                  if (content.publishedAt != null)
                                    _formatDate(content.publishedAt!),
                                ].join(' • '),
                                style: theme.bodyMedium,
                              ),
                              if ((content.summary ?? '').isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(content.summary!, style: theme.bodyLarge),
                              ],
                            ],
                          ),
                        ),
                      ),
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

class ParentContentDetailScreen extends StatelessWidget {
  const ParentContentDetailScreen({
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
        title: const Text('Resource Detail'),
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
                    const SizedBox(height: 8),
                    Text(
                      [
                        if ((detail.theme ?? '').isNotEmpty) detail.theme!,
                        detail.contentType,
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
                  title: detail.theme ?? 'Resource',
                  body: detail.plainText!,
                )
              else
                ...textBlocks.map(
                  (block) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: PlainTextBlock(
                      title: detail.theme ?? 'Resource',
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

class ParentStudentPicker extends StatelessWidget {
  const ParentStudentPicker({
    required this.students,
    required this.selectedStudentProfileId,
    required this.onChanged,
    super.key,
  });

  final List<MobileLinkedStudentSummary> students;
  final String selectedStudentProfileId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return BahaSurface(
      child: DropdownButtonFormField<String>(
        initialValue: selectedStudentProfileId,
        decoration: const InputDecoration(labelText: 'Linked student'),
        items: students
            .map(
              (student) => DropdownMenuItem<String>(
                value: student.studentProfileId,
                child: Text(student.studentName),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _ParentSummaryData {
  const _ParentSummaryData({required this.students, this.summary});

  final List<MobileLinkedStudentSummary> students;
  final ParentWeeklySummary? summary;
}

class _ParentConsentData {
  const _ParentConsentData({required this.students, this.consent});

  final List<MobileLinkedStudentSummary> students;
  final ParentSummaryConsentStatus? consent;
}

class _ParentMetricChip extends StatelessWidget {
  const _ParentMetricChip({required this.label, required this.value});

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

class _ConsentInfoRow extends StatelessWidget {
  const _ConsentInfoRow({required this.label, required this.value});

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
            width: 100,
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

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}
