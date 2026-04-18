// lib/services/auth_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import 'api_service.dart';

class AuthService {
  static const _tokenKey = 'dazlin_token';
  static const _userKey  = 'dazlin_user';

  static UserModel? _currentUser;
  static UserModel? get currentUser => _currentUser;
  static bool get isLoggedIn => _currentUser != null;

  static Future<bool> tryRestoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);
    if (token == null || userJson == null) return false;
    try {
      ApiService.setToken(token);
      _currentUser = UserModel.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      // Verify token still valid
      _currentUser = await ApiService.getMe();
      await _persistUser(_currentUser!);
      return true;
    } catch (_) {
      await signOut();
      return false;
    }
  }

  static Future<void> _persist(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await _persistUser(user);
    ApiService.setToken(token);
    _currentUser = user;
  }

  static Future<void> _persistUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel> signUp({
    required String email,
    required String username,
    required String password,
    String? displayName,
  }) async {
    final result = await ApiService.signUp(
      email:       email,
      username:    username,
      password:    password,
      displayName: displayName,
    );
    await _persist(result.token, result.user);
    return result.user;
  }

  static Future<UserModel> signIn({
    required String emailOrUsername,
    required String password,
  }) async {
    final result = await ApiService.signIn(
      emailOrUsername: emailOrUsername,
      password:        password,
    );
    await _persist(result.token, result.user);
    return result.user;
  }

  static Future<UserModel> googleSignIn({
    required String idToken,
    required String email,
    required String displayName,
    String? avatarUrl,
  }) async {
    final result = await ApiService.googleAuth(
      idToken:     idToken,
      email:       email,
      displayName: displayName,
      avatarUrl:   avatarUrl,
    );
    await _persist(result.token, result.user);
    return result.user;
  }

  static Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    ApiService.clearToken();
    _currentUser = null;
  }

  static Future<void> updateCurrentUser(UserModel updated) async {
    _currentUser = updated;
    await _persistUser(updated);
  }
}
