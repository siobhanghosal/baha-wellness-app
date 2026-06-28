import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

class MobileContentBodyView extends StatelessWidget {
  const MobileContentBodyView({
    required this.blocks,
    this.plainText,
    super.key,
  });

  final List<MobileContentBlock> blocks;
  final String? plainText;

  @override
  Widget build(BuildContext context) {
    final normalizedBlocks = blocks.isEmpty
        ? _fallbackBlocksFromPlainText(plainText)
        : blocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in normalizedBlocks) ...[
          _ContentBlockView(block: block),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  List<MobileContentBlock> _fallbackBlocksFromPlainText(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return const <MobileContentBlock>[];
    }
    return <MobileContentBlock>[MobileContentBlock(type: 'text', value: text)];
  }
}

class _ContentBlockView extends StatelessWidget {
  const _ContentBlockView({required this.block});

  final MobileContentBlock block;

  @override
  Widget build(BuildContext context) {
    return switch (block.type) {
      'heading' => _HeadingBlock(value: block.value ?? ''),
      'bullet_list' => _ListBlock(
        title: _titleOrNull(block),
        items: _items(block),
        numbered: false,
      ),
      'checklist' => _ChecklistBlock(
        title: _titleOrNull(block),
        items: _items(block),
      ),
      'callout' => _CalloutBlock(
        title: _titleOrNull(block) ?? 'Takeaway',
        value: block.value ?? '',
      ),
      'reflection_prompt' => _ReflectionPromptBlock(
        title: _titleOrNull(block),
        prompt: block.value ?? '',
      ),
      'step_list' => _ListBlock(
        title: _titleOrNull(block),
        items: _items(block),
        numbered: true,
      ),
      _ => _TextBlock(value: block.value ?? _items(block).join('\n')),
    };
  }

  List<String> _items(MobileContentBlock block) {
    final rawItems = block.data['items'];
    if (rawItems is List) {
      return rawItems
          .map((item) => item.toString())
          .where((item) => item.trim().isNotEmpty)
          .toList();
    }
    final value = block.value ?? '';
    return value
        .split('\n')
        .map((item) => item.replaceFirst(RegExp(r'^\s*[-*]\s*'), '').trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  String? _titleOrNull(MobileContentBlock block) {
    final title = block.data['title']?.toString().trim();
    if (title == null || title.isEmpty) {
      return null;
    }
    return title;
  }
}

class _HeadingBlock extends StatelessWidget {
  const _HeadingBlock({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w900,
        height: 1.2,
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final paragraphs = value
        .split(RegExp(r'\n\s*\n'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < paragraphs.length; index++) ...[
          Text(
            paragraphs[index],
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.65,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (index != paragraphs.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ListBlock extends StatelessWidget {
  const _ListBlock({required this.items, required this.numbered, this.title});

  final String? title;
  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
        ],
        for (var index = 0; index < items.length; index++) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  numbered ? '${index + 1}.' : '•',
                  style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[index],
                  style: theme.bodyLarge?.copyWith(
                    fontSize: 16.5,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ChecklistBlock extends StatelessWidget {
  const _ChecklistBlock({required this.items, this.title});

  final String? title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Text(
            title!,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
        ],
        for (var index = 0; index < items.length; index++) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.primary.withValues(alpha: .16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    items[index],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16.5,
                      height: 1.55,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (index != items.length - 1) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _CalloutBlock extends StatelessWidget {
  const _CalloutBlock({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.secondary.withValues(alpha: .20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontSize: 16.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _ReflectionPromptBlock extends StatelessWidget {
  const _ReflectionPromptBlock({required this.prompt, this.title});

  final String? title;
  final String prompt;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.tertiary.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.tertiary.withValues(alpha: .18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title ?? 'Pause and reflect',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            prompt,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: 17,
              height: 1.65,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
