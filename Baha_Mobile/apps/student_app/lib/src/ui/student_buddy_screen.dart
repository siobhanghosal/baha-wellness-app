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
    this.heroKicker = 'BAHA Buddy',
    this.heroTitle = 'A calm place to talk things through.',
    this.heroSubtitle =
        'Ask questions, share how your day feels, or talk through something on your mind.',
    this.startSectionTitle = 'Start a conversation',
    this.startSectionSubtitle = 'Open a new chat whenever you want support.',
    this.startButtonLabel = 'Start new chat',
    this.sessionsSectionTitle = 'Recent sessions',
    this.sessionsSectionSubtitle = 'Pick up where you left off.',
    this.emptySessionsMessage =
        'No chats yet. Start one above when you are ready.',
    this.sessionType = 'general_support',
    this.chatScreenTitle = 'Buddy',
    this.chatInputHint = 'Message Buddy',
    this.emptyConversationMessage =
        'Your conversation will appear here.',
    this.assistantName = 'Buddy',
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String heroKicker;
  final String heroTitle;
  final String heroSubtitle;
  final String startSectionTitle;
  final String startSectionSubtitle;
  final String startButtonLabel;
  final String sessionsSectionTitle;
  final String sessionsSectionSubtitle;
  final String emptySessionsMessage;
  final String sessionType;
  final String chatScreenTitle;
  final String chatInputHint;
  final String emptyConversationMessage;
  final String assistantName;

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
        request: ChatSessionCreateRequest(sessionType: widget.sessionType),
      );
      if (!mounted) {
        return;
      }
      await _pushThemedRoute(
        builder: (context) => StudentBuddyChatScreen(
          apiClient: widget.apiClient,
          identity: widget.identity,
          session: session,
          screenTitle: widget.chatScreenTitle,
          inputHint: widget.chatInputHint,
          emptyConversationMessage: widget.emptyConversationMessage,
          assistantName: widget.assistantName,
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
        screenTitle: widget.chatScreenTitle,
        inputHint: widget.chatInputHint,
        emptyConversationMessage: widget.emptyConversationMessage,
        assistantName: widget.assistantName,
      ),
    );
    await _refresh();
  }

  Future<void> _pushThemedRoute({required WidgetBuilder builder}) async {
    final controller = ThemeScope.maybeOf(context);
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => controller == null
            ? builder(context)
            : ThemeScope(
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
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
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
                    kicker: widget.heroKicker,
                    title: widget.heroTitle,
                    subtitle: widget.heroSubtitle,
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
                        SectionTitle(
                          title: widget.startSectionTitle,
                          subtitle: widget.startSectionSubtitle,
                        ),
                        AnimatedPrimaryButton(
                          label: widget.startButtonLabel,
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
                        SectionTitle(
                          title: widget.sessionsSectionTitle,
                          subtitle: widget.sessionsSectionSubtitle,
                        ),
                        if (sessions.isEmpty)
                          Text(
                            widget.emptySessionsMessage,
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

class StudentBuddyDirectScreen extends StatefulWidget {
  const StudentBuddyDirectScreen({
    required this.apiClient,
    required this.identity,
    this.sessionType = 'general_support',
    this.screenTitle = 'Buddy',
    this.inputHint = 'Message Buddy',
    this.emptyConversationMessage = 'Your conversation will appear here.',
    this.assistantName = 'Buddy',
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final String sessionType;
  final String screenTitle;
  final String inputHint;
  final String emptyConversationMessage;
  final String assistantName;

  @override
  State<StudentBuddyDirectScreen> createState() =>
      _StudentBuddyDirectScreenState();
}

class _StudentBuddyDirectScreenState extends State<StudentBuddyDirectScreen> {
  bool _launching = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_openLatestOrCreate());
    });
  }

  Future<void> _openLatestOrCreate() async {
    try {
      final sessions = await widget.apiClient.listChatSessions(
        identity: widget.identity,
      );
      ChatSessionSummary session;
      if (sessions.isNotEmpty) {
        final sorted = [...sessions]..sort((a, b) {
          final aDate = a.lastMessageAt ?? a.startedAt;
          final bDate = b.lastMessageAt ?? b.startedAt;
          return bDate.compareTo(aDate);
        });
        session = sorted.first;
      } else {
        session = await widget.apiClient.createChatSession(
          identity: widget.identity,
          request: ChatSessionCreateRequest(sessionType: widget.sessionType),
        );
      }
      if (!mounted) {
        return;
      }
      final controller = ThemeScope.maybeOf(context);
      final route = MaterialPageRoute<void>(
        builder: (context) => controller == null
            ? StudentBuddyChatScreen(
                apiClient: widget.apiClient,
                identity: widget.identity,
                session: session,
                screenTitle: widget.screenTitle,
                inputHint: widget.inputHint,
                emptyConversationMessage: widget.emptyConversationMessage,
                assistantName: widget.assistantName,
              )
            : ThemeScope(
                controller: controller,
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => StudentBuddyChatScreen(
                    apiClient: widget.apiClient,
                    identity: widget.identity,
                    session: session,
                    screenTitle: widget.screenTitle,
                    inputHint: widget.inputHint,
                    emptyConversationMessage: widget.emptyConversationMessage,
                    assistantName: widget.assistantName,
                  ),
                ),
              ),
      );
      await Navigator.of(context).pushReplacement(route);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _launching = false;
        _errorMessage = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
    );
    return Theme(
      data: buildTheme(palette),
      child: AnimatedGradientScaffold(
        palette: palette,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GlassPanel(
              palette: palette,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_launching) ...[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 18),
                    Text(
                      'Opening Buddy...',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Getting your conversation ready.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ] else ...[
                    Text(
                      'Buddy could not open right now',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _errorMessage ?? 'Please try again.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        setState(() {
                          _launching = true;
                          _errorMessage = null;
                        });
                        unawaited(_openLatestOrCreate());
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Try again'),
                    ),
                  ],
                ],
              ),
            ),
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
    this.screenTitle = 'Buddy Chat',
    this.inputHint = 'Talk to BAHA Buddy',
    this.emptyConversationMessage =
        'No messages yet. Start the conversation with BAHA Buddy.',
    this.assistantName = 'Buddy',
    super.key,
  });

  final BahaApiClient apiClient;
  final DevelopmentIdentity identity;
  final ChatSessionSummary session;
  final String screenTitle;
  final String inputHint;
  final String emptyConversationMessage;
  final String assistantName;

  @override
  State<StudentBuddyChatScreen> createState() => _StudentBuddyChatScreenState();
}

