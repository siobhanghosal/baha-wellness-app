import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../dummy_data/mock_data.dart';
import '../../models/prototype_models.dart';
import '../../navigation/app_router.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/prototype_widgets.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final palette =
        rolePalette(AppRole.admin, isDark: ThemeScope.of(context).isDark);
    final pages = [
      _command(palette),
      _approvals(palette),
      _content(palette),
      _system(palette)
    ];
    return Theme(
        data: buildTheme(palette),
        child: AnimatedGradientScaffold(
            palette: palette,
            bottomNavigationBar: SalomonBottomBar(
                currentIndex: tab,
                onTap: (i) => setState(() => tab = i),
                items: [
                  SalomonBottomBarItem(
                      icon: Icon(Icons.dashboard_rounded),
                      title: Text('Command')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.verified_rounded),
                      title: Text('Approvals')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.library_books_rounded),
                      title: Text('Content')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.monitor_heart_rounded),
                      title: Text('System'))
                ]),
            child: AnimatedSwitcher(duration: 320.ms, child: pages[tab])));
  }

  Widget _command(PrototypePalette palette) => ListView(
          key: const ValueKey('admin-command'),
          padding: const EdgeInsets.all(22),
          children: [
            DashboardTopBar(palette: palette),
            HeroHeader(
                palette: palette,
                kicker: 'BAHA Command Center',
                title: 'Clinical operations, queue, approvals, and safety.',
                subtitle:
                    'Enterprise dark dashboard aligned to the BAHA/Counselor app flow.',
                actions: const [
                  Pill(icon: Icons.dark_mode_rounded, label: 'Dark enterprise'),
                  Pill(icon: Icons.security_rounded, label: 'Governance')
                ]),
            const SizedBox(height: 18),
            LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: adaptiveGridCount(constraints.maxWidth),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .96,
                    children: adminMetrics
                        .map((m) => MetricTile(
                            palette: palette,
                            metric: m,
                            onTap: () =>
                                context.go(detailPath(AppRole.admin, m.label))))
                        .toList())),
            const SizedBox(height: 14),
            GlassPanel(
                palette: palette,
                onTap: () =>
                    context.go(detailPath(AppRole.admin, 'Support Queue')),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Support queue',
                          subtitle:
                              'Open cases, unresolved signals, and help requests.'),
                      ...[
                        '1 open case · Escalation review',
                        '1 unassigned signal · Emergency language',
                        '1 help request · Student support',
                      ].map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(line,
                              style:
                                  Theme.of(context).textTheme.bodyLarge))),
                    ])),
            const SizedBox(height: 14),
            LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: adaptiveGridCount(constraints.maxWidth),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .92,
                    children: [
                      ActionCard(
                          palette: palette,
                          item: const UiCardItem(
                              title: 'Case Detail',
                              subtitle:
                                  'Open a local case record with notes and status actions.',
                              tag: 'Case',
                              icon: Icons.folder_shared_rounded,
                              color: Color(0xFF38BDF8)),
                          onTap: () =>
                              context.go(detailPath(AppRole.admin, 'Case Detail'))),
                      ActionCard(
                          palette: palette,
                          item: const UiCardItem(
                              title: 'Threshold Configuration',
                              subtitle:
                                  'Adjust safety-review sensitivity in local demo mode.',
                              tag: 'Safety',
                              icon: Icons.tune_rounded,
                              color: Color(0xFFFBBF24)),
                          onTap: () => context.go(detailPath(
                              AppRole.admin, 'Threshold Configuration'))),
                    ])),
            const SizedBox(height: 14),
            GlassPanel(
                palette: palette,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Pilot analytics',
                          subtitle: 'School-level synthetic dashboard.'),
                      MiniLineChart(palette: palette)
                    ]))
          ]);
  Widget _approvals(PrototypePalette palette) => ListView(
          key: const ValueKey('admin-approvals'),
          padding: const EdgeInsets.all(22),
          children: [
            const SectionTitle(
                title: 'Approval requests',
                subtitle:
                    'Teachers, counselors, schools, and content moderation.'),
            ...[
              'Counselor verification · Dr. Meera',
              'School admin · Green Valley',
              'Teacher account · Class 10',
              'Content review · Sleep module'
            ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                    palette: palette,
                    onTap: () =>
                        context.go(detailPath(AppRole.admin, 'Approval Decision')),
                    child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pending_actions_rounded),
                        title: Text(s),
                        subtitle: const Text(
                            'Tap to inspect and approve in demo mode.'),
                        trailing: FilledButton(
                            onPressed: () =>
                                context.go(detailPath(
                                    AppRole.admin, 'Approval Decision')),
                            child: const Text('Review'))))))
            ,
            const SizedBox(height: 12),
            ActionCard(
                palette: palette,
                item: const UiCardItem(
                    title: 'Approval Requests',
                    subtitle:
                        'Open the full local approval workflow and simulated decisions.',
                    tag: 'Review',
                    icon: Icons.verified_rounded,
                    color: Color(0xFFF59E0B)),
                onTap: () =>
                    context.go(detailPath(AppRole.admin, 'Approval Requests')))
          ]);
  Widget _content(PrototypePalette palette) => LayoutBuilder(
        builder: (context, constraints) => GridView.count(
            key: const ValueKey('admin-content'),
            padding: const EdgeInsets.all(22),
            crossAxisCount: adaptiveGridCount(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .8,
            children: [
              const UiCardItem(
                  title: 'Operational Content',
                  subtitle:
                      'Read-only counselor-safe content and operational materials.',
                  tag: 'Partial',
                  icon: Icons.library_books_rounded,
                  color: Color(0xFF38BDF8)),
              const UiCardItem(
                  title: 'Content Review Workflow',
                  subtitle:
                      'Review and approve content locally without cloud dependency.',
                  tag: 'Review',
                  icon: Icons.fact_check_rounded,
                  color: Color(0xFFA78BFA)),
              ...learning,
              ...roleActions
            ]
                .map((item) => ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.admin, item.title))))
                .toList()),
      );
  Widget _system(PrototypePalette palette) => ListView(
          key: const ValueKey('admin-system'),
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
                palette: palette,
                kicker: 'System health',
                title: 'Everything looks operational.',
                subtitle:
                    'Queue health, support contacts, governance, and system controls.',
                actions: const [
                  Pill(icon: Icons.check_circle_rounded, label: '99.96%'),
                  Pill(icon: Icons.bolt_rounded, label: 'Fast')
                ]),
            const SizedBox(height: 18),
            GlassPanel(
                palette: palette,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Local BAHA tools',
                          subtitle:
                              'These operational flows are now reachable as local prototype pages.'),
                      ...[
                        'Support queue and case detail',
                        'Approval requests and decisions',
                        'Content review workflow',
                        'Threshold configuration and crisis contacts',
                      ].map((contract) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(contract,
                              style:
                                  Theme.of(context).textTheme.bodyLarge))),
                    ])),
            const SizedBox(height: 18),
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: const UiCardItem(
                        title: 'Expert Routing and Crisis Contacts',
                        subtitle:
                            'Open local support-routing and crisis reference details.',
                        tag: 'Safe',
                        icon: Icons.support_agent_rounded,
                        color: Color(0xFF38BDF8)),
                    onTap: () => context.go(detailPath(
                        AppRole.admin, 'Expert Routing and Crisis Contacts')))),
            ...roleActions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.admin, item.title)))))
          ]);
}
