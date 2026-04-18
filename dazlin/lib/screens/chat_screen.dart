// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import '../widgets/dazlin_avatar.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _msgCtrl     = TextEditingController();
  final _scrollCtrl  = ScrollController();
  bool _sending      = false;
  String? _replyToId;
  String? _replyPreview;

  String get _chatId => widget.chat.id;
  String get _myId   => AuthService.currentUser!.id;

  @override
  void initState() {
    super.initState();
    ChatService.startMessagesPolling(_chatId);
    ApiService.markRead(_chatId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    ChatService.stopMessagesPolling(_chatId);
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animated = false}) {
    if (!_scrollCtrl.hasClients) return;
    if (animated) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
    }
  }

  Future<void> _send() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    _msgCtrl.clear();
    final replyId      = _replyToId;
    final replyPreview = _replyPreview;
    setState(() { _replyToId = null; _replyPreview = null; });

    try {
      await ChatService.sendMessage(
        chatId:    _chatId,
        content:   text,
        replyToId: replyId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animated: true));
    } catch (_) {
      // Restore text on failure
      _msgCtrl.text = text;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.chat.displayName(_myId);
    final av   = widget.chat.displayAvatar(_myId);

    return Scaffold(
      backgroundColor: DazlinTheme.bg,
      appBar: AppBar(
        backgroundColor: DazlinTheme.surface,
        leadingWidth:    40,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
          color: DazlinTheme.textSecondary,
        ),
        title: Row(
          children: [
            DazlinAvatar(url: av, initials: name.isNotEmpty ? name[0] : '?', size: 36),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                  style: const TextStyle(
                    color:      DazlinTheme.textPrimary,
                    fontSize:   15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Text('tap here for info',
                  style: TextStyle(color: DazlinTheme.textMuted, fontSize: 11)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, color: DazlinTheme.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: DazlinTheme.textSecondary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: DazlinTheme.textSecondary),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DazlinTheme.border),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          if (_replyToId != null) _buildReplyBar(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() => StreamBuilder<List<MessageModel>>(
    stream: ChatService.messagesStream(_chatId),
    initialData: ChatService.cachedMessages(_chatId),
    builder: (ctx, snap) {
      final msgs = snap.data ?? [];
      if (msgs.isEmpty && snap.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator(
          color: DazlinTheme.lime, strokeWidth: 2,
        ));
      }
      if (msgs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.waving_hand_outlined, color: DazlinTheme.lime, size: 36),
              const SizedBox(height: 12),
              const Text('Say hello!',
                style: TextStyle(color: DazlinTheme.textSecondary, fontSize: 15)),
            ],
          ),
        );
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

      return ListView.builder(
        controller:  _scrollCtrl,
        padding:     const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        itemCount:   msgs.length,
        itemBuilder: (ctx, i) {
          final msg  = msgs[i];
          final prev = i > 0 ? msgs[i - 1] : null;
          final isMine       = msg.senderId == _myId;
          final showDate     = prev == null || !_sameDay(prev.createdAt, msg.createdAt);
          final showSender   = !isMine && (prev == null || prev.senderId != msg.senderId);

          return Column(
            children: [
              if (showDate) _buildDateDivider(msg.createdAt),
              _MessageBubble(
                msg:        msg,
                isMine:     isMine,
                showSender: showSender,
                onReply: () => setState(() {
                  _replyToId     = msg.id;
                  _replyPreview  = msg.content.length > 60
                      ? '${msg.content.substring(0, 60)}…'
                      : msg.content;
                }),
              ),
            ],
          );
        },
      );
    },
  );

  Widget _buildDateDivider(DateTime d) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        const Expanded(child: Divider(color: DazlinTheme.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:        DazlinTheme.card,
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: DazlinTheme.border),
            ),
            child: Text(
              _formatDate(d),
              style: const TextStyle(color: DazlinTheme.textMuted, fontSize: 11),
            ),
          ),
        ),
        const Expanded(child: Divider(color: DazlinTheme.border)),
      ],
    ),
  );

  Widget _buildReplyBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: const BoxDecoration(
      color: DazlinTheme.surfaceAlt,
      border: Border(top: BorderSide(color: DazlinTheme.border)),
    ),
    child: Row(
      children: [
        Container(width: 3, height: 36, color: DazlinTheme.lime, margin: const EdgeInsets.only(right: 10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Replying to', style: TextStyle(color: DazlinTheme.lime, fontSize: 11, fontWeight: FontWeight.w600)),
              Text(_replyPreview ?? '', style: const TextStyle(color: DazlinTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 18, color: DazlinTheme.textMuted),
          onPressed: () => setState(() { _replyToId = null; _replyPreview = null; }),
        ),
      ],
    ),
  );

  Widget _buildInputBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: const BoxDecoration(
      color: DazlinTheme.surface,
      border: Border(top: BorderSide(color: DazlinTheme.border)),
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.emoji_emotions_outlined, color: DazlinTheme.textMuted),
          onPressed: () {},
        ),
        Expanded(
          child: TextField(
            controller: _msgCtrl,
            maxLines:   null,
            onSubmitted: (_) => _send(),
            style: const TextStyle(color: DazlinTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText:  'Message',
              hintStyle: const TextStyle(color: DazlinTheme.textMuted),
              filled:    true,
              fillColor: DazlinTheme.surfaceAlt,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide:   const BorderSide(color: DazlinTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide:   const BorderSide(color: DazlinTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide:   const BorderSide(color: DazlinTheme.lime, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: _send,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color:        _sending ? DazlinTheme.limeDeep : DazlinTheme.lime,
              shape:        BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:      DazlinTheme.limeGlow,
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: _sending
                ? const Center(child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: DazlinTheme.textOnLime, strokeWidth: 2)))
                : const Icon(Icons.send_rounded, color: DazlinTheme.textOnLime, size: 20),
          ),
        ),
      ],
    ),
  );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    return DateFormat('MMMM d, y').format(d);
  }
}

