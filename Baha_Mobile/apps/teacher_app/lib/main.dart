import 'package:baha_design_system/baha_design_system.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const TeacherApp());
}

class TeacherApp extends StatelessWidget {
  const TeacherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BAHA Teacher',
      debugShowCheckedModeBanner: false,
      theme: BahaTheme.light(),
      home: const _StakeholderPlaceholder(
        title: 'Teacher app scaffolded',
        body: 'The teacher class list and cohort summary slice will build on the shared student session foundation.',
      ),
    );
  }
}

class _StakeholderPlaceholder extends StatelessWidget {
  const _StakeholderPlaceholder({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: BahaSurface(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.headlineMedium),
                  const SizedBox(height: 12),
                  Text(body, style: theme.bodyLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
