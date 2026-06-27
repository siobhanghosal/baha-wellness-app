import 'package:baha_design_system/baha_design_system.dart';
import 'package:flutter/material.dart';

class PlainTextBlock extends StatelessWidget {
  const PlainTextBlock({
    required this.title,
    required this.body,
    super.key,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return BahaSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.titleLarge),
          const SizedBox(height: 12),
          Text(body, style: theme.bodyLarge),
        ],
      ),
    );
  }
}
