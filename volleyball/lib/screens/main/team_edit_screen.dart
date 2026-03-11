import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class TeamEditScreen extends StatefulWidget {
  const TeamEditScreen({super.key});

  @override
  State<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends State<TeamEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _teamNameController = TextEditingController(text: 'Волейбольная команда');
  final _cityController = TextEditingController(text: 'Москва');
  final _descriptionController = TextEditingController(text: 'Профессиональная команда');
  
  File? _teamLogo;

  final List<Map<String, dynamic>> _teamPlayers = [
    {'id': 1, 'name': 'Иван Петров', 'position': 'Капитан', 'number': 1},
    {'id': 2, 'name': 'Алексей Сидоров', 'position': 'Нападающий', 'number': 2},
    {'id': 3, 'name': 'Дмитрий Иванов', 'position': 'Защитник', 'number': 3},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Редактирование команды'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/team');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTeamInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickTeamLogo,
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _teamLogo != null
                        ? FileImage(_teamLogo!)
                        : const NetworkImage('https://via.placeholder.com/120') as ImageProvider,
                    child: _teamLogo == null
                        ? const Icon(Icons.camera_alt, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Center(
                child: Text(
                  'Изменить логотип',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(
                  labelText: 'Название команды',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.groups),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите название команды';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'Город',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Описание команды',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Состав команды',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('Добавить игрока'),
                    onPressed: () {
                      context.push('/team/add-player');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ..._teamPlayers.map((player) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Text(
                        player['number'].toString(),
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    title: Text(player['name']),
                    subtitle: Text(player['position']),
                    trailing: player['position'] != 'Капитан'
                        ? IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _removePlayer(player['id']);
                            },
                          )
                        : const Chip(
                            label: Text('Капитан'),
                            backgroundColor: Colors.amber,
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickTeamLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _teamLogo = File(pickedFile.path);
      });
    }
  }

  void _removePlayer(int playerId) {
    if (!mounted) return;
    
    setState(() {
      _teamPlayers.removeWhere((player) => player['id'] == playerId);
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Игрок удален из команды'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveTeamInfo() async {
    if (_formKey.currentState!.validate()) {
      try {
        await Future.delayed(const Duration(seconds: 1));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Информация о команде сохранена'),
            backgroundColor: Colors.green,
          ),
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ошибка сохранения: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}