class _StudentBuddyChatScreenState extends State<StudentBuddyChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  late Future<List<MobileChatMessage>> _future;
  List<MobileChatMessage>? _messages;
  bool _sending = false;
  Timer? _loadingTimer;
  int _loadingFrame = 0;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
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
    _scrollToBottom();
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
    final now = DateTime.now().toUtc();
    final pendingUserId = 'pending-user-${now.microsecondsSinceEpoch}';
    final pendingAssistantId = 'pending-assistant-${now.microsecondsSinceEpoch}';
    final optimisticUser = MobileChatMessage(
      id: pendingUserId,
      chatSessionId: widget.session.id,
      senderType: 'user',
      messageType: 'user_query',
      ordinal: (_messages?.length ?? 0) + 1,
      body: body,
      createdAt: now,
      updatedAt: now,
    );
    final optimisticAssistant = MobileChatMessage(
      id: pendingAssistantId,
      chatSessionId: widget.session.id,
      senderType: 'assistant',
      messageType: 'assistant_pending',
      ordinal: (_messages?.length ?? 0) + 2,
      body: '',
      createdAt: now,
      updatedAt: now,
    );
    _messageController.clear();
    setState(() {
      _sending = true;
      _messages = <MobileChatMessage>[
        ...?_messages,
        optimisticUser,
        optimisticAssistant,
      ];
    });
    _startThinkingAnimation();
    _scrollToBottom();
    try {
      await for (final event in widget.apiClient.createChatMessageStream(
        identity: widget.identity,
        sessionId: widget.session.id,
        request: MobileChatMessageCreateRequest(body: body),
      )) {
        if (!mounted) {
          return;
        }
        if (event.isAck && event.userMessage != null) {
          setState(() {
            _messages = _replaceMessage(
              _messages,
              pendingUserId,
              event.userMessage!,
            );
          });
          _scrollToBottom();
          continue;
        }
        if (event.isDelta) {
          final partialBody = _currentMessageBody(pendingAssistantId) + (event.delta ?? '');
          setState(() {
            _messages = _replaceMessage(
              _messages,
              pendingAssistantId,
              _updatedMessage(
                _findMessage(pendingAssistantId) ?? optimisticAssistant,
                body: partialBody,
              ),
            );
          });
          _scrollToBottom();
          continue;
        }
        if (event.isComplete && event.assistantMessage != null) {
          setState(() {
            _messages = _replaceMessage(
              _messages,
              pendingAssistantId,
              event.assistantMessage!,
            );
          });
          _scrollToBottom();
        }
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _messages = _replaceMessage(
          _messages,
          pendingAssistantId,
          _updatedMessage(
            _findMessage(pendingAssistantId) ?? optimisticAssistant,
            body: 'Buddy could not reply right now. Please try again.',
            messageType: 'assistant_error',
          ),
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    } finally {
      _stopThinkingAnimation();
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  void _startThinkingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = Timer.periodic(const Duration(milliseconds: 420), (_) {
      if (!mounted || !_sending) {
        return;
      }
      setState(() {
        _loadingFrame = (_loadingFrame + 1) % 3;
      });
    });
  }

  void _stopThinkingAnimation() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
    _loadingFrame = 0;
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  MobileChatMessage? _findMessage(String id) {
    final messages = _messages;
    if (messages == null) {
      return null;
    }
    for (final message in messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  String _currentMessageBody(String id) {
    return _findMessage(id)?.body ?? '';
  }

  List<MobileChatMessage> _replaceMessage(
    List<MobileChatMessage>? messages,
    String id,
    MobileChatMessage replacement,
  ) {
    final items = <MobileChatMessage>[...?messages];
    final index = items.indexWhere((message) => message.id == id);
    if (index == -1) {
      items.add(replacement);
      return items;
    }
    items[index] = replacement;
    return items;
  }

  MobileChatMessage _updatedMessage(
    MobileChatMessage message, {
    String? body,
    String? messageType,
  }) {
    return MobileChatMessage(
      id: message.id,
      chatSessionId: message.chatSessionId,
      senderType: message.senderType,
      messageType: messageType ?? message.messageType,
      ordinal: message.ordinal,
      body: body ?? message.body,
      structuredPayload: message.structuredPayload,
      retrievalFilters: message.retrievalFilters,
      safetyLabels: message.safetyLabels,
      createdAt: message.createdAt,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ThemeScope.maybeOf(context);
    final palette = appPaletteForTheme(
      themeController?.colorTheme ?? AppColorTheme.growth,
      isDark: themeController?.isDark ?? false,
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
                      widget.screenTitle,
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
                        controller: _scrollController,
                        loadingFrame: _loadingFrame,
                        emptyConversationMessage:
                            widget.emptyConversationMessage,
                        assistantName: widget.assistantName,
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
                      controller: _scrollController,
                      loadingFrame: _loadingFrame,
                      emptyConversationMessage:
                          widget.emptyConversationMessage,
                      assistantName: widget.assistantName,
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
                          decoration: InputDecoration(
                            hintText: widget.inputHint,
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
  const _ChatMessageList({
    required this.messages,
    required this.palette,
    required this.controller,
    required this.loadingFrame,
    required this.emptyConversationMessage,
    required this.assistantName,
  });

  final List<MobileChatMessage> messages;
  final PrototypePalette palette;
  final ScrollController controller;
  final int loadingFrame;
  final String emptyConversationMessage;
  final String assistantName;

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(22),
        children: [
          GlassPanel(
            palette: palette,
            child: Text(emptyConversationMessage),
          ),
        ],
      );
    }
    final theme = Theme.of(context).textTheme;
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isUser = message.senderType == 'user';
        final isPendingAssistant =
            message.senderType == 'assistant' &&
            message.messageType == 'assistant_pending';
        final displayedBody = isPendingAssistant
            ? (message.body.isEmpty
                  ? '$assistantName is thinking${'.' * (loadingFrame + 1)}'
                  : '${message.body}  ')
            : message.body;
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
                    isUser ? 'You' : assistantName,
                    style: theme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    displayedBody,
                    style: theme.bodyLarge?.copyWith(
                      color: isPendingAssistant ? palette.text : null,
                    ),
                  ),
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
