// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/dazlin_avatar.dart';
import 'auth_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _nameCtrl = TextEditingController();
  bool _editing   = false;
  bool _saving    = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = AuthService.currentUser?.displayName ?? '';
  }

  Future<void> _saveProfile() async {
    setState(() => _saving = true);
    try {
      await ApiService.updateProfile(displayName: _nameCtrl.text.trim());
      if (mounted) {
        setState(() => _editing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated!'),
            backgroundColor: DazlinTheme.lime,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Update failed'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ApiService.setOnline(false);
    await AuthService.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    return Scaffold(
      backgroundColor: DazlinTheme.bg,
      appBar: AppBar(
        backgroundColor: DazlinTheme.surface,
        title: const Text('Settings',
          style: TextStyle(color: DazlinTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: DazlinTheme.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: DazlinTheme.border),
        ),
      ),
      body: ListView(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            color: DazlinTheme.surface,
            child: Row(
              children: [
                DazlinAvatar(
                  url:      user?.avatarUrl,
                  initials: user?.initials ?? '?',
                  size:     60,
                  isOnline: true,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _editing
                          ? TextField(
                              controller: _nameCtrl,
                              autofocus:  true,
                              style: const TextStyle(
                                color: DazlinTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              decoration: const InputDecoration(
                                isDense:     true,
                                contentPadding: EdgeInsets.zero,
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: DazlinTheme.lime),
                                ),
                                enabledBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: DazlinTheme.border),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: DazlinTheme.lime, width: 2),
                                ),
                              ),
                            )
                          : Text(
                              user?.name ?? 'User',
                              style: const TextStyle(
                                color: DazlinTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                      const SizedBox(height: 2),
                      Text('@${user?.username ?? ''}',
                        style: const TextStyle(color: DazlinTheme.lime, fontSize: 13)),
                      Text(user?.email ?? '',
                        style: const TextStyle(color: DazlinTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                if (_editing)
                  IconButton(
                    icon: _saving
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: DazlinTheme.lime, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded, color: DazlinTheme.lime),
                    onPressed: _saving ? null : _saveProfile,
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: DazlinTheme.textSecondary),
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          _sectionHeader('Account'),
          _tile(icon: Icons.person_outline,   label: 'Profile',       sub: 'Edit your display name'),
          _tile(icon: Icons.star_border,       label: 'Starred',       sub: 'Saved messages'),
          _tile(icon: Icons.history_rounded,   label: 'Chat history',  sub: 'Manage your chats'),

          const SizedBox(height: 12),
          _sectionHeader('Privacy & Security'),
          _tile(icon: Icons.lock_outline,      label: 'Privacy',       sub: 'Who can see your info'),
          _tile(icon: Icons.notifications_none, label: 'Notifications', sub: 'Sound, vibration, banners'),

          const SizedBox(height: 12),
          _sectionHeader('App'),
          _tile(icon: Icons.chat_outlined,     label: 'Chats',         sub: 'Chat wallpaper, themes'),
          _tile(icon: Icons.info_outline,      label: 'About Dazlin',  sub: 'Version 1.0.0'),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: _signOut,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:        const Color(0x22FF6B6B),
                  borderRadius: BorderRadius.circular(14),
                  border:       Border.all(color: const Color(0x55FF6B6B)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B)),
                    SizedBox(width: 12),
                    Text('Sign Out', style: TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    )),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
    child: Text(title.toUpperCase(),
      style: const TextStyle(
        color:        DazlinTheme.lime,
        fontSize:     11,
        fontWeight:   FontWeight.w700,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _tile({required IconData icon, required String label, String? sub}) =>
    Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: DazlinTheme.border, width: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color:        DazlinTheme.card,
            borderRadius: BorderRadius.circular(10),
            border:       Border.all(color: DazlinTheme.border),
          ),
          child: Icon(icon, color: DazlinTheme.lime, size: 20),
        ),
        title:    Text(label, style: const TextStyle(color: DazlinTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 15)),
        subtitle: sub != null ? Text(sub, style: const TextStyle(color: DazlinTheme.textMuted, fontSize: 12)) : null,
        trailing: const Icon(Icons.chevron_right_rounded, color: DazlinTheme.textMuted, size: 20),
        onTap:    () {},
        tileColor: DazlinTheme.surface,
      ),
    );
}
