import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_formatPhoneNumber);
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    _phoneController.removeListener(_formatPhoneNumber);
    _phoneController.dispose();
    super.dispose();
  }
  
  // Форматирование номера телефона при вводе
  void _formatPhoneNumber() {
    final text = _phoneController.text;
    
    if (text.isEmpty) return;
    
    // Убираем все нецифровые символы кроме +
    String digitsOnly = text.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Автоматическое добавление +7 для российских номеров
    if (!digitsOnly.startsWith('+')) {
      if (digitsOnly.startsWith('7') || digitsOnly.startsWith('8')) {
        digitsOnly = '+7${digitsOnly.substring(1)}';
      } else if (digitsOnly.length == 10 && digitsOnly.startsWith('9')) {
        digitsOnly = '+7$digitsOnly';
      } else {
        digitsOnly = '+$digitsOnly';
      }
    }
    
    String formatted = '';
    
    if (digitsOnly.startsWith('+7')) {
      // Формат для России: +7 (XXX) XXX-XX-XX
      final numbers = digitsOnly.substring(2);
      
      if (numbers.isNotEmpty) {
        formatted = '+7';
        
        if (numbers.isNotEmpty) { // ИСПРАВЛЕНО: numbers.length > 0 -> numbers.isNotEmpty
          formatted += ' (${numbers.substring(0, numbers.length > 3 ? 3 : numbers.length)}';
          
          if (numbers.length > 3) {
            formatted += ') ${numbers.substring(3, numbers.length > 6 ? 6 : numbers.length)}';
            
            if (numbers.length > 6) {
              formatted += '-${numbers.substring(6, numbers.length > 8 ? 8 : numbers.length)}';
              
              if (numbers.length > 8) {
                formatted += '-${numbers.substring(8, numbers.length > 10 ? 10 : numbers.length)}';
              }
            }
          }
        }
      }
    } else {
      // Общий формат для других стран
      formatted = digitsOnly;
    }
    
    if (text != formatted) {
      _phoneController.value = _phoneController.value.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }
  
  // Получение чистого номера телефона
  String _getCleanPhoneNumber() {
    final text = _phoneController.text;
    String digitsOnly = text.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Автоматическое добавление +7 для российских номеров
    if (!digitsOnly.startsWith('+')) {
      if (digitsOnly.startsWith('7') || digitsOnly.startsWith('8')) {
        digitsOnly = '+7${digitsOnly.substring(1)}';
      } else if (digitsOnly.length == 10 && digitsOnly.startsWith('9')) {
        digitsOnly = '+7$digitsOnly';
      } else {
        digitsOnly = '+$digitsOnly';
      }
    }
    
    return digitsOnly;
  }
  
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final role = authProvider.selectedRole ?? 'игрок';
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/role'),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Роль пользователя
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withAlpha(100),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getRoleIcon(role),
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _getRoleDisplayName(role),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        context.go('/role');
                      },
                      child: Text(
                        'Изменить',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Отображение ошибки
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.red[700], size: 20),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'example@gmail.com',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите email';
                  }
                  
                  final email = value.trim();
                  
                  if (!email.contains('@')) {
                    return 'Email должен содержать @';
                  }
                  
                  final parts = email.split('@');
                  if (parts.length != 2) {
                    return 'Некорректный email';
                  }
                  
                  final localPart = parts[0];
                  final domain = parts[1];
                  
                  if (localPart.isEmpty || domain.isEmpty) {
                    return 'Некорректный email';
                  }
                  
                  if (!domain.contains('.')) {
                    return 'Некорректный домен email';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Пароль
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Пароль',
                  hintText: 'Не менее 6 символов',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                ),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 6) {
                    return 'Пароль должен быть не менее 6 символов';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Подтверждение пароля
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Подтвердите пароль',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: const Color(0xFFF8F9FA),
                ),
                obscureText: _obscureConfirmPassword,
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Подтвердите пароль';
                  }
                  if (value != _passwordController.text) {
                    return 'Пароли не совпадают';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Полное имя
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Полное имя',
                  hintText: 'Иванов Иван Иванович',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                ),
                textInputAction: TextInputAction.next,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите ваше имя';
                  }
                  if (value.trim().length < 2) {
                    return 'Имя должно содержать минимум 2 символа';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Телефон с автоматическим форматированием
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  hintText: '+7 (999) 123-45-67',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                ),
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите телефон';
                  }
                  
                  final cleaned = _getCleanPhoneNumber();
                  
                  if (cleaned.length < 12) {
                    return 'Введите полный номер телефона';
                  }
                  
                  if (!cleaned.startsWith('+')) {
                    return 'Номер должен начинаться с + и кода страны';
                  }
                  
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Кнопка регистрации
              _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      onPressed: _register,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        backgroundColor: Theme.of(context).primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'Зарегистрироваться',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
              
              const SizedBox(height: 20),
              
              // Ссылка на авторизацию
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/authorization');
                  },
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                      children: [
                        const TextSpan(text: 'Уже есть аккаунт? '),
                        TextSpan(
                          text: 'Авторизоваться',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 10),
              
              // Ссылка на выбор роли
              Center(
                child: TextButton(
                  onPressed: () {
                    context.go('/role');
                  },
                  child: Text(
                    'Вернуться к выбору роли',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    
    setState(() {
      _errorMessage = null;
    });
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        
        // Подготовка данных
        final email = _emailController.text.trim();
        final password = _passwordController.text;
        final fullName = _fullNameController.text.trim();
        final phone = _getCleanPhoneNumber();
        
        if (kDebugMode) {
          debugPrint('=== РЕГИСТРАЦИЯ ===');
          debugPrint('Email: $email');
          debugPrint('Пароль: $password');
          debugPrint('Имя: $fullName');
          debugPrint('Телефон: $phone');
          debugPrint('Роль: ${authProvider.selectedRole ?? 'игрок'}');
          debugPrint('===================');
        }
        
        await authProvider.signUp(
          email: email,
          password: password,
          fullName: fullName,
          phone: phone,
          role: authProvider.selectedRole ?? 'игрок',
        );
        
        if (mounted) {
          _showSuccessNotification(context);
        }
        
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring('Exception: '.length);
          }
          
          setState(() {
            _errorMessage = errorMessage;
          });
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 300),
            );
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
  
  void _showSuccessNotification(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text('Регистрация успешна!'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Добро пожаловать в приложение Volleyball!'),
            SizedBox(height: 10),
            Text(
              'Теперь вы можете войти в систему и начать использовать все возможности приложения.',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.go('/home');
            },
            child: const Text('На главную'),
          ),
        ],
      ),
    );
  }
  
  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'игрок':
        return 'Игрок';
      case 'любитель':
        return 'Любитель';
      case 'болельщик':
        return 'Болельщик';
      case 'капитан':
        return 'Капитан';
      default:
        return 'Игрок';
    }
  }
  
  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'игрок':
        return Icons.sports_volleyball;
      case 'любитель':
        return Icons.person;
      case 'болельщик':
        return Icons.people;
      case 'капитан':
        return Icons.star;
      default:
        return Icons.person;
    }
  }
}