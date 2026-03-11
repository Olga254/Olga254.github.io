import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddPlayerScreen extends StatefulWidget {
  const AddPlayerScreen({super.key});

  @override
  State<AddPlayerScreen> createState() => _AddPlayerScreenState();
}

class _AddPlayerScreenState extends State<AddPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _jerseyNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  File? _playerPhoto;
  String? _selectedPosition;
  bool _isLoading = false;

  final List<String> _positions = [
    'Нападающий',
    'Защитник',
    'Связующий',
    'Либеро',
    'Диагональный',
    'Доигровщик',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить игрока'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/team/edit');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Фото игрока
              Center(
                child: GestureDetector(
                  onTap: _pickPlayerPhoto,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _playerPhoto != null
                        ? FileImage(_playerPhoto!)
                        : const NetworkImage('https://via.placeholder.com/100') as ImageProvider,
                    child: _playerPhoto == null
                        ? const Icon(Icons.person_add, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Добавить фото',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 30),
              // Полное имя
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Полное имя',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите имя игрока';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Номер на майке
              TextFormField(
                controller: _jerseyNumberController,
                decoration: const InputDecoration(
                  labelText: 'Номер на майке',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.confirmation_number),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите номер игрока';
                  }
                  final number = int.tryParse(value);
                  if (number == null || number < 1 || number > 99) {
                    return 'Введите число от 1 до 99';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Позиция - используем initialValue вместо value
              DropdownButtonFormField<String>(
                initialValue: _selectedPosition,
                decoration: const InputDecoration(
                  labelText: 'Позиция',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_volleyball),
                ),
                items: _positions.map((position) {
                  return DropdownMenuItem(
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPosition = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Выберите позицию';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Телефон
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Телефон',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 30),
              // Кнопки
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                      ),
                      onPressed: _isLoading ? null : _addPlayer,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Добавить игрока',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        context.pop();
                      },
                      child: const Text('Отмена'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickPlayerPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _playerPhoto = File(pickedFile.path);
      });
    }
  }

  Future<void> _addPlayer() async {
    if (_formKey.currentState!.validate()) {
      if (!mounted) return;

      setState(() {
        _isLoading = true;
      });

      try {
        // Временная заглушка - добавление игрока
        await Future.delayed(const Duration(seconds: 1));

        // Проверяем mounted перед использованием контекста
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Игрок успешно добавлен в команду'),
            backgroundColor: Colors.green,
          ),
        );
        // Вернуться к редактированию команды
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка добавления игрока: $e'),
              backgroundColor: Colors.red,
            ),
          );
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
}