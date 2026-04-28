import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../auth/auth_provider.dart';
import 'caja_provider.dart';

class CajaScreen extends ConsumerStatefulWidget {
  const CajaScreen({super.key});

  @override
  ConsumerState<CajaScreen> createState() => _CajaScreenState();
}

class _CajaScreenState extends ConsumerState<CajaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final user = ref.read(authNotifierProvider).user;
    if (user != null) {
      await ref.read(cajaProvider.notifier).loadCaja(user.id);
    }
  }

  String _formatCurrency(num? value) {
    if (value == null) return '\$ 0';
    return NumberFormat("\$ #,##0").format(value);
  }



  String _formatTime(String? timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      final date = DateTime.parse(timestamp).toLocal();
      return DateFormat('h:mm a').format(date);
    } catch (e) {
      return timestamp;
    }
  }

  void _confirmCerrarCaja(String shiftId, String userId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1B2333),
          title: const Text('Confirmar Cierre', style: TextStyle(color: Colors.white)),
          content: const Text(
            '¿Estás seguro de que deseas cerrar la caja del día? Esta acción no se puede deshacer.',
            style: TextStyle(color: Colors.grey),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await ref.read(cajaProvider.notifier).cerrarCaja(userId, shiftId);
                if (!context.mounted) return;
                final error = ref.read(cajaProvider).errorMessage;
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caja cerrada con éxito')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cerrar Caja', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cajaProvider);
    final user = ref.watch(authNotifierProvider).user;

    final shift = cajaState.shift;
    final resumen = cajaState.resumen;
    final status = shift?['status'] as String? ?? 'N/A';
    final openedAt = shift?['opened_at'] as String?;
    final shiftId = shift?['id']?.toString();

    final totalCollected = resumen?['total_collected'] as num? ?? 0;
    final totalExpenses = resumen?['total_expenses'] as num? ?? 0;
    final net = resumen?['net'] as num? ?? 0;

    final payments = (resumen?['payments'] as List<dynamic>?) ?? [];
    final expenses = (resumen?['expenses'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        title: const Text('Caja del día', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B2333),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cajaState.isLoading && shift == null && resumen == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  if (cajaState.errorMessage != null && !cajaState.isLoading)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        cajaState.errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  
                  // Header Card
                  Card(
                    color: const Color(0xFF1B2333),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estado', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              Text(
                                status,
                                style: TextStyle(
                                  color: status == 'OPEN' ? Colors.green : Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Apertura', style: TextStyle(color: Colors.grey, fontSize: 16)),
                              Text(
                                _formatTime(openedAt),
                                style: const TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                          if (status == 'OPEN' && user != null && shiftId != null) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _confirmCerrarCaja(shiftId, user.id),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Cerrar Caja', style: TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Cards Row
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard('Cobrado', totalCollected, Colors.green)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryCard('Gastos', totalExpenses, Colors.red)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildSummaryCard('Neto', net, Colors.blue)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Últimos cobros
                  const Text('Últimos cobros', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (payments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text('Sin registros hoy', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...payments.map((p) => _buildPaymentItem(p)),
                  
                  const SizedBox(height: 24),
                  
                  // Gastos del día
                  const Text('Gastos del día', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (expenses.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Center(child: Text('Sin registros hoy', style: TextStyle(color: Colors.grey))),
                    )
                  else
                    ...expenses.map((e) => _buildExpenseItem(e)),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryCard(String title, num amount, Color color) {
    return Card(
      color: const Color(0xFF1B2333),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 4),
            Text(
              _formatCurrency(amount),
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentItem(dynamic payment) {
    final clientName = payment['client_name'] as String? ?? 'Desconocido';
    final loanNumber = payment['loan_number']?.toString() ?? 'N/A';
    final amount = payment['amount'] as num? ?? 0;
    final timestamp = payment['timestamp'] as String?;

    return Card(
      color: const Color(0xFF1B2333),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(clientName, style: const TextStyle(color: Colors.white)),
        subtitle: Text(
          'Préstamo #$loanNumber • ${_formatTime(timestamp)}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: Text(
          _formatCurrency(amount),
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildExpenseItem(dynamic expense) {
    final category = expense['category'] as String? ?? 'Gasto';
    final description = expense['description'] as String? ?? '';
    final amount = expense['amount'] as num? ?? 0;

    return Card(
      color: const Color(0xFF1B2333),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(category, style: const TextStyle(color: Colors.white)),
        subtitle: description.isNotEmpty
            ? Text(description, style: const TextStyle(color: Colors.grey, fontSize: 12))
            : null,
        trailing: Text(
          _formatCurrency(amount),
          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ),
    );
  }
}
