import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardState {
  final Map<String, dynamic>? stats;
  final bool isLoading;
  final String? errorMessage;

  DashboardState({
    this.stats,
    this.isLoading = false,
    this.errorMessage,
  });

  DashboardState copyWith({
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DashboardState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final _supabase = Supabase.instance.client;

  DashboardNotifier() : super(DashboardState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // a) fund_accounts main
      final fundRes = await _supabase
          .from('fund_accounts')
          .select('available_amount, total_disbursed, total_recovered')
          .eq('id', 'main')
          .maybeSingle();

      // b) total_active_loans
      final activeLoansCount = await _supabase
          .from('loans')
          .count(CountOption.exact)
          .eq('status', 'ACTIVE');

      // c) total_defaulted_loans
      final defaultedLoansCount = await _supabase
          .from('loans')
          .count(CountOption.exact)
          .eq('status', 'DEFAULTED');

      // d) total_clients
      final clientsCount = await _supabase
          .from('clients')
          .count(CountOption.exact)
          .eq('is_active', true);

      // e) total_collected_today
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

      final paymentsRes = await _supabase
          .from('payments')
          .select('amount')
          .gte('payment_timestamp', startOfDay)
          .lte('payment_timestamp', endOfDay);

      double totalCollectedToday = 0;
      for (var p in (paymentsRes as List<dynamic>)) {
        totalCollectedToday += (p['amount'] as num).toDouble();
      }

      double availableAmount = 0;
      double totalDisbursed = 0;
      double totalRecovered = 0;

      if (fundRes != null) {
        availableAmount = (fundRes['available_amount'] as num?)?.toDouble() ?? 0;
        totalDisbursed = (fundRes['total_disbursed'] as num?)?.toDouble() ?? 0;
        totalRecovered = (fundRes['total_recovered'] as num?)?.toDouble() ?? 0;
      }

      final stats = {
        'total_active_loans': activeLoansCount,
        'total_clients': clientsCount,
        'total_collected_today': totalCollectedToday,
        'total_disbursed': totalDisbursed,
        'available_fund': availableAmount,
        'total_recovered': totalRecovered,
        'total_defaulted_loans': defaultedLoansCount,
      };

      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final dashboardProvider =
    StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
