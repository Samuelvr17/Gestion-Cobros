import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/auth_provider.dart';
import '../prestamos/prestamos_provider.dart';

class PrestamosScreen extends ConsumerStatefulWidget {
  const PrestamosScreen({super.key});

  @override
  ConsumerState<PrestamosScreen> createState() => _PrestamosScreenState();
}

class _PrestamosScreenState extends ConsumerState<PrestamosScreen> {
  final _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLoans();
    });
  }

  Future<void> _loadLoans() async {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      ref.read(prestamosProvider.notifier).loadLoans(user.id);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.blue;
      case 'COMPLETED':
        return Colors.green;
      case 'DEFAULTED':
        return Colors.red;
      case 'RENEWED':
        return Colors.orange;
      case 'CANCELLED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prestamosProvider);
    final loans = state.filteredLoans;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        title: const Text('Préstamos', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B2333),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('Todos', null, state.filterStatus),
                const SizedBox(width: 8),
                _buildFilterChip('ACTIVE', 'ACTIVE', state.filterStatus),
                const SizedBox(width: 8),
                _buildFilterChip('COMPLETED', 'COMPLETED', state.filterStatus),
                const SizedBox(width: 8),
                _buildFilterChip('DEFAULTED', 'DEFAULTED', state.filterStatus),
              ],
            ),
          ),
          
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
            
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadLoans,
              child: state.isLoading && loans.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : loans.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            Center(
                              child: Text(
                                'Sin préstamos',
                                style: TextStyle(color: Colors.white70, fontSize: 16),
                              ),
                            )
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: loans.length,
                          itemBuilder: (context, index) {
                            final loan = loans[index];
                            final status = loan['status'] as String? ?? '';
                            final clientName = loan['client_name'] as String? ?? 'Desconocido';
                            final loanNumber = loan['loan_number']?.toString() ?? 'N/A';
                            final principalAmount = double.tryParse(loan['principal_amount']?.toString() ?? '0') ?? 0.0;
                            final totalAmount = double.tryParse(loan['total_amount']?.toString() ?? '0') ?? 0.0;
                            final paidAmount = double.tryParse(loan['paid_amount']?.toString() ?? '0') ?? 0.0;
                            final overdueDays = loan['overdue_days'] as int? ?? 0;
                            final moraAmount = double.tryParse(loan['mora_amount']?.toString() ?? '0') ?? 0.0;
                            
                            final progress = totalAmount > 0 ? (paidAmount / totalAmount).clamp(0.0, 1.0) : 0.0;

                            return Card(
                              color: const Color(0xFF1B2333),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            clientName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(status).withAlpha(51),
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: _getStatusColor(status)),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: _getStatusColor(status),
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Préstamo: $loanNumber',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Principal',
                                              style: TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                            Text(
                                              _currencyFormat.format(principalAmount),
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Total a Pagar',
                                              style: TextStyle(color: Colors.grey, fontSize: 12),
                                            ),
                                            Text(
                                              _currencyFormat.format(totalAmount),
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress,
                                        backgroundColor: Colors.grey[800],
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          progress >= 1.0 ? Colors.green : Colors.blue,
                                        ),
                                        minHeight: 6,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pagado: ${_currencyFormat.format(paidAmount)} (${(progress * 100).toStringAsFixed(1)}%)',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                    if (overdueDays > 0 || moraAmount > 0) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          if (overdueDays > 0)
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withAlpha(51),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                '$overdueDays días mora',
                                                style: const TextStyle(color: Colors.red, fontSize: 12),
                                              ),
                                            ),
                                          if (overdueDays > 0 && moraAmount > 0) const SizedBox(width: 8),
                                          if (moraAmount > 0)
                                            Text(
                                              'Mora: ${_currencyFormat.format(moraAmount)}',
                                              style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value, String? currentValue) {
    final isSelected = currentValue == value || (currentValue == null && value == null);
    
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: isSelected ? Colors.blue : const Color(0xFF1B2333),
      side: BorderSide(color: isSelected ? Colors.blue : Colors.grey[800]!),
      onPressed: () {
        ref.read(prestamosProvider.notifier).setFilter(value);
      },
    );
  }
}
