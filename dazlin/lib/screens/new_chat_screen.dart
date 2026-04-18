// lib/screens/new_chat_screen.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/chat_model.dart';
import '../widgets/dazlin_avatar.dart';
import 'chat_screen.dart';

class NewChatScreen extends StatefulWidget {
  final bool isGroup;
  const NewChatScreen({super.key, this.isGroup = false});

  @override
  State<NewChatScreen> createState() => _NewChatScreenState();
}

class _NewChatScreenState extends State<NewChatScreen> {
  final _searchCtrl  = TextEditingController();
  final _nameCtrl    = TextEditingController();
  List<UserModel>    _results   = [];
  List<UserModel>    _selected  = [];
  bool               _searching = false;
  bool               _creating  = false;
  String?            _error;

  Future<void> _search(String q) async {
    if (q.length < 2) { setState(() => _results = []); return; }
    setState(() { _searching = true; _error = null; });
    try {
      final users = await ApiService.searchUsers(q);
      // exclude self
      setState(() => _results = users
          .where((u) => u.id != AuthService.currentUser!.id)
          .toList());
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _start(UserModel user) async {
    setState(() => _creating = true);
    try {
      final chat = await ApiService.createDirectChat(user.id);
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
    } catch (e) {
      setState(() { _error = e.toString(); _creating = false; });
    }
  }

  Future<void> _createGroup() async {
    if (_selected.isEmpty || _nameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Enter a group name and select members');
      return;
    }
    setState(() => _creating = true);
    try {
      final chat = await ApiService.createGroupChat(
        _nameCtrl.text.trim(),
        _selected.map((u) => u.id).toList(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(chat: chat)));
    } catch (e) {
      setState(() { _error = e.toString(); _creating = false; });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DazlinTheme.bg,
    appBar: AppBar(
      backgroundColor: DazlinTheme.surface,
      title: Text(
        widget.isGroup ? 'New Group' : 'New Chat',
        style: const TextStyle(color: DazlinTheme.textPrimary, fontWeight: FontWeight.w700),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: DazlinTheme.textSecondary),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (widget.isGroup)
          TextButton(
            onPressed: _creating ? null : _createGroup,
            child: _creating
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: DazlinTheme.lime, strokeWidth: 2))
                : const Text('Create', style: TextStyle(color: DazlinTheme.lime, fontWeight: FontWeight.w700)),
          ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: DazlinTheme.border),
      ),
    ),
    body: Column(
      children: [
        if (widget.isGroup) ...[
          _buildGroupNameField(),
          if (_selected.isNotEmpty) _buildSelectedChips(),
        ],
        _buildSearchBar(),
        if (_error != null)
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color:        const Color(0x22FF6B6B),
              borderRadius: BorderRadius.circular(8),
              border:       Border.all(color: const Color(0x55FF6B6B)),
            ),
            child: Text(_error!, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
          ),
        Expanded(child: _buildResults()),
      ],
    ),
  );

  Widget _buildGroupNameField() => Padding(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
    child: TextField(
      controller: _nameCtrl,
      style: const TextStyle(color: DazlinTheme.textPrimary),
      decoration: const InputDecoration(
        hintText:   'Group name',
        prefixIcon: Icon(Icons.group_outlined, color: DazlinTheme.textMuted, size: 20),
      ),
    ),
  );

  Widget _buildSelectedChips() => SizedBox(
    height: 52,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _selected.length,
      itemBuilder: (_, i) {
        final u = _selected[i];
        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color:        DazlinTheme.limeFade,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(color: DazlinTheme.lime.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(u.name, style: const TextStyle(color: DazlinTheme.lime, fontSize: 13)),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _selected.remove(u)),
                child: const Icon(Icons.close, size: 14, color: DazlinTheme.lime),
              ),
            ],
          ),
        );
      },
    ),
  );

  Widget _buildSearchBar() => Padding(
    padding: const EdgeInsets.all(16),
    child: TextField(
      controller: _searchCtrl,
      onChanged:  _search,
      style: const TextStyle(color: DazlinTheme.textPrimary),
      decoration: InputDecoration(
        hintText:   'Search by username or name…',
        prefixIcon: _searching
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(color: DazlinTheme.lime, strokeWidth: 2)),
              )
            : const Icon(Icons.search, color: DazlinTheme.textMuted, size: 20),
      ),
    ),
  );

  Widget _buildResults() {
    if (_results.isEmpty && _searchCtrl.text.length >= 2) {
      return const Center(
        child: Text('No users found', style: TextStyle(color: DazlinTheme.textMuted)),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final u = _results[i];
        final isSelected = _selected.contains(u);
        return ListTile(
          leading: DazlinAvatar(url: u.avatarUrl, initials: u.initials, size: 42),
          title: Text(u.name, style: const TextStyle(color: DazlinTheme.textPrimary, fontWeight: FontWeight.w600)),
          subtitle: Text('@${u.username}', style: const TextStyle(color: DazlinTheme.textMuted, fontSize: 12)),
          trailing: widget.isGroup
              ? Checkbox(
                  value:          isSelected,
                  onChanged:      (_) => _toggleSelect(u),
                  activeColor:    DazlinTheme.lime,
                  checkColor:     DazlinTheme.textOnLime,
                  side:           const BorderSide(color: DazlinTheme.border),
                )
              : const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: DazlinTheme.textMuted),
          onTap: widget.isGroup ? () => _toggleSelect(u) : () => _start(u),
          tileColor: Colors.transparent,
        );
      },
    );
  }

  void _toggleSelect(UserModel u) => setState(() {
    if (_selected.contains(u)) _selected.remove(u);
    else _selected.add(u);
  });
}
