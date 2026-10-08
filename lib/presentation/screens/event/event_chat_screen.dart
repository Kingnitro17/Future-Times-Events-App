import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/event_model.dart';
import '../../../data/models/event_message.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/event_chat_repository.dart';
import '../../../data/repositories/ticket_repository.dart';
import '../../widgets/chat/sticker_picker.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/glass_app_bar.dart';
import '../../widgets/common/glass_container.dart';
import '../../widgets/common/premium_text_field.dart';

class EventChatScreen extends StatefulWidget {
  const EventChatScreen({
    super.key,
    required this.event,
    required this.authRepository,
    this.ticketRepository,
  });

  final EventModel event;
  final AuthRepository authRepository;
  final TicketRepository? ticketRepository;

  @override
  State<EventChatScreen> createState() => _EventChatScreenState();
}

class _EventChatScreenState extends State<EventChatScreen> {
  late final EventChatRepository _repository;
  late final Stream<List<EventMessage>> _messageStream;
  final TextEditingController _messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _canChat = false;
  bool _loadingTicket = true;
  bool _offline = false;
  final Map<String, EventMessage> _failedMessages = <String, EventMessage>{};

  @override
  void initState() {
    super.initState();
    _repository = EventChatRepository(authRepository: widget.authRepository);
    _messageStream = _repository.watchMessages(widget.event.id);
    _loadAccess();
  }

  Future<void> _loadAccess() async {
    final ticketRepo = widget.ticketRepository ??
        TicketRepository(authRepository: widget.authRepository);
    final hasTicket = await ticketRepo.hasViewableTicketForEvent(widget.event.id);
    if (!mounted) return;
    setState(() {
      _canChat = hasTicket;
      _loadingTicket = false;
    });
  }

