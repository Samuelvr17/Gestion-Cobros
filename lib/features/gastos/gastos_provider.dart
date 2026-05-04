import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GastosState {
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  GastosState({
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  GastosState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return GastosState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      success: success ?? this.success,
    );
  }
}

class GastosNotifier extends StateNotifier<GastosState> {
  GastosNotifier() : super(GastosState());

  Future<void> registrarGasto({
    required String userId,
    required String shiftId,
    required String category,
    required double amount,
    String? description,
  }) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null, success: false);

      await Supabase.instance.client.rpc(
        'registrar_gasto',
        params: {
          'p_user_id': userId,
          'p_shift_id': shiftId,
          'p_category': category,
          'p_amount': amount,
          'p_description': description,
        },
      );

      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void reset() {
    state = GastosState();
  }
}

final gastosProvider = StateNotifierProvider<GastosNotifier, GastosState>((ref) {
  return GastosNotifier();
});
