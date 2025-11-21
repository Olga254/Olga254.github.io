import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'user.dart';

class AuthService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Регистрация нового пользователя
  Future<bool> register(String email, String password) async {
    try {
      final user = User(email: email, password: password);
      await _storage.write(key: email, value: json.encode(user.toJson()));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Авторизация пользователя
  Future<bool> login(String email, String password) async {
    try {
      final userData = await _storage.read(key: email);
      if (userData != null) {
        final user = User.fromJson(json.decode(userData));
        return user.password == password;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Проверка, авторизован ли пользователь
  Future<bool> isLoggedIn() async {
    final email = await _storage.read(key: 'current_user');
    return email != null;
  }

  // Сохранение текущего пользователя
  Future<void> setCurrentUser(String email) async {
    await _storage.write(key: 'current_user', value: email);
  }

  // Выход из системы
  Future<void> logout() async {
    await _storage.delete(key: 'current_user');
  }

  // Получение текущего пользователя
  Future<String?> getCurrentUser() async {
    return await _storage.read(key: 'current_user');
  }
}