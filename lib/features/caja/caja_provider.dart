import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class CajaState {
  final Map<String, dynamic>? shift;
  final Map<String, dynamic>? resumen;
  final bool isLoading;
  final String? errorMessage;

  CajaState({
    this.shift,
    this.resumen,
    this.isLoading = false,
    this.errorMessage,
  });

  CajaState copyWith({
    Map<String, dynamic>? shift,
    Map<String, dynamic>? resumen,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CajaState(
      shift: shift ?? this.shift,
      resumen: resumen ?? this.resumen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CajaNotifier extends StateNotifier<CajaState> {
  CajaNotifier() : super(CajaState());

  Future<void> loadCaja(String userId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      // Call abrir_o_obtener_caja
      final shiftResponse = await Supabase.instance.client.rpc(
        'abrir_o_obtener_caja',
        params: {'p_collector_id': userId},
      );
      
      // Get today's date in YYYY-MM-DD
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      // Call obtener_resumen_cobrador
      final resumenResponse = await Supabase.instance.client.rpc(
        'obtener_resumen_cobrador',
        params: {'p_collector_id': userId, 'p_date': todayStr},
      );

      state = CajaState(
        shift: shiftResponse as Map<String, dynamic>?,
        resumen: resumenResponse as Map<String, dynamic>?,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> cerrarCaja(String userId, String shiftId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);
      
      await Supabase.instance.client.rpc(
        'cerrar_caja',
        params: {'p_shift_id': shiftId, 'p_user_id': userId},
      );

      await loadCaja(userId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final cajaProvider = StateNotifierProvider<CajaNotifier, CajaState>((ref) {
  return CajaNotifier();
});
