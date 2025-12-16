import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCaptain = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _checkIfCaptain();
  }

  Future<void> _checkIfCaptain() async {
    // Временная заглушка
    await Future.delayed(const Duration(milliseconds: 100));
    setState(() {
      _isCaptain = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Команда'),
        actions: [
          if (_isCaptain)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                context.push('/team/edit');
              },
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Расписание'),
            Tab(text: 'Состав'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamScheduleTab(),
          _buildTeamPlayersTab(),
        ],
      ),
    );
  }

  Widget _buildTeamScheduleTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.calendar_today, color: Colors.blue),
            title: Text('Тренировка ${index + 1}'),
            subtitle: Text('${index + 1} ноября 2024, 18:00\nСпортзал ${index + 1}'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Детали тренировки ${index + 1}'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTeamPlayersTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.blue),
              ),
            ),
            title: Text('Игрок ${index + 1}'),
            subtitle: Text(index == 0 ? 'Капитан' : 'Игрок'),
            trailing: index == 0 ? const Icon(Icons.star, color: Colors.amber) : null,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}