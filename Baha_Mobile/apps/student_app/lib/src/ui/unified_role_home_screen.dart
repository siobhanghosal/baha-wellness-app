import 'dart:async';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_environment.dart';
import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';
import 'student_buddy_screen.dart';
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

class GuardianLinkWaitingScreen extends StatefulWidget {
  const GuardianLinkWaitingScreen({
    required this.apiClient,
    required this.identity,
    required this.onboardingState,
    required this.onRefresh,
    required this.onChangeIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final AuthOnboardingState? onboardingState;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onChangeIdentity;

  @override
  State<GuardianLinkWaitingScreen> createState() =>
      _GuardianLinkWaitingScreenState();
}

class _GuardianLinkWaitingScreenState extends State<GuardianLinkWaitingScreen> {
  final _studentCodeController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  String _relationship = 'Parent';
  bool _linking = false;
  String? _errorMessage;

  @override
  void dispose() {
    _studentCodeController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _linkStudent() async {
    if (_linking) {
      return;
    }
    final studentCode = _studentCodeController.text.trim();
    final verificationCode = _verificationCodeController.text.trim();
    if (studentCode.isEmpty || verificationCode.isEmpty) {
      setState(() {
        _errorMessage =
            'Enter the student ID and verification code from the student app first.';
      });
      return;
    }
    setState(() {
      _linking = true;
      _errorMessage = null;
    });
    try {
      await widget.apiClient.linkGuardianStudent(
        identity: widget.identity,
        request: GuardianLinkStudentRequest(
          studentCode: studentCode,
          verificationCode: verificationCode,
          relationshipToStudent: _relationship.toLowerCase(),
        ),
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student linked. Loading the guardian dashboard...'),
        ),
      );
      await widget.onRefresh();
    } on BahaApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = error.message);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _errorMessage = 'Could not link student: $error');
    } finally {
      if (mounted) {
        setState(() => _linking = false);
      }
    }
  }

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
              kicker: 'Parent or guardian',
              title: 'Link your child account',
              subtitle:
                  widget.onboardingState?.detail ??
                  'Enter the student ID and the 6-digit verification code from the student app to continue.',
              actions: const [
                Pill(icon: Icons.family_restroom_rounded, label: 'Guardian'),
                Pill(icon: Icons.link_rounded, label: 'Link required'),
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
                children: const [
                  SectionTitle(
                    title: 'How to continue',
                    subtitle:
                        'This is the parent-safe linking step for any student who chooses to connect a parent or guardian.',
                  ),
                  SizedBox(height: 10),
                  _GuardianChecklistRow(
                    icon: Icons.phone_android_rounded,
                    title: '1. Open the student account',
                    subtitle:
                        'The student waiting screen shows the student ID and verification code.',
                  ),
                  SizedBox(height: 10),
                  _GuardianChecklistRow(
                    icon: Icons.link_rounded,
                    title: '2. Enter both details here',
                    subtitle:
                        'This confirms the child initiated the connection.',
                  ),
                  SizedBox(height: 10),
                  _GuardianChecklistRow(
                    icon: Icons.approval_rounded,
                    title: '3. Approve access after linking',
                    subtitle:
                        'For under-18 students, approve access after linking. For all students, summary sharing still stays under the student’s control.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _linking ? null : widget.onRefresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh onboarding state'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _linking ? null : widget.onChangeIdentity,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out and switch account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuardianReadyScreenState extends State<GuardianReadyScreen> {
  final _studentCodeController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  late final ThemeController _themeController;
  String _relationship = 'Parent';
  int _currentIndex = 0;
  bool _loading = true;
  bool _linking = false;
  String? _errorMessage;
  String? _selectedStudentProfileId;
  List<MobileLinkedStudentSummary> _students = const [];
  final Map<String, ParentWeeklySummary> _summaryByStudent =
      <String, ParentWeeklySummary>{};
  final Map<String, String> _summaryAccessMessageByStudent = <String, String>{};
  final Map<String, PlatformParticipationConsentStatus>
  _platformConsentByStudent = <String, PlatformParticipationConsentStatus>{};
  final Map<String, ParentSummaryConsentStatus> _summaryConsentByStudent =
      <String, ParentSummaryConsentStatus>{};
  final Set<String> _busyStudentIds = <String>{};

  @override
  void initState() {
    super.initState();
    _themeController = ThemeController()..load();
    _loadGuardianHome();
  }

  @override
  void dispose() {
    _studentCodeController.dispose();
    _verificationCodeController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  Future<T?> _pushRoute<T>({required WidgetBuilder builder}) {
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

  Future<void> _loadGuardianHome() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final students = await widget.apiClient.listParentStudents(
        identity: widget.identity,
      );
      final summaryByStudent = <String, ParentWeeklySummary>{};
      final summaryAccessMessageByStudent = <String, String>{};
      final platformConsentByStudent =
          <String, PlatformParticipationConsentStatus>{};
      final summaryConsentByStudent = <String, ParentSummaryConsentStatus>{};
      for (final student in students) {
        try {
          summaryByStudent[student.studentProfileId] = await widget.apiClient
              .getParentWeeklySummary(
                identity: widget.identity,
                studentProfileId: student.studentProfileId,
              );
        } on BahaApiException catch (error) {
          summaryAccessMessageByStudent[student.studentProfileId] =
              error.message;
        } catch (_) {}
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
      final selectedStudentProfileId =
          students.any(
            (item) => item.studentProfileId == _selectedStudentProfileId,
          )
          ? _selectedStudentProfileId
          : (students.isEmpty ? null : students.first.studentProfileId);
      setState(() {
        _students = students;
        _selectedStudentProfileId = selectedStudentProfileId;
        _summaryByStudent
          ..clear()
          ..addAll(summaryByStudent);
        _summaryAccessMessageByStudent
          ..clear()
          ..addAll(summaryAccessMessageByStudent);
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

  Future<void> _confirmUnpairStudent(MobileLinkedStudentSummary student) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unpair this child account?'),
        content: Text(
          'This will remove the link to ${student.studentName}. You will lose access to their parent summary view until the account is linked again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Unpair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    await _runStudentAction(student.studentProfileId, () async {
      await widget.apiClient.unpairGuardianStudent(
        identity: widget.identity,
        studentProfileId: student.studentProfileId,
      );
      await _loadGuardianHome();
      if (!mounted) {
        return;
      }
      _showMessage('${student.studentName} was unpaired.');
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
    await _pushRoute<void>(
      builder: (context) => GuardianStudentSummaryScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        student: student,
      ),
    );
    await _loadGuardianHome();
  }

  MobileLinkedStudentSummary? get _selectedStudent {
    for (final student in _students) {
      if (student.studentProfileId == _selectedStudentProfileId) {
        return student;
      }
    }
    return _students.isEmpty ? null : _students.first;
  }

  ParentWeeklySummary? get _selectedSummary {
    final student = _selectedStudent;
    if (student == null) {
      return null;
    }
    return _summaryByStudent[student.studentProfileId];
  }

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: _themeController,
      child: AnimatedBuilder(
        animation: _themeController,
        builder: (context, _) {
          final palette = appPaletteForTheme(
            _themeController.colorTheme,
            isDark: _themeController.isDark,
          );
          final pages = <Widget>[
            _GuardianHomeTab(
              palette: palette,
              actor: widget.actor,
              loading: _loading,
              errorMessage: _errorMessage,
              students: _students,
              selectedStudent: _selectedStudent,
              selectedStudentProfileId: _selectedStudentProfileId,
              selectedSummary: _selectedSummary,
              summaryAccessMessageByStudent: _summaryAccessMessageByStudent,
              platformConsentByStudent: _platformConsentByStudent,
              summaryConsentByStudent: _summaryConsentByStudent,
              busyStudentIds: _busyStudentIds,
              studentCodeController: _studentCodeController,
              verificationCodeController: _verificationCodeController,
              relationship: _relationship,
              linking: _linking,
              onRelationshipChanged: (value) {
                setState(() => _relationship = value);
              },
              onLink: _linkStudent,
              onSelectedStudentChanged: (value) {
                setState(() => _selectedStudentProfileId = value);
              },
              onGrantPlatform: _grantPlatformConsent,
              onGrantSummary: _grantSummaryConsent,
              onOpenSummary: _openStudentSummary,
              onUnpairStudent: _confirmUnpairStudent,
              onRefresh: _loadGuardianHome,
            ),
            GuardianLearningHubScreen(
              actor: widget.actor,
              linkedStudents: _students,
            ),
            StudentBuddyScreen(
              apiClient: widget.apiClient,
              identity: widget.identity,
              heroKicker: 'Parent Buddy',
              heroTitle: 'A calm place for parent support.',
              heroSubtitle:
                  'Ask for guidance, conversation ideas, routines, school stress support, sleep help, or screen-time balance.',
              startSectionTitle: 'Start a chat',
              startSectionSubtitle:
                  'Open a private conversation whenever you want support.',
              startButtonLabel: 'Start new chat',
              sessionsSectionTitle: 'Recent chats',
              sessionsSectionSubtitle: 'Pick up where you left off.',
              emptySessionsMessage:
                  'No chats yet. Start one above whenever you need support.',
              sessionType: 'parent_guidance',
              chatScreenTitle: 'Parent Buddy',
              chatInputHint: 'Ask for guidance or support',
              emptyConversationMessage: 'Your conversation will appear here.',
              assistantName: 'Buddy',
            ),
            GuardianProfileScreen(
              apiClient: widget.apiClient,
              identity: widget.identity,
              actor: widget.actor,
              linkedStudents: _students,
              onClearIdentity: widget.onClearIdentity,
            ),
          ];

          return Theme(
            data: buildTheme(palette),
            child: Scaffold(
              body: IndexedStack(index: _currentIndex, children: pages),
              bottomNavigationBar: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: palette.surface.withValues(
                        alpha: palette.isDark ? .88 : .92,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: palette.isDark ? .08 : .52,
                        ),
                      ),
                    ),
                    child: SalomonBottomBar(
                      currentIndex: _currentIndex,
                      onTap: (value) => setState(() => _currentIndex = value),
                      selectedItemColor: palette.primary,
                      unselectedItemColor: palette.muted,
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 8,
                      ),
                      items: [
                        SalomonBottomBarItem(
                          icon: Icon(Icons.home_outlined),
                          title: Text('Home'),
                          selectedColor: Colors.green,
                        ),
                        SalomonBottomBarItem(
                          icon: Icon(Icons.auto_stories_outlined),
                          title: Text('Learn'),
                          selectedColor: Colors.blue,
                        ),
                        SalomonBottomBarItem(
                          icon: Icon(Icons.smart_toy_outlined),
                          title: Text('Buddy'),
                          selectedColor: Colors.pink,
                        ),
                        SalomonBottomBarItem(
                          icon: Icon(Icons.person_outline_rounded),
                          title: Text('Profile'),
                          selectedColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GuardianHomeTab extends StatelessWidget {
  const _GuardianHomeTab({
    required this.palette,
    required this.actor,
    required this.loading,
    required this.errorMessage,
    required this.students,
    required this.selectedStudent,
    required this.selectedStudentProfileId,
    required this.selectedSummary,
    required this.summaryAccessMessageByStudent,
    required this.platformConsentByStudent,
    required this.summaryConsentByStudent,
    required this.busyStudentIds,
    required this.studentCodeController,
    required this.verificationCodeController,
    required this.relationship,
    required this.linking,
    required this.onRelationshipChanged,
    required this.onLink,
    required this.onSelectedStudentChanged,
    required this.onGrantPlatform,
    required this.onGrantSummary,
    required this.onOpenSummary,
    required this.onUnpairStudent,
    required this.onRefresh,
  });

  final PrototypePalette palette;
  final MobileActor actor;
  final bool loading;
  final String? errorMessage;
  final List<MobileLinkedStudentSummary> students;
  final MobileLinkedStudentSummary? selectedStudent;
  final String? selectedStudentProfileId;
  final ParentWeeklySummary? selectedSummary;
  final Map<String, String> summaryAccessMessageByStudent;
  final Map<String, PlatformParticipationConsentStatus>
  platformConsentByStudent;
  final Map<String, ParentSummaryConsentStatus> summaryConsentByStudent;
  final Set<String> busyStudentIds;
  final TextEditingController studentCodeController;
  final TextEditingController verificationCodeController;
  final String relationship;
  final bool linking;
  final ValueChanged<String> onRelationshipChanged;
  final VoidCallback onLink;
  final ValueChanged<String?> onSelectedStudentChanged;
  final ValueChanged<MobileLinkedStudentSummary> onGrantPlatform;
  final ValueChanged<MobileLinkedStudentSummary> onGrantSummary;
  final ValueChanged<MobileLinkedStudentSummary> onOpenSummary;
  final ValueChanged<MobileLinkedStudentSummary> onUnpairStudent;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final summary = selectedSummary?.summary ?? const <String, dynamic>{};
    final selectedStudent = this.selectedStudent;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: loading
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
                    title: students.isEmpty
                        ? 'Link your child in one short step'
                        : 'Family overview',
                    subtitle: students.isEmpty
                        ? 'Link a student account to view summaries, guidance, and support tools.'
                        : 'See patterns, watch areas, and support ideas without exposing your child’s private entries.',
                    actions: [
                      const Pill(
                        icon: Icons.family_restroom_rounded,
                        label: 'Guardian',
                      ),
                      Pill(
                        icon: Icons.verified_user_rounded,
                        label: '${students.length} linked',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (errorMessage != null) ...[
                    GlassPanel(palette: palette, child: Text(errorMessage!)),
                    const SizedBox(height: 18),
                  ],
                  if (students.isEmpty) ...[
                    _GuardianLinkPanel(
                      palette: palette,
                      studentCodeController: studentCodeController,
                      verificationCodeController: verificationCodeController,
                      relationship: relationship,
                      linking: linking,
                      onRelationshipChanged: onRelationshipChanged,
                      onLink: onLink,
                    ),
                    const SizedBox(height: 18),
                    GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SectionTitle(
                            title: 'Getting started',
                            subtitle:
                                'This flow keeps parents informed while protecting student privacy.',
                          ),
                          SizedBox(height: 10),
                          _GuardianChecklistRow(
                            icon: Icons.link_rounded,
                            title:
                                '1. Link with student ID + verification code',
                            subtitle:
                                'This proves the child initiated the connection.',
                          ),
                          SizedBox(height: 10),
                          _GuardianChecklistRow(
                            icon: Icons.approval_rounded,
                            title:
                                '2. Approve access if the student is under 18',
                            subtitle:
                                'Adult students can use the app immediately. Under-18 students still need parent approval.',
                          ),
                          SizedBox(height: 10),
                          _GuardianChecklistRow(
                            icon: Icons.insights_rounded,
                            title:
                                '3. View summary trends, not private answers',
                            subtitle:
                                'BAHA only shows high-level patterns, alerts, and support nudges here.',
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    if (selectedSummary != null && selectedStudent != null) ...[
                      GlassPanel(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(
                              title: 'Family snapshot',
                              subtitle:
                                  'A weekly summary to help you have calm, supportive conversations.',
                            ),
                            ParentStudentPicker(
                              students: students,
                              selectedStudentProfileId:
                                  selectedStudentProfileId ??
                                  students.first.studentProfileId,
                              onChanged: onSelectedStudentChanged,
                            ),
                            const SizedBox(height: 18),
                            Text(
                              '${summary['headline'] ?? 'No summary available yet.'}',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${summary['week_story'] ?? 'A weekly summary will appear here once there is enough recent activity.'}',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 16),
                            _GuardianNarrativeCard(
                              palette: palette,
                              title: 'What improved',
                              body:
                                  '${summary['best_progress'] ?? 'No clear improvement has been highlighted yet.'}',
                              icon: Icons.trending_up_rounded,
                            ),
                            const SizedBox(height: 12),
                            _GuardianNarrativeCard(
                              palette: palette,
                              title: 'What to watch',
                              body:
                                  '${summary['watch_area'] ?? 'There are no watch areas right now.'}',
                              icon: Icons.visibility_rounded,
                            ),
                            const SizedBox(height: 12),
                            _GuardianNarrativeCard(
                              palette: palette,
                              title: 'Support action to try',
                              body:
                                  '${summary['support_nudge'] ?? 'Try a calm check-in conversation and notice whether any patterns repeat over time.'}',
                              icon: Icons.favorite_outline_rounded,
                            ),
                            if ((summary['privacy_note'] as String?) !=
                                null) ...[
                              const SizedBox(height: 12),
                              Text(
                                '${summary['privacy_note']}',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: palette.muted),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                FilledButton.icon(
                                  onPressed: () =>
                                      onOpenSummary(selectedStudent),
                                  icon: const Icon(Icons.insights_rounded),
                                  label: const Text('Open full summary'),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () => onRefresh(),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Refresh snapshot'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (selectedSummary != null && selectedStudent != null) ...[
                      GlassPanel(
                        palette: palette,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionTitle(
                              title: 'Parent next steps',
                              subtitle:
                                  'Simple prompts you can use right away.',
                            ),
                            _GuardianNarrativeCard(
                              palette: palette,
                              title: 'Conversation starter',
                              body:
                                  '${summary['safe_talking_point'] ?? summary['conversation_starter'] ?? 'Start small: ask what felt easiest this week and what felt heavier.'}',
                              icon: Icons.forum_rounded,
                            ),
                            const SizedBox(height: 12),
                            _GuardianNarrativeCard(
                              palette: palette,
                              title: 'One thing to watch next',
                              body:
                                  '${summary['watch_area'] ?? 'Watch for repeated shifts rather than reacting to one difficult day.'}',
                              icon: Icons.visibility_rounded,
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
                            title: 'Linked students',
                            subtitle:
                                'Student app access lets your child use BAHA. Parent summary access lets you view their high-level weekly trends.',
                          ),
                          ...students.map((student) {
                            final platformConsent =
                                platformConsentByStudent[student
                                    .studentProfileId];
                            final summaryConsent =
                                summaryConsentByStudent[student
                                    .studentProfileId];
                            final busy = busyStudentIds.contains(
                              student.studentProfileId,
                            );
                            final summaryAccessMessage =
                                summaryAccessMessageByStudent[student
                                    .studentProfileId];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _GuardianStudentCard(
                                palette: palette,
                                student: student,
                                platformStatus:
                                    platformConsent?.status ?? 'pending',
                                summaryStatus:
                                    summaryConsent?.status ?? 'pending',
                                summaryAccessMessage: summaryAccessMessage,
                                busy: busy,
                                onGrantPlatform: () => onGrantPlatform(student),
                                onGrantSummary: () => onGrantSummary(student),
                                onOpenSummary: () => onOpenSummary(student),
                                onUnpairStudent: () => onUnpairStudent(student),
                              ),
                            );
                          }),
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
                            title: 'Link another child account',
                            subtitle:
                                'Use the same student ID and verification code flow to add another child.',
                          ),
                          _GuardianLinkPanel(
                            palette: palette,
                            studentCodeController: studentCodeController,
                            verificationCodeController:
                                verificationCodeController,
                            relationship: relationship,
                            linking: linking,
                            onRelationshipChanged: onRelationshipChanged,
                            onLink: onLink,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  OutlinedButton.icon(
                    onPressed: () => onRefresh(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Refresh parent view'),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GuardianNarrativeCard extends StatelessWidget {
  const _GuardianNarrativeCard({
    required this.palette,
    required this.title,
    required this.body,
    required this.icon,
  });

  final PrototypePalette palette;
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      palette: palette,
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: palette.primary.withValues(alpha: .14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: palette.primary),
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
                const SizedBox(height: 6),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GuardianLearningHubScreen extends StatefulWidget {
  const GuardianLearningHubScreen({
    required this.actor,
    required this.linkedStudents,
    super.key,
  });

  final MobileActor actor;
  final List<MobileLinkedStudentSummary> linkedStudents;

  @override
  State<GuardianLearningHubScreen> createState() =>
      _GuardianLearningHubScreenState();
}

class _GuardianLearningHubScreenState extends State<GuardianLearningHubScreen> {
  static const _completedModulesKey = 'baha.guardian.learning.completed';

  late Future<Set<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCompleted();
  }

  Future<Set<String>> _loadCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(_completedModulesKey) ?? const <String>[])
        .toSet();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _loadCompleted();
    });
    await _future;
  }

  Future<void> _openTopic(_GuardianLearningTopic topic) async {
    final controller = ThemeScope.maybeOf(context);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => controller == null
            ? _GuardianLearningTopicScreen(
                topic: topic,
                completedStorageKey: _completedModulesKey,
              )
            : ThemeScope(
                controller: controller,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => _GuardianLearningTopicScreen(
                    topic: topic,
                    completedStorageKey: _completedModulesKey,
                  ),
                ),
              ),
      ),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<Set<String>>(
            future: _future,
            builder: (context, snapshot) {
              final completed = snapshot.data ?? const <String>{};
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  DashboardTopBar(palette: palette),
                  HeroHeader(
                    palette: palette,
                    kicker: 'Parent learning',
                    title: 'Support that helps at home.',
                    subtitle:
                        'Explore the same five core wellbeing topics as the student side, translated into calmer adult guidance, conversation prompts, and practical next steps for home.',
                    actions: [
                      Pill(
                        icon: Icons.family_restroom_rounded,
                        label: '${widget.linkedStudents.length} linked',
                      ),
                      const Pill(
                        icon: Icons.menu_book_rounded,
                        label: '5 topics',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  ..._guardianLearningTopics.map((topic) {
                    final completedCount = topic.modules
                        .where((module) => completed.contains(module.id))
                        .length;
                    final progress = topic.modules.isEmpty
                        ? 0.0
                        : completedCount / topic.modules.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: GlassPanel(
                        palette: palette,
                        onTap: () => _openTopic(topic),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: topic.color.withValues(alpha: .16),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Icon(topic.icon, color: topic.color),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        topic.title,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge
                                            ?.copyWith(
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        topic.subtitle,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(
                              value: progress,
                              minHeight: 10,
                              borderRadius: BorderRadius.circular(999),
                              backgroundColor: topic.color.withValues(
                                alpha: .12,
                              ),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                topic.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '$completedCount of ${topic.modules.length} mini-modules completed',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _GuardianLearningTopicScreen extends StatefulWidget {
  const _GuardianLearningTopicScreen({
    required this.topic,
    required this.completedStorageKey,
  });

  final _GuardianLearningTopic topic;
  final String completedStorageKey;

  @override
  State<_GuardianLearningTopicScreen> createState() =>
      _GuardianLearningTopicScreenState();
}

class _GuardianLearningTopicScreenState
    extends State<_GuardianLearningTopicScreen> {
  late Future<Set<String>> _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCompleted();
  }

  Future<Set<String>> _loadCompleted() async {
    final preferences = await SharedPreferences.getInstance();
    return (preferences.getStringList(widget.completedStorageKey) ??
            const <String>[])
        .toSet();
  }

  Future<void> _toggleModule(String moduleId) async {
    final preferences = await SharedPreferences.getInstance();
    final completed = await _loadCompleted();
    if (completed.contains(moduleId)) {
      completed.remove(moduleId);
    } else {
      completed.add(moduleId);
    }
    await preferences.setStringList(
      widget.completedStorageKey,
      completed.toList(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _future = Future<Set<String>>.value(completed);
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: FutureBuilder<Set<String>>(
          future: _future,
          builder: (context, snapshot) {
            final completed = snapshot.data ?? const <String>{};
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
                  kicker: 'Parent learning lane',
                  title: widget.topic.title,
                  subtitle: widget.topic.subtitle,
                  actions: [
                    Pill(
                      icon: widget.topic.icon,
                      label: '${widget.topic.modules.length} mini-modules',
                    ),
                    Pill(
                      icon: Icons.check_circle_outline_rounded,
                      label:
                          '${widget.topic.modules.where((module) => completed.contains(module.id)).length}/${widget.topic.modules.length} done',
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                ...widget.topic.modules.map((module) {
                  final done = completed.contains(module.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: GlassPanel(
                      palette: palette,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  module.title,
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              Pill(
                                icon: done
                                    ? Icons.check_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                label: done ? 'Done' : 'To do',
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            module.summary,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 12),
                          ...module.keyPoints.map(
                            (point) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 7),
                                    child: Icon(Icons.circle, size: 7),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(point)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          GlassPanel(
                            palette: palette,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Conversation prompt',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 6),
                                Text(module.prompt),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedPrimaryButton(
                            label: done
                                ? 'Mark as not done'
                                : 'Mark this mini-module complete',
                            icon: done
                                ? Icons.undo_rounded
                                : Icons.check_rounded,
                            onPressed: () => _toggleModule(module.id),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (widget.topic.quickSupportCards.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Quick support cards',
                          subtitle:
                              'Short reminders you can use right away at home.',
                        ),
                        const SizedBox(height: 12),
                        ...widget.topic.quickSupportCards.map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassPanel(
                              palette: palette,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    card.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(card.body),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class GuardianProfileScreen extends StatefulWidget {
  const GuardianProfileScreen({
    required this.apiClient,
    required this.identity,
    required this.actor,
    required this.linkedStudents,
    required this.onClearIdentity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final MobileActor actor;
  final List<MobileLinkedStudentSummary> linkedStudents;
  final Future<void> Function() onClearIdentity;

  @override
  State<GuardianProfileScreen> createState() => _GuardianProfileScreenState();
}

class _GuardianProfileScreenState extends State<GuardianProfileScreen> {
  static const _weeklyDigestKey = 'baha.guardian.notifications.weekly_digest';
  static const _supportNudgeKey = 'baha.guardian.notifications.support_nudge';

  late Future<List<MobileSupportContact>> _future;
  bool _weeklyDigestEnabled = true;
  bool _supportNudgesEnabled = true;

  @override
  void initState() {
    super.initState();
    _future = widget.apiClient.listSupportContacts(identity: widget.identity);
    unawaited(_loadPreferences());
  }

  Future<void> _loadPreferences() async {
    final preferences = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _weeklyDigestEnabled =
          preferences.getBool(_weeklyDigestKey) ?? _weeklyDigestEnabled;
      _supportNudgesEnabled =
          preferences.getBool(_supportNudgeKey) ?? _supportNudgesEnabled;
    });
  }

  Future<void> _setPreference(String key, bool value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: FutureBuilder<List<MobileSupportContact>>(
          future: _future,
          builder: (context, snapshot) {
            final contacts = snapshot.data ?? const <MobileSupportContact>[];
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                DashboardTopBar(palette: palette),
                HeroHeader(
                  palette: palette,
                  kicker: 'Parent profile',
                  title: widget.actor.displayName,
                  subtitle:
                      'Account details, privacy reminders, support contacts, and session controls in one place.',
                  actions: [
                    const Pill(
                      icon: Icons.lock_outline_rounded,
                      label: 'Privacy-safe',
                    ),
                    Pill(
                      icon: Icons.family_restroom_rounded,
                      label: '${widget.linkedStudents.length} linked',
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
                        title: 'Account snapshot',
                        subtitle:
                            'See your account details, linked children, and parent-side controls in one place.',
                      ),
                      _GuardianProfileInfoRow(
                        label: 'Role',
                        value: widget.actor.primaryRole,
                      ),
                      _GuardianProfileInfoRow(
                        label: 'Linked children',
                        value: '${widget.linkedStudents.length}',
                      ),
                      if ((widget.actor.schoolName ?? '').isNotEmpty)
                        _GuardianProfileInfoRow(
                          label: 'School',
                          value: widget.actor.schoolName!,
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
                        title: 'What parents can see',
                        subtitle:
                            'The parent side is intentionally limited to summaries, alerts, and support prompts.',
                      ),
                      Text(
                        'Raw student check-in answers, journal-like entries, and message-level Buddy conversations do not appear here.',
                        style: Theme.of(context).textTheme.bodyLarge,
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
                        title: 'Notifications',
                        subtitle:
                            'Local reminders for the parent side so the experience feels complete and configurable.',
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Weekly family digest reminder'),
                        subtitle: const Text(
                          'Keeps the parent profile ready for a calm weekly review.',
                        ),
                        value: _weeklyDigestEnabled,
                        onChanged: (value) {
                          setState(() => _weeklyDigestEnabled = value);
                          unawaited(_setPreference(_weeklyDigestKey, value));
                        },
                      ),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Support nudge reminders'),
                        subtitle: const Text(
                          'Keeps conversation starters and support ideas easy to revisit.',
                        ),
                        value: _supportNudgesEnabled,
                        onChanged: (value) {
                          setState(() => _supportNudgesEnabled = value);
                          unawaited(_setPreference(_supportNudgeKey, value));
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
                      const SectionTitle(
                        title: 'Appearance and app',
                        subtitle:
                            'Keep the parent view visually consistent with the rest of the unified app.',
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
                            selected: themeController?.colorTheme == theme,
                            selectedColor: palette.primary.withValues(
                              alpha: .18,
                            ),
                            onSelected: (_) {
                              unawaited(themeController?.setColorTheme(theme));
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      _GuardianProfileInfoRow(
                        label: 'Sign-in ID',
                        value: widget.identity.externalAuthId,
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
                        title: 'Support contacts',
                        subtitle:
                            'Useful contact points you can reach from the parent side of BAHA.',
                      ),
                      if (snapshot.connectionState != ConnectionState.done)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: CircularProgressIndicator(),
                        )
                      else if (contacts.isEmpty)
                        Text(
                          'No support contacts are available yet for this account.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        )
                      else
                        ...contacts.map(
                          (contact) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassPanel(
                              palette: palette,
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    contact.label,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    contact.contactType.replaceAll('_', ' '),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                  if (contact.phone != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Phone: ${contact.phone}'),
                                  ],
                                  if (contact.email != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Email: ${contact.email}'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                OutlinedButton.icon(
                  onPressed: widget.onClearIdentity,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out and switch account'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GuardianLearningTopic {
  const _GuardianLearningTopic({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.modules,
    required this.quickSupportCards,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<_GuardianLearningModule> modules;
  final List<_GuardianQuickSupportCard> quickSupportCards;
}

class _GuardianLearningModule {
  const _GuardianLearningModule({
    required this.id,
    required this.title,
    required this.summary,
    required this.keyPoints,
    required this.prompt,
  });

  final String id;
  final String title;
  final String summary;
  final List<String> keyPoints;
  final String prompt;
}

class _GuardianQuickSupportCard {
  const _GuardianQuickSupportCard({required this.title, required this.body});

  final String title;
  final String body;
}

const _guardianLearningTopics = <_GuardianLearningTopic>[
  _GuardianLearningTopic(
    title: 'Sleep',
    subtitle:
        'Practical routines, calmer evenings, and simple ways to support better rest at home.',
    icon: Icons.bedtime_rounded,
    color: Color(0xFF6366F1),
    modules: [
      _GuardianLearningModule(
        id: 'guardian_sleep_1',
        title: 'Spotting the sleep pattern behind the behavior',
        summary:
            'Parents often notice irritability, rushed mornings, or school fatigue before a child says they are not resting well.',
        keyPoints: [
          'Look for repeated evening delay patterns, not one rough night.',
          'Sleep problems often show up as mood, energy, or concentration struggles the next day.',
          'A calm routine usually works better than punishment-based rules at bedtime.',
        ],
        prompt:
            'Try: “I’ve noticed evenings feel rushed lately. What would make bedtime feel easier this week?”',
      ),
      _GuardianLearningModule(
        id: 'guardian_sleep_2',
        title: 'Building one calmer evening routine',
        summary:
            'A simple repeated sequence is easier for children to follow than a long list of changing instructions.',
        keyPoints: [
          'Pick one or two anchor habits such as device-off time and a regular wind-down cue.',
          'Keep instructions concrete and repeatable.',
          'Praise follow-through more than you lecture about failures.',
        ],
        prompt:
            'Ask: “What is one small step we can repeat every night so bedtime feels less stressful?”',
      ),
      _GuardianLearningModule(
        id: 'guardian_sleep_3',
        title: 'When sleep deserves extra attention',
        summary:
            'If poor sleep becomes frequent and starts affecting school, mood, or health, the parent role shifts from routine support to getting more help.',
        keyPoints: [
          'Notice whether the pattern is improving, stuck, or getting worse.',
          'Link sleep changes to daytime strain without blaming the child.',
          'If the concern keeps repeating, involve school or qualified professional support early.',
        ],
        prompt:
            'Say: “This seems to be happening a lot now. Let’s figure out who can help us look at it properly.”',
      ),
    ],
    quickSupportCards: [
      _GuardianQuickSupportCard(
        title: 'Tonight\'s fast reset',
        body:
            'Choose one bedtime anchor for tonight only: device-off time, a dim-light cue, or one calm wind-down habit.',
      ),
    ],
  ),
  _GuardianLearningTopic(
    title: 'Stress',
    subtitle:
        'Notice stress sooner, respond calmly, and make space for support without escalating the moment.',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF14B8A6),
    modules: [
      _GuardianLearningModule(
        id: 'guardian_stress_1',
        title: 'How stress shows up at home',
        summary:
            'Children and adolescents do not always say “I am stressed.” It often appears as shutdown, irritability, avoidance, or physical complaints.',
        keyPoints: [
          'Watch for repeated patterns around school, homework, friendships, or performance moments.',
          'Stress cues can be emotional, behavioral, or physical.',
          'Naming the pattern calmly is usually more useful than reacting to the behavior alone.',
        ],
        prompt:
            'Try: “I’m not upset with you. I’m trying to understand what feels heavy right now.”',
      ),
      _GuardianLearningModule(
        id: 'guardian_stress_2',
        title: 'How to respond without making it bigger',
        summary:
            'Parents help most when they lower pressure first, then move toward one manageable next step.',
        keyPoints: [
          'Start with regulation before problem-solving.',
          'Keep your first response short, calm, and specific.',
          'Offer one next step instead of many at once.',
        ],
        prompt:
            'Say: “Let’s slow this down. What is the smallest useful next step we can take today?”',
      ),
      _GuardianLearningModule(
        id: 'guardian_stress_3',
        title: 'When to bring in more support',
        summary:
            'If stress is frequent, intense, or clearly affecting school, sleep, mood, or daily functioning, outside support should become part of the plan.',
        keyPoints: [
          'Look for stress that stays high across several days or settings.',
          'Use the school or BAHA pathway early when concerns are persistent.',
          'Support-seeking is a steadying move, not a failure of parenting.',
        ],
        prompt:
            'Try: “We don’t have to handle all of this alone. Let’s decide who can help us think clearly about it.”',
      ),
    ],
    quickSupportCards: [
      _GuardianQuickSupportCard(
        title: 'One calmer first line',
        body:
            'Start with regulation before advice: “We can slow this down. Tell me what feels heaviest first.”',
      ),
    ],
  ),
  _GuardianLearningTopic(
    title: 'Bullying',
    subtitle:
        'Respond in a way that keeps the child safe, believed, and connected to real adult help.',
    icon: Icons.shield_rounded,
    color: Color(0xFFEC4899),
    modules: [
      _GuardianLearningModule(
        id: 'guardian_bullying_1',
        title: 'Recognizing the difference between conflict and bullying',
        summary:
            'Bullying is usually repeated, targeted, and meant to make someone feel smaller or unsafe.',
        keyPoints: [
          'One disagreement is not the same as a repeated pattern of harm.',
          'Online behavior counts too, especially if it keeps continuing.',
          'Children may hide bullying because they fear things will get worse.',
        ],
        prompt:
            'Ask: “Is this something that happened once, or does it keep happening in different ways?”',
      ),
      _GuardianLearningModule(
        id: 'guardian_bullying_2',
        title: 'What helps in the first conversation',
        summary:
            'The first goal is belief, calm, and safety, not immediately solving everything in one talk.',
        keyPoints: [
          'Thank the child for telling you.',
          'Avoid blame, panic, or promises you cannot keep.',
          'Focus on what will help them feel safer today.',
        ],
        prompt:
            'Say: “Thank you for telling me. We’ll take this seriously and work out the safest next step together.”',
      ),
      _GuardianLearningModule(
        id: 'guardian_bullying_3',
        title: 'Escalating safely through adults and school',
        summary:
            'Once the pattern is clearer, parents need a practical escalation path that is calm, documented, and protective.',
        keyPoints: [
          'Write down what happened, where, and how often.',
          'Use school staff or BAHA support channels instead of trying to handle it only through the child.',
          'Keep checking whether the child feels safer after each adult step.',
        ],
        prompt:
            'Try: “Let’s note the pattern clearly so we can explain it properly to the adults who need to act on it.”',
      ),
    ],
    quickSupportCards: [
      _GuardianQuickSupportCard(
        title: 'First response that helps',
        body:
            'Lead with belief and safety: thank them for telling you, avoid blame, and decide the safest next adult step.',
      ),
    ],
  ),
  _GuardianLearningTopic(
    title: 'Healthy Gaming',
    subtitle:
        'Keep gaming enjoyable without letting it quietly take over sleep, school, mood, or family rhythm.',
    icon: Icons.sports_esports_rounded,
    color: Color(0xFF0EA5E9),
    modules: [
      _GuardianLearningModule(
        id: 'guardian_gaming_1',
        title: 'Spotting when gaming is crowding out balance',
        summary:
            'The concern is not gaming by itself. The concern is what starts getting pushed out around it.',
        keyPoints: [
          'Look for patterns affecting sleep, homework, movement, or family participation.',
          'Repeated conflict around stopping can be a useful clue.',
          'Frame the issue around balance, not shame.',
        ],
        prompt:
            'Ask: “What parts of the day feel harder to manage because gaming is taking more space?”',
      ),
      _GuardianLearningModule(
        id: 'guardian_gaming_2',
        title: 'Setting limits that are clear and livable',
        summary:
            'Rules work better when they are predictable, simple, and tied to the whole day rather than punishment in the moment.',
        keyPoints: [
          'Use routines and expectations before you use consequences.',
          'Explain the reason for limits in terms of balance and wellbeing.',
          'Keep the plan short enough that everyone can remember it.',
        ],
        prompt:
            'Try: “Let’s agree on a gaming plan that still protects sleep, school, and downtime.”',
      ),
      _GuardianLearningModule(
        id: 'guardian_gaming_3',
        title: 'Keeping the conversation open',
        summary:
            'If gaming becomes the only topic parents raise, children often stop hearing the message. Keep the wider relationship intact.',
        keyPoints: [
          'Notice what the child likes about gaming before jumping into restriction.',
          'Keep one part of the conversation collaborative.',
          'If the pattern is stuck, use support rather than endlessly repeating the same argument.',
        ],
        prompt:
            'Say: “I know gaming matters to you. I want us to protect that and still keep the rest of life steady.”',
      ),
    ],
    quickSupportCards: [
      _GuardianQuickSupportCard(
        title: 'Quick balance check',
        body:
            'If gaming is pushing out sleep, homework, or family time, adjust the daily rhythm first instead of arguing in the moment.',
      ),
    ],
  ),
  _GuardianLearningTopic(
    title: 'Alcohol Safety',
    subtitle:
        'Prepare for tricky situations, reduce panic, and make sure the child knows how to reach for safe adult help.',
    icon: Icons.no_drinks_rounded,
    color: Color(0xFFF97316),
    modules: [
      _GuardianLearningModule(
        id: 'guardian_alcohol_1',
        title: 'Starting the conversation before the problem',
        summary:
            'Parents usually have more influence before a risky moment than during one. A calm early conversation is useful.',
        keyPoints: [
          'Keep the tone matter-of-fact, not dramatic.',
          'Focus on safety, trusted adults, and what to do if something feels wrong.',
          'Children remember simple plans better than long warnings.',
        ],
        prompt:
            'Ask: “If you were ever in a situation that felt unsafe, who would you contact first?”',
      ),
      _GuardianLearningModule(
        id: 'guardian_alcohol_2',
        title: 'What to emphasize about safety',
        summary:
            'Safety conversations should help children leave a risky situation early rather than hide it because they fear punishment.',
        keyPoints: [
          'Make it clear that reaching out for help is the right move.',
          'Separate immediate safety from later consequences.',
          'Repeat that they do not have to manage unsafe situations alone.',
        ],
        prompt:
            'Say: “If something feels wrong, call me or another trusted adult first. We can deal with the rest afterwards.”',
      ),
      _GuardianLearningModule(
        id: 'guardian_alcohol_3',
        title: 'How to respond after a concerning situation',
        summary:
            'After a risky event, children need calm containment first so parents can learn what happened and protect the next step.',
        keyPoints: [
          'Get the facts once safety is steady.',
          'Ask what support is needed next, not only what rule was broken.',
          'If the situation points to repeated concern, involve school or professional help early.',
        ],
        prompt:
            'Try: “I want to understand what happened and what support would make the next situation safer.”',
      ),
    ],
    quickSupportCards: [
      _GuardianQuickSupportCard(
        title: 'Safety line to repeat',
        body:
            '“If something feels unsafe, call me first. We will deal with the rest after you are safe.”',
      ),
    ],
  ),
];

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
    return DropdownButtonFormField<String>(
      initialValue: selectedStudentProfileId,
      items: students
          .map(
            (student) => DropdownMenuItem<String>(
              value: student.studentProfileId,
              child: Text(student.studentName),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: const InputDecoration(labelText: 'Selected child'),
    );
  }
}

class _GuardianStudentCard extends StatelessWidget {
  const _GuardianStudentCard({
    required this.palette,
    required this.student,
    required this.platformStatus,
    required this.summaryStatus,
    required this.summaryAccessMessage,
    required this.busy,
    required this.onGrantPlatform,
    required this.onGrantSummary,
    required this.onOpenSummary,
    required this.onUnpairStudent,
  });

  final PrototypePalette palette;
  final MobileLinkedStudentSummary student;
  final String platformStatus;
  final String summaryStatus;
  final String? summaryAccessMessage;
  final bool busy;
  final VoidCallback onGrantPlatform;
  final VoidCallback onGrantSummary;
  final VoidCallback onOpenSummary;
  final VoidCallback onUnpairStudent;

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
                label: 'Student app: ${_titleCase(platformStatus)}',
                ok: platformStatus == 'granted',
              ),
              _GuardianStatusPill(
                label: 'Parent summary: ${_titleCase(summaryStatus)}',
                ok: summaryStatus == 'granted' && summaryAccessMessage == null,
              ),
              if ((student.ageCohort ?? '').isNotEmpty)
                _GuardianStatusPill(
                  label: student.ageCohort!.replaceAll('_', ' '),
                  ok: true,
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (summaryAccessMessage != null) ...[
            Text(
              summaryAccessMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.muted),
            ),
            const SizedBox(height: 10),
          ],
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
                  label: const Text('Approve summary view'),
                ),
              OutlinedButton.icon(
                onPressed: busy ? null : onOpenSummary,
                icon: const Icon(Icons.insights_rounded),
                label: const Text('Open summary'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onUnpairStudent,
                icon: const Icon(Icons.link_off_rounded),
                label: const Text('Unpair'),
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
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: FutureBuilder<_GuardianStudentSummaryViewModel>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  DashboardTopBar(palette: palette),
                  _GuardianBackRow(palette: palette),
                  ShimmerBlock(palette: palette),
                ],
              );
            }
            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  DashboardTopBar(palette: palette),
                  _GuardianBackRow(palette: palette),
                  GlassPanel(
                    palette: palette,
                    child: Text('${snapshot.error}'),
                  ),
                ],
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
            final conversationStarter =
                summaryMap['safe_talking_point']?.toString() ??
                summaryMap['conversation_starter']?.toString() ??
                (summaryMap['best_progress'] != null
                    ? 'Ask what part of the week felt a little easier and what helped.'
                    : 'Start with a calm check-in: “How has this week felt for you overall?”');
            final watchNextWeek =
                summaryMap['watch_area']?.toString() ??
                (flags.isNotEmpty
                    ? 'Keep an eye on ${flags.first.toLowerCase()} next week and notice whether it repeats.'
                    : 'Watch for any repeated shift in sleep, mood, stress, or connection rather than reacting to one difficult day.');
            final supportAction =
                summaryMap['support_nudge']?.toString() ??
                'Keep support low-pressure: listen first, reflect what you notice, and offer one small practical step.';
            final whatChanged =
                summaryMap['week_story']?.toString() ??
                summaryMap['headline']?.toString() ??
                'BAHA is still building a clearer weekly pattern story for this student.';
            final accessGranted = data.platform.status == 'granted';
            final summaryGranted = data.summaryConsent.status == 'granted';
            final studentBlockedSharing = (data.summaryError ?? '')
                .toLowerCase()
                .contains('student has not enabled parent summary sharing');
            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                DashboardTopBar(palette: palette),
                _GuardianBackRow(palette: palette),
                HeroHeader(
                  palette: palette,
                  kicker: 'Parent summary',
                  title: widget.student.studentName,
                  subtitle:
                      'This view is intentionally high-level. It shows weekly trends and concern signals without exposing private daily answers.',
                  actions: [
                    if ((widget.student.ageCohort ?? '').isNotEmpty)
                      Pill(
                        icon: Icons.person_outline_rounded,
                        label: widget.student.ageCohort!.replaceAll('_', ' '),
                      ),
                    Pill(
                      icon: Icons.approval_rounded,
                      label: 'Student app: ${data.platform.status}',
                    ),
                    Pill(
                      icon: Icons.visibility_rounded,
                      label: 'Parent summary: ${data.summaryConsent.status}',
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
                else if (studentBlockedSharing)
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'The student has not enabled summary sharing',
                          subtitle:
                              'Ask them to turn on parent summary sharing from the student settings first.',
                        ),
                        if (data.summaryError != null) Text(data.summaryError!),
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
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: () => setState(() {
                                _future = _load();
                              }),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Refresh summary'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              label: const Text('Back to parent home'),
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
                          title: 'How to respond this week',
                          subtitle:
                              'A privacy-safe parent action layer built on the summary, not the child’s private entries.',
                        ),
                        _SummaryBlock(
                          title: 'What changed',
                          value: whatChanged,
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'Conversation starter',
                          value: conversationStarter,
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'What to watch next week',
                          value: watchNextWeek,
                        ),
                        const SizedBox(height: 10),
                        _SummaryBlock(
                          title: 'Support action to try',
                          value: supportAction,
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

class _GuardianBackRow extends StatelessWidget {
  const _GuardianBackRow({required this.palette});

  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          Text(
            'Back',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
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

class _GuardianProfileInfoRow extends StatelessWidget {
  const _GuardianProfileInfoRow({required this.label, required this.value});

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
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Log out and switch account'),
            ),
          ],
        ),
      ),
    );
  }
}
