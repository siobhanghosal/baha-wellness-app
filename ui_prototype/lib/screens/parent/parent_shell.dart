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

class ParentShell extends StatefulWidget {
  const ParentShell({super.key});
  @override
  State<ParentShell> createState() => _ParentShellState();
}

class _ParentShellState extends State<ParentShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final palette =
        rolePalette(AppRole.parent, isDark: ThemeScope.of(context).isDark);
    final pages = [
      _overview(palette),
      _reports(palette),
      _resources(palette),
      _settings(palette)
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
                      icon: Icon(Icons.home_rounded), title: Text('Home')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.analytics_rounded),
                      title: Text('Reports')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.menu_book_rounded),
                      title: Text('Resources')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.settings_rounded),
                      title: Text('Settings'))
                ]),
            child: AnimatedSwitcher(duration: 320.ms, child: pages[tab])));
  }

  Widget _overview(PrototypePalette palette) => ListView(
          key: const ValueKey('parent-home'),
          padding: const EdgeInsets.all(22),
          children: [
            DashboardTopBar(palette: palette),
            HeroHeader(
                palette: palette,
                kicker: 'Parent Dashboard',
                title: 'Support without surveillance.',
                subtitle:
                    'Consent-aware summaries, conversation prompts, and family resources.',
                actions: const [
                  Pill(
                      icon: Icons.verified_user_rounded,
                      label: 'Consent gated'),
                  Pill(icon: Icons.family_restroom_rounded, label: '2 children')
                ]),
            const SizedBox(height: 18),
            ...parentMetrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MetricTile(
                    palette: palette,
                    metric: m,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, m.label))))),
            GlassPanel(
                palette: palette,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Weekly mood graph',
                          subtitle: 'Aggregate trend only.'),
                      MiniLineChart(palette: palette)
                    ]))
          ]);
  Widget _reports(PrototypePalette palette) => ListView(
          key: const ValueKey('parent-reports'),
          padding: const EdgeInsets.all(22),
          children: [
            const SectionTitle(
                title: 'Reports and insights',
                subtitle: 'Daily, weekly, and monthly fake reports.'),
            ...timeline.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                    palette: palette,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, e.title)),
                    child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                            backgroundColor: e.color.withValues(alpha: .16),
                            child:
                                Icon(Icons.insights_rounded, color: e.color)),
                        title: Text(e.title),
                        subtitle: Text('${e.time} · ${e.detail}'),
                        trailing: const Icon(Icons.chevron_right_rounded)))))
          ]);
  Widget _resources(PrototypePalette palette) => LayoutBuilder(
        builder: (context, constraints) => GridView.count(
            key: const ValueKey('parent-resources'),
            padding: const EdgeInsets.all(22),
            crossAxisCount: adaptiveGridCount(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .8,
            children: learning
                .map((item) => ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, item.title))))
                .toList()),
      );
  Widget _settings(PrototypePalette palette) => ListView(
          key: const ValueKey('parent-settings'),
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
                palette: palette,
                kicker: 'Family settings',
                title: 'Consent, appointments, chat, and privacy.',
                subtitle: 'All controls open local demo pages.',
                actions: const [
                  Pill(icon: Icons.lock_rounded, label: 'Privacy'),
                  Pill(icon: Icons.chat_rounded, label: 'Chat')
                ]),
            const SizedBox(height: 18),
            ...roleActions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, item.title)))))
          ]);
}
