import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      setState(() {
        _news = [
          {
            'id': 1,
            'title': 'Начало нового сезона волейбола 2024',
            'content': 'Уважаемые игроки и болельщики! Рады сообщить, что с 15 сентября начинается новый сезон волейбольных соревнований. Регистрация команд открыта до 10 сентября.',
            'category': 'Новости лиги',
            'image_url': 'https://via.placeholder.com/400x200',
            'created_at': '2024-09-01T10:00:00Z',
          },
          {
            'id': 2,
            'title': 'Турнир выходного дня в Москве',
            'content': 'Приглашаем все команды на открытый турнир по волейболу, который состоится 7-8 сентября в спортивном комплексе "Олимпийский". Призовой фонд - 100 000 рублей.',
            'category': 'Соревнования',
            'image_url': 'https://via.placeholder.com/400x200',
            'created_at': '2024-08-28T14:30:00Z',
          },
          {
            'id': 3,
            'title': 'Мастер-класс от профессиональных игроков',
            'content': '24 сентября состоится мастер-класс от игроков сборной России. Участие бесплатное, требуется предварительная регистрация.',
            'category': 'Обучение',
            'image_url': 'https://via.placeholder.com/400x200',
            'created_at': '2024-08-25T09:15:00Z',
          },
          {
            'id': 4,
            'title': 'Обновление функционала приложения',
            'content': 'Мы добавили новые функции: расписание команд, поиск игр для любителей и систему уведомлений. Оставляйте отзывы!',
            'category': 'Обновления',
            'image_url': 'https://via.placeholder.com/400x200',
            'created_at': '2024-08-20T16:45:00Z',
          },
          {
            'id': 5,
            'title': 'Набор в новые команды',
            'content': 'В нескольких районах Москвы формируются новые волейбольные команды. Если вы ищете команду для регулярных тренировок, заполните анкету.',
            'category': 'Набор',
            'image_url': 'https://via.placeholder.com/400x200',
            'created_at': '2024-08-18T11:20:00Z',
          },
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;
    final role = user?['role'] ?? 'игрок';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Новости',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (user != null)
              Text(
                '${user['full_name']} (${_capitalize(role)})',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            context.go('/authorization');
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Уведомления будут реализованы позже'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Уведомления',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  context.go('/profile');
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Профиль'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Выйти', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: _loadNews,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _news.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final newsItem = _news[index];
                  return _buildNewsCard(newsItem);
                },
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              context.go('/team');
              break;
            case 2:
              context.go('/schedule');
              break;
            case 3:
              if (role == 'любитель' || role == 'игрок') {
                context.go('/game-search');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Поиск игр доступен только для ролей "Игрок" и "Любитель"'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Команда',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Расписание',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: role == 'любитель' || role == 'игрок' ? 'Поиск игр' : 'Расписание',
          ),
        ],
      ),
    );
  }

  Future<void> _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      await authProvider.signOut();
      if (mounted) {
        context.go('/authorization');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка выхода: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildNewsCard(Map<String, dynamic> newsItem) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Image.network(
              newsItem['image_url'],
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsItem['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  newsItem['content'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        newsItem['category'] ?? 'Новости',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(newsItem['created_at']),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays == 0) {
        return 'Сегодня';
      } else if (difference.inDays == 1) {
        return 'Вчера';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} дня назад';
      } else {
        return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}