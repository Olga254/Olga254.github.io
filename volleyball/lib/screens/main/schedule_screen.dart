import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _schedules = [
        {
          'id': 1,
          'title': 'Тренировка команды',
          'description': 'Общая физическая подготовка',
          'date': '2024-01-20',
          'day': 'Понедельник',
          'time': '18:00 - 20:00',
          'location': 'Спортзал №1',
          'type': 'training',
        },
        {
          'id': 2,
          'title': 'Товарищеский матч',
          'description': 'Матч с командой "Спартак"',
          'date': '2024-01-22',
          'day': 'Среда',
          'time': '19:00 - 21:00',
          'location': 'Стадион "Локомотив"',
          'type': 'game',
        },
        {
          'id': 3,
          'title': 'Совещание капитанов',
          'description': 'Обсуждение графика игр',
          'date': '2024-01-24',
          'day': 'Пятница',
          'time': '17:00 - 18:00',
          'location': 'Офис федерации',
          'type': 'meeting',
        },
        {
          'id': 4,
          'title': 'Тренировка по подачам',
          'description': 'Индивидуальная работа над техникой',
          'date': '2024-01-25',
          'day': 'Суббота',
          'time': '10:00 - 12:00',
          'location': 'Спортзал №2',
          'type': 'training',
        },
        {
          'id': 5,
          'title': 'Турнир выходного дня',
          'description': 'Еженедельный турнир среди любителей',
          'date': '2024-01-27',
          'day': 'Воскресенье',
          'time': '11:00 - 16:00',
          'location': 'Спорткомплекс "Олимп"',
          'type': 'tournament',
        },
      ];
      _isLoading = false;
    });
  }

  Widget _buildScheduleCard(Map<String, dynamic> schedule) {
    Color typeColor;
    IconData typeIcon;

    switch (schedule['type']) {
      case 'game':
        typeColor = Colors.red;
        typeIcon = Icons.sports_volleyball;
        break;
      case 'training':
        typeColor = Colors.blue;
        typeIcon = Icons.fitness_center;
        break;
      case 'meeting':
        typeColor = Colors.green;
        typeIcon = Icons.people;
        break;
      case 'tournament':
        typeColor = Colors.orange;
        typeIcon = Icons.emoji_events;
        break;
      default:
        typeColor = Colors.grey;
        typeIcon = Icons.event;
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: typeColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(typeIcon, color: typeColor),
        ),
        title: Text(
          schedule['title'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(schedule['description']),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14),
                const SizedBox(width: 4),
                Text('${schedule['date']} (${schedule['day']})'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14),
                const SizedBox(width: 4),
                Text(schedule['time']),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14),
                const SizedBox(width: 4),
                Text(schedule['location']),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${schedule['title']} - ${schedule['description']}'),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Расписание'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Добавление нового события'),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadSchedules,
              child: ListView.builder(
                itemCount: _schedules.length,
                itemBuilder: (context, index) {
                  return _buildScheduleCard(_schedules[index]);
                },
              ),
            ),
    );
  }
}