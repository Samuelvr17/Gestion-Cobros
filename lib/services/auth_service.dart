import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isLoggedIn => _supabase.auth.currentSession != null;

  Future<UserProfile?> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Usuario no encontrado');
      }

      return await _fetchUserProfile(response.user!.id);
    } catch (e) {
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<UserProfile?> getCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    return await _fetchUserProfile(userId);
  }

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('*, roles(name)')
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      // In case of error fetching profile (e.g. doesn't exist yet)
      return null;
    }
  }
}
