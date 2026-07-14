import 'dart:async';
import 'dart:math';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_design_system/baha_design_system.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../app_environment.dart';
import '../prototype/app_theme.dart';
import '../prototype/mock_data.dart';
import '../prototype/prototype_models.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';
import 'student_buddy_screen.dart';
import 'student_help_request_screen.dart';
import 'student_learn_screen.dart';
import 'student_profile_setup_screen.dart';
import 'student_story_world_screen.dart';
import '../wellbeing/student_checkin_logic.dart';
import '../wellbeing/student_profile_logic.dart';

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
  late final ThemeController _themeController;
  late final ConfettiController _confettiController;
  late final StudentWellbeingProfileStore _profileStore;
  int _currentIndex = 0;
  StudentWellbeingProfile? _profile;
  bool _profileLoaded = false;

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController()..load();
    _confettiController = ConfettiController(duration: 900.ms);
    _profileStore = StudentWellbeingProfileStore();
    unawaited(_restoreProfile());
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant StudentReadyScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.actor?.studentMetadata != widget.actor?.studentMetadata) {
      unawaited(_restoreProfile());
    }
  }

  Future<void> _openCheckins() async {
    final profile = await _ensureProfileForAdaptiveCheckins();
    if (profile == null || !mounted) {
      return;
    }
    await _pushRoute(
      builder: (context) => StudentCheckinsScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        profile: profile,
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

  Future<void> _openStoryWorld() async {
    await _pushRoute(
      builder: (context) => StudentStoryWorldScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        palette: _currentPalette,
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
        profile: _profile,
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
        identity: widget.identity,
        onboardingState: widget.onboardingState,
        environment: widget.environment,
        profile: _profile,
        themeController: _themeController,
        onRefreshOnboarding: widget.onRefresh,
        onOpenSupport: _openSupport,
        onEditProfile: _openProfileSetup,
        onClearIdentity: _resetIdentityFromChildRoute,
      ),
    );
  }

  PrototypePalette get _currentPalette => appPaletteForTheme(
    _themeController.colorTheme,
    isDark: _themeController.isDark,
  );

  Future<T?> _pushRoute<T>({required WidgetBuilder builder}) async {
    return Navigator.of(context).push<T>(
      MaterialPageRoute<T>(
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

  Future<void> _restoreProfile() async {
    final actorProfile = _profileFromActor(widget.actor);
    final localProfile = await _profileStore.load(
      widget.identity.externalAuthId,
    );
    final profile = actorProfile ?? localProfile;
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
      _profileLoaded = true;
    });
  }

  Future<StudentWellbeingProfile?> _openProfileSetup() async {
    final result = await _pushRoute<StudentWellbeingProfile>(
      builder: (context) => StudentProfileSetupScreen(
        palette: _currentPalette,
        initialProfile: _profile,
      ),
    );
    if (result == null) {
      return _profile;
    }
    await _profileStore.save(
      externalAuthId: widget.identity.externalAuthId,
      profile: result,
    );
    await _persistProfileToBackend(result);
    if (!mounted) {
      return result;
    }
    setState(() {
      _profile = result;
      _profileLoaded = true;
    });
    return result;
  }

  Future<StudentWellbeingProfile?> _ensureProfileForAdaptiveCheckins() async {
    if (!_profileLoaded) {
      await _restoreProfile();
    }
    if (_profile != null) {
      return _profile;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Finish your one-time onboarding baseline from Home or Settings before starting daily check-ins.',
          ),
        ),
      );
    }
    return null;
  }

  StudentWellbeingProfile? _profileFromActor(MobileActor? actor) {
    final raw = actor?.studentMetadata['wellbeing_profile'];
    if (raw is Map<String, dynamic>) {
      return StudentWellbeingProfile.fromJson(raw);
    }
    if (raw is Map) {
      return StudentWellbeingProfile.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Future<void> _persistProfileToBackend(StudentWellbeingProfile profile) async {
    final actor = widget.actor;
    if (actor == null) {
      return;
    }
    if ((actor.schoolId == null || actor.schoolId!.isEmpty) &&
        (actor.schoolName == null || actor.schoolName!.isEmpty)) {
      return;
    }
    try {
      await widget.apiClient.bootstrapIdentity(
        identity: widget.identity,
        request: AppBootstrapRequest(
          role: AppRequestedRole.student,
          displayName: actor.displayName,
          email: widget.identity.authEmail,
          schoolId: actor.schoolId,
          schoolName: actor.schoolName,
          ageCohort: profile.ageBand,
          legalConsentBand: profile.ageBand == '18_plus' ? 'adult' : 'minor',
          gender: profile.genderIdentity,
          metadata: profile.toBootstrapMetadata(),
        ),
      );
      await widget.onRefresh();
    } catch (_) {
      // Keep local persistence even if the backend metadata refresh fails.
    }
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
      case 'Comet Sequence':
      case 'Calm Breathing':
      case 'Focus Catch':
        unawaited(_openTool(item));
        return;
      case 'Story World':
        unawaited(_openStoryWorld());
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
          final palette = appPaletteForTheme(
            _themeController.colorTheme,
            isDark: _themeController.isDark,
          );
          final pages = <Widget>[
            StudentReferenceHomeTab(
              palette: palette,
              apiClient: widget.apiClient,
              identity: widget.identity,
              actor: widget.actor,
              onboardingState: widget.onboardingState,
              profile: _profile,
              onMetricTap: (metric) => unawaited(_openInsights(metric)),
              onOpenProfileSetup: _openProfileSetup,
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
    required this.profile,
    required this.onMetricTap,
    required this.onOpenProfileSetup,
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
  final StudentWellbeingProfile? profile;
  final ValueChanged<UiMetric> onMetricTap;
  final Future<StudentWellbeingProfile?> Function() onOpenProfileSetup;
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
    final checkins = await widget.apiClient.listStudentCheckins(
      identity: widget.identity,
      limit: 7,
    );
    final details = await Future.wait<StudentCheckinDetail>(
      checkins
          .where((checkin) => checkin.submittedAt != null)
          .take(7)
          .map(
            (checkin) => widget.apiClient.getStudentCheckinDetail(
              identity: widget.identity,
              responseSetId: checkin.id,
            ),
          ),
    );
    final summary = await _loadWeeklySummaryOrFallback(
      apiClient: widget.apiClient,
      identity: widget.identity,
      actor: widget.actor,
      checkinCount: checkins.length,
    );
    final trendPoints = buildTrendPointsFromDetails(details);
    return _StudentDashboardData(
      summary: summary,
      checkins: checkins,
      details: details,
      trendPoints: trendPoints,
    );
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  List<UiMetric> _metricsForData(_StudentDashboardData data) {
    return buildFactorMetrics(
      points: data.trendPoints,
      profile: widget.profile,
    ).map((metric) => metric.toUiMetric()).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = widget.palette;
    final cohortLabel = switch (widget.profile?.ageBand ??
        widget.actor?.ageCohort) {
      '9_12' => 'Age 9-12',
      '13_14' => 'Age 13-14',
      '15_18' => 'Age 15-18',
      '18_plus' => 'Age 18+',
      _ => 'Student',
    };
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
                  kicker: cohortLabel,
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
          final metrics = _metricsForData(data);
          final hasTrendData = data.trendPoints.isNotEmpty;
          final labels = chartLabels(data.trendPoints);
          final overallValues = overallChartValues(data.trendPoints);
          final dailyHeadline = dailyStateHeadline(data.trendPoints);
          final flags = riskFlags(
            points: data.trendPoints,
            profile: widget.profile,
          );
          final dashboardCallouts = _dashboardCallouts(
            summary: data.summary,
            points: data.trendPoints,
            profile: widget.profile,
          );
          return ListView(
            key: const ValueKey('student-home'),
            padding: const EdgeInsets.all(22),
            children: [
              DashboardTopBar(palette: palette),
              HeroHeader(
                palette: palette,
                kicker: cohortLabel,
                title: 'Your private wellness world',
                subtitle: palette.story,
                actions: [
                  Pill(icon: palette.heroIcon, label: palette.name),
                  const Pill(icon: Icons.lock_rounded, label: 'Private'),
                ],
              ),
              const SizedBox(height: 18),
              if (widget.profile == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Finish your one-time profile',
                          subtitle:
                              'This keeps daily check-ins short and makes follow-up questions more relevant.',
                        ),
                        const SizedBox(height: 8),
                        AnimatedPrimaryButton(
                          label: 'Set up wellbeing profile',
                          icon: Icons.playlist_add_check_rounded,
                          onPressed: () =>
                              unawaited(widget.onOpenProfileSetup()),
                        ),
                      ],
                    ),
                  ),
                ),
              const SectionTitle(
                title: 'Today',
                subtitle: 'Tiny signals, no judgement.',
              ),
              if (!hasTrendData)
                GlassPanel(
                  palette: palette,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                        title: 'No check-in entries yet',
                        subtitle:
                            'Your trend cards and graphs will appear after you submit your first daily check-in.',
                      ),
                      Text(
                        'Once you add a few entries, BAHA will start showing real patterns for sleep, mood, stress, energy, body, and connection.',
                      ),
                    ],
                  ),
                )
              else ...[
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
                      SectionTitle(
                        title: 'Tracked factors',
                        subtitle: dailyHeadline,
                      ),
                      MiniLineChart(
                        palette: palette,
                        values: overallValues,
                        labels: labels,
                        lineColor: palette.primary,
                      ),
                      if (flags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: flags
                              .map(
                                (flag) => Pill(
                                  icon: Icons.insights_rounded,
                                  label: flag,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
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
                    if (widget.profile != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Profile focus: ${widget.profile!.checkinFocusLabel} • Support style: ${widget.profile!.supportPreferenceLabel}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Recent check-ins: ${data.checkins.length} • Privacy tier: ${data.summary.privacyTierApplied}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: palette.muted),
                    ),
                    if (dashboardCallouts.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'This week at a glance',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      ...dashboardCallouts.map(
                        (callout) => _ProfileInfoRow(
                          label: callout.label,
                          value: callout.value,
                        ),
                      ),
                    ],
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
                    onPressed: () => unawaited(widget.onOpenProfileSetup()),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      widget.profile == null
                          ? 'Set up profile'
                          : 'Edit profile',
                    ),
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
    required this.profile,
    super.key,
  });

  final PrototypePalette palette;
  final UiMetric metric;
  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final StudentWellbeingProfile? profile;

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
    final checkins = await widget.apiClient.listStudentCheckins(
      identity: widget.identity,
      limit: 7,
    );
    final modules = await widget.apiClient.listStudentModules(
      identity: widget.identity,
    );
    final details = await Future.wait<StudentCheckinDetail>(
      checkins
          .where((checkin) => checkin.submittedAt != null)
          .take(7)
          .map(
            (checkin) => widget.apiClient.getStudentCheckinDetail(
              identity: widget.identity,
              responseSetId: checkin.id,
            ),
          ),
    );
    final summary = await _loadWeeklySummaryOrFallback(
      apiClient: widget.apiClient,
      identity: widget.identity,
      actor: null,
      checkinCount: checkins.length,
    );
    final trendPoints = buildTrendPointsFromDetails(details);
    return _StudentInsightData(
      summary: summary,
      checkins: checkins,
      modules: modules,
      details: details,
      trendPoints: trendPoints,
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
              final factorKey = _factorKeyForMetricLabel(widget.metric.label);
              final summaryText = _summaryForMetric(
                factorKey,
                data.summary,
                data.trendPoints,
                widget.profile,
              );
              final moduleProgress = data.modules.isEmpty
                  ? 'No modules started'
                  : '${data.modules.where((module) => module.completionPercent > 0).length}/${data.modules.length} active modules';
              final chartValues = chartValuesForFactor(
                data.trendPoints,
                factorKey,
              );
              final labels = chartLabels(data.trendPoints);
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
                          subtitle:
                              'Rendered from real check-ins using the factors we actually track.',
                        ),
                        MiniLineChart(
                          palette: palette,
                          values: chartValues,
                          labels: labels,
                          lineColor: widget.metric.color,
                        ),
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
  static const _breathingPhases = <_BreathingPhase>[
    _BreathingPhase(label: 'Inhale', durationSeconds: 4, scale: 1.14),
    _BreathingPhase(label: 'Hold', durationSeconds: 4, scale: 1.14),
    _BreathingPhase(label: 'Exhale', durationSeconds: 6, scale: 0.84),
  ];

  final Random _random = Random();

  Timer? _breathingTimer;
  bool _breathingRunning = false;
  int _breathingIndex = 0;
  int _breathingPhaseSecondsLeft = _breathingPhases[0].durationSeconds;
  int _breathingTotalSecondsLeft = 60;
  int _cyclesCompleted = 0;

  int _sequenceToken = 0;
  List<int> _sequencePattern = const [];
  List<int> _sequenceInput = const [];
  bool _sequenceStarted = false;
  bool _sequencePlayingBack = false;
  int? _sequenceHighlighted;
  int _sequenceLevel = 0;
  int _sequenceBest = 0;
  String _sequenceStatus = 'Watch the pattern, then tap the same order.';

  Timer? _focusCountdownTimer;
  bool _focusRunning = false;
  int _focusTimeLeft = 20;
  int _focusScore = 0;
  int _focusBest = 0;
  int _focusJumps = 0;
  double _focusTargetX = .18;
  double _focusTargetY = .22;
  String _focusStatus = 'Tap the moving comet before it jumps again.';

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _focusCountdownTimer?.cancel();
    super.dispose();
  }

  void _toggleBreathing() {
    if (_breathingRunning) {
      _stopBreathing();
      return;
    }
    _startBreathing();
  }

  void _startBreathing() {
    _breathingTimer?.cancel();
    setState(() {
      _breathingRunning = true;
      _breathingIndex = 0;
      _breathingPhaseSecondsLeft = _breathingPhases[0].durationSeconds;
      _breathingTotalSecondsLeft = 60;
      _cyclesCompleted = 0;
    });
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_breathingTotalSecondsLeft <= 1) {
        _stopBreathing(completed: true);
        return;
      }
      var nextPhaseSecondsLeft = _breathingPhaseSecondsLeft - 1;
      var nextPhaseIndex = _breathingIndex;
      var nextCyclesCompleted = _cyclesCompleted;
      if (nextPhaseSecondsLeft <= 0) {
        nextPhaseIndex = (_breathingIndex + 1) % _breathingPhases.length;
        nextPhaseSecondsLeft = _breathingPhases[nextPhaseIndex].durationSeconds;
        if (nextPhaseIndex == 0) {
          nextCyclesCompleted += 1;
        }
      }
      setState(() {
        _breathingRunning = true;
        _breathingIndex = nextPhaseIndex;
        _breathingPhaseSecondsLeft = nextPhaseSecondsLeft;
        _breathingTotalSecondsLeft -= 1;
        _cyclesCompleted = nextCyclesCompleted;
      });
    });
  }

  void _stopBreathing({bool completed = false}) {
    _breathingTimer?.cancel();
    _breathingTimer = null;
    setState(() {
      _breathingRunning = false;
      _breathingIndex = 0;
      _breathingPhaseSecondsLeft = _breathingPhases[0].durationSeconds;
      _breathingTotalSecondsLeft = completed ? 0 : 60;
    });
  }

  Future<void> _startSequenceGame() async {
    final token = ++_sequenceToken;
    setState(() {
      _sequencePattern = const [];
      _sequenceInput = const [];
      _sequenceStarted = true;
      _sequencePlayingBack = false;
      _sequenceHighlighted = null;
      _sequenceLevel = 0;
      _sequenceStatus = 'Watch closely. The pattern gets longer each round.';
    });
    await _playNextSequenceRound(token);
  }

  Future<void> _playNextSequenceRound(int token) async {
    if (!mounted || token != _sequenceToken) {
      return;
    }
    final nextPattern = [..._sequencePattern, _random.nextInt(4)];
    setState(() {
      _sequencePattern = nextPattern;
      _sequenceInput = const [];
      _sequencePlayingBack = true;
      _sequenceHighlighted = null;
      _sequenceStatus = 'Watch the lights, then repeat them.';
    });
    await Future<void>.delayed(const Duration(milliseconds: 320));
    for (final tileIndex in nextPattern) {
      if (!mounted || token != _sequenceToken) {
        return;
      }
      setState(() => _sequenceHighlighted = tileIndex);
      await Future<void>.delayed(const Duration(milliseconds: 460));
      if (!mounted || token != _sequenceToken) {
        return;
      }
      setState(() => _sequenceHighlighted = null);
      await Future<void>.delayed(const Duration(milliseconds: 180));
    }
    if (!mounted || token != _sequenceToken) {
      return;
    }
    setState(() {
      _sequencePlayingBack = false;
      _sequenceLevel = nextPattern.length;
      _sequenceStatus = 'Your turn. Tap the same order.';
    });
  }

  void _handleSequenceTap(int tileIndex) {
    if (!_sequenceStarted || _sequencePlayingBack) {
      return;
    }
    final expectedIndex = _sequencePattern[_sequenceInput.length];
    if (tileIndex != expectedIndex) {
      setState(() {
        _sequenceStarted = false;
        _sequencePlayingBack = false;
        _sequenceHighlighted = tileIndex;
        _sequenceBest = max(_sequenceBest, _sequenceLevel);
        _sequenceStatus =
            'Almost. You reached round $_sequenceLevel. Tap play again to retry.';
      });
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) {
          return;
        }
        setState(() => _sequenceHighlighted = null);
      });
      return;
    }
    final nextInput = [..._sequenceInput, tileIndex];
    setState(() {
      _sequenceInput = nextInput;
      _sequenceHighlighted = tileIndex;
      _sequenceStatus = 'Nice. Keep going.';
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) {
        return;
      }
      setState(() => _sequenceHighlighted = null);
    });
    if (nextInput.length == _sequencePattern.length) {
      setState(() {
        _sequenceBest = max(_sequenceBest, _sequencePattern.length);
        _sequenceStatus = 'Round clear. Next pattern loading...';
      });
      final token = _sequenceToken;
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 700), () async {
          if (!mounted || token != _sequenceToken || !_sequenceStarted) {
            return;
          }
          await _playNextSequenceRound(token);
        }),
      );
    }
  }

  void _toggleFocusGame() {
    if (_focusRunning) {
      _stopFocusGame();
      return;
    }
    _startFocusGame();
  }

  void _startFocusGame() {
    _focusCountdownTimer?.cancel();
    setState(() {
      _focusRunning = true;
      _focusTimeLeft = 20;
      _focusScore = 0;
      _focusJumps = 0;
      _focusStatus = 'Catch the comet before it jumps away.';
    });
    _moveFocusTarget(incrementJumpCount: false);
    _focusCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_focusTimeLeft <= 1) {
        _stopFocusGame(completed: true);
        return;
      }
      setState(() {
        _focusTimeLeft -= 1;
        _focusStatus = 'Keep tracking. Fast eyes, calm hands.';
      });
      _moveFocusTarget();
    });
  }

  void _stopFocusGame({bool completed = false}) {
    _focusCountdownTimer?.cancel();
    _focusCountdownTimer = null;
    setState(() {
      _focusRunning = false;
      _focusBest = max(_focusBest, _focusScore);
      _focusStatus = completed
          ? 'Round complete. You caught $_focusScore comets.'
          : 'Round paused. Start again when you are ready.';
    });
  }

  void _moveFocusTarget({bool incrementJumpCount = true}) {
    final nextX = .08 + (_random.nextDouble() * .72);
    final nextY = .08 + (_random.nextDouble() * .66);
    if (!mounted) {
      return;
    }
    setState(() {
      _focusTargetX = nextX;
      _focusTargetY = nextY;
      if (incrementJumpCount) {
        _focusJumps += 1;
      }
    });
  }

  void _handleFocusCatch() {
    if (!_focusRunning) {
      return;
    }
    setState(() {
      _focusScore += 1;
      _focusBest = max(_focusBest, _focusScore);
      _focusStatus = switch (_focusScore % 4) {
        0 => 'Great rhythm. Keep your eyes on the next jump.',
        1 => 'Nice catch.',
        2 => 'Quick hands.',
        _ => 'Locked in. Stay steady.',
      };
    });
    _moveFocusTarget(incrementJumpCount: false);
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
              'Comet Sequence' => _buildSequenceContent(palette),
              'Calm Breathing' => _buildBreathingContent(palette),
              'Focus Catch' => _buildFocusCatchContent(palette),
              _ => _buildGenericToolContent(palette),
            },
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSequenceContent(PrototypePalette palette) {
    final tiles = <Color>[
      palette.primary,
      palette.secondary,
      const Color(0xFFF97316),
      const Color(0xFF14B8A6),
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Watch. Remember. Repeat.',
              subtitle:
                  'A short sequence-memory game inspired by classic repeat-the-pattern play, rebuilt to match the BAHA visual shell.',
            ),
            Text(_sequenceStatus),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LocalToolStatCard(
                    palette: palette,
                    icon: Icons.layers_rounded,
                    label: 'Round',
                    value: _sequenceLevel.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LocalToolStatCard(
                    palette: palette,
                    icon: Icons.workspace_premium_rounded,
                    label: 'Best',
                    value: _sequenceBest.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tiles.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final highlighted = _sequenceHighlighted == index;
                return GestureDetector(
                  onTap: () => _handleSequenceTap(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(26),
                      color: tiles[index].withValues(
                        alpha: highlighted ? .92 : .22,
                      ),
                      border: Border.all(
                        color: highlighted
                            ? Colors.white.withValues(alpha: .92)
                            : tiles[index].withValues(alpha: .58),
                        width: highlighted ? 3 : 1.5,
                      ),
                      boxShadow: highlighted
                          ? [
                              BoxShadow(
                                color: tiles[index].withValues(alpha: .36),
                                blurRadius: 18,
                                spreadRadius: 1,
                              ),
                            ]
                          : const [],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: highlighted ? 38 : 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 18),
            AnimatedPrimaryButton(
              label: _sequenceStarted ? 'Restart sequence' : 'Start sequence',
              icon: _sequenceStarted
                  ? Icons.refresh_rounded
                  : Icons.play_arrow_rounded,
              onPressed: _startSequenceGame,
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
              title: 'Why this fits BAHA',
              subtitle: 'A focused mini-game, not a clinical claim.',
            ),
            Text(
              'It gives students a short, replayable way to practice visual attention, short-term recall, and steady pacing without turning the app into a generic arcade.',
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildBreathingContent(PrototypePalette palette) {
    final running = _breathingRunning;
    final phase = _breathingPhases[_breathingIndex];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: '60-second reset',
              subtitle:
                  'A full local breathing exercise with animated pacing and a real countdown.',
            ),
            Center(
              child: AnimatedScale(
                scale: running ? phase.scale : 1,
                duration: Duration(seconds: phase.durationSeconds),
                curve: running && _breathingIndex == 2
                    ? Curves.easeInOutCubicEmphasized
                    : Curves.easeInOut,
                child: Container(
                  width: 188,
                  height: 188,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        palette.primary.withValues(alpha: .18),
                        palette.secondary.withValues(alpha: .22),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: palette.primary.withValues(alpha: .36),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: palette.primary.withValues(alpha: .22),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        phase.label,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        running
                            ? '${_breathingPhaseSecondsLeft}s in this phase'
                            : 'Tap start to begin',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            LinearProgressIndicator(
              value: running ? _breathingTotalSecondsLeft / 60 : 0,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: palette.primary.withValues(alpha: .12),
            ),
            const SizedBox(height: 12),
            Text(
              running
                  ? '$_breathingTotalSecondsLeft seconds left'
                  : _breathingTotalSecondsLeft == 0
                  ? 'Session complete'
                  : 'Use this before check-ins, support, or sleep modules.',
              style: Theme.of(context).textTheme.bodyMedium,
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

  List<Widget> _buildFocusCatchContent(PrototypePalette palette) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Track. Tap. Reset.',
              subtitle:
                  'A quick hand-eye coordination game inspired by simple mobile tap-and-track loops.',
            ),
            Text(_focusStatus),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _LocalToolStatCard(
                    palette: palette,
                    icon: Icons.timer_rounded,
                    label: 'Time',
                    value: '${_focusTimeLeft}s',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LocalToolStatCard(
                    palette: palette,
                    icon: Icons.bolt_rounded,
                    label: 'Score',
                    value: _focusScore.toString(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _LocalToolStatCard(
                    palette: palette,
                    icon: Icons.rocket_launch_rounded,
                    label: 'Best',
                    value: _focusBest.toString(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final fieldWidth = constraints.maxWidth;
                final targetSize = 66.0;
                final usableWidth = max(0.0, fieldWidth - targetSize);
                final usableHeight = 280.0 - targetSize;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Container(
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          palette.surface.withValues(alpha: .72),
                          palette.primary.withValues(alpha: .09),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: palette.primary.withValues(alpha: .16),
                      ),
                    ),
                    child: Stack(
                      children: [
                        for (final dot in const [
                          (18.0, 28.0),
                          (100.0, 48.0),
                          (180.0, 90.0),
                          (54.0, 170.0),
                          (220.0, 220.0),
                        ])
                          Positioned(
                            left: dot.$1,
                            top: dot.$2,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: .28),
                              ),
                            ),
                          ),
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          left: _focusTargetX * usableWidth,
                          top: _focusTargetY * usableHeight,
                          child: GestureDetector(
                            onTap: _handleFocusCatch,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: targetSize,
                              height: targetSize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [palette.primary, palette.secondary],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: palette.primary.withValues(
                                      alpha: .34,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.travel_explore_rounded,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
            AnimatedPrimaryButton(
              label: _focusRunning ? 'Stop focus round' : 'Start focus round',
              icon: _focusRunning
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
              onPressed: _toggleFocusGame,
            ),
            const SizedBox(height: 12),
            Text('Target jumps: $_focusJumps'),
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
              title: 'Why this fits BAHA',
              subtitle: 'Useful, quick, and easy to explain in a demo.',
            ),
            Text(
              'This gives the app a simple visual-tracking and touch-response loop without drifting into violent or random arcade mechanics.',
            ),
          ],
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

class _BreathingPhase {
  const _BreathingPhase({
    required this.label,
    required this.durationSeconds,
    required this.scale,
  });

  final String label;
  final int durationSeconds;
  final double scale;
}

class _LocalToolStatCard extends StatelessWidget {
  const _LocalToolStatCard({
    required this.palette,
    required this.icon,
    required this.label,
    required this.value,
  });

  final PrototypePalette palette;
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: palette.primary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.primary.withValues(alpha: .14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.primary, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
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
    required this.identity,
    required this.onboardingState,
    required this.environment,
    required this.profile,
    required this.themeController,
    required this.onRefreshOnboarding,
    required this.onOpenSupport,
    required this.onEditProfile,
    required this.onClearIdentity,
    super.key,
  });

  final PrototypePalette palette;
  final MobileActor? actor;
  final DevelopmentIdentity identity;
  final AuthOnboardingState? onboardingState;
  final StudentAppEnvironment environment;
  final StudentWellbeingProfile? profile;
  final ThemeController themeController;
  final Future<void> Function() onRefreshOnboarding;
  final Future<void> Function() onOpenSupport;
  final Future<StudentWellbeingProfile?> Function() onEditProfile;
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
                  if (widget.profile != null) ...[
                    _ProfileInfoRow(
                      label: 'Focus',
                      value: widget.profile!.checkinFocusLabel,
                    ),
                    _ProfileInfoRow(
                      label: 'Support',
                      value: widget.profile!.supportPreferenceLabel,
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
                  Text(
                    'Accent palette',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AppColorTheme.values.map((theme) {
                      return ChoiceChip(
                        label: Text(theme.label),
                        selected: widget.themeController.colorTheme == theme,
                        selectedColor: palette.primary.withValues(alpha: .18),
                        onSelected: (_) {
                          unawaited(
                            widget.themeController.setColorTheme(theme),
                          );
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  _ProfileInfoRow(
                    label: 'API URL',
                    value: widget.environment.apiBaseUrl,
                  ),
                  _ProfileInfoRow(
                    label: 'External ID',
                    value: widget.identity.externalAuthId,
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
              onPressed: () => unawaited(widget.onEditProfile()),
              icon: const Icon(Icons.tune_rounded),
              label: Text(
                widget.profile == null
                    ? 'Set up wellbeing profile'
                    : 'Edit wellbeing profile',
              ),
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
    required this.details,
    required this.trendPoints,
  });

  final StudentWeeklySummary summary;
  final List<StudentCheckinSummary> checkins;
  final List<StudentModuleSummary> modules;
  final List<StudentCheckinDetail> details;
  final List<WellbeingTrendPoint> trendPoints;
}

class _DashboardCallout {
  const _DashboardCallout({required this.label, required this.value});

  final String label;
  final String value;
}

class _StudentCalendarData {
  const _StudentCalendarData({required this.templates, required this.modules});

  final List<MobileCheckinTemplateSummary> templates;
  final List<StudentModuleSummary> modules;
}

List<_DashboardCallout> _dashboardCallouts({
  required StudentWeeklySummary summary,
  required List<WellbeingTrendPoint> points,
  required StudentWellbeingProfile? profile,
}) {
  final payload = summary.summary;
  final callouts = <_DashboardCallout>[];
  final weekStory = payload['week_story']?.toString().trim();
  final bestProgress = payload['best_progress']?.toString().trim();
  final watchArea = payload['watch_area']?.toString().trim();
  final supportNudge = payload['support_nudge']?.toString().trim();

  if (weekStory != null && weekStory.isNotEmpty) {
    callouts.add(_DashboardCallout(label: 'Story', value: weekStory));
  }
  if (bestProgress != null && bestProgress.isNotEmpty) {
    callouts.add(_DashboardCallout(label: 'Best sign', value: bestProgress));
  } else {
    final derived = _derivedImprovement(points);
    if (derived != null) {
      callouts.add(_DashboardCallout(label: 'Best sign', value: derived));
    }
  }
  if (watchArea != null && watchArea.isNotEmpty) {
    callouts.add(_DashboardCallout(label: 'Watch area', value: watchArea));
  } else {
    final derived = _derivedWatchArea(points, profile);
    if (derived != null) {
      callouts.add(_DashboardCallout(label: 'Watch area', value: derived));
    }
  }
  if (supportNudge != null && supportNudge.isNotEmpty) {
    callouts.add(
      _DashboardCallout(label: 'BAHA suggests', value: supportNudge),
    );
  }
  return callouts.take(4).toList();
}

String? _derivedImprovement(List<WellbeingTrendPoint> points) {
  if (points.length < 2) {
    return null;
  }
  final first = points.first;
  final last = points.last;
  String? bestFactor;
  double bestDelta = 0;
  for (final factorKey in const [
    'sleep',
    'energy',
    'mood',
    'stress',
    'physical_wellbeing',
    'connectedness',
  ]) {
    final start = first.factorScores[factorKey];
    final end = last.factorScores[factorKey];
    if (start == null || end == null) {
      continue;
    }
    final improvement = start - end;
    if (improvement > bestDelta) {
      bestDelta = improvement;
      bestFactor = factorKey;
    }
  }
  if (bestFactor == null || bestDelta < 0.5) {
    return null;
  }
  return '${_factorLabel(bestFactor)} improved most across recent check-ins.';
}

String? _derivedWatchArea(
  List<WellbeingTrendPoint> points,
  StudentWellbeingProfile? profile,
) {
  if (points.isEmpty) {
    return null;
  }
  final latest = points.last;
  MapEntry<String, double>? highest;
  for (final entry in latest.factorScores.entries) {
    if (highest == null || entry.value > highest.value) {
      highest = entry;
    }
  }
  if (highest == null) {
    return null;
  }
  if (highest.value < 2) {
    return 'No repeated high-strain pattern stands out right now.';
  }
  final previousValue = points.length > 1
      ? points[points.length - 2].factorScores[highest.key]
      : null;
  final delta = previousValue == null ? 0 : highest.value - previousValue;
  final severity = highest.value >= 3
      ? 'high'
      : highest.value >= 2
      ? 'moderate'
      : 'steady';
  final direction = delta >= 0.35
      ? 'worsening'
      : delta <= -0.35
      ? 'improving'
      : 'steady';
  final label = _factorLabel(highest.key);
  if (highest.key == 'sleep' &&
      profile?.profileTags.contains('sleep_vulnerable') == true) {
    return '$label looks $severity and $direction against this student\'s sleep-sensitive baseline.';
  }
  if (highest.key == 'stress' &&
      profile?.profileTags.contains('school_pressure_driven') == true) {
    return '$label looks $severity, with school pressure likely to matter most.';
  }
  return '$label looks $severity and $direction across recent check-ins.';
}

String _factorLabel(String factorKey) {
  switch (factorKey) {
    case 'sleep':
      return 'Sleep';
    case 'energy':
      return 'Energy';
    case 'mood':
      return 'Mood';
    case 'stress':
      return 'Stress';
    case 'physical_wellbeing':
      return 'Body';
    case 'connectedness':
      return 'Connection';
    default:
      return 'Wellbeing';
  }
}

String _summaryForMetric(
  String factorKey,
  StudentWeeklySummary summary,
  List<WellbeingTrendPoint> points,
  StudentWellbeingProfile? profile,
) {
  switch (factorKey) {
    case 'mood':
      return summary.summary['mood_trend']?.toString() ??
          buildFactorMetrics(
            points: points,
            profile: profile,
          ).firstWhere((metric) => metric.factorKey == 'mood').detail;
    case 'sleep':
      return summary.summary['sleep_trend']?.toString() ??
          buildFactorMetrics(
            points: points,
            profile: profile,
          ).firstWhere((metric) => metric.factorKey == 'sleep').detail;
    case 'stress':
      return summary.summary['stress_trend']?.toString() ??
          buildFactorMetrics(
            points: points,
            profile: profile,
          ).firstWhere((metric) => metric.factorKey == 'stress').detail;
    case 'energy':
      return summary.summary['energy_trend']?.toString() ??
          buildFactorMetrics(
            points: points,
            profile: profile,
          ).firstWhere((metric) => metric.factorKey == 'energy').detail;
    case 'physical_wellbeing':
      return summary.summary['physical_trend']?.toString() ??
          buildFactorMetrics(points: points, profile: profile)
              .firstWhere((metric) => metric.factorKey == 'physical_wellbeing')
              .detail;
    case 'connectedness':
      return summary.summary['connectedness_trend']?.toString() ??
          buildFactorMetrics(
            points: points,
            profile: profile,
          ).firstWhere((metric) => metric.factorKey == 'connectedness').detail;
    default:
      return summary.summary['headline']?.toString() ??
          'Weekly insight available.';
  }
}

String _factorKeyForMetricLabel(String label) {
  switch (label.toLowerCase()) {
    case 'sleep':
      return 'sleep';
    case 'energy':
      return 'energy';
    case 'stress':
      return 'stress';
    case 'body':
      return 'physical_wellbeing';
    case 'connection':
      return 'connectedness';
    case 'mood':
    default:
      return 'mood';
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
    final checkins = await widget.apiClient.listStudentCheckins(
      identity: widget.identity,
      limit: 5,
    );
    final details = await Future.wait<StudentCheckinDetail>(
      checkins
          .where((checkin) => checkin.submittedAt != null)
          .take(5)
          .map(
            (checkin) => widget.apiClient.getStudentCheckinDetail(
              identity: widget.identity,
              responseSetId: checkin.id,
            ),
          ),
    );
    final summary = await _loadWeeklySummaryOrFallback(
      apiClient: widget.apiClient,
      identity: widget.identity,
      actor: widget.actor,
      checkinCount: checkins.length,
    );
    return _StudentDashboardData(
      summary: summary,
      checkins: checkins,
      details: details,
      trendPoints: buildTrendPointsFromDetails(details),
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
    required this.profile,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final StudentWellbeingProfile profile;

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
        profile: widget.profile,
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
                    title: 'Sleep, mood, stress, energy, body, and connection.',
                    subtitle:
                        'Adaptive check-ins powered by the live backend template and your saved profile.',
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
                          subtitle:
                              'Live templates from the backend. Follow-up questions appear only when relevant.',
                        ),
                        if (data.templates.isEmpty)
                          Text(
                            'No check-in templates are available for this account yet. Pull to refresh after the backend template setup is complete.',
                          )
                        else
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
    required this.profile,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String templateId;
  final StudentWellbeingProfile profile;

  @override
  State<StudentCheckinFormScreen> createState() =>
      _StudentCheckinFormScreenState();
}

class _StudentCheckinFormScreenState extends State<StudentCheckinFormScreen> {
  late Future<MobileCheckinTemplateDetail> _future;
  final Map<String, String> _selectedChoices = <String, String>{};
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
      final visibleQuestions = _visibleQuestions(detail);
      final answers = visibleQuestions
          .where(
            (question) => _selectedChoices.containsKey(question.questionKey),
          )
          .map((question) {
            final choiceKey = _selectedChoices[question.questionKey]!;
            final choice = choicesForQuestion(
              question,
              widget.profile,
            ).firstWhere((item) => item.key == choiceKey);
            return buildSubmissionAnswer(question: question, choice: choice);
          })
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

  List<MobileCheckinQuestion> _visibleQuestions(
    MobileCheckinTemplateDetail detail,
  ) {
    final visible = <MobileCheckinQuestion>[];
    for (final question in detail.questions) {
      if (isQuestionVisible(
        question: question,
        selectedAnswers: _selectedChoices,
        profile: widget.profile,
      )) {
        visible.add(question);
      }
    }
    return visible;
  }

  void _pruneHiddenAnswers(MobileCheckinTemplateDetail detail) {
    final visibleKeys = _visibleQuestions(
      detail,
    ).map((question) => question.questionKey).toSet();
    _selectedChoices.removeWhere((key, _) => !visibleKeys.contains(key));
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
            final visibleQuestions = _visibleQuestions(detail);
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
                      'Six core signals, then only the follow-up questions that actually matter today.',
                  actions: [
                    const Pill(icon: Icons.favorite_rounded, label: 'Private'),
                    Pill(
                      icon: Icons.help_outline_rounded,
                      label: '${visibleQuestions.length} Qs today',
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
                            'Respond honestly. BAHA keeps the core pulse short and uses your profile only where it improves relevance.',
                      ),
                      Text(
                        '${detail.cadence} check-in • ${detail.questions.where((question) => question.metadata['is_core'] == true).length} core questions',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                ...visibleQuestions.map(
                  (question) => Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            personalizedPromptForQuestion(
                              question,
                              widget.profile,
                            ),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                choicesForQuestion(
                                  question,
                                  widget.profile,
                                ).map((choice) {
                                  final selected =
                                      _selectedChoices[question.questionKey] ==
                                      choice.key;
                                  return ChoiceChip(
                                    label: Text(choice.label),
                                    selected: selected,
                                    selectedColor: palette.primary.withValues(
                                      alpha: .22,
                                    ),
                                    onSelected: (_) {
                                      setState(() {
                                        _selectedChoices[question.questionKey] =
                                            choice.key;
                                        _pruneHiddenAnswers(detail);
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
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
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
            final trendPoint = buildTrendPointsFromDetails([detail]).single;
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
                  subtitle: dailyStateHeadline([trendPoint]),
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
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: riskFlags(points: [trendPoint], profile: null)
                            .map(
                              (flag) => Pill(
                                icon: Icons.insights_rounded,
                                label: flag,
                              ),
                            )
                            .toList(),
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
                            answerDisplayLabel(answer),
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
  const _StudentDashboardData({
    required this.summary,
    required this.checkins,
    required this.details,
    required this.trendPoints,
  });

  final StudentWeeklySummary summary;
  final List<StudentCheckinSummary> checkins;
  final List<StudentCheckinDetail> details;
  final List<WellbeingTrendPoint> trendPoints;
}

class _StudentCheckinHubData {
  const _StudentCheckinHubData({
    required this.templates,
    required this.history,
  });

  final List<MobileCheckinTemplateSummary> templates;
  final List<StudentCheckinSummary> history;
}

Future<StudentWeeklySummary> _loadWeeklySummaryOrFallback({
  required BahaApiClient apiClient,
  required DevelopmentIdentity identity,
  required MobileActor? actor,
  required int checkinCount,
}) async {
  try {
    return await apiClient.getStudentWeeklySummary(identity: identity);
  } on BahaApiException catch (error) {
    if (error.statusCode != 404) {
      rethrow;
    }
    return _buildEmptyWeeklySummary(actor: actor, checkinCount: checkinCount);
  }
}

StudentWeeklySummary _buildEmptyWeeklySummary({
  required MobileActor? actor,
  required int checkinCount,
}) {
  final now = DateTime.now();
  final weekStart = DateTime(
    now.year,
    now.month,
    now.day,
  ).subtract(Duration(days: now.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));
  return StudentWeeklySummary(
    id: 'local-empty-summary-${actor?.studentProfileId ?? 'student'}',
    studentProfileId: actor?.studentProfileId ?? '',
    weekStart: weekStart,
    weekEnd: weekEnd,
    privacyTierApplied: 'private',
    summaryStatus: 'not_started',
    summary: <String, dynamic>{
      'headline': checkinCount == 0
          ? 'Complete your first daily check-in to unlock personal trends.'
          : 'Your dashboard is getting ready. Complete a few more check-ins to unlock stronger weekly insights.',
      'mood_trend': checkinCount == 0
          ? 'No mood trend yet.'
          : 'Initial mood data is being collected.',
      'sleep_trend': checkinCount == 0
          ? 'No sleep trend yet.'
          : 'Initial sleep data is being collected.',
      'stress_trend': checkinCount == 0
          ? 'No stress trend yet.'
          : 'Initial stress data is being collected.',
      'energy_trend': checkinCount == 0
          ? 'No energy trend yet.'
          : 'Initial energy data is being collected.',
      'physical_trend': checkinCount == 0
          ? 'No physical wellbeing trend yet.'
          : 'Initial physical wellbeing data is being collected.',
      'connectedness_trend': checkinCount == 0
          ? 'No connectedness trend yet.'
          : 'Initial connectedness data is being collected.',
      'module_progress': checkinCount == 0
          ? 'Start with a daily check-in or a learning card.'
          : 'Keep going to build a clearer weekly picture.',
      'is_placeholder': true,
    },
    sourceWindow: <String, dynamic>{'checkins': checkinCount},
    generationVersion: 'first-use-placeholder',
    generatedAt: now,
  );
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}
