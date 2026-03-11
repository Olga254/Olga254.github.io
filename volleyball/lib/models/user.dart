class User {
  final String id;
  final Map<String, dynamic> appMetadata;
  final Map<String, dynamic> userMetadata;
  final String aud;
  final String createdAt;

  User({
    required this.id,
    required this.appMetadata,
    required this.userMetadata,
    required this.aud,
    required this.createdAt,
  });
}