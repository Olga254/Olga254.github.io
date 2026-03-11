class AppConstants {
  static const List<String> positions = [
    'Нападающий',
    'Защитник',
    'Связующий',
    'Либеро',
    'Диагональный',
    'Доигровщик',
  ];

  static const List<String> roles = [
    'игрок',
    'любитель',
    'болельщик',
    'капитан',
    'admin',
  ];

  static const Map<String, String> roleDisplayNames = {
    'игрок': 'Игрок',
    'любитель': 'Любитель',
    'болельщик': 'Болельщик',
    'капитан': 'Капитан',
    'admin': 'Администратор',
  };

  static const List<String> scheduleTypes = [
    'training',
    'game',
    'meeting',
    'tournament',
    'event',
  ];

  static const Map<String, String> scheduleTypeNames = {
    'training': 'Тренировка',
    'game': 'Игра',
    'meeting': 'Совещание',
    'tournament': 'Турнир',
    'event': 'Мероприятие',
  };

  static const List<String> gameLevels = [
    'Начинающие',
    'Любители',
    'Средний',
    'Профессионалы',
  ];

  static const List<String> notificationTypes = [
    'info',
    'warning',
    'success',
    'error',
  ];
}