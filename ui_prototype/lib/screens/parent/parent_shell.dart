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
      _summary(palette),
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
                      title: Text('Summary')),
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
                  Pill(icon: Icons.family_restroom_rounded, label: 'Linked child')
                ]),
            const SizedBox(height: 18),
            ...parentMetrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MetricTile(
                    palette: palette,
                    metric: m,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, m.label))))),
            const SizedBox(height: 10),
            GlassPanel(
                palette: palette,
                onTap: () =>
                    context.go(detailPath(AppRole.parent, 'Parent Home')),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Linked students',
                          subtitle:
                              'This prototype now reflects the parent linked-student flow.'),
                      ...[
                        'Aarav Demo · Early Teen · Primary guardian',
                        'Visible summary only after consent',
                      ].map((line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(line,
                              style:
                                  Theme.of(context).textTheme.bodyLarge))),
                    ])),
            const SizedBox(height: 10),
            LayoutBuilder(
                builder: (context, constraints) => GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: adaptiveGridCount(constraints.maxWidth),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: .9,
                    children: [
                      ActionCard(
                          palette: palette,
                          item: const UiCardItem(
                              title: 'Link Child Account',
                              subtitle:
                                  'Open a local child-linking and relationship flow.',
                              tag: 'Link',
                              icon: Icons.link_rounded,
                              color: Color(0xFF14B8A6)),
                          onTap: () => context.go(
                              detailPath(AppRole.parent, 'Link Child Account'))),
                      ActionCard(
                          palette: palette,
                          item: const UiCardItem(
                              title: 'Parent Notifications',
                              subtitle:
                                  'Review family-safe reminders and updates locally.',
                              tag: 'Updates',
                              icon: Icons.notifications_rounded,
                              color: Color(0xFFF59E0B)),
                          onTap: () => context.go(
                              detailPath(AppRole.parent, 'Parent Notifications'))),
                    ])),
            const SizedBox(height: 10),
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
  Widget _summary(PrototypePalette palette) => ListView(
          key: const ValueKey('parent-summary'),
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
                palette: palette,
                kicker: 'Student Summary',
                title: 'Conversation-safe weekly summary',
                subtitle:
                    'This tab now aligns to the parent weekly summary and consent surfaces from the app flow docs.',
                actions: const [
                  Pill(icon: Icons.lock_rounded, label: 'Consent-aware'),
                  Pill(icon: Icons.family_restroom_rounded, label: 'Parent-safe')
                ]),
            const SizedBox(height: 18),
            GlassPanel(
                palette: palette,
                onTap: () => context
                    .go(detailPath(AppRole.parent, 'Summary Sharing Consent')),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Summary sharing consent',
                          subtitle:
                              'This local build opens a working fake guardian sharing flow.'),
                      Text(
                          'Try granting, revoking, and revisiting summary access without any backend dependency.',
                          style: Theme.of(context).textTheme.bodyLarge),
                    ])),
            const SizedBox(height: 12),
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: const UiCardItem(
                        title: 'Platform Participation Consent',
                        subtitle:
                            'Simulate minor-participation approval and revoke flows.',
                        tag: 'Consent',
                        icon: Icons.verified_user_rounded,
                        color: Color(0xFF14B8A6)),
                    onTap: () => context.go(detailPath(
                        AppRole.parent, 'Platform Participation Consent')))),
            ...timeline.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                    palette: palette,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, 'Parent Home')),
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
                        context.go(detailPath(
                            AppRole.parent, 'Parent Resources'))))
                .toList()),
      );
  Widget _settings(PrototypePalette palette) => ListView(
          key: const ValueKey('parent-settings'),
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
                palette: palette,
                kicker: 'Family settings',
                title: 'Consent, support contacts, and privacy.',
                subtitle:
                    'This settings surface is now aligned to parent linking and support references.',
                actions: const [
                  Pill(icon: Icons.lock_rounded, label: 'Privacy'),
                  Pill(icon: Icons.chat_rounded, label: 'Chat')
                ]),
            const SizedBox(height: 18),
            GlassPanel(
                palette: palette,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Planned backend links',
                          subtitle:
                              'These pages are now all available as local UI flows.'),
                      ...[
                        'Link child account',
                        'Summary sharing consent',
                        'Platform participation consent',
                        'Parent notifications',
                      ].map((contract) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text(contract,
                              style:
                                  Theme.of(context).textTheme.bodyLarge))),
                    ])),
            const SizedBox(height: 14),
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: const UiCardItem(
                        title: 'Parent Notifications',
                        subtitle:
                            'Open a local reminder center for guardians.',
                        tag: 'Local',
                        icon: Icons.notifications_rounded,
                        color: Color(0xFFF59E0B)),
                    onTap: () => context.go(
                        detailPath(AppRole.parent, 'Parent Notifications')))),
            ...roleActions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.parent, item.title)))))
          ]);
}
