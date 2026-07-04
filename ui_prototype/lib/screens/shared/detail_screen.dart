import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../dummy_data/mock_data.dart';
import '../../dummy_data/screen_blueprints.dart';
import '../../models/prototype_models.dart';
import '../../navigation/app_router.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/prototype_widgets.dart';

enum _MockFlowKind {
  onboarding,
  checkin,
  trend,
  module,
  buddy,
  support,
  games,
  summary,
  consent,
  notifications,
  settings,
  classFlow,
  pastoral,
  referral,
  queue,
  caseDetail,
  approvals,
  contentReview,
  threshold,
  generic,
}

class DetailScreen extends StatefulWidget {
  const DetailScreen({super.key, required this.role, required this.title});

  final AppRole role;
  final String title;

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late final TextEditingController _textController;
  late List<ChatBubble> _messages;
  bool _primaryToggle = true;
  bool _secondaryToggle = false;
  double _sliderValue = 0.62;
  int _selectedIndex = 0;
  String _selectedChoice = 'Calm';
  String _activeChild = 'Aarav Demo';
  String _activeClass = 'Class 9B';
  final Set<String> _completedItems = <String>{};
  final List<String> _activityLog = <String>[];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _messages = List<ChatBubble>.from(chatBubbles);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(
      widget.role,
      isDark: ThemeScope.of(context).isDark,
    );
    final blueprint = findBlueprint(widget.role, widget.title);
    final item = _findItem(widget.title);
    final kind = _kindFor(widget.title);

    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showActionSheet(context),
          icon: const Icon(Icons.flash_on_rounded),
          label: const Text('Quick demo'),
        ),
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.go(homePath(widget.role)),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const Spacer(),
                ThemeModeToggle(palette: palette),
              ],
            ),
            HeroHeader(
              palette: palette,
              kicker: widget.role.label,
              title: widget.title,
              subtitle: _heroSubtitle(kind, blueprint, item),
              actions: [
                Pill(
                  icon: item?.icon ?? widget.role.icon,
                  label: item?.tag ?? _kindLabel(kind),
                ),
                const Pill(
                  icon: Icons.flutter_dash_rounded,
                  label: 'Local demo mode',
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
                    title: 'Experience status',
                    subtitle:
                        'Cloud integration is intentionally paused in this build.',
                  ),
                  Text(
                    blueprint == null
                        ? 'This page is fully simulated inside Flutter. Every action below is local, reversible, and safe for UI review.'
                        : 'This page is mapped to ${blueprint.screenId}. The future API connection is paused for now, so the flow is being simulated locally while preserving the intended product behavior.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ..._buildFlowSections(context, palette, kind),
            const SizedBox(height: 16),
            if (blueprint != null)
              GlassPanel(
                palette: palette,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionTitle(
                      title: 'Planned live behavior',
                      subtitle:
                          'These notes stay here as implementation guidance only.',
                    ),
                    ...blueprint.behaviors.map(
                      (behavior) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6, right: 8),
                              child: Icon(
                                Icons.circle,
                                size: 8,
                                color: palette.primary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                behavior,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (blueprint != null) const SizedBox(height: 16),
            _buildRelatedSection(context, palette, kind),
            const SizedBox(height: 16),
            _buildActivityLog(context, palette),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _heroSubtitle(
    _MockFlowKind kind,
    ScreenBlueprint? blueprint,
    UiCardItem? item,
  ) {
    if (item != null) {
      return item.subtitle;
    }
    if (blueprint != null) {
      return blueprint.purpose;
    }
    return switch (kind) {
      _MockFlowKind.onboarding =>
        'A guided local flow with real page states and fake completion.',
      _MockFlowKind.consent =>
        'Consent, privacy, and participation decisions simulated locally.',
      _MockFlowKind.queue =>
        'Operational cards, filters, and actions running entirely in Flutter.',
      _MockFlowKind.approvals =>
        'Review and decision states without backend dependencies.',
      _ => 'A polished fake-data page with working local actions.',
    };
  }

  String _kindLabel(_MockFlowKind kind) {
    return switch (kind) {
      _MockFlowKind.onboarding => 'Onboarding',
      _MockFlowKind.checkin => 'Check-in',
      _MockFlowKind.trend => 'Insight',
      _MockFlowKind.module => 'Module',
      _MockFlowKind.buddy => 'Chat',
      _MockFlowKind.support => 'Support',
      _MockFlowKind.games => 'Interactive',
      _MockFlowKind.summary => 'Summary',
      _MockFlowKind.consent => 'Consent',
      _MockFlowKind.notifications => 'Updates',
      _MockFlowKind.settings => 'Preferences',
      _MockFlowKind.classFlow => 'Class',
      _MockFlowKind.pastoral => 'Pastoral',
      _MockFlowKind.referral => 'Referral',
      _MockFlowKind.queue => 'Queue',
      _MockFlowKind.caseDetail => 'Case',
      _MockFlowKind.approvals => 'Review',
      _MockFlowKind.contentReview => 'Content',
      _MockFlowKind.threshold => 'Safety',
      _MockFlowKind.generic => 'Prototype',
    };
  }

  _MockFlowKind _kindFor(String title) {
    final normalized = _normalize(title);
    if (_containsAny(normalized, [
      'welcome',
      'bootstrap',
      'age cohort',
      'consent band',
      'privacy explanation',
      'privacy acknowledgement',
      'guardian consent',
      'self consent',
      'dashboard unlock',
      'approval pending',
      'enter parent dashboard',
      'enter teacher workspace',
      'enter command center',
      'open operations dashboard',
      'class assignment setup',
      'confirm relationship',
      'review queue and access requests',
      'pastoral visibility guidance',
    ])) {
      return _MockFlowKind.onboarding;
    }
    if (_containsAny(normalized, [
      'daily check in',
      'sleep reflection',
      'exam stress pulse',
      'friendship check',
    ])) {
      return _MockFlowKind.checkin;
    }
    if (_containsAny(normalized, [
      'mood',
      'sleep',
      'stress',
      'energy',
      'check in rhythm',
      'sleep pattern',
      'trend',
      'class calm index',
      'attendance',
      'class report',
    ])) {
      return _MockFlowKind.trend;
    }
    if (_containsAny(normalized, [
      'learn feed',
      'sleep reset',
      'digital wellness',
      'peer pressure',
      'exam stress',
      'teacher resources',
      'parent resources',
      'operational content',
      'module detail',
      'calendar',
    ])) {
      return _MockFlowKind.module;
    }
    if (_containsAny(normalized, ['baha buddy'])) {
      return _MockFlowKind.buddy;
    }
    if (_containsAny(normalized, [
      'sos help',
      'support contacts',
      'support',
      'expert routing',
      'crisis contacts',
    ])) {
      return _MockFlowKind.support;
    }
    if (_containsAny(normalized, [
      'games hub',
      'calm breathing',
      'emotion wheel',
      'friendship choices',
    ])) {
      return _MockFlowKind.games;
    }
    if (_containsAny(normalized, [
      'parent home',
      'reports and insights',
      'weekly summary',
      'summary detail',
    ])) {
      return _MockFlowKind.summary;
    }
    if (_containsAny(normalized, [
      'summary sharing consent',
      'platform participation consent',
      'link child account',
    ])) {
      return _MockFlowKind.consent;
    }
    if (_containsAny(normalized, [
      'notifications',
      'parent notifications',
      'teacher notifications',
    ])) {
      return _MockFlowKind.notifications;
    }
    if (_containsAny(normalized, ['settings', 'profile and settings'])) {
      return _MockFlowKind.settings;
    }
    if (_containsAny(normalized, [
      'class list',
      'classes',
      'class summary',
    ])) {
      return _MockFlowKind.classFlow;
    }
    if (_containsAny(normalized, [
      'student wellbeing signals',
      'pastoral flag',
    ])) {
      return _MockFlowKind.pastoral;
    }
    if (_containsAny(normalized, ['referral workflow'])) {
      return _MockFlowKind.referral;
    }
    if (_containsAny(normalized, ['support queue'])) {
      return _MockFlowKind.queue;
    }
    if (_containsAny(normalized, ['case detail'])) {
      return _MockFlowKind.caseDetail;
    }
    if (_containsAny(normalized, [
      'approval requests',
      'approval decision',
    ])) {
      return _MockFlowKind.approvals;
    }
    if (_containsAny(normalized, ['content review workflow'])) {
      return _MockFlowKind.contentReview;
    }
    if (_containsAny(normalized, ['threshold configuration'])) {
      return _MockFlowKind.threshold;
    }
    return _MockFlowKind.generic;
  }

  List<Widget> _buildFlowSections(
    BuildContext context,
    PrototypePalette palette,
    _MockFlowKind kind,
  ) {
    switch (kind) {
      case _MockFlowKind.onboarding:
        return _onboardingSections(context, palette);
      case _MockFlowKind.checkin:
        return _checkinSections(context, palette);
      case _MockFlowKind.trend:
        return _trendSections(context, palette);
      case _MockFlowKind.module:
        return _moduleSections(context, palette);
      case _MockFlowKind.buddy:
        return _buddySections(context, palette);
      case _MockFlowKind.support:
        return _supportSections(context, palette);
      case _MockFlowKind.games:
        return _gameSections(context, palette);
      case _MockFlowKind.summary:
        return _summarySections(context, palette);
      case _MockFlowKind.consent:
        return _consentSections(context, palette);
      case _MockFlowKind.notifications:
        return _notificationSections(context, palette);
      case _MockFlowKind.settings:
        return _settingsSections(context, palette);
      case _MockFlowKind.classFlow:
        return _classSections(context, palette);
      case _MockFlowKind.pastoral:
        return _pastoralSections(context, palette);
      case _MockFlowKind.referral:
        return _referralSections(context, palette);
      case _MockFlowKind.queue:
        return _queueSections(context, palette);
      case _MockFlowKind.caseDetail:
        return _caseSections(context, palette);
      case _MockFlowKind.approvals:
        return _approvalSections(context, palette);
      case _MockFlowKind.contentReview:
        return _contentReviewSections(context, palette);
      case _MockFlowKind.threshold:
        return _thresholdSections(context, palette);
      case _MockFlowKind.generic:
        return _genericSections(context, palette);
    }
  }

  List<Widget> _onboardingSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final steps = [
      'Review trust and safety note',
      'Confirm role and profile basics',
      'Simulate privacy or approval decision',
      'Unlock the next screen locally',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Mock onboarding progress',
              subtitle:
                  'Each tap marks a step complete and keeps the flow moving.',
            ),
            ...steps.map(
              (step) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _completedItems.contains(step),
                onChanged: (_) => _toggleCompleted(step),
                title: Text(step),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    for (final step in steps) {
                      _completedItems.add(step);
                    }
                    _log('Completed the ${widget.title.toLowerCase()} mock flow.');
                    setState(() {});
                    _toast('${widget.title} completed locally.');
                  },
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Complete step'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.go(homePath(widget.role)),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue to app'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _checkinSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final feelings = ['Calm', 'Hopeful', 'Tired', 'Stressed'];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'How are you feeling?',
              subtitle: 'This fake form behaves like a real check-in flow.',
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(
                feelings.length,
                (index) => ChoiceChip(
                  selected: _selectedChoice == feelings[index],
                  label: Text(feelings[index]),
                  onSelected: (_) => setState(() {
                    _selectedChoice = feelings[index];
                  }),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Stress level',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            Slider(
              value: _sliderValue,
              onChanged: (value) => setState(() => _sliderValue = value),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'What is one thing on your mind today?',
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _log(
                      'Saved a ${widget.title.toLowerCase()} draft with feeling $_selectedChoice.',
                    );
                    _toast('Draft saved locally.');
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save draft'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _log(
                      'Submitted a local ${widget.title.toLowerCase()} with stress ${(100 * _sliderValue).round()}%.',
                    );
                    _textController.clear();
                    _toast('Check-in submitted locally.');
                  },
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _trendSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Trend snapshot',
              subtitle:
                  'This chart and summary stay local while preserving the intended flow.',
            ),
            MiniLineChart(palette: palette),
            const SizedBox(height: 12),
            Text(
              'This week looks steadier than last week. The biggest improvement is consistency, and the next recommended step is one small repeatable routine.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: () {
                _log('Viewed a deeper trend explanation for ${widget.title}.');
                _toast('Insight expanded.');
              },
              icon: const Icon(Icons.insights_rounded),
              label: const Text('Expand insight'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _moduleSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final sections = [
      'Short intro',
      'Key takeaway card',
      'One practice exercise',
      'Reflection prompt',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Local learning module',
              subtitle:
                  'This acts like a module detail page with completion tracking.',
            ),
            ...sections.map(
              (section) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _completedItems.contains(section),
                onChanged: (_) => _toggleCompleted(section),
                title: Text(section),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    for (final section in sections) {
                      _completedItems.add(section);
                    }
                    _log('Completed the ${widget.title.toLowerCase()} module.');
                    setState(() {});
                    _toast('Module marked complete.');
                  },
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Complete module'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _log('Bookmarked ${widget.title}.');
                    _toast('Added to saved resources.');
                  },
                  icon: const Icon(Icons.bookmark_rounded),
                  label: const Text('Save for later'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buddySections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Mock Buddy conversation',
              subtitle:
                  'Messages stay local, but the interaction feels like a real chat surface.',
            ),
            ..._messages.map(
              (bubble) => Align(
                alignment: bubble.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  constraints: const BoxConstraints(maxWidth: 320),
                  decoration: BoxDecoration(
                    color: bubble.isUser
                        ? palette.primary.withValues(alpha: .18)
                        : palette.surface.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${bubble.sender}: ${bubble.text}'),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a local demo message...',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton.small(
                  onPressed: _sendMockChat,
                  child: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _supportSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final contacts = [
      'School counselor · 9:00 AM - 5:00 PM',
      'Parent/guardian contact path',
      'Emergency support guidance',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Support options',
              subtitle:
                  'These actions are local, but the structure mirrors the real support flow.',
            ),
            ...contacts.map(
              (contact) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.support_agent_rounded),
                  title: Text(contact),
                  subtitle: const Text('Tap actions below for a local demo.'),
                ),
              ),
            ),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _log('Created a local help request from ${widget.title}.');
                    _toast('Help request sent locally.');
                  },
                  icon: const Icon(Icons.health_and_safety_rounded),
                  label: const Text('Request help'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _log('Opened emergency guidance from ${widget.title}.');
                    _toast('Emergency guidance opened.');
                  },
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Open guidance'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _gameSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final activities = [
      '1-minute breathing reset',
      'Emotion naming practice',
      'Friendship choice scenario',
      'Tiny reflection reward',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Interactive local activity',
              subtitle:
                  'A lightweight demo replacement for future game logic.',
            ),
            ...activities.map(
              (activity) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Icon(Icons.auto_awesome_rounded, color: palette.primary),
                    const SizedBox(width: 10),
                    Expanded(child: Text(activity)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Finished a local activity in ${widget.title}.');
                _toast('Activity completed. Bonus badge unlocked.');
              },
              icon: const Icon(Icons.emoji_events_rounded),
              label: const Text('Finish activity'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _summarySections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Role-safe summary',
              subtitle:
                  'This is a local mock of the parent-safe and teacher-safe summary style.',
            ),
            DropdownButtonFormField<String>(
              initialValue: _activeChild,
              decoration: const InputDecoration(labelText: 'Active student'),
              items: const [
                DropdownMenuItem(value: 'Aarav Demo', child: Text('Aarav Demo')),
                DropdownMenuItem(
                  value: 'Ananya Demo',
                  child: Text('Ananya Demo'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _activeChild = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Summary for $_activeChild: overall rhythm is stable, sleep consistency is improving, and the most useful next step is a calm check-in conversation rather than direct questioning.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            MiniLineChart(palette: palette),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Viewed a role-safe summary for $_activeChild.');
                _toast('Summary refreshed locally.');
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh summary'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _consentSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Local consent controls',
              subtitle:
                  'Use these toggles to simulate consent, participation, and sharing decisions.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _primaryToggle,
              onChanged: (value) => setState(() => _primaryToggle = value),
              title: const Text('Allow parent-safe summary sharing'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _secondaryToggle,
              onChanged: (value) => setState(() => _secondaryToggle = value),
              title: const Text('Activate platform participation'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _log(
                      'Updated local consent on ${widget.title}: summary=$_primaryToggle participation=$_secondaryToggle.',
                    );
                    _toast('Consent saved locally.');
                  },
                  icon: const Icon(Icons.verified_rounded),
                  label: const Text('Save decision'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _primaryToggle = false;
                      _secondaryToggle = false;
                    });
                    _log('Revoked local consent on ${widget.title}.');
                    _toast('Consent revoked locally.');
                  },
                  icon: const Icon(Icons.block_rounded),
                  label: const Text('Revoke all'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _notificationSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final notifications = [
      'A new weekly summary is ready to review.',
      'A check-in reminder is scheduled for tomorrow.',
      'A support follow-up note was added locally.',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Recent updates',
              subtitle:
                  'A simple local notifications center for prototype review.',
            ),
            ...notifications.map(
              (note) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_active_rounded),
                title: Text(note),
                trailing: TextButton(
                  onPressed: () {
                    _log('Opened a local notification from ${widget.title}.');
                    _toast('Notification opened.');
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _settingsSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Preferences',
              subtitle: 'Everything here is stored only for this local session.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _primaryToggle,
              onChanged: (value) => setState(() => _primaryToggle = value),
              title: const Text('Gentle reminders'),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _secondaryToggle,
              onChanged: (value) => setState(() => _secondaryToggle = value),
              title: const Text('Celebrate small wins'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Updated local settings from ${widget.title}.');
                _toast('Preferences updated.');
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save preferences'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _classSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final classes = ['Class 9B', 'Class 10A', 'Class 11 Humanities'];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Class context',
              subtitle:
                  'This local view simulates class selection and summary review.',
            ),
            DropdownButtonFormField<String>(
              initialValue: _activeClass,
              decoration: const InputDecoration(labelText: 'Selected class'),
              items: classes
                  .map(
                    (value) =>
                        DropdownMenuItem(value: value, child: Text(value)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _activeClass = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text(
              '$_activeClass is showing a steady wellbeing rhythm with one attendance dip and two low-priority pastoral follow-ups.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            MiniLineChart(palette: palette),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Viewed a local summary for $_activeClass.');
                _toast('Class summary refreshed.');
              },
              icon: const Icon(Icons.bar_chart_rounded),
              label: const Text('Refresh class summary'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _pastoralSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final students = [
      'Student A · Attendance dip',
      'Student B · Sleep concern',
      'Student C · Peer conflict',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Pastoral follow-up',
              subtitle:
                  'Simulated student signals and a non-diagnostic teacher action.',
            ),
            ...students.map(
              (student) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _selectedIndex == students.indexOf(student)
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: _selectedIndex == students.indexOf(student)
                      ? palette.primary
                      : palette.muted,
                ),
                title: Text(student),
                onTap: () =>
                    setState(() => _selectedIndex = students.indexOf(student)),
              ),
            ),
            TextField(
              controller: _textController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Teacher observation',
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log(
                  'Created a local pastoral flag for ${students[_selectedIndex]}.',
                );
                _textController.clear();
                _toast('Pastoral flag saved locally.');
              },
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Save pastoral flag'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _referralSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final stages = [
      'Observation recorded',
      'Pastoral review prepared',
      'Counselor handoff drafted',
      'Follow-up scheduled',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Referral workflow',
              subtitle:
                  'This is a clean local walkthrough of the later referral flow.',
            ),
            ...stages.asMap().entries.map(
              (entry) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text('${entry.key + 1}')),
                title: Text(entry.value),
                subtitle: Text(
                  entry.key <= _selectedIndex ? 'Complete' : 'Waiting',
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = (_selectedIndex + 1) % stages.length;
                });
                _log('Moved the local referral workflow forward.');
                _toast('Referral stage advanced.');
              },
              icon: const Icon(Icons.redo_rounded),
              label: const Text('Advance stage'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _queueSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final items = [
      'High priority signal · Review now',
      'Student help request · Awaiting first response',
      'Open case · Follow-up note needed',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Operational queue',
              subtitle:
                  'A mock triage queue with local filtering and action buttons.',
            ),
            ...items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.priority_high_rounded),
                title: Text(item),
                trailing: TextButton(
                  onPressed: () {
                    _log('Opened a queue item from ${widget.title}.');
                    _toast('Queue item opened locally.');
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Filtered the local support queue.');
                _toast('Queue filtered.');
              },
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Filter queue'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _caseSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Case activity',
              subtitle:
                  'A local case record with note-taking and state changes.',
            ),
            ...[
              'Created from a support request',
              'Assigned to counselor',
              'Parent-safe contact note drafted',
            ].map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(line, style: Theme.of(context).textTheme.bodyLarge),
              ),
            ),
            TextField(
              controller: _textController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Add case note'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _log('Added a local case note.');
                    _textController.clear();
                    _toast('Case note saved locally.');
                  },
                  icon: const Icon(Icons.note_add_rounded),
                  label: const Text('Save note'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _log('Marked the local case as reviewed.');
                    _toast('Case marked reviewed.');
                  },
                  icon: const Icon(Icons.task_alt_rounded),
                  label: const Text('Mark reviewed'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _approvalSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final requests = [
      'Teacher account · Green Valley School',
      'Counselor verification · Dr. Meera',
      'School admin onboarding · Riverstone Campus',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Approval workflow',
              subtitle:
                  'This screen simulates review actions and local reviewer notes.',
            ),
            ...requests.map(
              (request) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _selectedIndex == requests.indexOf(request)
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                  color: _selectedIndex == requests.indexOf(request)
                      ? palette.primary
                      : palette.muted,
                ),
                title: Text(request),
                onTap: () =>
                    setState(() => _selectedIndex = requests.indexOf(request)),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _log('Approved ${requests[_selectedIndex]} locally.');
                    _toast('Request approved locally.');
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Approve'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _log('Rejected ${requests[_selectedIndex]} locally.');
                    _toast('Request rejected locally.');
                  },
                  icon: const Icon(Icons.cancel_rounded),
                  label: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _contentReviewSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    final entries = [
      'Digital wellness parent guide',
      'Teacher burnout response note',
      'Sleep reset student module',
    ];
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Content review queue',
              subtitle:
                  'A local moderation flow that keeps the operational UI moving.',
            ),
            ...entries.map(
              (entry) => CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _completedItems.contains(entry),
                onChanged: (_) => _toggleCompleted(entry),
                title: Text(entry),
                subtitle: const Text('Mark reviewed or return for edits'),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Published reviewed local content from ${widget.title}.');
                _toast('Content marked approved locally.');
              },
              icon: const Icon(Icons.publish_rounded),
              label: const Text('Approve selected'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _thresholdSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Monitoring thresholds',
              subtitle:
                  'A handcrafted local control panel for safety-review demos.',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _primaryToggle,
              onChanged: (value) => setState(() => _primaryToggle = value),
              title: const Text('Escalate repeated high-risk language'),
            ),
            Slider(
              value: _sliderValue,
              onChanged: (value) => setState(() => _sliderValue = value),
            ),
            Text(
              'Sensitivity level: ${(100 * _sliderValue).round()}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                _log('Saved local threshold settings.');
                _toast('Thresholds updated locally.');
              },
              icon: const Icon(Icons.security_rounded),
              label: const Text('Save thresholds'),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _genericSections(
    BuildContext context,
    PrototypePalette palette,
  ) {
    return [
      GlassPanel(
        palette: palette,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionTitle(
              title: 'Prototype actions',
              subtitle:
                  'This generic page still behaves like a complete local demo.',
            ),
            TextField(
              controller: _textController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: 'Notes for ${widget.title}'),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () {
                    _log('Saved local notes for ${widget.title}.');
                    _textController.clear();
                    _toast('Saved locally.');
                  },
                  icon: const Icon(Icons.save_rounded),
                  label: const Text('Save'),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    _log('Marked ${widget.title} complete locally.');
                    _toast('Completed locally.');
                  },
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Complete'),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildRelatedSection(
    BuildContext context,
    PrototypePalette palette,
    _MockFlowKind kind,
  ) {
    final titles = _relatedTitles(kind);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(
          title: 'Next local pages',
          subtitle:
              'These buttons now move through the rest of the prototype with no backend dependency.',
        ),
        LayoutBuilder(
          builder: (context, constraints) => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: adaptiveGridCount(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .84,
            children: titles
                .map(
                  (title) => ActionCard(
                    palette: palette,
                    item: _buildCardItem(title),
                    onTap: () => context.go(detailPath(widget.role, title)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityLog(BuildContext context, PrototypePalette palette) {
    if (_activityLog.isEmpty) {
      return GlassPanel(
        palette: palette,
        child: const SectionTitle(
          title: 'Activity log',
          subtitle:
              'Your local interactions will appear here as you tap through the prototype.',
        ),
      );
    }
    return GlassPanel(
      palette: palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(
            title: 'Activity log',
            subtitle: 'A small local trace of your recent fake actions.',
          ),
          ..._activityLog.reversed.take(5).map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(entry, style: Theme.of(context).textTheme.bodyLarge),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _relatedTitles(_MockFlowKind kind) {
    return switch (widget.role) {
      AppRole.student => switch (kind) {
          _MockFlowKind.checkin => [
              'Learn Feed',
              'BAHA Buddy',
              'SOS Help',
            ],
          _MockFlowKind.module => [
              'Daily Check-in',
              'Digital Wellness',
              'Games Hub',
            ],
          _MockFlowKind.buddy => [
              'SOS Help',
              'Support Contacts',
              'Daily Check-in',
            ],
          _MockFlowKind.games => [
              'Emotion Wheel',
              'Calm Breathing',
              'Friendship Choices',
            ],
          _ => [
              'Daily Check-in',
              'Learn Feed',
              'BAHA Buddy',
            ],
        },
      AppRole.parent => switch (kind) {
          _MockFlowKind.consent => [
              'Parent Home',
              'Parent Resources',
              'Parent Notifications',
            ],
          _ => [
              'Parent Home',
              'Summary Sharing Consent',
              'Parent Resources',
            ],
        },
      AppRole.teacher => switch (kind) {
          _MockFlowKind.pastoral => [
              'Class Summary',
              'Referral Workflow',
              'Teacher Notifications',
            ],
          _ => [
              'Class List',
              'Pastoral Flag',
              'Teacher Resources',
            ],
        },
      AppRole.admin => switch (kind) {
          _MockFlowKind.queue => [
              'Case Detail',
              'Approval Requests',
              'Threshold Configuration',
            ],
          _ => [
              'Support Queue',
              'Approval Requests',
              'Content Review Workflow',
            ],
        },
    };
  }

  UiCardItem _buildCardItem(String title) {
    final allItems = [
      ...studentCards,
      ...learning,
      ...roleActions,
    ];
    for (final item in allItems) {
      if (item.title == title) {
        return item;
      }
    }
    if (_containsAny(_normalize(title), ['approval', 'review'])) {
      return UiCardItem(
        title: title,
        subtitle: 'Review activation requests in local demo mode.',
        tag: 'Review',
        icon: Icons.verified_rounded,
        color: Color(0xFFF59E0B),
      );
    }
    if (_containsAny(_normalize(title), ['queue', 'case'])) {
      return UiCardItem(
        title: title,
        subtitle: 'Open triage, notes, and follow-up actions.',
        tag: 'Ops',
        icon: Icons.monitor_heart_rounded,
        color: Color(0xFF38BDF8),
      );
    }
    if (_containsAny(_normalize(title), ['consent', 'link'])) {
      return UiCardItem(
        title: title,
        subtitle: 'Manage local sharing, participation, and linking states.',
        tag: 'Safe',
        icon: Icons.verified_user_rounded,
        color: Color(0xFF14B8A6),
      );
    }
    if (_containsAny(_normalize(title), ['notification'])) {
      return UiCardItem(
        title: title,
        subtitle: 'Review local reminders and status updates.',
        tag: 'Local',
        icon: Icons.notifications_rounded,
        color: Color(0xFFF59E0B),
      );
    }
    if (_containsAny(_normalize(title), ['game', 'breathing', 'emotion'])) {
      return UiCardItem(
        title: title,
        subtitle: 'Interactive local calming and reflection actions.',
        tag: 'Fun',
        icon: Icons.games_rounded,
        color: Color(0xFF8B5CF6),
      );
    }
    return UiCardItem(
      title: title,
      subtitle: 'A local demo page for $title.',
      tag: 'Local',
      icon: Icons.auto_awesome_rounded,
      color: const Color(0xFF6366F1),
    );
  }

  UiCardItem? _findItem(String title) {
    final allItems = [...studentCards, ...learning, ...roleActions];
    for (final item in allItems) {
      if (item.title == title) {
        return item;
      }
    }
    return null;
  }

  void _toggleCompleted(String key) {
    setState(() {
      if (_completedItems.contains(key)) {
        _completedItems.remove(key);
      } else {
        _completedItems.add(key);
      }
    });
  }

  void _sendMockChat() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast('Type a message first.');
      return;
    }
    setState(() {
      _messages = [
        ..._messages,
        ChatBubble(sender: 'You', text: text, isUser: true),
        const ChatBubble(
          sender: 'BAHA Buddy',
          text:
              'Thanks for sharing. In this UI-only build I can respond locally and keep the conversation moving.',
          isUser: false,
        ),
      ];
      _textController.clear();
    });
    _log('Sent a local Buddy message.');
  }

  void _showActionSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick demo actions',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.check_circle_rounded),
              title: const Text('Mark this page complete'),
              onTap: () {
                Navigator.pop(context);
                _log('Marked ${widget.title} complete from the quick menu.');
                _toast('Marked complete locally.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded),
              title: const Text('Reset local inputs'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _primaryToggle = true;
                  _secondaryToggle = false;
                  _sliderValue = 0.62;
                  _selectedIndex = 0;
                  _selectedChoice = 'Calm';
                  _textController.clear();
                  _messages = List<ChatBubble>.from(chatBubbles);
                });
                _log('Reset local state for ${widget.title}.');
                _toast('Local state reset.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.home_rounded),
              title: const Text('Return to dashboard'),
              onTap: () {
                Navigator.pop(context);
                context.go(homePath(widget.role));
              },
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _log(String message) {
    setState(() {
      _activityLog.add(message);
    });
  }

  bool _containsAny(String normalized, List<String> values) {
    return values.any((value) => normalized.contains(_normalize(value)));
  }
}

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
