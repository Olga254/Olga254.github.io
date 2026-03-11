import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    setState(() {
      _notifications = [
        {
          'id': 1,
          'title': 'Добро пожаловать!',
          'message': 'Вы успешно зарегистрировались в приложении.',
          'time': '2024-01-15 10:00',
          'read': false,
        },
        {
          'id': 2,
          'title': 'Новая тренировка',
          'message': 'Завтра в 18:00 запланирована тренировка.',
          'time': '2024-01-14 15:30',
          'read': true,
        },
        {
          'id': 3,
          'title': 'Обновление приложения',
          'message': 'Доступна новая версия приложения.',
          'time': '2024-01-13 09:15',
          'read': false,
        },
        {
          'id': 4,
          'title': 'Изменение расписания',
          'message': 'Тренировка в среду перенесена на 19:00.',
          'time': '2024-01-12 14:20',
          'read': false,
        },
        {
          'id': 5,
          'title': 'Оплата членского взноса',
          'message': 'Напоминаем об оплате членского взноса до конца месяца.',
          'time': '2024-01-10 11:45',
          'read': true,
        },
      ];
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    try {
      await authProvider.signOut();
      if (!mounted) return;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/authorization',
            (route) => false,
          );
        }
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при выходе: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Профиль'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    color: Theme.of(context).primaryColor.withAlpha(25),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 50,
                          child: Icon(Icons.person, size: 50),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?['full_name'] ?? 'Пользователь',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?['email'] ?? '',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            user?['role'] ?? 'игрок',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        if (user?['team_name'] != null) ...[
                          const SizedBox(height: 8),
                          Chip(
                            label: Text(
                              user?['team_name'] ?? '',
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Уведомления',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._notifications.map((notification) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: notification['read']
                                ? null
                                : Colors.blue.shade50,
                            child: ListTile(
                              leading: notification['read']
                                  ? const Icon(Icons.notifications_none)
                                  : const Icon(Icons.notifications_active,
                                      color: Colors.blue),
                              title: Text(notification['title']),
                              subtitle: Text(notification['message']),
                              trailing: Text(
                                notification['time'].toString().split(' ')[0],
                                style: const TextStyle(fontSize: 12),
                              ),
                              onTap: () {
                                setState(() {
                                  notification['read'] = true;
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Настройки',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Настройки приложения'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Настройки приложения'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.notifications),
                                title: const Text('Уведомления'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Настройка уведомлений'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.security),
                                title: const Text('Безопасность'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Настройки безопасности'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.help),
                                title: const Text('Помощь и поддержка'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Помощь и поддержка'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.info),
                                title: const Text('О приложении'),
                                trailing: const Icon(Icons.arrow_forward_ios),
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('О приложении'),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.logout,
                                    color: Colors.red),
                                title: const Text('Выйти',
                                    style: TextStyle(color: Colors.red)),
                                onTap: () => _logout(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
}