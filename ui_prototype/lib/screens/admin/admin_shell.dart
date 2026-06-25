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
                title: 'Clinical operations, content, schools, and safety.',
                subtitle:
                    'Enterprise dark dashboard with fake analytics and live-feeling controls.',
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
                    onTap: () => context.go(detailPath(AppRole.admin, s)),
                    child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.pending_actions_rounded),
                        title: Text(s),
                        subtitle: const Text(
                            'Tap to inspect and approve in demo mode.'),
                        trailing: FilledButton(
                            onPressed: () =>
                                context.go(detailPath(AppRole.admin, s)),
                            child: const Text('Review'))))))
          ]);
  Widget _content(PrototypePalette palette) => LayoutBuilder(
        builder: (context, constraints) => GridView.count(
            key: const ValueKey('admin-content'),
            padding: const EdgeInsets.all(22),
            crossAxisCount: adaptiveGridCount(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .8,
            children: [...learning, ...roleActions]
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
                    'Fake queues, uptime, AI insights, notifications, and reports.',
                actions: const [
                  Pill(icon: Icons.check_circle_rounded, label: '99.96%'),
                  Pill(icon: Icons.bolt_rounded, label: 'Fast')
                ]),
            const SizedBox(height: 18),
            ...roleActions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.admin, item.title)))))
          ]);
}
