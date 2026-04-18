// lib/screens/chats_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/theme.dart';
import '../models/chat_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/api_service.dart';
import '../widgets/dazlin_avatar.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';
import 'new_chat_screen.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  int _selectedNav = 0; // 0=Chats 1=Communities 2=Calls 3=Settings
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    ChatService.startChatsPolling();
    ApiService.setOnline(true);
  }

  @override
  void dispose() {
    ChatService.stopChatsPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isWide = w >= 800;

    return Scaffold(
      backgroundColor: DazlinTheme.bg,
      body: isWide ? _buildWideLayout() : _buildNarrowLayout(),
    );
  }

  Widget _buildWideLayout() => Row(
    children: [
      _buildSidebar(),
      Container(width: 1, color: DazlinTheme.border),
      Expanded(child: _buildChatsList()),
      Container(width: 1, color: DazlinTheme.border),
      const Expanded(
        flex: 2,
        child: _EmptyChat(),
      ),
    ],
  );

  Widget _buildNarrowLayout() => Scaffold(
    backgroundColor: DazlinTheme.bg,
    body: _buildChatsList(),
    bottomNavigationBar: _buildBottomNav(),
  );

  // ── Sidebar (wide) ────────────────────────────────────────────────────────

  Widget _buildSidebar() => Container(
    width: 64,
    color: DazlinTheme.surface,
    child: Column(
      children: [
        const SizedBox(height: 16),
        // Logo
        Container(
          width: 36, height: 36,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: DazlinTheme.lime,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Center(child: Text('D',
            style: TextStyle(color: DazlinTheme.textOnLime, fontWeight: FontWeight.w900, fontSize: 18))),
        ),
        const SizedBox(height: 16),
        _sideNavItem(0, Icons.chat_bubble_outline_rounded, 'Chats'),
        _sideNavItem(1, Icons.group_outlined, 'Groups'),
        _sideNavItem(2, Icons.call_outlined, 'Calls'),
        const Spacer(),
        _sideNavItem(3, Icons.settings_outlined, 'Settings'),
        const SizedBox(height: 16),
      ],
    ),
  );

  Widget _sideNavItem(int idx, IconData icon, String label) {
    final active = _selectedNav == idx;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNav = idx);
        if (idx == 3) _openSettings();
      },
      child: Tooltip(
        message: label,
        child: Container(
          width: 44, height: 44,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color:        active ? DazlinTheme.limeFade : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: active ? Border.all(color: DazlinTheme.lime.withOpacity(0.3)) : null,
          ),
          child: Icon(icon,
            color: active ? DazlinTheme.lime : DazlinTheme.textMuted,
            size: 22,
          ),
        ),
      ),
    );
  }

  // ── Bottom nav (narrow) ────────────────────────────────────────────────────

  Widget _buildBottomNav() => Container(
    height: 62,
    decoration: const BoxDecoration(
      color: DazlinTheme.surface,
      border: Border(top: BorderSide(color: DazlinTheme.border)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _bottomNavItem(0, Icons.chat_bubble_outline_rounded, 'Chats'),
        _bottomNavItem(1, Icons.group_outlined, 'Groups'),
        _bottomNavItem(2, Icons.call_outlined, 'Calls'),
        _bottomNavItem(3, Icons.settings_outlined, 'Settings'),
      ],
    ),
  );

  Widget _bottomNavItem(int idx, IconData icon, String label) {
    final active = _selectedNav == idx;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNav = idx);
        if (idx == 3) _openSettings();
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
            color: active ? DazlinTheme.lime : DazlinTheme.textMuted,
            size: 22,
          ),
          const SizedBox(height: 2),
          Text(label,
            style: TextStyle(
              color: active ? DazlinTheme.lime : DazlinTheme.textMuted,
              fontSize: 10,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── Chats list ─────────────────────────────────────────────────────────────

  Widget _buildChatsList() => Column(
    children: [
      _buildHeader(),
      _buildSearchBar(),
      Expanded(
        child: StreamBuilder<List<ChatModel>>(
          stream: ChatService.chatsStream,
          initialData: ChatService.cachedChats,
          builder: (ctx, snap) {
            final all = snap.data ?? [];
            final chats = _search.isEmpty
                ? all
                : all.where((c) {
                    final name = c.displayName(AuthService.currentUser!.id).toLowerCase();
                    return name.contains(_search.toLowerCase());
                  }).toList();
            if (chats.isEmpty && snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(
                color: DazlinTheme.lime, strokeWidth: 2,
              ));
            }
            if (chats.isEmpty) return _buildEmptyState();
            return ListView.builder(
              itemCount: chats.length,
              itemBuilder: (ctx, i) => _ChatTile(chat: chats[i]),
            );
          },
        ),
      ),
    ],
  );

  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
    child: Row(
      children: [
        const Text('Chats',
          style: TextStyle(
            color: DazlinTheme.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        const Spacer(),
        _iconBtn(Icons.person_add_outlined, _openNewChat),
        const SizedBox(width: 4),
        _iconBtn(Icons.group_add_outlined, _openNewGroup),
      ],
    ),
  );

  Widget _iconBtn(IconData icon, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: DazlinTheme.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: DazlinTheme.border),
      ),
      child: Icon(icon, color: DazlinTheme.lime, size: 18),
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
    child: TextField(
      controller: _searchCtrl,
      onChanged:  (v) => setState(() => _search = v),
      style: const TextStyle(color: DazlinTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        hintText:   'Search chats...',
        prefixIcon: const Icon(Icons.search, color: DazlinTheme.textMuted, size: 20),
        suffixIcon: _search.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close, size: 18, color: DazlinTheme.textMuted),
                onPressed: () { _searchCtrl.clear(); setState(() => _search = ''); },
              )
            : null,
        filled: true,
        fillColor: DazlinTheme.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DazlinTheme.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DazlinTheme.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DazlinTheme.lime, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        hintStyle: const TextStyle(color: DazlinTheme.textMuted, fontSize: 14),
      ),
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: DazlinTheme.limeFade,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(Icons.chat_bubble_outline, color: DazlinTheme.lime, size: 30),
        ),
        const SizedBox(height: 16),
        const Text('No chats yet',
          style: TextStyle(color: DazlinTheme.textSecondary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        const Text('Start a conversation',
          style: TextStyle(color: DazlinTheme.textMuted, fontSize: 13)),
      ],
    ),
  );

  void _openSettings() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );

  void _openNewChat() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NewChatScreen()),
  );

  void _openNewGroup() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const NewChatScreen(isGroup: true)),
  );
}

