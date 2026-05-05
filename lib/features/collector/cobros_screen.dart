import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../cobros/cobros_provider.dart';
import '../caja/caja_provider.dart';

class CobrosScreen extends ConsumerStatefulWidget {
  const CobrosScreen({super.key});

  @override
  ConsumerState<CobrosScreen> createState() => _CobrosScreenState();
}

class _CobrosScreenState extends ConsumerState<CobrosScreen> {
  final _searchController = TextEditingController();
  final _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        ref.read(cobrosProvider.notifier).loadLoans(user.id);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  void _registrarPago(Map<String, dynamic> loan) async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0.0;

    if (amount <= 0) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final cajaState = ref.read(cajaProvider);
    final shiftId = cajaState.shift?['id']?.toString();

    // Format if string, parse. The db schema likely uses bigserial for shiftId.
    // If shiftId is null, we pass null as specified.
    await ref.read(cobrosProvider.notifier).registrarPago(
          loan['id'].toString(),
          user.id,
          amount,
          shiftId,
        );

    final updatedCobrosState = ref.read(cobrosProvider);
    if (updatedCobrosState.errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${updatedCobrosState.errorMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (updatedCobrosState.success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pago registrado'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Reload Caja to update totals
      ref.read(cajaProvider.notifier).loadCaja(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cobrosProvider);

    if (state.isLoading && state.loans.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.selectedLoan != null) {
      return _buildPaymentForm(state.selectedLoan!);
    }

    return _buildLoanList(state.loans);
  }

  Widget _buildLoanList(List<dynamic> loans) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );

    final filteredLoans = loans.where((loan) {
      final clientName = (loan['client_name'] as String?)?.toLowerCase() ?? '';
      final loanNumber = (loan['loan_number'] as String?)?.toLowerCase() ?? '';
      return clientName.contains(_searchQuery) || loanNumber.contains(_searchQuery);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o número...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              filled: true,
              fillColor: const Color(0xFF1E2738),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                await ref.read(cobrosProvider.notifier).loadLoans(user.id);
              }
            },
            child: filteredLoans.isEmpty
                ? const Center(
                    child: Text(
                      'No tienes préstamos activos asignados',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredLoans.length,
                    itemBuilder: (context, index) {
                      final loan = filteredLoans[index];
                      final remainingAmount = loan['remaining_amount'] as num? ?? 0;
                      final overdueDays = loan['overdue_days'] as int? ?? 0;
                      final moraAmount = loan['mora_amount'] as num? ?? 0;

                      Color badgeColor;
                      String badgeText;
                      if (overdueDays == 0) {
                        badgeColor = Colors.green;
                        badgeText = 'Al día';
                      } else if (overdueDays <= 15) {
                        badgeColor = Colors.yellow.shade700;
                        badgeText = '$overdueDays días';
                      } else {
                        badgeColor = Colors.red;
                        badgeText = '$overdueDays días';
                      }

                      return Card(
                        color: const Color(0xFF1E2738),
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            _amountController.text = (loan['installment_amount'] as num? ?? 0).toString();
                            ref.read(cobrosProvider.notifier).selectLoan(loan);
                          },
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
                                        loan['client_name'] ?? 'Desconocido',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: badgeColor.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: badgeColor),
                                      ),
                                      child: Text(
                                        badgeText,
                                        style: TextStyle(
                                          color: badgeColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Préstamo: ${loan['loan_number'] ?? ''}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      currencyFormatter.format(remainingAmount),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (moraAmount > 0)
                                      Text(
                                        'Mora: ${currencyFormatter.format(moraAmount)}',
                                        style: const TextStyle(
                                          color: Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentForm(Map<String, dynamic> loan) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    
    final remainingAmount = loan['remaining_amount'] as num? ?? 0;
    final installmentAmount = loan['installment_amount'] as num? ?? 0;
    final overdueDays = loan['overdue_days'] as int? ?? 0;
    final isSubmitting = ref.watch(cobrosProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  ref.read(cobrosProvider.notifier).selectLoan(null);
                },
              ),
              Expanded(
                child: Text(
                  '${loan['client_name']} - ${loan['loan_number']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2738),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildInfoRow('Saldo Restante:', currencyFormatter.format(remainingAmount), Colors.white),
                const SizedBox(height: 12),
                _buildInfoRow('Cuota Sugerida:', currencyFormatter.format(installmentAmount), Colors.white),
                const SizedBox(height: 12),
                _buildInfoRow('Días de atraso:', '$overdueDays', overdueDays > 0 ? Colors.redAccent : Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 24),
              decoration: InputDecoration(
                labelText: 'Monto a pagar (COP)',
                labelStyle: const TextStyle(color: Colors.white54),
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Colors.white, fontSize: 24),
                filled: true,
                fillColor: const Color(0xFF1E2738),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Ingrese un monto';
                }
                final amount = double.tryParse(value.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
                if (amount <= 0) {
                  return 'El monto debe ser mayor a 0';
                }
                if (amount > remainingAmount) {
                  return 'El monto no puede superar el saldo';
                }
                return null;
              },
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : () => _registrarPago(loan),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB), // Tailwind blue-600
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Registrar Pago',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.grey, fontSize: 16),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
}

