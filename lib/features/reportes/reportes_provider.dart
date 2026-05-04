import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportesState {
  final List<dynamic> data;
  final bool isLoading;
  final String? errorMessage;
  final int selectedTab;

  ReportesState({
    required this.data,
    this.isLoading = false,
    this.errorMessage,
    this.selectedTab = 0,
  });

  ReportesState copyWith({
    List<dynamic>? data,
    bool? isLoading,
    String? errorMessage,
    int? selectedTab,
  }) {
    return ReportesState(
      data: data ?? this.data,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}

class ReportesNotifier extends StateNotifier<ReportesState> {
  final _supabase = Supabase.instance.client;

  ReportesNotifier() : super(ReportesState(data: []));

  Future<void> loadReporte(int tab) async {
    state = state.copyWith(isLoading: true, errorMessage: null, selectedTab: tab);

    try {
      List<dynamic> result = [];

      switch (tab) {
        case 0: // Cobros del día
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

          final response = await _supabase
              .from('payments')
              .select('''
                amount,
                payment_timestamp,
                loans (
                  loan_number,
                  clients (name)
                ),
                collector:user_profiles (full_name)
              ''')
              .gte('payment_timestamp', startOfDay)
              .lte('payment_timestamp', endOfDay)
              .order('payment_timestamp', ascending: false);
          
          result = response as List<dynamic>;
          break;

        case 1: // Préstamos activos
          final response = await _supabase
              .from('loans')
              .select('''
                *,
                clients (name),
                collector:user_profiles (full_name)
              ''')
              .eq('status', 'ACTIVE')
              .order('created_at', ascending: false);
          
          result = response as List<dynamic>;
          break;

        case 2: // Clientes en mora
          final response = await _supabase
              .from('loans')
              .select('''
                overdue_days,
                mora_amount,
                remaining_amount,
                loan_number,
                clients (name, phone, traffic_light),
                collector:user_profiles (full_name)
              ''')
              .eq('status', 'ACTIVE')
              .gt('overdue_days', 0)
              .order('overdue_days', ascending: false);
          
          result = response as List<dynamic>;
          break;

        case 3: // Cobradores
          // 1. Get collectors
          final collectorsRes = await _supabase
              .from('user_profiles')
              .select('id, full_name, phone, roles!inner(name)')
              .eq('roles.name', 'cobrador')
              .eq('is_active', true)
              .order('full_name');

          // 2. Get active loans total count per collector
          final loansRes = await _supabase
              .from('loans')
              .select('collector_id')
              .eq('status', 'ACTIVE');

          // 3. Get payments today per collector
          final now = DateTime.now();
          final startOfDay = DateTime(now.year, now.month, now.day).toIso8601String();
          final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59, 999).toIso8601String();

          final paymentsRes = await _supabase
              .from('payments')
              .select('collector_id, amount')
              .gte('payment_timestamp', startOfDay)
              .lte('payment_timestamp', endOfDay);

          // Process stats in Dart
          final List<Map<String, dynamic>> collectors = List<Map<String, dynamic>>.from(collectorsRes);
          final List<dynamic> allLoans = loansRes as List<dynamic>;
          final List<dynamic> allPayments = paymentsRes as List<dynamic>;

          for (var collector in collectors) {
            final collectorId = collector['id'];
            
            final activeLoansCount = allLoans.where((l) => l['collector_id'] == collectorId).length;
            
            final collectedToday = allPayments
                .where((p) => p['collector_id'] == collectorId)
                .fold<double>(0.0, (sum, p) => sum + (p['amount'] as num).toDouble());

            collector['active_loans'] = activeLoansCount;
            collector['collected_today'] = collectedToday;
          }
          
          result = collectors;
          break;
      }

      state = state.copyWith(data: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final reportesProvider = StateNotifierProvider<ReportesNotifier, ReportesState>((ref) {
  return ReportesNotifier();
});
