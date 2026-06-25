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

class TeacherShell extends StatefulWidget {
  const TeacherShell({super.key});
  @override
  State<TeacherShell> createState() => _TeacherShellState();
}

class _TeacherShellState extends State<TeacherShell> {
  int tab = 0;
  @override
  Widget build(BuildContext context) {
    final palette =
        rolePalette(AppRole.teacher, isDark: ThemeScope.of(context).isDark);
    final pages = [
      _classes(palette),
      _students(palette),
      _tasks(palette),
      _reports(palette)
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
                      icon: Icon(Icons.groups_rounded), title: Text('Classes')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.favorite_rounded),
                      title: Text('Students')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.task_alt_rounded), title: Text('Tasks')),
                  SalomonBottomBarItem(
                      icon: Icon(Icons.bar_chart_rounded),
                      title: Text('Reports'))
                ]),
            child: AnimatedSwitcher(duration: 320.ms, child: pages[tab])));
  }

  Widget _classes(PrototypePalette palette) => ListView(
          key: const ValueKey('teacher-classes'),
          padding: const EdgeInsets.all(22),
          children: [
            DashboardTopBar(palette: palette),
            HeroHeader(
                palette: palette,
                kicker: 'Teacher Dashboard',
                title: 'Class wellbeing at a glance.',
                subtitle:
                    'Anonymized trends, attendance, alerts, and pastoral recommendations.',
                actions: const [
                  Pill(icon: Icons.school_rounded, label: 'Class 9B'),
                  Pill(
                      icon: Icons.privacy_tip_rounded,
                      label: 'No raw student data')
                ]),
            const SizedBox(height: 18),
            ...teacherMetrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MetricTile(
                    palette: palette,
                    metric: m,
                    onTap: () =>
                        context.go(detailPath(AppRole.teacher, m.label)))))
          ]);
  Widget _students(PrototypePalette palette) => ListView(
          key: const ValueKey('teacher-students'),
          padding: const EdgeInsets.all(22),
          children: [
            const SectionTitle(
                title: 'Student wellbeing signals',
                subtitle: 'Role-safe pastoral visibility.'),
            ...[
              'Student A · Sleep concern',
              'Student B · Attendance drop',
              'Student C · Peer conflict',
              'Student D · Improved check-ins'
            ].map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                    palette: palette,
                    onTap: () => context.go(detailPath(AppRole.teacher, s)),
                    child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const CircleAvatar(
                            child: Icon(Icons.person_rounded)),
                        title: Text(s),
                        subtitle: const Text(
                            'Tap for recommendations and communication options.'),
                        trailing: const Icon(Icons.chevron_right_rounded)))))
          ]);
  Widget _tasks(PrototypePalette palette) => LayoutBuilder(
        builder: (context, constraints) => GridView.count(
            key: const ValueKey('teacher-tasks'),
            padding: const EdgeInsets.all(22),
            crossAxisCount: adaptiveGridCount(constraints.maxWidth),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: .8,
            children: [...roleActions, ...learning.take(2)]
                .map((item) => ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.teacher, item.title))))
                .toList()),
      );
  Widget _reports(PrototypePalette palette) => ListView(
          key: const ValueKey('teacher-reports'),
          padding: const EdgeInsets.all(22),
          children: [
            GlassPanel(
                palette: palette,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Class report',
                          subtitle: 'Animated fake analytics.'),
                      MiniLineChart(palette: palette)
                    ])),
            const SizedBox(height: 14),
            ...timeline.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassPanel(
                    palette: palette,
                    onTap: () =>
                        context.go(detailPath(AppRole.teacher, e.title)),
                    child: Text('${e.time} · ${e.title}\n${e.detail}'))))
          ]);
}