// ── Chat Tile ─────────────────────────────────────────────────────────────────

class _ChatTile extends StatelessWidget {
  final ChatModel chat;
  const _ChatTile({required this.chat});

  @override
  Widget build(BuildContext context) {
    final me   = AuthService.currentUser!;
    final name = chat.displayName(me.id);
    final av   = chat.displayAvatar(me.id);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: DazlinTheme.border, width: 0.5)),
        ),
        child: Row(
          children: [
            DazlinAvatar(
              url:      av,
              initials: name.isNotEmpty ? name[0].toUpperCase() : '?',
              size:     46,
              isOnline: false,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DazlinTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (chat.lastMessageAt != null)
                        Text(
                          _formatTime(chat.lastMessageAt!),
                          style: TextStyle(
                            color: chat.unreadCount > 0
                                ? DazlinTheme.lime
                                : DazlinTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      if (chat.lastSenderId == me.id)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all, size: 14, color: DazlinTheme.lime),
                        ),
                      Expanded(
                        child: Text(
                          chat.lastMessage ?? 'Start chatting...',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: DazlinTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (chat.unreadCount > 0)
                        UnreadBadge(count: chat.unreadCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    if (now.difference(t).inDays == 0) return DateFormat('HH:mm').format(t);
    if (now.difference(t).inDays == 1) return 'Yesterday';
    return DateFormat('d MMM').format(t);
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();

  @override
  Widget build(BuildContext context) => Container(
    color: DazlinTheme.bg,
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: DazlinTheme.limeFade,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.chat_bubble_outline, color: DazlinTheme.lime, size: 34),
          ),
          const SizedBox(height: 20),
          const Text('Select a chat', style: TextStyle(
            color: DazlinTheme.textSecondary, fontSize: 18, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const Text('Choose a conversation to start messaging',
            style: TextStyle(color: DazlinTheme.textMuted, fontSize: 13)),
        ],
      ),
    ),
  );
}
