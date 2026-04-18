// lib/screens/auth_screen.dart
import 'package:flutter/material.dart';
import '../utils/theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../widgets/dazlin_avatar.dart';
import 'chats_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  bool _loading = false;
  String? _error;

  // Sign-in fields
  final _siCtrl  = TextEditingController();
  final _sPassCtrl = TextEditingController();
  bool _siObscure = true;

  // Sign-up fields
  final _suEmailCtrl = TextEditingController();
  final _suUserCtrl  = TextEditingController();
  final _suNameCtrl  = TextEditingController();
  final _suPassCtrl  = TextEditingController();
  bool _suObscure = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() => _error = null));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_siCtrl.text.trim().isEmpty || _sPassCtrl.text.isEmpty) {
      setState(() => _error = 'Fill in all fields');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signIn(
        emailOrUsername: _siCtrl.text.trim(),
        password:        _sPassCtrl.text,
      );
      if (!mounted) return;
      _goToChats();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Sign in failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUp() async {
    final email = _suEmailCtrl.text.trim();
    final user  = _suUserCtrl.text.trim();
    final pass  = _suPassCtrl.text;
    if (email.isEmpty || user.isEmpty || pass.isEmpty) {
      setState(() => _error = 'Fill in all required fields');
      return;
    }
    if (pass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService.signUp(
        email:       email,
        username:    user,
        password:    pass,
        displayName: _suNameCtrl.text.trim().isEmpty ? null : _suNameCtrl.text.trim(),
      );
      if (!mounted) return;
      _goToChats();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Sign up failed. Check your connection.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToChats() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ChatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 600;

    return Scaffold(
      backgroundColor: DazlinTheme.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogo(),
                const SizedBox(height: 40),
                _buildTabBar(),
                const SizedBox(height: 24),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: _tab.index == 0 ? _buildSignIn() : _buildSignUp(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  _buildError(),
                ],
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 16),
                _buildGoogleBtn(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: DazlinTheme.lime,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('D', style: TextStyle(
                color: DazlinTheme.textOnLime,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              )),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Dazlin',
            style: TextStyle(
              color: DazlinTheme.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      const Text(
        'Chat with anyone, anywhere.',
        style: TextStyle(color: DazlinTheme.textSecondary, fontSize: 14),
      ),
    ],
  );

  Widget _buildTabBar() => Container(
    decoration: BoxDecoration(
      color:        DazlinTheme.surfaceAlt,
      borderRadius: BorderRadius.circular(12),
      border:       Border.all(color: DazlinTheme.border),
    ),
    child: TabBar(
      controller: _tab,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: BoxDecoration(
        color:        DazlinTheme.card,
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: DazlinTheme.lime.withOpacity(0.4)),
      ),
      labelColor:         DazlinTheme.lime,
      unselectedLabelColor: DazlinTheme.textMuted,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      tabs: const [Tab(text: 'Sign In'), Tab(text: 'Sign Up')],
    ),
  );

  Widget _buildSignIn() => Column(
    key: const ValueKey('signin'),
    children: [
      DazlinField(
        hint:       'Email or username',
        controller: _siCtrl,
        prefix:     const Icon(Icons.person_outline, color: DazlinTheme.textMuted, size: 20),
        onSubmit:   (_) => _signIn(),
      ),
      const SizedBox(height: 12),
      DazlinField(
        hint:       'Password',
        controller: _sPassCtrl,
        obscure:    _siObscure,
        prefix:     const Icon(Icons.lock_outline, color: DazlinTheme.textMuted, size: 20),
        suffix: IconButton(
          icon: Icon(
            _siObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: DazlinTheme.textMuted, size: 20,
          ),
          onPressed: () => setState(() => _siObscure = !_siObscure),
        ),
        onSubmit: (_) => _signIn(),
      ),
      const SizedBox(height: 20),
      GlowButton(label: 'Sign In', onTap: _signIn, loading: _loading && _tab.index == 0),
    ],
  );

  Widget _buildSignUp() => Column(
    key: const ValueKey('signup'),
    children: [
      DazlinField(
        hint:       'Display name',
        controller: _suNameCtrl,
        prefix:     const Icon(Icons.badge_outlined, color: DazlinTheme.textMuted, size: 20),
      ),
      const SizedBox(height: 12),
      DazlinField(
        hint:       'Username *',
        controller: _suUserCtrl,
        prefix:     const Icon(Icons.alternate_email, color: DazlinTheme.textMuted, size: 20),
      ),
      const SizedBox(height: 12),
      DazlinField(
        hint:       'Email *',
        controller: _suEmailCtrl,
        keyboard:   TextInputType.emailAddress,
        prefix:     const Icon(Icons.mail_outline, color: DazlinTheme.textMuted, size: 20),
      ),
      const SizedBox(height: 12),
      DazlinField(
        hint:       'Password *',
        controller: _suPassCtrl,
        obscure:    _suObscure,
        prefix:     const Icon(Icons.lock_outline, color: DazlinTheme.textMuted, size: 20),
        suffix: IconButton(
          icon: Icon(
            _suObscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: DazlinTheme.textMuted, size: 20,
          ),
          onPressed: () => setState(() => _suObscure = !_suObscure),
        ),
        onSubmit: (_) => _signUp(),
      ),
      const SizedBox(height: 20),
      GlowButton(label: 'Create Account', onTap: _signUp, loading: _loading && _tab.index == 1),
    ],
  );

  Widget _buildError() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color:        const Color(0x22FF6B6B),
      borderRadius: BorderRadius.circular(10),
      border:       Border.all(color: const Color(0x55FF6B6B)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(_error!,
            style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
        ),
      ],
    ),
  );

  Widget _buildDivider() => Row(
    children: [
      const Expanded(child: Divider(color: DazlinTheme.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text('or', style: TextStyle(color: DazlinTheme.textMuted, fontSize: 13)),
      ),
      const Expanded(child: Divider(color: DazlinTheme.border)),
    ],
  );

  Widget _buildGoogleBtn() => GestureDetector(
    onTap: _loading ? null : _handleGoogleSignIn,
    child: Container(
      width:  double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color:        DazlinTheme.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border:       Border.all(color: DazlinTheme.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google G icon via text
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Center(
              child: Text('G', style: TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w800,
                fontSize: 14,
              )),
            ),
          ),
          const SizedBox(width: 12),
          const Text('Continue with Google',
            style: TextStyle(
              color: DazlinTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _handleGoogleSignIn() async {
    // Google Sign-In on Flutter Web requires the google_sign_in package
    // and proper OAuth client configuration. This shows the flow stub.
    // Real implementation: configure google_sign_in in index.html meta tags
    setState(() { _loading = true; _error = null; });
    try {
      // TODO: Replace with real Google Sign-In flow once OAuth client ID is configured
      // final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      // final account = await _googleSignIn.signIn();
      // if (account == null) return;
      // final auth = await account.authentication;
      // await AuthService.googleSignIn(
      //   idToken: auth.idToken!,
      //   email: account.email,
      //   displayName: account.displayName ?? account.email,
      //   avatarUrl: account.photoUrl,
      // );
      // _goToChats();
      setState(() => _error = 'Configure Google OAuth client ID in index.html to enable Google Sign-In');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
