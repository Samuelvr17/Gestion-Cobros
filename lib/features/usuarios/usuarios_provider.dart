import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuariosState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? errorMessage;

  UsuariosState({
    required this.users,
    this.isLoading = false,
    this.errorMessage,
  });

  UsuariosState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UsuariosState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UsuariosNotifier extends StateNotifier<UsuariosState> {
  final SupabaseClient _supabase;

  UsuariosNotifier(this._supabase) : super(UsuariosState(users: []));

  Future<void> loadUsers() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      final response = await _supabase
          .from('user_profiles')
          .select('id, full_name, phone, cedula, is_active, must_change_password, roles(name)')
          .order('full_name', ascending: true);
      
      state = state.copyWith(
        users: List<Map<String, dynamic>>.from(response),
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar usuarios: $e',
      );
    }
  }

  Future<void> toggleActive(String userId, bool currentStatus) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      await _supabase
          .from('user_profiles')
          .update({'is_active': !currentStatus})
          .eq('id', userId);
          
      await loadUsers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al actualizar estado: $e',
      );
    }
  }

  Future<void> createUser({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String cedula,
    required String roleId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await _supabase.rpc('admin_create_user', params: {
        'p_email': email,
        'p_password': password,
        'p_full_name': fullName,
        'p_phone': phone,
        'p_cedula': cedula,
        'p_role_id': roleId,
      });

      await loadUsers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al crear usuario: $e',
      );
      rethrow; // Re-throw to handle in UI
    }
  }
}

final usuariosProvider = StateNotifierProvider<UsuariosNotifier, UsuariosState>((ref) {
  return UsuariosNotifier(Supabase.instance.client);
});
