import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrestamosState {
  final List<Map<String, dynamic>> loans;
  final bool isLoading;
  final String? errorMessage;
  final String? filterStatus;

  PrestamosState({
    this.loans = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filterStatus,
  });

  PrestamosState copyWith({
    List<Map<String, dynamic>>? loans,
    bool? isLoading,
    String? errorMessage,
    String? filterStatus,
    bool clearError = false,
  }) {
    return PrestamosState(
      loans: loans ?? this.loans,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      filterStatus: filterStatus ?? this.filterStatus,
    );
  }

  List<Map<String, dynamic>> get filteredLoans {
    if (filterStatus == null || filterStatus == 'Todos') {
      return loans;
    }
    return loans.where((loan) => loan['status'] == filterStatus).toList();
  }
}

class PrestamosNotifier extends StateNotifier<PrestamosState> {
  PrestamosNotifier() : super(PrestamosState());

  Future<void> loadLoans(String collectorId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await Supabase.instance.client
          .from('loans')
          .select('*, clients!inner(name)')
          .eq('collector_id', collectorId)
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> mappedLoans = (response as List<dynamic>).map((e) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(e as Map);
        item['client_name'] = item['clients']['name'];
        return item;
      }).toList();

      state = state.copyWith(loans: mappedLoans, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setFilter(String? status) {
    state = state.copyWith(filterStatus: status);
  }
}

final prestamosProvider = StateNotifierProvider<PrestamosNotifier, PrestamosState>((ref) {
  return PrestamosNotifier();
});
