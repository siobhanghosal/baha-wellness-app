import 'dart:async';

import 'package:baha_api_client/baha_api_client.dart';
import 'package:baha_shared_models/baha_shared_models.dart';
import 'package:flutter/material.dart';

import '../prototype/app_theme.dart';
import '../prototype/prototype_widgets.dart';
import '../prototype/theme_manager.dart';

class StudentBuddyScreen extends StatefulWidget {
  const StudentBuddyScreen({
    required this.apiClient,
    required this.identity,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;

  @override
  State<StudentBuddyScreen> createState() => _StudentBuddyScreenState();
}

class _StudentBuddyScreenState extends State<StudentBuddyScreen> {
  late Future<List<ChatSessionSummary>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<ChatSessionSummary>> _load() {
    return widget.apiClient.listChatSessions(identity: widget.identity);
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _startSession() async {
    try {
      final session = await widget.apiClient.createChatSession(
        identity: widget.identity,
      );
      if (!mounted) {
        return;
      }
      await _pushThemedRoute(
        builder: (context) => StudentBuddyChatScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          session: session,
        ),
      );
      await _refresh();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
  }

  Future<void> _openSession(ChatSessionSummary session) async {
    await _pushThemedRoute(
      builder: (context) => StudentBuddyChatScreen(
        apiClient: widget.apiClient,
        identity: widget.identity,
        session: session,
      ),
    );
    await _refresh();
  }

  Future<void> _pushThemedRoute({required WidgetBuilder builder}) async {
    final controller = ThemeScope.of(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => ThemeScope(
          controller: controller,
          child: AnimatedBuilder(
            animation: controller,
            builder: (context, _) => builder(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<ChatSessionSummary>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [ShimmerBlock(palette: palette)],
                );
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(22),
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        const Spacer(),
                        ThemeModeToggle(palette: palette),
                      ],
                    ),
                    HeroHeader(
                      palette: palette,
                      kicker: 'BAHA Buddy',
                      title: 'Could not load Buddy sessions',
                      subtitle: '${snapshot.error}',
                      actions: const [
                        Pill(icon: Icons.warning_rounded, label: 'Retry'),
                      ],
                    ),
                    const SizedBox(height: 18),
                    AnimatedPrimaryButton(
                      label: 'Reload sessions',
                      icon: Icons.refresh_rounded,
                      onPressed: () => unawaited(_refresh()),
                    ),
                  ],
                );
              }
              final sessions = snapshot.data ?? const <ChatSessionSummary>[];
              return ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Spacer(),
                      ThemeModeToggle(palette: palette),
                    ],
                  ),
                  HeroHeader(
                    palette: palette,
                    kicker: 'BAHA Buddy',
                    title: 'A companion, not a clinician.',
                    subtitle:
                        'Start a private support conversation backed by the live BAHA backend chat runtime.',
                    actions: [
                      const Pill(
                        icon: Icons.verified_rounded,
                        label: 'Safe Q&A',
                      ),
                      const Pill(icon: Icons.sos_rounded, label: 'Escalation'),
                      Pill(
                        icon: Icons.cloud_done_rounded,
                        label: '${sessions.length} sessions',
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Start chatting',
                          subtitle: 'Create a new real Buddy conversation.',
                        ),
                        AnimatedPrimaryButton(
                          label: 'Start new Buddy chat',
                          icon: Icons.chat_rounded,
                          onPressed: _startSession,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassPanel(
                    palette: palette,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle(
                          title: 'Recent sessions',
                          subtitle: 'Live session list from the API.',
                        ),
                        if (sessions.isEmpty)
                          Text(
                            'No Buddy sessions yet. Start the first one above.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          )
                        else
                          ...sessions.map(
                            (session) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: GlassPanel(
                                palette: palette,
                                padding: const EdgeInsets.all(16),
                                onTap: () => _openSession(session),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: palette.primary.withValues(
                                          alpha: .16,
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Icon(
                                        Icons.forum_outlined,
                                        color: palette.primary,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Buddy chat',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            [
                                              session.status,
                                              '${session.messageCount} messages',
                                              _formatDateTime(
                                                session.lastMessageAt ??
                                                    session.startedAt,
                                              ),
                                            ].join(' • '),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  color: palette.muted,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: palette.muted,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class StudentBuddyChatScreen extends StatefulWidget {
  const StudentBuddyChatScreen({
    required this.apiClient,
    required this.identity,
    required this.session,
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final ChatSessionSummary session;

  @override
  State<StudentBuddyChatScreen> createState() => _StudentBuddyChatScreenState();
}

class _StudentBuddyChatScreenState extends State<StudentBuddyChatScreen> {
  final _messageController = TextEditingController();
  late Future<List<MobileChatMessage>> _future;
  List<MobileChatMessage>? _messages;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<List<MobileChatMessage>> _load() async {
    final messages = await widget.apiClient.listChatMessages(
      identity: widget.identity,
      sessionId: widget.session.id,
    );
    _messages = messages;
    return messages;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  Future<void> _send() async {
    final body = _messageController.text.trim();
    if (body.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Type at least 3 characters to send a message.'),
        ),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      final exchange = await widget.apiClient.createChatMessage(
        identity: widget.identity,
        sessionId: widget.session.id,
        request: MobileChatMessageCreateRequest(body: body),
      );
      if (!mounted) {
        return;
      }
      _messageController.clear();
      setState(() {
        _messages = <MobileChatMessage>[
          ...?_messages,
          exchange.userMessage,
          exchange.assistantMessage,
        ];
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = appPaletteForTheme(
      ThemeScope.of(context).colorTheme,
      isDark: ThemeScope.of(context).isDark,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Text(
                      'Buddy Chat',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<MobileChatMessage>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (_messages != null) {
                      return _ChatMessageList(
                        messages: _messages!,
                        palette: palette,
                      );
                    }
                    if (snapshot.connectionState != ConnectionState.done) {
                      return ListView(
                        padding: const EdgeInsets.all(22),
                        children: [ShimmerBlock(palette: palette)],
                      );
                    }
                    if (snapshot.hasError) {
                      return ListView(
                        padding: const EdgeInsets.all(22),
                        children: [
                          GlassPanel(
                            palette: palette,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Could not load this Buddy conversation.',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: 8),
                                Text('${snapshot.error}'),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => unawaited(_refresh()),
                                  icon: const Icon(Icons.refresh_rounded),
                                  label: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    final messages =
                        snapshot.data ?? const <MobileChatMessage>[];
                    _messages = messages;
                    return _ChatMessageList(
                      messages: messages,
                      palette: palette,
                    );
                  },
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: GlassPanel(
                  palette: palette,
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Talk to BAHA Buddy',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 88,
                        child: FilledButton(
                          onPressed: _sending ? null : _send,
                          child: Text(_sending ? '...' : 'Send'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageList extends StatelessWidget {
  const _ChatMessageList({required this.messages, required this.palette});

  final List<MobileChatMessage> messages;
  final PrototypePalette palette;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          GlassPanel(
            palette: palette,
            child: const Text(
              'No messages yet. Start the conversation with BAHA Buddy.',
            ),
          ),
        ],
      );
    }
    final theme = Theme.of(context).textTheme;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.senderType == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.only(bottom: 12),
            child: GlassPanel(
              palette: palette,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isUser ? 'You' : 'Buddy',
                    style: theme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(message.body, style: theme.bodyLarge),
                  const SizedBox(height: 8),
                  Text(
                    _formatDateTime(message.createdAt),
                    style: theme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _formatDateTime(DateTime date) {
  final local = date.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${_formatDate(local)} ${local.hour}:$minute';
}