// ── Message Bubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatefulWidget {
  final MessageModel msg;
  final bool isMine;
  final bool showSender;
  final VoidCallback onReply;

  const _MessageBubble({
    required this.msg,
    required this.isMine,
    required this.showSender,
    required this.onReply,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: widget.showSender ? 10 : 2,
        bottom: 2,
      ),
      child: Row(
        mainAxisAlignment: widget.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!widget.isMine) ...[
            DazlinAvatar(
              url:      widget.msg.senderAvatar,
              initials: widget.msg.senderName?.isNotEmpty == true ? widget.msg.senderName![0] : '?',
              size:     28,
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: MouseRegion(
              onEnter:  (_) => setState(() => _hovered = true),
              onExit:   (_) => setState(() => _hovered = false),
              child: GestureDetector(
                onLongPress: widget.onReply,
                child: Column(
                  crossAxisAlignment: widget.isMine
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    if (!widget.isMine && widget.showSender)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 3),
                        child: Text(
                          widget.msg.senderName ?? 'Unknown',
                          style: const TextStyle(
                            color: DazlinTheme.lime,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (widget.msg.replyPreview != null) _buildReplyQuote(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (widget.isMine && _hovered)
                          _actionBtn(Icons.reply, widget.onReply),
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.sizeOf(context).width * 0.65,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                          decoration: BoxDecoration(
                            color:  widget.isMine ? DazlinTheme.sent : DazlinTheme.received,
                            borderRadius: BorderRadius.only(
                              topLeft:     const Radius.circular(18),
                              topRight:    const Radius.circular(18),
                              bottomLeft:  Radius.circular(widget.isMine ? 18 : 4),
                              bottomRight: Radius.circular(widget.isMine ? 4 : 18),
                            ),
                            border: Border.all(
                              color: widget.isMine
                                  ? DazlinTheme.sentBorder
                                  : DazlinTheme.border,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                widget.msg.content,
                                style: const TextStyle(
                                  color:  DazlinTheme.textPrimary,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    DateFormat('HH:mm').format(widget.msg.createdAt),
                                    style: const TextStyle(
                                      color:   DazlinTheme.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (widget.isMine) ...[
                                    const SizedBox(width: 3),
                                    Icon(
                                      widget.msg.isRead
                                          ? Icons.done_all
                                          : Icons.done,
                                      size:  12,
                                      color: widget.msg.isRead
                                          ? DazlinTheme.lime
                                          : DazlinTheme.textMuted,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (!widget.isMine && _hovered)
                          _actionBtn(Icons.reply, widget.onReply),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (widget.isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildReplyQuote() => Container(
    margin: const EdgeInsets.only(bottom: 4),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color:        DazlinTheme.card,
      borderRadius: BorderRadius.circular(10),
      border: const Border(left: BorderSide(color: DazlinTheme.lime, width: 3)),
    ),
    child: Text(
      widget.msg.replyPreview!,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(color: DazlinTheme.textSecondary, fontSize: 12),
    ),
  );

  Widget _actionBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Icon(icon, size: 16, color: DazlinTheme.textMuted),
    ),
  );
}
