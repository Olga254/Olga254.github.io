// supabase_client.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  static const String url = 'https://frvexfoezbscdbcvuxas.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZydmV4Zm9lemJzY2RiY3Z1eGFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTk3NDY4ODgsImV4cCI6MjA3NTMyMjg4OH0.XDr9MFxBMX0P42a4MwjstxtZeh_Caqdyrfpfr7d9ec8';

  Future<void> initialize() async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
  }

  SupabaseClient get client {
    return Supabase.instance.client;
  }

  // Методы для работы с пользователями
  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser {
    return client.auth.currentUser;
  }

  // Методы для работы с постами
  Future<List<Map<String, dynamic>>> getPosts() async {
    final response = await client
        .from('posts')
        .select('*')
        .order('created_at', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> createPost(
    String description, 
    List<String> imageUrls, 
    String userId
  ) async {
    final response = await client
        .from('posts')
        .insert({
          'description': description,
          'image_urls': imageUrls,
          'user_id': userId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();
    return response;
  }

  // Методы для работы с профилями
  Future<Map<String, dynamic>> getProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();
    return response;
  }

  Future<void> updateProfile(
    String userId, 
    String name, 
    String username, 
    String bio
  ) async {
    await client
        .from('profiles')
        .upsert({
          'id': userId,
          'name': name,
          'username': username,
          'bio': bio,
          'updated_at': DateTime.now().toIso8601String(),
        });
  }

  // Методы для работы с лайками
  Future<void> toggleLike(String postId, String userId) async {
    final existingLike = await client
        .from('likes')
        .select('*')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();

    if (existingLike != null) {
      await client
          .from('likes')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', userId);
    } else {
      await client
          .from('likes')
          .insert({
            'post_id': postId,
            'user_id': userId,
            'created_at': DateTime.now().toIso8601String(),
          });
    }
  }

  Future<int> getLikesCount(String postId) async {
    final response = await client
        .from('likes')
        .select('*')
        .eq('post_id', postId);
    return response.length;
  }

  Future<bool> isLiked(String postId, String userId) async {
    final response = await client
        .from('likes')
        .select('*')
        .eq('post_id', postId)
        .eq('user_id', userId)
        .maybeSingle();
    return response != null;
  }

  // Методы для работы с комментариями
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    final response = await client
        .from('comments')
        .select('''
          *,
          profiles:user_id(name, username)
        ''')
        .eq('post_id', postId)
        .order('created_at', ascending: true);
    return response;
  }

  Future<Map<String, dynamic>> addComment(
    String postId, 
    String userId, 
    String text
  ) async {
    final response = await client
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'text': text,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('''
          *,
          profiles:user_id(name, username)
        ''')
        .single();
    return response;
  }
}