  Future<void> _sendText() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_canChat) return;

    final userId = widget.authRepository.user?.id;
    if (userId == null) return;

    final localMessage = EventMessage(
      id: 'local_${DateTime.now().microsecondsSinceEpoch}',
      eventId: widget.event.id,
      senderId: userId,
      kind: 'text',
      body: text,
      createdAt: DateTime.now(),
      senderDisplayName: widget.authRepository.profile?['display_name']?.toString() ??
          (widget.authRepository.user?.email?.split('@').first ?? 'You'),
      reactionCounts: const {},
      myReactions: const [],
    );

    setState(() {
      _failedMessages[localMessage.id] = localMessage;
      _messageController.clear();
    });

    try {
      final sent = await _repository.sendText(
        eventId: widget.event.id,
        body: text,
      );
      setState(() {
        _failedMessages.remove(localMessage.id);
      });
      if (!mounted) return;
      _messageStream.listen((_) {});
      if (sent.body != null) {
        FocusScope.of(context).requestFocus(FocusNode());
      }
    } catch (_) {
      setState(() {
        _offline = true;
      });
    }
  }

  Future<void> _sendSticker(String sticker) async {
    if (!_canChat) return;
    try {
      await _repository.sendSticker(
        eventId: widget.event.id,
        stickerId: sticker,
      );
    } catch (_) {
      setState(() => _offline = true);
    }
  }

  Future<void> _sendImage() async {
    if (!_canChat) return;
    final xFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (xFile == null) return;

    try {
      await _repository.sendImage(
        eventId: widget.event.id,
        file: File(xFile.path),
      );
    } catch (_) {
      setState(() => _offline = true);
    }
  }

  Future<void> _react(EventMessage message, String emoji) async {
    try {
      await _repository.reactToMessage(
        messageId: message.id,
        emoji: emoji,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _deleteMessage(EventMessage message) async {
    if (message.senderId != widget.authRepository.user?.id) return;
    try {
      await _repository.deleteMessage(message.id);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _showMessageMenu(EventMessage message) {
    final actions = <Widget>[];
    for (final emoji in const ['❤️', '😂', '🔥', '👍', '😮', '😢']) {
      actions.add(
        ListTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 24)),
          title: Text('React with $emoji'),
          onTap: () => _react(message, emoji),
        ),
      );
    }

    if (message.senderId == widget.authRepository.user?.id) {
      actions.add(
        ListTile(
          leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          title: const Text('Delete', style: TextStyle(color: AppColors.error)),
          onTap: () => _deleteMessage(message),
        ),
      );
    }

    showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: actions,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingTicket) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_canChat) {
      return const Scaffold(
        appBar: GlassAppBar(title: 'Chat'),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: GlassContainer(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded, size: 42, color: AppColors.purple),
                  SizedBox(height: 16),
                  Text(
                    'You need a ticket to join the chat',
                    textAlign: TextAlign.center,
                    style: AppText.h2,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Purchase a ticket or claim access before joining this event discussion.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
    appBar: const GlassAppBar(title: 'Chat'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              widget.event.name.text,
              style: AppText.h2.copyWith(color: AppColors.text),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (_offline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: AppColors.surfaceMuted,
              child: Text(
                'Offline — messages will send when online',
                textAlign: TextAlign.center,
                style: AppText.caption.copyWith(color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            child: StreamBuilder<List<EventMessage>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                final messages = <EventMessage>[...(snapshot.data ?? const <EventMessage>[]), ..._failedMessages.values];
                messages.sort((a, b) => b.createdAt.compareTo(a.createdAt));

                if (messages.isEmpty) {
                  return const EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Be the first to say hi 👋',
                    message: 'Start the conversation with other attendees.',
                  );
                }

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isOwn = message.senderId == widget.authRepository.user?.id;
                    final bubbleColor = isOwn ? AppColors.purple : AppColors.surface;
                    final textColor = isOwn ? Colors.white : AppColors.text;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Align(
                        alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.78,
                          ),
                          child: GestureDetector(
                            onLongPress: () => _showMessageMenu(message),
                            child: Column(
                              crossAxisAlignment:
                                  isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (!isOwn)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 6, bottom: 4),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const CircleAvatar(
                                          radius: 10,
                                          backgroundColor: AppColors.purpleLight,
                                          child: Icon(Icons.person, color: Colors.white, size: 14),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          message.senderDisplayName ?? 'Attendee',
                                          style: AppText.micro.copyWith(color: AppColors.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: bubbleColor,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(18),
                                      topRight: const Radius.circular(18),
                                      bottomLeft: Radius.circular(isOwn ? 18 : 6),
                                      bottomRight: Radius.circular(isOwn ? 6 : 18),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (message.kind == 'image' && message.mediaUrl != null)
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            message.mediaUrl!,
                                            width: 220,
                                            height: 180,
                                            fit: BoxFit.cover,
                                          ),
                                        )
                                      else if (message.kind == 'sticker' || message.stickerId != null)
                                        Text(
                                          message.stickerId ?? '✨',
                                          style: const TextStyle(fontSize: 28),
                                        )
                                      else if (message.body != null)
                                        Text(
                                          message.body!,
                                          style: AppText.body.copyWith(color: textColor),
                                        ),
                                      if (_failedMessages.containsKey(message.id))
                                        GestureDetector(
                                          onTap: () => _sendText(),
                                          child: Container(
                                            margin: const EdgeInsets.only(top: 8),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.error.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(999),
                                            ),
                                            child: Text(
                                              'Retry',
                                              style: AppText.micro.copyWith(color: AppColors.error),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (message.reactionCounts.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, left: 6, right: 6),
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: message.reactionCounts.entries
                                          .map(
                                            (entry) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: AppColors.surface,
                                                border: Border.all(color: AppColors.border),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                '${entry.key} ${entry.value}',
                                                style: AppText.micro.copyWith(color: AppColors.textSecondary),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 6, right: 6, top: 6),
                                  child: Text(
                                    DateFormat.jm().format(message.createdAt),
                                    style: AppText.micro.copyWith(color: AppColors.textMuted),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: GlassContainer(
              padding: const EdgeInsets.all(8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () async {
                      final sticker = await showModalBottomSheet<String>(
                        context: context,
                        builder: (sheetContext) => const StickerPicker(),
                      );
                      if (sticker == null || sticker.isEmpty) return;
                      await _sendSticker(sticker);
                    },
                    icon: const Icon(Icons.sentiment_satisfied_alt_rounded),
                  ),
                  IconButton(
                    onPressed: _sendImage,
                    icon: const Icon(Icons.photo_library_outlined),
                  ),
                  Expanded(
                    child: PremiumTextField(
                      label: '',
                      hint: 'Write a message',
                      controller: _messageController,
                      maxLines: 5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: _sendText,
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _messageController.text.trim().isNotEmpty ? AppColors.purple : AppColors.surfaceMuted,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
