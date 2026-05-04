import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_provider.dart';

class ClienteDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> client;

  const ClienteDetailScreen({super.key, required this.client});

  @override
  ConsumerState<ClienteDetailScreen> createState() =>
      _ClienteDetailScreenState();
}

class _ClienteDetailScreenState extends ConsumerState<ClienteDetailScreen> {
  final _currencyFormat =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  bool _loadingLoan = true;
  Map<String, dynamic>? _activeLoan;
  String? _loanError;

  @override
  void initState() {
    super.initState();
    _loadActiveLoan();
  }

  Future<void> _loadActiveLoan() async {
    setState(() {
      _loadingLoan = true;
      _loanError = null;
    });
    try {
      final response = await Supabase.instance.client
          .from('loans')
          .select(
              'id, loan_number, remaining_amount, overdue_days, installment_amount, status')
          .eq('client_id', widget.client['id'] as String)
          .eq('status', 'ACTIVE')
          .limit(1);

      final list = response as List<dynamic>;
      setState(() {
        _activeLoan =
            list.isNotEmpty ? list.first as Map<String, dynamic> : null;
        _loadingLoan = false;
      });
    } catch (e) {
      setState(() {
        _loanError = e.toString();
        _loadingLoan = false;
      });
    }
  }

  Color _getTrafficLightColor(String? colorStr) {
    switch ((colorStr ?? '').toUpperCase()) {
      case 'GREEN':
        return Colors.green;
      case 'YELLOW':
        return Colors.yellow;
      case 'RED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _openCreateLoanSheet() {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreateLoanSheet(
        clientId: widget.client['id'] as String,
        collectorId: user.id,
        onSuccess: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Préstamo creado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadActiveLoan();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final client = widget.client;
    final isPunished = client['is_punished'] == true;
    final trafficLight = client['traffic_light'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        title: Text(
          client['name'] ?? 'Detalle Cliente',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1B2333),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: _loadActiveLoan,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Client Info Card ───────────────────────────────────────
            Card(
              color: const Color(0xFF1B2333),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getTrafficLightColor(trafficLight),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            client['name'] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isPunished)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red),
                            ),
                            child: const Text(
                              'Castigado',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _infoRow(Icons.badge_outlined, 'Cédula',
                        client['cedula'] ?? '—'),
                    const SizedBox(height: 10),
                    _infoRow(Icons.phone_outlined, 'Teléfono',
                        client['phone'] ?? '—'),
                    const SizedBox(height: 10),
                    _infoRow(Icons.location_on_outlined, 'Dirección',
                        client['address'] ?? '—'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Active Loan / Create Loan ─────────────────────────────
            if (_loadingLoan)
              const Center(
                  child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ))
            else if (_loanError != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(_loanError!,
                    style: const TextStyle(color: Colors.red)),
              )
            else if (_activeLoan != null)
              _buildActiveLoanCard(_activeLoan!)
            else
              _buildNoLoanSection(),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(color: Colors.grey)),
        Expanded(
            child: Text(value,
                style: const TextStyle(color: Colors.white70),
                overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildActiveLoanCard(Map<String, dynamic> loan) {
    final loanNumber = loan['loan_number']?.toString() ?? '—';
    final remaining =
        double.tryParse(loan['remaining_amount']?.toString() ?? '0') ?? 0.0;
    final installment =
        double.tryParse(loan['installment_amount']?.toString() ?? '0') ?? 0.0;
    final overdueDays = loan['overdue_days'] as int? ?? 0;

    return Card(
      color: const Color(0xFF1B2333),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Préstamo Activo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: const Text(
                    'ACTIVO',
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '# $loanNumber',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const Divider(color: Colors.white12, height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statColumn('Saldo Pendiente',
                    _currencyFormat.format(remaining), Colors.white),
                _statColumn(
                    'Cuota', _currencyFormat.format(installment), Colors.white),
              ],
            ),
            if (overdueDays > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '$overdueDays días en mora',
                      style: const TextStyle(
                          color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statColumn(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ],
    );
  }

  Widget _buildNoLoanSection() {
    return Column(
      children: [
        Card(
          color: const Color(0xFF1B2333),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.credit_card_off_outlined,
                    color: Colors.grey, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Sin préstamo activo',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Este cliente no tiene préstamos activos.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openCreateLoanSheet,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      'Crear Préstamo',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Create Loan Bottom Sheet ─────────────────────────────────────────────────

class _CreateLoanSheet extends StatefulWidget {
  final String clientId;
  final String collectorId;
  final VoidCallback onSuccess;

  const _CreateLoanSheet({
    required this.clientId,
    required this.collectorId,
    required this.onSuccess,
  });

  @override
  State<_CreateLoanSheet> createState() => _CreateLoanSheetState();
}

class _CreateLoanSheetState extends State<_CreateLoanSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _installmentsController = TextEditingController(text: '24');

  String _frequency = 'DAILY';
  bool _isSubmitting = false;

  final _currencyFormat =
      NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  double get _amount =>
      double.tryParse(_amountController.text.replaceAll(',', '').trim()) ?? 0;
  int get _installments =>
      int.tryParse(_installmentsController.text.trim()) ?? 0;
  double get _total => _amount * 1.20;
  double get _cuota => _installments > 0 ? _total / _installments : 0;

  @override
  void dispose() {
    _amountController.dispose();
    _installmentsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await Supabase.instance.client.rpc('crear_prestamo', params: {
        'p_client_id': widget.clientId,
        'p_collector_id': widget.collectorId,
        'p_principal_amount': _amount,
        'p_total_installments': _installments,
        'p_payment_frequency': _frequency,
      });

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDeco(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF0C1220),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.blue),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1B2333),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white30,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      'Crear Préstamo',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Monto
                        TextFormField(
                          controller: _amountController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('Monto a prestar *'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = double.tryParse(
                                (v ?? '').replaceAll(',', '').trim());
                            if (val == null || val <= 0) {
                              return 'Ingrese un monto válido mayor a 0';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Número de cuotas
                        TextFormField(
                          controller: _installmentsController,
                          style: const TextStyle(color: Colors.white),
                          keyboardType: TextInputType.number,
                          decoration: _inputDeco('Número de cuotas *'),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final val = int.tryParse((v ?? '').trim());
                            if (val == null || val <= 0) {
                              return 'Ingrese un número de cuotas válido';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Frecuencia de pago
                        DropdownButtonFormField<String>(
                          initialValue: _frequency,
                          dropdownColor: const Color(0xFF1B2333),
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDeco('Frecuencia de pago'),
                          items: const [
                            DropdownMenuItem(
                                value: 'DAILY',
                                child: Text('Diario',
                                    style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(
                                value: 'WEEKLY',
                                child: Text('Semanal',
                                    style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(
                                value: 'MONTHLY',
                                child: Text('Mensual',
                                    style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _frequency = v);
                          },
                        ),
                        const SizedBox(height: 20),

                        // Live calculation info
                        if (_amount > 0 && _installments > 0)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0C1220),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                            ),
                            child: Column(
                              children: [
                                _calcRow('Total a pagar (20% interés)',
                                    _currencyFormat.format(_total),
                                    Colors.white),
                                const SizedBox(height: 8),
                                _calcRow(
                                    'Valor de cada cuota',
                                    _currencyFormat.format(_cuota),
                                    Colors.blue),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Submit
                        ElevatedButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2))
                              : const Text(
                                  'Crear Préstamo',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 16),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _calcRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 14)),
      ],
    );
  }
}
