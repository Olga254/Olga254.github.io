import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../utils/auth_storage.dart';

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

  String _generatePasswordHash(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _cleanPhoneNumber(String phone) {
    if (phone.trim().isEmpty) return '';
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('8')) {
      cleaned = '+7${cleaned.substring(1)}';
    } else if (cleaned.startsWith('7') && !cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    } else if (cleaned.length == 10 && cleaned.startsWith('9')) {
      cleaned = '+7$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+$cleaned';
    }
    return cleaned;
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
    required DateTime birthDate,
    String? position,
    String? teamName,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('Начало регистрации с email: $email, роль: $role');
      }

      // Очистка и валидация email
      final cleanedEmail = email.trim().toLowerCase();
      if (cleanedEmail.isEmpty) {
        throw Exception('Введите email');
      }
      final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
      if (!emailRegex.hasMatch(cleanedEmail)) {
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
      final cleanedPhone = _cleanPhoneNumber(phone);
      if (cleanedPhone.isEmpty) {
        throw Exception('Введите номер телефона');
      }
      final phoneRegex = RegExp(r'^\+[0-9]{10,15}$');
      if (!phoneRegex.hasMatch(cleanedPhone)) {
        throw Exception('Некорректный номер телефона. Пример: +79991234567');
      }

      // Проверка даты рождения
      final now = DateTime.now();
      if (birthDate.isAfter(now)) {
        throw Exception('Дата рождения не может быть в будущем');
      }
      final minAgeDate = DateTime(now.year - 14, now.month, now.day);
      if (birthDate.isAfter(minAgeDate)) {
        throw Exception('Возраст должен быть не менее 14 лет');
      }

      // Проверка на уже существующий email (опционально, но полезно)
      try {
        final existingUser = await _supabase.client
            .from('profiles')
            .select('email')
            .eq('email', cleanedEmail)
            .limit(1)
            .maybeSingle();
        if (existingUser != null) {
          throw Exception('Пользователь с таким email уже зарегистрирован');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Проверка существующего email не удалась: $e');
      }

      // Проверка на уже существующий телефон
      try {
        final existingPhone = await _supabase.client
            .from('profiles')
            .select('phone')
            .eq('phone', cleanedPhone)
            .limit(1)
            .maybeSingle();
        if (existingPhone != null) {
          throw Exception('Пользователь с таким номером телефона уже зарегистрирован');
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Проверка существующего телефона не удалась: $e');
      }

      // Регистрация в Supabase Auth
      final AuthResponse authResponse = await _supabase.client.auth.signUp(
        email: cleanedEmail,
        password: password,
        phone: cleanedPhone,
        data: {
          'full_name': fullName.trim(),
          'phone': cleanedPhone,
          'role': role,
          'birth_date': birthDate.toIso8601String(),
          'position': position,
          'team_name': teamName,
          'email': cleanedEmail,
        },
      );

      if (authResponse.user == null) {
        throw Exception('Регистрация не удалась. Пользователь не был создан.');
      }

      if (kDebugMode) debugPrint('Пользователь создан в Auth: ${authResponse.user!.id}');

      _currentUser = authResponse.user;

      // Генерация хэша пароля
      final passwordHash = _generatePasswordHash(password);

      // Форматирование даты рождения
      final birthDateFormatted = birthDate.toIso8601String().split('T')[0];

      // Создаём профиль прямым insert (политики RLS разрешают вставку для аутентифицированного пользователя)
      final profileData = {
        'id': _currentUser!.id,
        'email': cleanedEmail,
        'full_name': fullName.trim(),
        'phone': cleanedPhone,
        'role': role,
        'birth_date': birthDateFormatted,
        'position': position,
        'team_name': teamName,
        'password': password, // В реальном проекте лучше не хранить открытый пароль
        'password_hash': passwordHash,
        'password_changed_at': DateTime.now().toUtc().toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await _supabase.client
          .from('profiles')
          .insert(profileData)
          .timeout(const Duration(seconds: 10));

      // Получаем созданный профиль
      final createdProfile = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .single()
          .timeout(const Duration(seconds: 5));

      _userProfile = createdProfile;
      _selectedRole = role;

      // Сохраняем в истории паролей
      try {
        await _supabase.client.from('password_history').insert({
          'user_id': _currentUser!.id,
          'password_hash': passwordHash,
          'changed_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (historyError) {
        if (kDebugMode) debugPrint('Ошибка сохранения истории паролей: $historyError');
      }

      // Сохраняем данные для автозаполнения
      await AuthStorage.saveCredentials(email, password);

      if (kDebugMode) debugPrint('Регистрация успешна! Профиль: $_userProfile');
      notifyListeners();

      // Возвращаемся без ошибок – пользователь уже аутентифицирован
      return;
    } on AuthException catch (e) {
      if (kDebugMode) debugPrint('AuthException: ${e.message}');
      String errorMessage = e.message.toLowerCase();
      if (errorMessage.contains('user already registered') ||
          errorMessage.contains('already registered')) {
        throw Exception('Пользователь с таким email уже зарегистрирован');
      } else if (errorMessage.contains('phone already registered')) {
        throw Exception('Пользователь с таким номером телефона уже зарегистрирован');
      } else if (errorMessage.contains('password should be at least')) {
        throw Exception('Пароль должен содержать минимум 6 символов');
      } else if (errorMessage.contains('invalid email') ||
          errorMessage.contains('email address') ||
          errorMessage.contains('is invalid')) {
        throw Exception('Некорректный email адрес');
      } else if (errorMessage.contains('rate limit')) {
        throw Exception('Слишком много попыток. Попробуйте позже');
      } else if (errorMessage.contains('phone must be a valid phone number')) {
        throw Exception('Некорректный номер телефона');
      } else {
        throw Exception('Ошибка регистрации: ${e.message}');
      }
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('PostgrestException: ${e.message}');
        debugPrint('Details: ${e.details}');
        debugPrint('Hint: ${e.hint}');
        debugPrint('Code: ${e.code}');
      }
      String errorMessage = e.message?.toLowerCase() ?? '';
      // Проверяем английские ключевые слова
      if (errorMessage.contains('duplicate key') ||
          errorMessage.contains('unique constraint')) {
        if (errorMessage.contains('email')) {
          throw Exception('Пользователь с таким email уже зарегистрирован');
        } else if (errorMessage.contains('phone')) {
          throw Exception('Пользователь с таким номером телефона уже зарегистрирован');
        } else {
          throw Exception('Пользователь с такими данными уже существует');
        }
      }
      // Проверяем русские сообщения от триггера
      else if (errorMessage.contains('уже зарегистрирован')) {
        if (errorMessage.contains('email')) {
          throw Exception('Пользователь с таким email уже зарегистрирован');
        } else if (errorMessage.contains('телефон') || errorMessage.contains('phone')) {
          throw Exception('Пользователь с таким номером телефона уже зарегистрирован');
        } else {
          throw Exception('Пользователь с такими данными уже существует');
        }
      }
      else if (errorMessage.contains('null value') || errorMessage.contains('not-null')) {
        throw Exception('Не все обязательные поля заполнены');
      } else if (errorMessage.contains('permission denied') ||
          errorMessage.contains('row-level security')) {
        throw Exception('Ошибка доступа к базе данных');
      } else {
        // Если ничего не подошло, выбрасываем оригинальное сообщение
        throw Exception('Ошибка сохранения данных в базе: ${e.message}');
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Общая ошибка регистрации: $e');
      if (e.toString().contains('timeout')) {
        throw Exception('Превышено время ожидания. Проверьте подключение к интернету');
      } else if (e.toString().contains('socket') || e.toString().contains('connection')) {
        throw Exception('Нет подключения к интернету');
      } else if (e.toString().contains('email already exists')) {
        throw Exception('Пользователь с таким email уже зарегистрирован');
      } else if (e.toString().contains('phone already exists')) {
        throw Exception('Пользователь с таким номером телефона уже зарегистрирован');
      } else {
        // Возвращаем конкретную ошибку вместо общей
        throw Exception('Произошла ошибка при регистрации: ${e.toString()}');
      }
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
        // Если профиль почему-то отсутствует, создаём его из metadata
        final userMetadata = user.userMetadata ?? {};
        final passwordHash = _generatePasswordHash(password);
        final birthDate = userMetadata['birth_date'] != null
            ? userMetadata['birth_date'].toString().split('T')[0]
            : null;

        final profileData = {
          'id': _currentUser!.id,
          'email': cleanedEmail,
          'full_name': userMetadata['full_name'] ?? '',
          'phone': userMetadata['phone'] ?? '',
          'role': userMetadata['role'] ?? 'игрок',
          'birth_date': birthDate,
          'position': userMetadata['position'],
          'team_name': userMetadata['team_name'],
          'password': password,
          'password_hash': passwordHash,
          'password_changed_at': DateTime.now().toUtc().toIso8601String(),
          'created_at': DateTime.now().toUtc().toIso8601String(),
        };

        await _supabase.client.from('profiles').insert(profileData);
        _userProfile = profileData;
      } else {
        _userProfile = profileResponse[0];
      }

      _selectedRole = _userProfile!['role'];

      await AuthStorage.saveCredentials(email, password);
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
        throw Exception('Ошибка входа: ${e.message}');
      }
    } catch (e) {
      throw Exception('Ошибка входа: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _supabase.client.auth.signOut();
      _currentUser = null;
      _userProfile = null;
      _selectedRole = null;
      await AuthStorage.clearCredentials();
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

      if (data.containsKey('password')) {
        final newPassword = data['password'];
        data['password_hash'] = _generatePasswordHash(newPassword);
        data['password_changed_at'] = DateTime.now().toUtc().toIso8601String();
      }

      await _supabase.client
          .from('profiles')
          .update(data)
          .eq('id', _currentUser!.id)
          .timeout(const Duration(seconds: 10));

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
      throw Exception('Ошибка обновления профиля: $e');
    }
  }

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

      final currentHash = _generatePasswordHash(currentPassword);
      final newHash = _generatePasswordHash(newPassword);

      final profileResponse = await _supabase.client
          .from('profiles')
          .select('password_hash')
          .eq('id', _currentUser!.id)
          .single();

      final storedHash = profileResponse['password_hash'] as String?;
      if (storedHash != currentHash) {
        throw Exception('Текущий пароль неверен');
      }

      await _supabase.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      await _supabase.client
          .from('profiles')
          .update({
            'password': newPassword,
            'password_hash': newHash,
            'password_changed_at': DateTime.now().toUtc().toIso8601String(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', _currentUser!.id);

      await _supabase.client.from('password_history').insert({
        'user_id': _currentUser!.id,
        'password_hash': newHash,
        'changed_at': DateTime.now().toUtc().toIso8601String(),
      });

      final updatedProfile = await _supabase.client
          .from('profiles')
          .select()
          .eq('id', _currentUser!.id)
          .single();

      _userProfile = updatedProfile;
      await AuthStorage.saveCredentials(_userProfile!['email'] ?? '', newPassword);
      notifyListeners();
    } on AuthException catch (e) {
      throw Exception('Ошибка смены пароля: ${e.message}');
    } catch (e) {
      throw Exception('Ошибка смены пароля: $e');
    }
  }

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