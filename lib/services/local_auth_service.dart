import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_user.dart';

/// Authentication repository for the academic prototype.
/// It only stores demonstration users locally on the device.
class LocalAuthService {
  LocalAuthService(this._storage);

  final SharedPreferences _storage;
  static const _usersKey = 'local_auth_users';
  static const _sessionKey = 'session';
  static const _nameKey = 'name';
  static const _emailKey = 'email';
  static const _roleKey = 'role';

  /// Keeps the existing method for startup compatibility.
  /// Public builds never ship example accounts or passwords.
  Future<void> seedDemoUsers() async {}

  Future<AuthUser?> signIn(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    for (final user in _users()) {
      if (user.email == normalizedEmail && user.password == password) {
        await _saveSession(user);
        return user;
      }
    }
    return null;
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final users = _users();
    if (users.any((user) => user.email == normalizedEmail)) {
      return 'Ya existe una cuenta con este correo.';
    }
    final user = AuthUser(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
      role: 'cliente',
    );
    users.add(user);
    await _saveUsers(users);
    await _saveSession(user);
    return null;
  }

  AuthUser? restoredSession() {
    if (!(_storage.getBool(_sessionKey) ?? false)) return null;
    final email = _storage.getString(_emailKey);
    if (email == null) return null;
    for (final user in _users()) {
      if (user.email == email) return user;
    }
    return null;
  }

  Future<void> signOut() => _storage.setBool(_sessionKey, false);

  List<AuthUser> _users() {
    final source = _storage.getString(_usersKey);
    if (source == null) return [];
    return (jsonDecode(source) as List<dynamic>)
        .map((item) => AuthUser.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveUsers(List<AuthUser> users) => _storage.setString(
    _usersKey,
    jsonEncode(users.map((user) => user.toJson()).toList()),
  );

  Future<void> _saveSession(AuthUser user) async {
    await _storage.setBool(_sessionKey, true);
    await _storage.setString(_nameKey, user.name);
    await _storage.setString(_emailKey, user.email);
    await _storage.setString(_roleKey, user.role);
  }
}
