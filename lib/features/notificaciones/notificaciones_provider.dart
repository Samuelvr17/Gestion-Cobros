import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificacionesState {
  final List<Map<String, dynamic>> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? errorMessage;

  NotificacionesState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.errorMessage,
  });

  NotificacionesState copyWith({
    List<Map<String, dynamic>>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificacionesState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class NotificacionesNotifier extends StateNotifier<NotificacionesState> {
  final SupabaseClient _supabase = Supabase.instance.client;

  NotificacionesNotifier() : super(NotificacionesState());

  Future<void> loadNotifications(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      final List<Map<String, dynamic>> notifications = List<Map<String, dynamic>>.from(response);
      final unreadCount = notifications.where((n) => n['is_read'] == false).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar notificaciones: ${e.toString()}',
      );
    }
  }

  Future<void> markAsRead(String notificationId, String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      await loadNotifications(userId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al marcar como leída: ${e.toString()}',
      );
    }
  }

  Future<void> markAllAsRead(String userId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
      
      await loadNotifications(userId);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error al marcar todas como leídas: ${e.toString()}',
      );
    }
  }
}

final notificacionesProvider = StateNotifierProvider<NotificacionesNotifier, NotificacionesState>((ref) {
  return NotificacionesNotifier();
});
