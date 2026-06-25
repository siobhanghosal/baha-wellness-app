import 'package:confetti/confetti.dart';
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

class StudentShell extends StatefulWidget {
  const StudentShell({super.key});
  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  int tab = 0;
  StudentGender gender = StudentGender.female;
  StudentAgeGroup age = StudentAgeGroup.teen;
  late final ConfettiController confetti = ConfettiController(duration: 900.ms);

  @override
  void dispose() {
    confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette =
        studentPalette(age, gender, isDark: ThemeScope.of(context).isDark);
    final pages = [
      _dashboard(palette),
      _discover(palette),
      _buddy(palette),
      _profile(palette)
    ];
    return Theme(
      data: buildTheme(palette),
      child: Stack(children: [
        AnimatedGradientScaffold(
          palette: palette,
          floatingActionButton: FloatingActionButton(
              onPressed: () {
                confetti.play();
                context.go(detailPath(AppRole.student, 'Daily Check-in'));
              },
              child: const Icon(Icons.favorite_rounded)),
          bottomNavigationBar: SalomonBottomBar(
              currentIndex: tab,
              onTap: (i) => setState(() => tab = i),
              items: [
                SalomonBottomBarItem(
                    icon: Icon(Icons.home_rounded), title: Text('Home')),
                SalomonBottomBarItem(
                    icon: Icon(Icons.explore_rounded), title: Text('Explore')),
                SalomonBottomBarItem(
                    icon: Icon(Icons.chat_rounded), title: Text('Buddy')),
                SalomonBottomBarItem(
                    icon: Icon(Icons.person_rounded), title: Text('Profile')),
              ]),
          child: AnimatedSwitcher(duration: 350.ms, child: pages[tab]),
        ),
        Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
                confettiController: confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false)),
      ]),
    );
  }

  Widget _dashboard(PrototypePalette palette) => ListView(
          key: const ValueKey('student-home'),
          padding: const EdgeInsets.all(22),
          children: [
            DashboardTopBar(palette: palette),
            HeroHeader(
                palette: palette,
                kicker: '${gender.label} · ${age.label}',
                title: 'Your private wellness world',
                subtitle: palette.story,
                actions: [
                  Pill(icon: palette.heroIcon, label: palette.name),
                  const Pill(icon: Icons.lock_rounded, label: 'Private')
                ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                  child: _selector<StudentAgeGroup>(palette, 'Age', age,
                      StudentAgeGroup.values, (v) => setState(() => age = v))),
              const SizedBox(width: 10),
              Expanded(
                  child: _selector<StudentGender>(palette, 'Gender', gender,
                      StudentGender.values, (v) => setState(() => gender = v)))
            ]),
            const SizedBox(height: 18),
            const SectionTitle(
                title: 'Today', subtitle: 'Tiny signals, no judgement.'),
            ...studentMetrics.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MetricTile(
                    palette: palette,
                    metric: m,
                    onTap: () =>
                        context.go(detailPath(AppRole.student, m.label))))),
            const SizedBox(height: 10),
            GlassPanel(
                palette: palette,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionTitle(
                          title: 'Wellness trend',
                          subtitle: 'A beautiful private graph.'),
                      MiniLineChart(palette: palette)
                    ])),
          ]);

  Widget _discover(PrototypePalette palette) => LayoutBuilder(
        builder: (context, constraints) => GridView.builder(
            key: const ValueKey('student-discover'),
            padding: const EdgeInsets.all(22),
            itemCount: studentCards.length + learning.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: adaptiveGridCount(constraints.maxWidth),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .78),
            itemBuilder: (context, index) {
              final items = [...studentCards, ...learning];
              return ActionCard(
                      palette: palette,
                      item: items[index],
                      onTap: () => context
                          .go(detailPath(AppRole.student, items[index].title)))
                  .animate(delay: (index * 50).ms)
                  .fadeIn()
                  .scale(begin: const Offset(.95, .95));
            }),
      );

  Widget _buddy(PrototypePalette palette) => ListView(
          key: const ValueKey('student-buddy'),
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
                palette: palette,
                kicker: 'BAHA Buddy',
                title: 'A companion, not a clinician.',
                subtitle:
                    'Ask safe questions, practice calming down, and find support paths.',
                actions: const [
                  Pill(icon: Icons.verified_rounded, label: 'Safe Q&A'),
                  Pill(icon: Icons.sos_rounded, label: 'Escalation')
                ]),
            const SizedBox(height: 18),
            ...chatBubbles.map((bubble) => Align(
                alignment: bubble.isUser
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ConstrainedBox(
                        constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width - 56),
                        child: GlassPanel(
                            palette: palette,
                            child:
                                Text('${bubble.sender}: ${bubble.text}')))))),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: TextField(
                      decoration: const InputDecoration(
                          hintText: 'Ask a fake question...'))),
              const SizedBox(width: 10),
              FloatingActionButton.small(
                  onPressed: () =>
                      context.go(detailPath(AppRole.student, 'BAHA Buddy')),
                  child: const Icon(Icons.send_rounded))
            ]),
            const SizedBox(height: 16),
            AnimatedPrimaryButton(
                label: 'Open SOS help',
                icon: Icons.health_and_safety_rounded,
                onPressed: () =>
                    context.go(detailPath(AppRole.student, 'SOS Help'))),
          ]);

  Widget _profile(PrototypePalette palette) => ListView(
          key: const ValueKey('student-profile'),
          padding: const EdgeInsets.all(22),
          children: [
            HeroHeader(
                palette: palette,
                kicker: 'Profile',
                title: 'Your style and progress',
                subtitle:
                    'Editable demo profile with achievements, badges, journal, and privacy.',
                actions: [
                  Pill(icon: Icons.palette_rounded, label: palette.name),
                  const Pill(
                      icon: Icons.emoji_events_rounded, label: '12 badges')
                ]),
            const SizedBox(height: 18),
            GlassPanel(
                palette: palette,
                child: Column(children: [
                  FloatingMascot(palette: palette),
                  const SizedBox(height: 14),
                  Text('Aarav / Ananya Demo',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  Text('Level 8 · Calm Explorer',
                      style: TextStyle(color: palette.muted))
                ])),
            const SizedBox(height: 14),
            ...roleActions.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ActionCard(
                    palette: palette,
                    item: item,
                    onTap: () =>
                        context.go(detailPath(AppRole.student, item.title))))),
          ]);

  Widget _selector<T>(PrototypePalette palette, String label, T value,
      List<T> values, ValueChanged<T> onChanged) {
    return GlassPanel(
        palette: palette,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                items: values
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v is StudentAgeGroup
                            ? v.label
                            : (v as StudentGender).label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                })));
  }
}
