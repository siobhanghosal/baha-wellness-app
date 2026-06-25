import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../dummy_data/mock_data.dart';
import '../../models/prototype_models.dart';
import '../../navigation/app_router.dart';
import '../../themes/app_theme.dart';
import '../../themes/theme_manager.dart';
import '../../widgets/prototype_widgets.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key, required this.role, required this.title});
  final AppRole role;
  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = rolePalette(role, isDark: ThemeScope.of(context).isDark);
    final allItems = [...studentCards, ...learning, ...roleActions];
    final matches = allItems.where((e) => e.title == title);
    final item = matches.isEmpty ? null : matches.first;
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showActionSheet(context, palette),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Action')),
        child: ListView(padding: const EdgeInsets.all(22), children: [
          Row(children: [
            IconButton(
                onPressed: () => context.go(homePath(role)),
                icon: const Icon(Icons.arrow_back_rounded)),
            const Spacer(),
            IconButton(
                onPressed: () => context.go(detailPath(role, 'Notifications')),
                icon: const Icon(Icons.notifications_rounded))
          ]),
          HeroHeader(
              palette: palette,
              kicker: role.label,
              title: title,
              subtitle: item?.subtitle ??
                  'A polished fake-data page with working actions, dialogs, charts, and preview content.',
              actions: [
                Pill(
                    icon: item?.icon ?? role.icon,
                    label: item?.tag ?? 'Prototype'),
                const Pill(icon: Icons.touch_app_rounded, label: 'Clickable')
              ]),
          const SizedBox(height: 18),
          GlassPanel(
              palette: palette,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionTitle(
                        title: 'Overview',
                        subtitle:
                            'This screen is fully local and designed to feel production-ready.'),
                    Text(
                        'The $title experience includes meaningful microcopy, status indicators, and action paths so demo users never hit a dead end.',
                        style: Theme.of(context).textTheme.bodyLarge),
                    const SizedBox(height: 16),
                    MiniLineChart(palette: palette),
                  ])),
          const SizedBox(height: 16),
          SectionTitle(
              title: 'Recommended next steps',
              subtitle: 'Every card opens another screen or interaction.'),
          ...roleActions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ActionCard(
                  palette: palette,
                  item: action,
                  onTap: () => context.go(detailPath(role, action.title))))),
          GlassPanel(
              palette: palette,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Demo controls',
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 10, runSpacing: 10, children: [
                      FilledButton.icon(
                          onPressed: () => _showSaved(context),
                          icon: const Icon(Icons.bookmark_rounded),
                          label: const Text('Save')),
                      OutlinedButton.icon(
                          onPressed: () => _showDialog(context, palette),
                          icon: const Icon(Icons.info_rounded),
                          label: const Text('Explain')),
                      OutlinedButton.icon(
                          onPressed: () => context.go(homePath(role)),
                          icon: const Icon(Icons.home_rounded),
                          label: const Text('Dashboard')),
                    ]),
                  ])),
        ]),
      ),
    );
  }

  void _showSaved(BuildContext context) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$title saved to demo profile.')));
  }

  void _showDialog(BuildContext context, PrototypePalette palette) {
    showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
                title: Text(title),
                content: const Text(
                    'This is a UI prototype interaction. In production this page would connect to reviewed BAHA content and operational data.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showSaved(context);
                      },
                      child: const Text('Looks good'))
                ])).then((_) {});
  }

  void _showActionSheet(BuildContext context, PrototypePalette palette) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) => Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick actions',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 12),
                  ListTile(
                      leading: const Icon(Icons.share_rounded),
                      title: const Text('Share preview'),
                      onTap: () {
                        Navigator.pop(context);
                        _showSaved(context);
                      }),
                  ListTile(
                      leading: const Icon(Icons.feedback_rounded),
                      title: const Text('Send feedback'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(detailPath(role, 'Feedback'));
                      }),
                  ListTile(
                      leading: const Icon(Icons.support_agent_rounded),
                      title: const Text('Contact support'),
                      onTap: () {
                        Navigator.pop(context);
                        context.go(detailPath(role, 'Support'));
                      })
                ])));
  }
}
