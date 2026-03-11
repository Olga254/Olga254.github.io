import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameSearchScreen extends StatefulWidget {
  const GameSearchScreen({super.key});

  @override
  State<GameSearchScreen> createState() => _GameSearchScreenState();
}

class _GameSearchScreenState extends State<GameSearchScreen> {
  List<Map<String, dynamic>> _games = [];
  bool _isLoading = true;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _games = [
        {
          'id': 1,
          'title': 'Вечерний волейбол',
          'description': 'Игра для всех желающих',
          'date': '2024-01-20',
          'time': '18:00 - 20:00',
          'location': 'Спортзал "Центральный"',
          'players_needed': 4,
          'price': 300,
          'level': 'Любители',
          'joined': false,
        },
        {
          'id': 2,
          'title': 'Турнир среди офисов',
          'description': 'Корпоративные соревнования',
          'date': '2024-01-22',
          'time': '19:00 - 22:00',
          'location': 'Стадион "Северный"',
          'players_needed': 6,
          'price': 500,
          'level': 'Средний',
          'joined': true,
        },
        {
          'id': 3,
          'title': 'Открытая тренировка',
          'description': 'Бесплатная тренировка с тренером',
          'date': '2024-01-23',
          'time': '17:00 - 19:00',
          'location': 'Парк "Победа"',
          'players_needed': 10,
          'price': 0,
          'level': 'Начинающие',
          'joined': false,
        },
      ];
      _isLoading = false;
    });
  }

  Widget _buildGameCard(Map<String, dynamic> game) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            width: double.infinity,
            color: Colors.blue[100],
            child: Center(
              child: Icon(
                Icons.sports_volleyball,
                size: 50,
                color: Colors.blue[600],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(game['description']),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 16),
                    const SizedBox(width: 8),
                    Text(game['date']),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 16),
                    const SizedBox(width: 8),
                    Text(game['time']),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 8),
                    Text(game['location']),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.people, size: 16),
                    const SizedBox(width: 8),
                    Text('Нужно игроков: ${game['players_needed']}'),
                    const Spacer(),
                    Text(
                      game['price'] == 0 ? 'Бесплатно' : '${game['price']} руб.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: game['price'] == 0 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Chip(
                      label: Text(game['level']),
                      backgroundColor: Colors.blue[50],
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          game['joined'] = !game['joined'];
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: game['joined'] ? Colors.green : Colors.blue,
                      ),
                      child: Text(
                        game['joined'] ? 'Вы записаны' : 'Записаться',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поиск игр'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/home');
          },
        ),
      ),
      body: Column(
        children: [
          // Фильтры
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Все игры', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Бесплатные', 'free'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Ближайшие', 'soon'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Мои записи', 'my'),
                ],
              ),
            ),
          ),
          // Список игр
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadGames,
                    child: ListView.builder(
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        return _buildGameCard(_games[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    return FilterChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
    );
  }
}