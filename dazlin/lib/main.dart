// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'screens/auth_screen.dart';
import 'screens/chats_screen.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const DazlinApp());
}

class DazlinApp extends StatelessWidget {
  const DazlinApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title:        'Dazlin',
    debugShowCheckedModeBanner: false,
    theme:        DazlinTheme.dark,
    home:         const _SplashGate(),
  );
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late AnimationController _anim;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _anim, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _anim, curve: Curves.elasticOut));
    _anim.forward();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.delayed(const Duration(milliseconds: 1200));
    final loggedIn = await AuthService.tryRestoreSession();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            loggedIn ? const ChatsScreen() : const AuthScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: DazlinTheme.bg,
    body: Center(
      child: AnimatedBuilder(
        animation: _anim,
        builder: (_, __) => FadeTransition(
          opacity: _fade,
          child: Transform.scale(
            scale: _scale.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo mark
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color:        DazlinTheme.lime,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color:      DazlinTheme.limeGlow,
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('D',
                      style: TextStyle(
                        color:      DazlinTheme.textOnLime,
                        fontSize:   44,
                        fontWeight: FontWeight.w900,
                        height:     1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Dazlin',
                  style: TextStyle(
                    color:       DazlinTheme.textPrimary,
                    fontSize:    32,
                    fontWeight:  FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text('Chat with anyone, anywhere.',
                  style: TextStyle(
                    color:    DazlinTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: DazlinTheme.lime.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
