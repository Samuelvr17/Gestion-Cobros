import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/models/user_profile.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool get isLoggedIn => _supabase.auth.currentSession != null;

  Future<UserProfile> login(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Usuario no encontrado');
      }

      final profile = await _fetchUserProfile(response.user!.id);
      
      if (profile == null) {
        await logout();
        throw Exception('Perfil de usuario no encontrado.');
      }

      if (!profile.isActive) {
        await logout();
        throw Exception('Tu cuenta está desactivada. Contacta al administrador.');
      }

      return profile;
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Error al iniciar sesión: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> changePassword(String newPassword) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) throw Exception('No hay sesión activa.');

    try {
      // 1. Update Auth password
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      // 2. Update Profile flag using the secure RPC
      await _supabase.rpc('complete_password_change');
    } catch (e) {
      throw Exception('Error al cambiar la contraseña: ${e.toString()}');
    }
  }

  Future<UserProfile?> getCurrentUser() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final profile = await _fetchUserProfile(userId);
      
      if (profile == null) {
        // Profile explicitly not found (not a connection error)
        await logout();
        return null;
      }

      if (!profile.isActive) {
        // User explicitly deactivated
        await logout();
        return null;
      }

      return profile;
    } catch (e) {
      // If it's a transient error (network, etc.), we don't log out.
      // We let the UI handle the error or keep the previous state.
      rethrow;
    }
  }

  Future<UserProfile?> _fetchUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select('*, roles(name)')
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } on PostgrestException catch (e) {
      // PGRST116 is "The result contains 0 rows"
      if (e.code == 'PGRST116') return null;
      rethrow;
    } catch (e) {
      rethrow;
    }
  }
}
