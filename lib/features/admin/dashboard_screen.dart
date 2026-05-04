import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../dashboard/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadStats();
    });
  }

  Future<void> _onRefresh() async {
    await ref.read(dashboardProvider.notifier).loadStats();
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '\$ 0';
    final format = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return format.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        title: const Text('Resumen General'),
        backgroundColor: const Color(0xFF0C1220),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardProvider.notifier).loadStats();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: state.isLoading && state.stats == null
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null
                ? Center(
                    child: Text(
                      'Error: ${state.errorMessage}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      if (state.stats != null) ...[
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.5,
                          children: [
                            _buildStatCard(
                              title: 'Préstamos Activos',
                              value: '${state.stats!['total_active_loans'] ?? 0}',
                              color: Colors.blueAccent,
                            ),
                            _buildStatCard(
                              title: 'Clientes Activos',
                              value: '${state.stats!['total_clients'] ?? 0}',
                              color: Colors.green,
                            ),
                            _buildStatCard(
                              title: 'En Mora',
                              value: '${state.stats!['total_defaulted_loans'] ?? 0}',
                              color: Colors.redAccent,
                            ),
                            _buildStatCard(
                              title: 'Fondo Disponible',
                              value: _formatCurrency(state.stats!['available_fund']),
                              color: Colors.blue,
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Movimientos del Fondo',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: const Color(0xFF1B2333),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                  label: 'Total Desembolsado',
                                  value: _formatCurrency(state.stats!['total_disbursed']),
                                ),
                                const Divider(color: Colors.white24, height: 24),
                                _buildDetailRow(
                                  label: 'Total Recuperado',
                                  value: _formatCurrency(state.stats!['total_recovered']),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Cobros de Hoy',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Card(
                          color: const Color(0xFF1B2333),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildDetailRow(
                              label: 'Total Cobrado Hoy',
                              value: _formatCurrency(state.stats!['total_collected_today']),
                              valueStyle: const TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      color: const Color(0xFF1B2333),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withAlpha(128), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    TextStyle? valueStyle,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 16),
        ),
        Text(
          value,
          style: valueStyle ?? const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
