import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CobrosState {
  final List<dynamic> loans;
  final Map<String, dynamic>? selectedLoan;
  final bool isLoading;
  final String? errorMessage;
  final bool success;

  CobrosState({
    this.loans = const [],
    this.selectedLoan,
    this.isLoading = false,
    this.errorMessage,
    this.success = false,
  });

  CobrosState copyWith({
    List<dynamic>? loans,
    Map<String, dynamic>? selectedLoan,
    bool? isLoading,
    String? errorMessage,
    bool? success,
  }) {
    return CobrosState(
      loans: loans ?? this.loans,
      selectedLoan: selectedLoan ?? this.selectedLoan,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      success: success ?? this.success,
    );
  }
}

class CobrosNotifier extends StateNotifier<CobrosState> {
  CobrosNotifier() : super(CobrosState());

  Future<void> loadLoans(String collectorId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null, success: false);

      final response = await Supabase.instance.client
          .from('loans')
          .select('*, clients!inner(name)')
          .eq('collector_id', collectorId)
          .eq('status', 'ACTIVE')
          .order('name', referencedTable: 'clients', ascending: true);

      // The response returns clients as a Map, let's map it to flatten client_name
      final mappedLoans = (response as List<dynamic>).map((loan) {
        final newLoan = Map<String, dynamic>.from(loan);
        newLoan['client_name'] = loan['clients']['name'];
        return newLoan;
      }).toList();

      state = state.copyWith(loans: mappedLoans, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void selectLoan(Map<String, dynamic>? loan) {
    state = state.copyWith(selectedLoan: loan, success: false);
  }

  Future<void> registrarPago(String loanId, String collectorId, double amount, String? shiftId) async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null, success: false);

      await Supabase.instance.client.rpc(
        'registrar_pago',
        params: {
          'p_loan_id': loanId,
          'p_collector_id': collectorId,
          'p_amount': amount,
          'p_shift_id': shiftId,
        },
      );

      state = state.copyWith(success: true, selectedLoan: null);
      await loadLoans(collectorId);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final cobrosProvider = StateNotifierProvider<CobrosNotifier, CobrosState>((ref) {
  return CobrosNotifier();
});
