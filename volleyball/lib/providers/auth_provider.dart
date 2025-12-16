import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseService _supabase = SupabaseService();
  
  User? _currentUser;
  Map<String, dynamic>? _userProfile;
  String? _selectedRole;
  
  User? get currentUser => _currentUser;
  Map<String, dynamic>? get userProfile => _userProfile;
  String? get selectedRole => _selectedRole;
  bool get isLoggedIn => _currentUser != null;
  
  void setRole(String role) {
    _selectedRole = role;
    notifyListeners();
  }
  
  // Генерация хэша пароля
  String _generatePasswordHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Начало регистрации с email: $email, роль: $role');
      }
      
      // Очистка email
      final cleanedEmail = email.trim().toLowerCase().replaceAll(' ', '');
      
      if (cleanedEmail.isEmpty) {
        throw Exception('Введите email');
      }
      
      // Базовая проверка email
      if (!cleanedEmail.contains('@') || !cleanedEmail.contains('.')) {
        throw Exception('Некорректный email адрес');
      }
      
      // Проверка пароля
      if (password.length < 6) {
        throw Exception('Пароль должен содержать минимум 6 символов');
      }
      
      if (fullName.trim().isEmpty) {
        throw Exception('Введите полное имя');
      }
      
      // Проверка телефона
      if (phone.trim().isEmpty) {
        throw Exception('Введите номер телефона');
      }
      
      // Генерация хэша пароля
      final passwordHash = _generatePasswordHash(password);
      
      if (kDebugMode) {
        debugPrint('Регистрация в Supabase Auth...');
      }
      
      // Регистрация в Supabase Auth
      final AuthResponse authResponse;
      try {
        authResponse = await _supabase.client.auth.signUp(
          email: cleanedEmail,
          password: password,
          data: {
            'full_name': fullName.trim(),
            'phone': phone.trim(),
            'role': role,
          },
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Ошибка при регистрации в Auth: $e');
        }
        rethrow;
      }
      
      if (authResponse.user == null) {
        throw Exception('Регистрация не удалась. Попробуйте еще раз.');
      }
      
      if (kDebugMode) {
        debugPrint('Пользователь создан в Auth: ${authResponse.user!.id}');
      }
      
      _currentUser = authResponse.user;
      
      try {
        // Создаем профиль в таблице profiles
        final profileData = {
          'id': _currentUser!.id,
          'email': cleanedEmail,
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'role': role,
          'password_hash': passwordHash,
          'password_changed_at': DateTime.now().toUtc().toIso8601String(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        
        if (kDebugMode) {
          debugPrint('Создание профиля с данными: $profileData');
        }
        
        // Вставляем профиль
        await _supabase.client
          .from('profiles')
          .insert(profileData);
        
        // Сохраняем в историю паролей
        await _supabase.client
          .from('password_history')
          .insert({
            'user_id': _currentUser!.id,
            'password_hash': passwordHash,
            'changed_at': DateTime.now().toUtc().toIso8601String(),
          });
        
        // Получаем созданный профиль
        final profileResponse = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .single()
          .timeout(const Duration(seconds: 5));
        
        _userProfile = profileResponse;
        _selectedRole = role;
        
        if (kDebugMode) {
          debugPrint('Регистрация успешна! Профиль: $_userProfile');
        }
        
        notifyListeners();
        
      } catch (profileError) {
        if (kDebugMode) {
          debugPrint('Ошибка создания профиля: $profileError');
        }
        
        // Откатываем регистрацию
        try {
          await _supabase.client.auth.signOut();
        } catch (e) {
          debugPrint('Ошибка при выходе: $e');
        }
        
        _currentUser = null;
        
        if (profileError is PostgrestException) {
          if (profileError.message.contains('duplicate key')) {
            if (profileError.message.contains('email')) {
              throw Exception('Пользователь с таким email уже зарегистрирован');
            } else if (profileError.message.contains('phone')) {
              throw Exception('Пользователь с таким номером телефона уже зарегистрирован');
            }
            throw Exception('Пользователь с такими данными уже существует');
          }
          throw Exception('Ошибка базы данных');
        }
        
        throw Exception('Ошибка создания профиля пользователя');
      }
      
    } on AuthException catch (e) {
      if (kDebugMode) {
        debugPrint('AuthException: ${e.message}');
      }
      
      final errorMessage = e.message.toLowerCase();
      
      if (errorMessage.contains('user already registered') ||
          errorMessage.contains('already registered')) {
        throw Exception('Пользователь с таким email уже зарегистрирован');
      } else if (errorMessage.contains('password should be at least')) {
        throw Exception('Пароль должен содержать минимум 6 символов');
      } else if (errorMessage.contains('invalid email') ||
                 errorMessage.contains('email address') ||
                 errorMessage.contains('is invalid')) {
        throw Exception('Некорректный email адрес. Убедитесь, что email указан правильно');
      } else if (errorMessage.contains('rate limit')) {
        throw Exception('Слишком много попыток. Попробуйте позже');
      } else {
        throw Exception('Ошибка регистрации. Проверьте данные и повторите попытку');
      }
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Общая ошибка регистрации: $e');
      }
      
      if (e.toString().contains('timeout')) {
        throw Exception('Превышено время ожидания. Проверьте подключение к интернету');
      } else if (e.toString().contains('socket') || e.toString().contains('connection')) {
        throw Exception('Нет подключения к интернету');
      }
      
      throw Exception('Произошла ошибка при регистрации. Попробуйте еще раз');
    }
  }
  
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final cleanedEmail = email.trim().toLowerCase();
      
      if (cleanedEmail.isEmpty) {
        throw Exception('Введите email');
      }
      
      if (!cleanedEmail.contains('@')) {
        throw Exception('Email должен содержать символ @');
      }
      
      final AuthResponse res = await _supabase.client.auth.signInWithPassword(
        email: cleanedEmail,
        password: password,
      );
      
      final user = res.user;
      if (user == null) {
        throw Exception('Неверный email или пароль');
      }
      
      _currentUser = user;
      
      // Получение профиля пользователя
      final profileResponse = await _supabase.client
        .from('profiles')
        .select()
        .eq('id', _currentUser!.id)
        .limit(1)
        .timeout(const Duration(seconds: 5));
      
      if (profileResponse.isEmpty) {
        final userMetadata = user.userMetadata ?? {};
        final profileData = {
          'id': _currentUser!.id,
          'email': cleanedEmail,
          'full_name': userMetadata['full_name'] ?? '',
          'phone': userMetadata['phone'] ?? '',
          'role': userMetadata['role'] ?? 'игрок',
          'password_hash': _generatePasswordHash(password),
          'password_changed_at': DateTime.now().toUtc().toIso8601String(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };
        
        await _supabase.client
          .from('profiles')
          .insert(profileData);
        
        _userProfile = profileData;
      } else {
        _userProfile = profileResponse[0];
      }
      
      _selectedRole = _userProfile?['role'];
      notifyListeners();
      
    } on AuthException catch (e) {
      final errorMessage = e.message.toLowerCase();
      
      if (errorMessage.contains('invalid login credentials') ||
          errorMessage.contains('invalid credentials')) {
        throw Exception('Неверный email или пароль');
      } else if (errorMessage.contains('email not confirmed')) {
        throw Exception('Email не подтвержден. Проверьте вашу почту');
      } else if (errorMessage.contains('rate limit')) {
        throw Exception('Слишком много попыток. Попробуйте позже');
      } else {
        throw Exception('Ошибка входа. Попробуйте еще раз');
      }
    } catch (e) {
      throw Exception('Ошибка входа. Попробуйте еще раз');
    }
  }
  
  Future<void> signOut() async {
    try {
      await _supabase.client.auth.signOut();
      _currentUser = null;
      _userProfile = null;
      _selectedRole = null;
      notifyListeners();
    } catch (e) {
      throw Exception('Ошибка при выходе');
    }
  }
  
  Future<void> updateProfile(Map<String, dynamic> data) async {
    try {
      if (_currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }
      
      await _supabase.client
        .from('profiles')
        .update(data)
        .eq('id', _currentUser!.id)
        .timeout(const Duration(seconds: 10));
      
      // Обновляем локальный профиль
      final updatedProfile = await _supabase.client
        .from('profiles')
        .select()
        .eq('id', _currentUser!.id)
        .limit(1);
      
      if (updatedProfile.isNotEmpty) {
        _userProfile = updatedProfile[0];
        notifyListeners();
      }
      
    } catch (e) {
      throw Exception('Ошибка обновления профиля');
    }
  }
  
  // Метод для смены пароля
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      if (_currentUser == null) {
        throw Exception('Пользователь не авторизован');
      }
      
      if (newPassword.length < 6) {
        throw Exception('Новый пароль должен содержать минимум 6 символов');
      }
      
      // Генерация хэшей
      final currentHash = _generatePasswordHash(currentPassword);
      final newHash = _generatePasswordHash(newPassword);
      
      // Получаем текущий хэш из профиля
      final profileResponse = await _supabase.client
        .from('profiles')
        .select('password_hash')
        .eq('id', _currentUser!.id)
        .single();
      
      final storedHash = profileResponse['password_hash'] as String?;
      
      // Проверяем текущий пароль
      if (storedHash != currentHash) {
        throw Exception('Текущий пароль неверен');
      }
      
      // Обновляем пароль в Auth
      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      
      // Обновляем хэш в профиле
      await _supabase.client
        .from('profiles')
        .update({
          'password_hash': newHash,
          'password_changed_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', _currentUser!.id);
      
      // Сохраняем в историю паролей
      await _supabase.client
        .from('password_history')
        .insert({
          'user_id': _currentUser!.id,
          'password_hash': newHash,
          'changed_at': DateTime.now().toUtc().toIso8601String(),
        });
      
      // Обновляем локальный профиль
      final updatedProfile = await _supabase.client
        .from('profiles')
        .select()
        .eq('id', _currentUser!.id)
        .single();
      
      _userProfile = updatedProfile;
      
      notifyListeners();
      
    } on AuthException catch (e) {
      throw Exception('Ошибка смены пароля: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка смены пароля: $e');
    }
  }
  
  // Получение истории изменений пароля
  Future<List<Map<String, dynamic>>> getPasswordHistory() async {
    if (_currentUser == null) {
      return [];
    }
    
    try {
      final response = await _supabase.client
        .from('password_history')
        .select('*')
        .eq('user_id', _currentUser!.id)
        .order('changed_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Ошибка получения истории паролей: $e');
      return [];
    }
  }
  
  // Проверка, менялся ли пароль
  Future<bool> hasPasswordChanged() async {
    if (_currentUser == null || _userProfile == null) {
      return false;
    }
    
    final passwordChangedAt = _userProfile!['password_changed_at'];
    if (passwordChangedAt == null) return false;
    
    final changedDate = DateTime.parse(passwordChangedAt);
    final createdDate = DateTime.parse(_userProfile!['created_at']);
    
    return changedDate.isAfter(createdDate);
  }
}