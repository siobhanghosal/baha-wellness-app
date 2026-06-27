import 'package:flutter/material.dart';

class StudentErrorScreen extends StatelessWidget {
  const StudentErrorScreen({
    required this.errorMessage,
    required this.onRetry,
    required this.onResetIdentity,
    super.key,
  });

  final String? errorMessage;
  final Future<void> Function() onRetry;
  final Future<void> Function() onResetIdentity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Text('Session failed', style: theme.headlineMedium),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'The app could not complete the startup flow.',
                style: theme.bodyLarge,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onResetIdentity,
                child: const Text('Reset development identity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
