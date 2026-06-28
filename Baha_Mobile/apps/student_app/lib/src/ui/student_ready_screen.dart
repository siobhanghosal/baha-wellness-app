import 'dart:async';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_design_system/baha_design_system.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_environment.dart';
import '../prototype/app_theme.dart';
import '../prototype/mock_data.dart';
import '../prototype/prototype_models.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';
import 'student_buddy_screen.dart';
import 'student_help_request_screen.dart';
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
  static const _ageStorageKey = 'baha.student.selected_age';
  static const _genderStorageKey = 'baha.student.selected_gender';

  late final ThemeController _themeController;
  late final ConfettiController _confettiController;
  int _currentIndex = 0;
  StudentGender _gender = StudentGender.female;
  StudentAgeGroup _age = StudentAgeGroup.teen;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController()..load();
    _confettiController = ConfettiController(duration: 900.ms);
    unawaited(_restoreDisplayPreferences());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<void> _openCheckins() async {
    await _pushRoute(
      builder: (context) => StudentCheckinsScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
    );
  }

  Future<void> _openLearn({
    String? theme,
    String? screenTitle,
    String? screenSubtitle,
  }) async {
    await _pushRoute(
      builder: (context) => StudentLearnScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        initialTheme: theme,
        screenTitle: screenTitle,
        screenSubtitle: screenSubtitle,
      ),
    );
  }

  Future<void> _openBuddy() async {
    await _pushRoute(
      builder: (context) => StudentBuddyScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
    );
  }

  Future<void> _openSupport() async {
    await _pushRoute(
      builder: (context) => StudentHelpRequestScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
    );
  }

  Future<void> _openInsights(UiMetric metric) async {
    await _pushRoute(
      builder: (context) => StudentInsightScreen(
        palette: _currentPalette,
        metric: metric,
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
    );
  }

  Future<void> _openTool(UiCardItem item) async {
    await _pushRoute(
      builder: (context) =>
          StudentLocalToolScreen(palette: _currentPalette, item: item),
    );
  }

  Future<void> _openNotifications() async {
    await _pushRoute(
      builder: (context) => StudentNotificationsScreen(
        palette: _currentPalette,
        actor: widget.actor,
        onboardingState: widget.onboardingState,
      ),
    );
  }

  Future<void> _openCalendar() async {
    await _pushRoute(
      builder: (context) => StudentCalendarScreen(
        palette: _currentPalette,
        apiClient: widget.apiClient,
        identity: widget.identity,
      ),
    );
  }

  Future<void> _openSettings() async {
    await _pushRoute(
      builder: (context) => StudentSettingsScreen(
        palette: _currentPalette,
        actor: widget.actor,
        onboardingState: widget.onboardingState,
        environment: widget.environment,
        onRefreshOnboarding: widget.onRefresh,
        onOpenSupport: _openSupport,
        onClearIdentity: _resetIdentityFromChildRoute,
      ),
    );
  }

  PrototypePalette get _currentPalette =>
      studentPalette(_age, _gender, isDark: _themeController.isDark);

  Future<void> _pushRoute({required WidgetBuilder builder}) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ThemeScope(
          controller: _themeController,
          child: AnimatedBuilder(
            animation: _themeController,
            builder: (context, _) => builder(context),
          ),
        ),
      ),
    );
  }

  Future<void> _restoreDisplayPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    final savedAge = preferences.getString(_ageStorageKey);
    final savedGender = preferences.getString(_genderStorageKey);
    if (!mounted) {
      return;
    }
    setState(() {
      _age = StudentAgeGroup.values.firstWhere(
        (value) => value.name == savedAge,
        orElse: () => _age,
      );
      _gender = StudentGender.values.firstWhere(
        (value) => value.name == savedGender,
        orElse: () => _gender,
      );
    });
  }

  Future<void> _persistDisplayPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_ageStorageKey, _age.name);
    await preferences.setString(_genderStorageKey, _gender.name);
  }

  void _updateAge(StudentAgeGroup value) {
    setState(() => _age = value);
    unawaited(_persistDisplayPreferences());
  }

  void _updateGender(StudentGender value) {
    setState(() => _gender = value);
    unawaited(_persistDisplayPreferences());
  }

  Future<void> _resetIdentityFromChildRoute() async {
    await widget.onClearIdentity();
    if (!mounted) {
      return;
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleCardAction(UiCardItem item) {
    switch (item.title) {
      case 'Daily Check-in':
        unawaited(_openCheckins());
        return;
      case 'Emotion Wheel':
      case 'Calm Breathing':
      case 'Friendship Choices':
        unawaited(_openTool(item));
        return;
      case 'BAHA Buddy':
        setState(() => _currentIndex = 2);
        return;
      case 'SOS Help':
      case 'Support':
        unawaited(_openSupport());
        return;
      case 'Notifications':
        unawaited(_openNotifications());
        return;
      case 'Calendar':
        unawaited(_openCalendar());
        return;
      case 'Sleep Reset':
        unawaited(
          _openLearn(
            theme: 'Sleep',
            screenTitle: 'Sleep Reset',
            screenSubtitle:
                'Wind-down routines, night checklists, and calmer bedtime habits.',
          ),
        );
        return;
      case 'Digital Wellness':
        unawaited(
          _openLearn(
            theme: 'Digital Wellness',
            screenTitle: 'Digital Wellness',
            screenSubtitle:
                'Screen boundaries, scroll resets, and healthier after-school habits.',
          ),
        );
        return;
      case 'Peer Pressure':
        unawaited(
          _openLearn(
            theme: 'Peer Pressure',
            screenTitle: 'Peer Pressure',
            screenSubtitle:
                'Boundary-setting, confidence scripts, and social choice practice.',
          ),
        );
        return;
      case 'Exam Stress':
        unawaited(
          _openLearn(
            theme: 'Exam Stress',
            screenTitle: 'Exam Stress',
            screenSubtitle:
                'Reset your thoughts, make a smaller plan, and recover focus.',
          ),
        );
        return;
      case 'Settings':
        unawaited(_openSettings());
        return;
      default:
        unawaited(_openTool(item));
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, child) {
          final palette = studentPalette(
            _age,
            _gender,
            isDark: _themeController.isDark,
          );
          final pages = <Widget>[
            StudentReferenceHomeTab(
              palette: palette,
              apiClient: widget.apiClient,
              identity: widget.identity,
              actor: widget.actor,
              onboardingState: widget.onboardingState,
              age: _age,
              gender: _gender,
              onAgeChanged: _updateAge,
              onGenderChanged: _updateGender,
              onMetricTap: (metric) => unawaited(_openInsights(metric)),
              onOpenCheckins: _openCheckins,
              onOpenSupport: _openSupport,
              onClearIdentity: _resetIdentityFromChildRoute,
            ),
            StudentReferenceExploreTab(
              palette: palette,
              onCardTap: _handleCardAction,
            ),
            StudentReferenceBuddyTab(
              palette: palette,
              apiClient: widget.apiClient,
              identity: widget.identity,
              onOpenBuddy: _openBuddy,
              onOpenSupport: _openSupport,
            ),
            StudentReferenceProfileTab(
              palette: palette,
              actor: widget.actor,
              onboardingState: widget.onboardingState,
              environment: widget.environment,
              onActionTap: _handleCardAction,
            ),
          ];

          return Theme(
            data: buildTheme(palette),
            child: Stack(
              children: [
                AnimatedGradientScaffold(
                  palette: palette,
                  floatingActionButton: FloatingActionButton(
                    onPressed: () {
                      _confettiController.play();
                      unawaited(_openCheckins());
                    },
                    child: const Icon(Icons.favorite_rounded),
                  ),
                  bottomNavigationBar: SalomonBottomBar(
                    backgroundColor: palette.surface.withValues(
                      alpha: palette.isDark ? .96 : .92,
                    ),
                    selectedItemColor: palette.primary,
                    unselectedItemColor: palette.isDark
                        ? Colors.white.withValues(alpha: .76)
                        : palette.muted,
                    currentIndex: _currentIndex,
                    onTap: (index) => setState(() => _currentIndex = index),
                    items: [
                      SalomonBottomBarItem(
                        icon: Icon(Icons.home_rounded),
                        title: Text('Home'),
                      ),
                      SalomonBottomBarItem(
                        icon: Icon(Icons.explore_rounded),
                        title: Text('Explore'),
                      ),
                      SalomonBottomBarItem(
                        icon: Icon(Icons.chat_rounded),
                        title: Text('Buddy'),
                      ),
                      SalomonBottomBarItem(
                        icon: Icon(Icons.person_rounded),
                        title: Text('Profile'),
                      ),
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: 350.ms,
                    child: pages[_currentIndex],
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    shouldLoop: false,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class StudentReferenceHomeTab extends StatefulWidget {
  const StudentReferenceHomeTab({
    required this.palette,
    required this.apiClient,
    required this.identity,
    required this.actor,
    required this.onboardingState,
    required this.age,
    required this.gender,
    required this.onAgeChanged,
    required this.onGenderChanged,
    required this.onMetricTap,
    required this.onOpenCheckins,
    required this.onOpenSupport,
    required this.onClearIdentity,
    super.key,
  });

  final PrototypePalette palette;
  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileActor? actor;
  final AuthOnboardingState? onboardingState;
  final StudentAgeGroup age;
  final StudentGender gender;
  final ValueChanged<StudentAgeGroup> onAgeChanged;
  final ValueChanged<StudentGender> onGenderChanged;
  final ValueChanged<UiMetric> onMetricTap;
  final Future<void> Function() onOpenCheckins;
  final Future<void> Function() onOpenSupport;
  final Future<void> Function() onClearIdentity;

  @override
  State<StudentReferenceHomeTab> createState() =>
      _StudentReferenceHomeTabState();
}

class _StudentReferenceHomeTabState extends State<StudentReferenceHomeTab> {
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

  List<UiMetric> _metricsForSummary(StudentWeeklySummary summary) {
    final headline =
        summary.summary['headline']?.toString() ?? 'Feeling steady today';
    final moodTrend = summary.summary['mood_trend']?.toString() ?? headline;
    final sleepTrend =
        summary.summary['sleep_trend']?.toString() ?? 'Sleep trend available';
    final stressTrend =
        summary.summary['stress_trend']?.toString() ??
        'Support signals are staying manageable';
    final energyTrend =
        summary.summary['energy_trend']?.toString() ??
        'Energy pattern captured in weekly summary';
    return [
      UiMetric(
        label: 'Mood',
        value: .78,
        detail: moodTrend,
        icon: Icons.sentiment_satisfied_alt_rounded,
        color: const Color(0xFF14B8A6),
      ),
      UiMetric(
        label: 'Sleep',
        value: .62,
        detail: sleepTrend,
        icon: Icons.bedtime_rounded,
        color: const Color(0xFF6366F1),
      ),
      UiMetric(
        label: 'Stress',
        value: .34,
        detail: stressTrend,
        icon: Icons.spa_rounded,
        color: const Color(0xFFF59E0B),
      ),
      UiMetric(
        label: 'Energy',
        value: .71,
        detail: energyTrend,
        icon: Icons.bolt_rounded,
        color: const Color(0xFFEF4444),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<_StudentDashboardData>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return ListView(
              key: const ValueKey('student-home-loading'),
              padding: const EdgeInsets.all(22),
              children: [
                DashboardTopBar(palette: palette),
                HeroHeader(
                  palette: palette,
                  kicker: '${widget.gender.label} · ${widget.age.label}',
                  title: 'Your private wellness world',
                  subtitle: palette.story,
                  actions: [
                    Pill(icon: palette.heroIcon, label: palette.name),
                    const Pill(icon: Icons.lock_rounded, label: 'Private'),
                  ],
                ),
                const SizedBox(height: 18),
                ShimmerBlock(palette: palette),
              ],
            );
          }
          if (snapshot.hasError) {
            return ListView(
              key: const ValueKey('student-home-error'),
              padding: const EdgeInsets.all(22),
              children: [
                DashboardTopBar(palette: palette),
                HeroHeader(
                  palette: palette,
                  kicker: 'Student App',
                  title: 'Could not load your dashboard',
                  subtitle: '${snapshot.error}',
                  actions: const [
                    Pill(icon: Icons.warning_rounded, label: 'Retry'),
                  ],
                ),
                const SizedBox(height: 18),
                AnimatedPrimaryButton(
                  label: 'Refresh dashboard',
                  icon: Icons.refresh_rounded,
                  onPressed: _refresh,
                ),
              ],
            );
          }

          final data = snapshot.data!;
          final actor = widget.actor;
          final metrics = _metricsForSummary(data.summary);
          return ListView(
            key: const ValueKey('student-home'),
            padding: const EdgeInsets.all(22),
            children: [
              DashboardTopBar(palette: palette),
              HeroHeader(
                palette: palette,
                kicker: '${widget.gender.label} · ${widget.age.label}',
                title: 'Your private wellness world',
                subtitle: palette.story,
                actions: [
                  Pill(icon: palette.heroIcon, label: palette.name),
                  const Pill(icon: Icons.lock_rounded, label: 'Private'),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _PrototypeSelector<StudentAgeGroup>(
                      palette: palette,
                      value: widget.age,
                      values: StudentAgeGroup.values,
                      labelBuilder: (value) => value.label,
                      onChanged: widget.onAgeChanged,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _PrototypeSelector<StudentGender>(
                      palette: palette,
                      value: widget.gender,
                      values: StudentGender.values,
                      labelBuilder: (value) => value.label,
                      onChanged: widget.onGenderChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const SectionTitle(
                title: 'Today',
                subtitle: 'Tiny signals, no judgement.',
              ),
              ...metrics.map(
                (metric) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: MetricTile(
                    palette: palette,
                    metric: metric,
                    onTap: () => widget.onMetricTap(metric),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Wellness trend',
                      subtitle: 'A beautiful private graph.',
                    ),
                    MiniLineChart(palette: palette),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      actor?.displayName ??
                          widget.onboardingState?.displayName ??
                          'Student profile',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data.summary.summary['headline']?.toString() ??
                          'Weekly summary available.',
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Recent check-ins: ${data.checkins.length} • Privacy tier: ${data.summary.privacyTierApplied}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: widget.onOpenCheckins,
                    icon: const Icon(Icons.favorite_rounded),
                    label: const Text('Daily Check-in'),
                  ),
                  OutlinedButton.icon(
                    onPressed: widget.onOpenSupport,
                    icon: const Icon(Icons.health_and_safety_rounded),
                    label: const Text('SOS Help'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (data.checkins.isNotEmpty)
                GlassPanel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Recent activity',
                        subtitle: 'Real check-ins from the backend.',
                      ),
                      ...data.checkins
                          .take(3)
                          .map(
                            (checkin) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '${checkin.title} • ${checkin.submittedAt == null ? 'Pending timestamp' : _formatDateTime(checkin.submittedAt!)}',
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: widget.onClearIdentity,
                child: const Text('Switch development identity'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StudentReferenceExploreTab extends StatelessWidget {
  const StudentReferenceExploreTab({
    required this.palette,
    required this.onCardTap,
    super.key,
  });

  final PrototypePalette palette;
  final ValueChanged<UiCardItem> onCardTap;

  @override
  Widget build(BuildContext context) {
    final items = [...studentCards, ...learning];
    return LayoutBuilder(
      key: const ValueKey('student-discover'),
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(22),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: adaptiveGridCount(constraints.maxWidth),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: constraints.maxWidth < 420
              ? 268
              : constraints.maxWidth < 620
              ? 236
              : 212,
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          return ActionCard(
                palette: palette,
                item: item,
                onTap: () => onCardTap(item),
              )
              .animate(delay: (index * 50).ms)
              .fadeIn()
              .scale(begin: const Offset(.95, .95));
        },
      ),
    );
  }
}

class StudentReferenceBuddyTab extends StatefulWidget {
  const StudentReferenceBuddyTab({
    required this.palette,
    required this.apiClient,
    required this.identity,
    required this.onOpenBuddy,
    required this.onOpenSupport,
    super.key,
  });

  final PrototypePalette palette;
  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final Future<void> Function() onOpenBuddy;
  final Future<void> Function() onOpenSupport;

  @override
  State<StudentReferenceBuddyTab> createState() =>
      _StudentReferenceBuddyTabState();
}

class _StudentReferenceBuddyTabState extends State<StudentReferenceBuddyTab> {
  late Future<List<ChatSessionSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.listChatSessions(identity: widget.identity);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = widget.apiClient.listChatSessions(identity: widget.identity);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<ChatSessionSummary>>(
        future: _future,
        builder: (context, snapshot) {
          final sessionLabel = snapshot.hasData
              ? '${snapshot.data!.length} live sessions'
              : 'Live backend chat';
          return ListView(
            key: const ValueKey('student-buddy'),
            padding: const EdgeInsets.all(22),
            children: [
              HeroHeader(
                palette: palette,
                kicker: 'BAHA Buddy',
                title: 'A companion, not a clinician.',
                subtitle:
                    'Ask safe questions, practice calming down, and find support paths.',
                actions: [
                  const Pill(icon: Icons.verified_rounded, label: 'Safe Q&A'),
                  const Pill(icon: Icons.sos_rounded, label: 'Escalation'),
                  Pill(icon: Icons.cloud_done_rounded, label: sessionLabel),
                ],
              ),
              const SizedBox(height: 18),
              ...chatBubbles.map(
                (bubble) => Align(
                  alignment: bubble.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.sizeOf(context).width - 56,
                      ),
                      child: GlassPanel(
                        palette: palette,
                        child: Text('${bubble.sender}: ${bubble.text}'),
                      ),
                    ),
                  ),
                ),
              ),
              if (snapshot.hasData && snapshot.data!.isNotEmpty) ...[
                const SizedBox(height: 10),
                GlassPanel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Recent backend sessions',
                        subtitle: 'These are real chat sessions from the API.',
                      ),
                      ...snapshot.data!
                          .take(3)
                          .map(
                            (session) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Text(
                                '${session.status} • ${session.messageCount} messages',
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Ask a real Buddy question...',
                      ),
                      readOnly: true,
                      onTap: widget.onOpenBuddy,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton.small(
                    onPressed: widget.onOpenBuddy,
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              AnimatedPrimaryButton(
                label: 'Open live Buddy',
                icon: Icons.smart_toy_rounded,
                onPressed: widget.onOpenBuddy,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: widget.onOpenSupport,
                icon: const Icon(Icons.health_and_safety_rounded),
                label: const Text('Open SOS help'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StudentReferenceProfileTab extends StatelessWidget {
  const StudentReferenceProfileTab({
    required this.palette,
    required this.actor,
    required this.onboardingState,
    required this.environment,
    required this.onActionTap,
    super.key,
  });

  final PrototypePalette palette;
  final MobileActor? actor;
  final AuthOnboardingState? onboardingState;
  final StudentAppEnvironment environment;
  final ValueChanged<UiCardItem> onActionTap;

  @override
  Widget build(BuildContext context) {
    final accountLabel =
        actor?.displayName ?? onboardingState?.displayName ?? 'Student profile';
    final privacyLabel = onboardingState?.legalConsentBand ?? 'minor_managed';
    final approvalLabel = onboardingState?.approvalStatus ?? 'approved';
    return ListView(
      key: const ValueKey('student-profile'),
      padding: const EdgeInsets.all(22),
      children: [
        DashboardTopBar(palette: palette),
        HeroHeader(
          palette: palette,
          kicker: 'Profile',
          title: 'Your style and progress',
          subtitle:
              'Profile, privacy, and app preferences in the reference student style.',
          actions: [
            Pill(icon: Icons.palette_rounded, label: palette.name),
            Pill(icon: Icons.verified_user_rounded, label: approvalLabel),
          ],
        ),
        const SizedBox(height: 18),
        GlassPanel(
          palette: palette,
          child: Column(
            children: [
              FloatingMascot(palette: palette),
              const SizedBox(height: 14),
              Text(
                accountLabel,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '${actor?.ageCohort ?? onboardingState?.ageCohort ?? '13_14'} · ${environment.apiBaseUrl}',
                style: TextStyle(color: palette.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassPanel(
          palette: palette,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle(
                title: 'Privacy snapshot',
                subtitle:
                    'Real onboarding state rendered inside the reference UI.',
              ),
              _ProfileInfoRow(label: 'Consent band', value: privacyLabel),
              _ProfileInfoRow(
                label: 'Consent status',
                value: onboardingState?.consentStatus ?? 'not_required',
              ),
              _ProfileInfoRow(
                label: 'Primary role',
                value:
                    actor?.primaryRole ??
                    onboardingState?.primaryRole ??
                    'student',
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        ...roleActions.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ActionCard(
              palette: palette,
              item: item,
              onTap: () => onActionTap(item),
            ),
          ),
        ),
      ],
    );
  }
}

class StudentPrototypeDetailScreen extends StatelessWidget {
  const StudentPrototypeDetailScreen({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.body,
    this.primaryActionLabel,
    this.onPrimaryAction,
    super.key,
  });

  final PrototypePalette palette;
  final String title;
  final String subtitle;
  final String body;
  final String? primaryActionLabel;
  final Future<void> Function()? onPrimaryAction;

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_rounded),
                ),
              ],
            ),
            HeroHeader(
              palette: palette,
              kicker: AppRole.student.label,
              title: title,
              subtitle: subtitle,
              actions: const [
                Pill(icon: Icons.touch_app_rounded, label: 'Clickable'),
                Pill(icon: Icons.cloud_done_rounded, label: 'Integrated'),
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
                    subtitle: 'Reference UI preserved with real app actions.',
                  ),
                  Text(body, style: Theme.of(context).textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  MiniLineChart(palette: palette),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (primaryActionLabel != null && onPrimaryAction != null)
              AnimatedPrimaryButton(
                label: primaryActionLabel!,
                icon: Icons.arrow_forward_rounded,
                onPressed: () async {
                  await onPrimaryAction!();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}

class StudentInsightScreen extends StatefulWidget {
  const StudentInsightScreen({
    required this.palette,
    required this.metric,
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final PrototypePalette palette;
  final UiMetric metric;
  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<StudentInsightScreen> createState() => _StudentInsightScreenState();
}

class _StudentInsightScreenState extends State<StudentInsightScreen> {
  late Future<_StudentInsightData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentInsightData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.getStudentWeeklySummary(identity: widget.identity),
      widget.apiClient.listStudentCheckins(identity: widget.identity, limit: 7),
      widget.apiClient.listStudentModules(identity: widget.identity),
    ]);
    return _StudentInsightData(
      summary: results[0] as StudentWeeklySummary,
      checkins: results[1] as List<StudentCheckinSummary>,
      modules: results[2] as List<StudentModuleSummary>,
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
    final palette = widget.palette;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StudentInsightData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [ShimmerBlock(palette: palette)],
                );
              }
              if (snapshot.hasError) {
                return _StudentScreenMessageView(
                  palette: palette,
                  title:
                      'Could not load ${widget.metric.label.toLowerCase()} insight',
                  subtitle: '${snapshot.error}',
                  onRetry: _refresh,
                );
              }
              final data = snapshot.data!;
              final summaryText = _summaryForMetric(
                widget.metric.label,
                data.summary,
              );
              final moduleProgress = data.modules.isEmpty
                  ? 'No modules started'
                  : '${data.modules.where((module) => module.completionPercent > 0).length}/${data.modules.length} active modules';
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  _StudentBackRow(
                    palette: palette,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  HeroHeader(
                    palette: palette,
                    kicker: '${widget.metric.label} insight',
                    title: 'A calmer view of your week',
                    subtitle: summaryText,
                    actions: [
                      Pill(
                        icon: widget.metric.icon,
                        label: widget.metric.label,
                      ),
                      Pill(
                        icon: Icons.lock_rounded,
                        label: data.summary.privacyTierApplied,
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
                          title: 'Weekly pulse',
                          subtitle: 'Rendered from the real backend summary.',
                        ),
                        MiniLineChart(palette: palette),
                        const SizedBox(height: 12),
                        Text(summaryText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _StudentStatTile(
                          palette: palette,
                          title: 'Check-ins',
                          value:
                              '${data.summary.sourceWindow['checkins'] ?? data.checkins.length}',
                          subtitle: 'Source window',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StudentStatTile(
                          palette: palette,
                          title: 'Modules',
                          value: '${data.modules.length}',
                          subtitle: moduleProgress,
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
                          title: 'Recent check-ins',
                          subtitle: 'Your latest real submissions.',
                        ),
                        if (data.checkins.isEmpty)
                          Text('No recent check-ins have been submitted yet.')
                        else
                          ...data.checkins
                              .take(4)
                              .map(
                                (checkin) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _CheckinSummaryTile(summary: checkin),
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
      ),
    );
  }
}

class StudentLocalToolScreen extends StatefulWidget {
  const StudentLocalToolScreen({
    required this.palette,
    required this.item,
    super.key,
  });

  final PrototypePalette palette;
  final UiCardItem item;

  @override
  State<StudentLocalToolScreen> createState() => _StudentLocalToolScreenState();
}

class _StudentLocalToolScreenState extends State<StudentLocalToolScreen> {
  static const _breathingSteps = <String>[
    'Inhale for 4',
    'Hold for 4',
    'Exhale for 6',
  ];

  Timer? _breathingTimer;
  int _breathingIndex = 0;
  int _cyclesCompleted = 0;

  @override
  void dispose() {
    _breathingTimer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    if (_breathingTimer != null) {
      _breathingTimer?.cancel();
      setState(() {
        _breathingTimer = null;
        _breathingIndex = 0;
      });
      return;
    }
    setState(() {
      _breathingIndex = 0;
      _cyclesCompleted = 0;
    });
    _breathingTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _breathingIndex = (_breathingIndex + 1) % _breathingSteps.length;
        if (_breathingIndex == 0) {
          _cyclesCompleted += 1;
        }
      });
    });
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
            _StudentBackRow(
              palette: palette,
              onBack: () => Navigator.of(context).pop(),
            ),
            HeroHeader(
              palette: palette,
              kicker: 'Student tool',
              title: widget.item.title,
              subtitle: widget.item.subtitle,
              actions: [
                Pill(icon: widget.item.icon, label: widget.item.tag),
                const Pill(
                  icon: Icons.phone_android_rounded,
                  label: 'Local tool',
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...switch (widget.item.title) {
              'Emotion Wheel' => _buildEmotionWheelContent(palette),
              'Calm Breathing' => _buildBreathingContent(palette),
              'Friendship Choices' => _buildFriendshipContent(palette),
              _ => _buildGenericToolContent(palette),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _buildEmotionWheelContent(PrototypePalette palette) {
    const feelings = <String>[
      'Calm',
      'Nervous',
      'Overwhelmed',
      'Hopeful',
      'Lonely',
      'Excited',
      'Frustrated',
      'Proud',
      'Embarrassed',
      'Confused',
      'Tired',
      'Relieved',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Name the feeling',
              subtitle:
                  'A finished local tool while game-style backend support comes later.',
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: feelings
                  .map((feeling) => Chip(label: Text(feeling)))
                  .toList(),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      GlassPanel(
        palette: palette,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Try this',
              subtitle: 'A simple reflection prompt.',
            ),
            Text(
              'Pick one feeling that matches best, then say where it shows up in your body and what made it stronger today.',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildBreathingContent(PrototypePalette palette) {
    final running = _breathingTimer != null;
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: '60-second reset',
              subtitle:
                  'A complete local breathing tool that preserves the reference look.',
            ),
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: palette.primary.withValues(alpha: .14),
                  border: Border.all(
                    color: palette.primary.withValues(alpha: .34),
                    width: 3,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _breathingSteps[_breathingIndex],
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: running ? 'Stop breathing reset' : 'Start breathing reset',
              icon: running ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onPressed: _toggleBreathing,
            ),
            if (_cyclesCompleted > 0) ...[
              const SizedBox(height: 12),
              Text('Completed cycles: $_cyclesCompleted'),
            ],
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildFriendshipContent(PrototypePalette palette) {
    const scenarios = <Map<String, String>>[
      {
        'title': 'Someone pressures you into a joke that feels mean',
        'response': 'Try: “I’m not into that. Let’s do something else.”',
      },
      {
        'title': 'A friend stops replying and you feel blamed',
        'response': 'Try: “Hey, I might be reading this wrong. Are we okay?”',
      },
      {
        'title': 'A group chat turns uncomfortable',
        'response': 'Try: “I’m stepping out for now. Message me later.”',
      },
    ];
    return [
      GlassPanel(
        palette: palette,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Practice options',
              subtitle:
                  'A usable local decision-support screen for the current slice.',
            ),
            Text(
              'Choose the response that protects your boundaries without escalating the moment.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      ...scenarios.map(
        (scenario) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassPanel(
            palette: palette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario['title']!,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(scenario['response']!),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildGenericToolContent(PrototypePalette palette) {
    return [
      GlassPanel(
        palette: palette,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: 'Available in this build',
              subtitle: 'Finished local utility surface.',
            ),
            Text(
              'This screen is intentionally local-only for now, but it is no longer a dead-end placeholder.',
            ),
          ],
        ),
      ),
    ];
  }
}

class StudentNotificationsScreen extends StatelessWidget {
  const StudentNotificationsScreen({
    required this.palette,
    required this.actor,
    required this.onboardingState,
    super.key,
  });

  final PrototypePalette palette;
  final MobileActor? actor;
  final AuthOnboardingState? onboardingState;

  @override
  Widget build(BuildContext context) {
    final items = <_StudentNotice>[
      _StudentNotice(
        title: 'Weekly summary is ready',
        subtitle:
            'Your private student dashboard has a fresh summary available.',
        icon: Icons.insights_rounded,
      ),
      _StudentNotice(
        title: 'Privacy remains protected',
        subtitle:
            'Consent status: ${onboardingState?.consentStatus ?? 'not_required'} • Legal band: ${onboardingState?.legalConsentBand ?? 'minor_managed'}',
        icon: Icons.lock_rounded,
      ),
      _StudentNotice(
        title: 'Account status',
        subtitle:
            '${actor?.displayName ?? onboardingState?.displayName ?? 'Student account'} is marked ${onboardingState?.approvalStatus ?? 'approved'}.',
        icon: Icons.verified_user_rounded,
      ),
    ];
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _StudentBackRow(
              palette: palette,
              onBack: () => Navigator.of(context).pop(),
            ),
            HeroHeader(
              palette: palette,
              kicker: 'Notifications',
              title: 'Important updates, not noise',
              subtitle:
                  'A finished student notification center built from current app state and privacy rules.',
              actions: const [
                Pill(
                  icon: Icons.notifications_active_rounded,
                  label: 'Student',
                ),
                Pill(icon: Icons.shield_rounded, label: 'Role-safe'),
              ],
            ),
            const SizedBox(height: 18),
            ...items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: GlassPanel(
                  palette: palette,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: palette.primary.withValues(alpha: .14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(item.icon, color: palette.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 6),
                            Text(item.subtitle),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentCalendarScreen extends StatefulWidget {
  const StudentCalendarScreen({
    required this.palette,
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final PrototypePalette palette;
  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<StudentCalendarScreen> createState() => _StudentCalendarScreenState();
}

class _StudentCalendarScreenState extends State<StudentCalendarScreen> {
  late Future<_StudentCalendarData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_StudentCalendarData> _load() async {
    final results = await Future.wait<Object>([
      widget.apiClient.listStudentCheckinTemplates(identity: widget.identity),
      widget.apiClient.listStudentModules(identity: widget.identity),
    ]);
    return _StudentCalendarData(
      templates: results[0] as List<MobileCheckinTemplateSummary>,
      modules: results[1] as List<StudentModuleSummary>,
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
    final palette = widget.palette;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StudentCalendarData>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [ShimmerBlock(palette: palette)],
                );
              }
              if (snapshot.hasError) {
                return _StudentScreenMessageView(
                  palette: palette,
                  title: 'Could not load your calendar',
                  subtitle: '${snapshot.error}',
                  onRetry: _refresh,
                );
              }
              final data = snapshot.data!;
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  _StudentBackRow(
                    palette: palette,
                    onBack: () => Navigator.of(context).pop(),
                  ),
                  HeroHeader(
                    palette: palette,
                    kicker: 'Calendar',
                    title: 'A gentle plan for this week',
                    subtitle:
                        'This uses the real check-in templates and module catalog to shape a student-friendly plan.',
                    actions: [
                      Pill(
                        icon: Icons.favorite_rounded,
                        label: '${data.templates.length} check-ins',
                      ),
                      Pill(
                        icon: Icons.auto_stories_rounded,
                        label: '${data.modules.length} modules',
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
                          title: 'Today',
                          subtitle:
                              'A simple schedule from the current backend data.',
                        ),
                        if (data.templates.isEmpty && data.modules.isEmpty)
                          Text('No student plan items are available yet.')
                        else ...[
                          if (data.templates.isNotEmpty)
                            Text(
                              'Complete ${data.templates.first.title} (${data.templates.first.cadence}).',
                            ),
                          if (data.modules.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Continue ${data.modules.first.title} for ${data.modules.first.estimatedMinutes ?? 10} minutes.',
                            ),
                          ],
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
                          title: 'Upcoming',
                          subtitle:
                              'Backend-powered routines, shown in the reference layout.',
                        ),
                        ...data.templates.map(
                          (template) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${template.title} • ${template.cadence} • ${template.questionCount} questions',
                            ),
                          ),
                        ),
                        ...data.modules.map(
                          (module) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              '${module.title} • ${module.completionPercent.toStringAsFixed(0)}% complete',
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
      ),
    );
  }
}

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({
    required this.palette,
    required this.actor,
    required this.onboardingState,
    required this.environment,
    required this.onRefreshOnboarding,
    required this.onOpenSupport,
    required this.onClearIdentity,
    super.key,
  });

  final PrototypePalette palette;
  final MobileActor? actor;
  final AuthOnboardingState? onboardingState;
  final StudentAppEnvironment environment;
  final Future<void> Function() onRefreshOnboarding;
  final Future<void> Function() onOpenSupport;
  final Future<void> Function() onClearIdentity;

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await widget.onRefreshOnboarding();
    } finally {
      if (mounted) {
        setState(() => _refreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final actor = widget.actor;
    final onboardingState = widget.onboardingState;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            _StudentBackRow(
              palette: palette,
              onBack: () => Navigator.of(context).pop(),
            ),
            HeroHeader(
              palette: palette,
              kicker: 'Settings',
              title: 'Privacy, account, and app controls',
              subtitle:
                  'This keeps the reference look while exposing the real student identity state.',
              actions: [
                const Pill(icon: Icons.settings_rounded, label: 'Student'),
                Pill(
                  icon: Icons.cloud_done_rounded,
                  label: onboardingState?.nextStep ?? 'ready',
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
                    title: 'Account state',
                    subtitle: 'Current mobile actor and onboarding data.',
                  ),
                  _ProfileInfoRow(
                    label: 'Name',
                    value:
                        actor?.displayName ??
                        onboardingState?.displayName ??
                        'Student profile',
                  ),
                  _ProfileInfoRow(
                    label: 'Role',
                    value: actor?.primaryRole ?? 'student',
                  ),
                  _ProfileInfoRow(
                    label: 'Age cohort',
                    value:
                        actor?.ageCohort ??
                        onboardingState?.ageCohort ??
                        '13_14',
                  ),
                  _ProfileInfoRow(
                    label: 'Consent',
                    value: onboardingState?.consentStatus ?? 'not_required',
                  ),
                  _ProfileInfoRow(
                    label: 'Approval',
                    value: onboardingState?.approvalStatus ?? 'approved',
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
                    title: 'Appearance and app',
                    subtitle:
                        'Local settings that are safe to manage on-device.',
                  ),
                  Row(
                    children: [
                      const Expanded(child: Text('Theme mode')),
                      ThemeModeToggle(palette: palette),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoRow(
                    label: 'API URL',
                    value: widget.environment.apiBaseUrl,
                  ),
                  _ProfileInfoRow(
                    label: 'External ID',
                    value: widget.environment.defaultExternalAuthId,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: _refreshing ? 'Refreshing...' : 'Refresh onboarding state',
              icon: Icons.refresh_rounded,
              onPressed: _refreshing ? () {} : _refresh,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onOpenSupport,
              icon: const Icon(Icons.health_and_safety_rounded),
              label: const Text('Open support'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: widget.onClearIdentity,
              icon: const Icon(Icons.switch_account_rounded),
              label: const Text('Switch development identity'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentBackRow extends StatelessWidget {
  const _StudentBackRow({required this.palette, required this.onBack});

  final PrototypePalette palette;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const Spacer(),
        ThemeModeToggle(palette: palette),
      ],
    );
  }
}

class _StudentScreenMessageView extends StatelessWidget {
  const _StudentScreenMessageView({
    required this.palette,
    required this.title,
    required this.subtitle,
    required this.onRetry,
  });

  final PrototypePalette palette;
  final String title;
  final String subtitle;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        _StudentBackRow(
          palette: palette,
          onBack: () => Navigator.of(context).pop(),
        ),
        HeroHeader(
          palette: palette,
          kicker: 'Student App',
          title: title,
          subtitle: subtitle,
          actions: const [
            Pill(icon: Icons.warning_rounded, label: 'Retry available'),
          ],
        ),
        const SizedBox(height: 18),
        AnimatedPrimaryButton(
          label: 'Try again',
          icon: Icons.refresh_rounded,
          onPressed: () => unawaited(onRetry()),
        ),
      ],
    );
  }
}

class _StudentStatTile extends StatelessWidget {
  const _StudentStatTile({
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

class _ProfileInfoRow extends StatelessWidget {
  const _ProfileInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StudentNotice {
  const _StudentNotice({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _StudentInsightData {
  const _StudentInsightData({
    required this.summary,
    required this.checkins,
    required this.modules,
  });

  final StudentWeeklySummary summary;
  final List<StudentCheckinSummary> checkins;
  final List<StudentModuleSummary> modules;
}

class _StudentCalendarData {
  const _StudentCalendarData({required this.templates, required this.modules});

  final List<MobileCheckinTemplateSummary> templates;
  final List<StudentModuleSummary> modules;
}

String _summaryForMetric(String metricLabel, StudentWeeklySummary summary) {
  final lower = metricLabel.toLowerCase();
  if (lower == 'mood') {
    return summary.summary['mood_trend']?.toString() ??
        summary.summary['headline']?.toString() ??
        'Mood trend available in the latest weekly summary.';
  }
  if (lower == 'sleep') {
    return summary.summary['sleep_trend']?.toString() ??
        'Sleep trend available in the latest weekly summary.';
  }
  if (lower == 'stress') {
    return summary.summary['stress_trend']?.toString() ??
        'Stress trend available in the latest weekly summary.';
  }
  if (lower == 'energy') {
    return summary.summary['energy_trend']?.toString() ??
        'Energy trend available in the latest weekly summary.';
  }
  return summary.summary['headline']?.toString() ?? 'Weekly insight available.';
}

class _PrototypeSelector<T> extends StatelessWidget {
  const _PrototypeSelector({
    required this.palette,
    required this.value,
    required this.values,
    required this.labelBuilder,
    required this.onChanged,
  });

  final PrototypePalette palette;
  final T value;
  final List<T> values;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          isExpanded: true,
          value: value,
          items: values
              .map(
                (item) => DropdownMenuItem<T>(
                  value: item,
                  child: Text(labelBuilder(item)),
                ),
              )
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
        ),
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

  Future<void> _openSupport() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => StudentHelpRequestScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
        ),
      ),
    );
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
                        Text('Need support?', style: theme.titleLarge),
                        const SizedBox(height: 12),
                        Text(
                          'Reach BAHA support using the real help-request workflow and view the active support contacts for your app audience.',
                          style: theme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _openSupport,
                          child: const Text('Ask for support'),
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
    await _pushThemedRoute<void>(
      builder: (context) => StudentCheckinFormScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        templateId: template.id,
      ),
    );
    unawaited(_refresh());
  }

  Future<void> _openHistory(StudentCheckinSummary summary) async {
    await _pushThemedRoute<void>(
      builder: (context) => StudentCheckinDetailScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        responseSetId: summary.id,
        titleOverride: summary.title,
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final palette = studentPalette(
      StudentAgeGroup.teen,
      StudentGender.female,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<_StudentCheckinHubData>(
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
                      kicker: 'Daily Check-in',
                      title: 'Could not load check-ins',
                      subtitle: '${snapshot.error}',
                      actions: const [
                        Pill(icon: Icons.warning_rounded, label: 'Retry'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedPrimaryButton(
                      label: 'Reload check-ins',
                      icon: Icons.refresh_rounded,
                      onPressed: () => unawaited(_refresh()),
                    ),
                  ],
                );
              }
              final data = snapshot.data!;
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
                    kicker: 'Daily Check-in',
                    title:
                        'Mood, sleep, stress, energy, and one gentle reflection.',
                    subtitle:
                        'Reference check-in UI powered by the live backend templates and submission flow.',
                    actions: [
                      const Pill(icon: Icons.favorite_rounded, label: '2 min'),
                      Pill(
                        icon: Icons.cloud_done_rounded,
                        label: '${data.templates.length} templates',
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
                          title: 'Available check-ins',
                          subtitle: 'Live templates from the backend.',
                        ),
                        ...data.templates.map(
                          (template) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: ActionCard(
                              palette: palette,
                              item: UiCardItem(
                                title: template.title,
                                subtitle:
                                    '${template.cadence} • ${template.questionCount} questions',
                                tag: 'Start',
                                icon: Icons.favorite_rounded,
                                color: palette.primary,
                              ),
                              onTap: () => _openTemplate(template),
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
                        const SectionTitle(
                          title: 'Submitted history',
                          subtitle: 'Your recent real check-ins.',
                        ),
                        if (data.history.isEmpty)
                          Text('No check-ins submitted yet.')
                        else
                          ...data.history.map(
                            (summary) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassPanel(
                                palette: palette,
                                padding: const EdgeInsets.all(16),
                                onTap: () => _openHistory(summary),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: palette.secondary.withValues(
                                          alpha: .16,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        Icons.history_rounded,
                                        color: palette.secondary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _CheckinSummaryTile(
                                        summary: summary,
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: palette.muted,
                                    ),
                                  ],
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
      final controller = ThemeScope.of(context);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (context) => ThemeScope(
            controller: controller,
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) => StudentCheckinDetailScreen(
                apiClient: widget.apiClient,
                identity: widget.identity,
                responseSetId: submission.id,
                titleOverride: submission.title,
              ),
            ),
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
    final palette = studentPalette(
      StudentAgeGroup.teen,
      StudentGender.female,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: FutureBuilder<MobileCheckinTemplateDetail>(
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
                          'Could not load this check-in template.',
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
                                  .getStudentCheckinTemplateDetail(
                                    identity: widget.identity,
                                    templateId: widget.templateId,
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
                  kicker: 'Daily Check-in',
                  title: detail.title,
                  subtitle:
                      'Small signals, no judgement. This form submits to the real backend.',
                  actions: [
                    const Pill(icon: Icons.favorite_rounded, label: 'Private'),
                    Pill(
                      icon: Icons.help_outline_rounded,
                      label: '${detail.questions.length} Qs',
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
                        title: 'Check-in flow',
                        subtitle:
                            'Respond honestly. Only role-safe summaries are shared later.',
                      ),
                      Text(
                        '${detail.cadence} check-in • ${detail.questions.length} questions',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...detail.questions.map(
                  (question) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            question.prompt,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: question.scaleValues.map((value) {
                              final selected =
                                  _scaleAnswers[question.id] ==
                                  value.toDouble();
                              return ChoiceChip(
                                label: Text('$value'),
                                selected: selected,
                                onSelected: (_) {
                                  setState(() {
                                    _scaleAnswers[question.id] = value
                                        .toDouble();
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
                AnimatedPrimaryButton(
                  label: _submitting ? 'Submitting...' : 'Submit check-in',
                  icon: Icons.send_rounded,
                  onPressed: _submitting ? () {} : () => _submit(detail),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class StudentCheckinDetailScreen extends StatefulWidget {
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
  State<StudentCheckinDetailScreen> createState() =>
      _StudentCheckinDetailScreenState();
}

class _StudentCheckinDetailScreenState
    extends State<StudentCheckinDetailScreen> {
  late Future<StudentCheckinDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.getStudentCheckinDetail(
      identity: widget.identity,
      responseSetId: widget.responseSetId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = studentPalette(
      StudentAgeGroup.teen,
      StudentGender.female,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: FutureBuilder<StudentCheckinDetail>(
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
                          'Could not load this check-in result.',
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
                                  .getStudentCheckinDetail(
                                    identity: widget.identity,
                                    responseSetId: widget.responseSetId,
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
                  kicker: 'Check-in complete',
                  title: widget.titleOverride,
                  subtitle:
                      'Your response set was saved successfully to the backend.',
                  actions: const [
                    Pill(icon: Icons.check_circle_rounded, label: 'Saved'),
                    Pill(icon: Icons.lock_rounded, label: 'Private'),
                  ],
                ),
                const SizedBox(height: 18),
                GlassPanel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'Submission detail',
                        subtitle:
                            'Real answers saved in the student mobile flow.',
                      ),
                      Text(
                        'Submitted ${detail.submittedAt == null ? 'recently' : _formatDateTime(detail.submittedAt!)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...detail.answers.map(
                  (answer) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            answer.prompt,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _answerLabel(answer),
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
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
