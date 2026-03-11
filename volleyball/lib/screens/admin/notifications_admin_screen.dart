import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';

class NotificationsAdminScreen extends StatefulWidget {
  const NotificationsAdminScreen({super.key});

  @override
  State<NotificationsAdminScreen> createState() => _NotificationsAdminScreenState();
}

class _NotificationsAdminScreenState extends State<NotificationsAdminScreen> {
  final SupabaseService _supabase = SupabaseService();
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _roleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final response = await _supabase.client
          .from('admin_notifications')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Заполните заголовок и текст уведомления'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _supabase.client.from('admin_notifications').insert({
        'title': _titleController.text,
        'message': _messageController.text,
        'target_role': _roleController.text.isEmpty ? null : _roleController.text,
        'is_active': true,
        'created_by': _supabase.client.auth.currentUser?.id,
      });

      _titleController.clear();
      _messageController.clear();
      _roleController.clear();

      await _loadNotifications();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Уведомление успешно добавлено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка добавления уведомления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleNotification(int index) async {
    try {
      final notification = _notifications[index];
      await _supabase.client
          .from('admin_notifications')
          .update({'is_active': !notification['is_active']})
          .eq('id', notification['id']);

      await _loadNotifications();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка обновления уведомления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _supabase.client
          .from('admin_notifications')
          .delete()
          .eq('id', id);

      await _loadNotifications();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Уведомление удалено'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления уведомления: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Управление уведомлениями'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Text(
                            'Добавить новое уведомление',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              labelText: 'Заголовок уведомления',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              labelText: 'Текст уведомления',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _roleController,
                            decoration: const InputDecoration(
                              labelText: 'Роль (оставьте пустым для всех)',
                              hintText: 'игрок, любитель, болельщик',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _addNotification,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Добавить уведомление'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        color: notification['is_active'] ? null : Colors.grey.shade200,
                        child: ListTile(
                          title: Text(
                            notification['title'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification['message']),
                              const SizedBox(height: 4),
                              if (notification['target_role'] != null)
                                Chip(
                                  label: Text(
                                    'Для: ${notification['target_role']}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  backgroundColor: Colors.blue.shade50,
                                ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Switch(
                                value: notification['is_active'],
                                onChanged: (value) {
                                  _toggleNotification(index);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteNotification(notification['id']);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}