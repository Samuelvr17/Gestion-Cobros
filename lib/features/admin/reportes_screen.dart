import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gestion_cobros/features/reportes/reportes_provider.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  final timeFormat = DateFormat('h:mm a');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabSelection);
    
    // Initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportesProvider.notifier).loadReporte(0);
    });
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      ref.read(reportesProvider.notifier).loadReporte(_tabController.index);
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Cobros Hoy'),
            Tab(text: 'Préstamos'),
            Tab(text: 'En Mora'),
            Tab(text: 'Cobradores'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCobrosTab(state),
          _buildPrestamosTab(state),
          _buildMoraTab(state),
          _buildCobradoresTab(state),
        ],
      ),
    );
  }

  Widget _buildLoadingOrError(ReportesState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    }
    if (state.errorMessage != null) {
      return Center(
        child: Text(
          state.errorMessage!,
          style: const TextStyle(color: Colors.red),
          textAlign: TextAlign.center,
        ),
      );
    }
    if (state.data.isEmpty) {
      return const Center(
        child: Text(
          'No hay datos disponibles',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildCobrosTab(ReportesState state) {
    if (state.isLoading || state.errorMessage != null || state.data.isEmpty) {
      return _buildLoadingOrError(state);
    }

    final totalCollected = state.data.fold<double>(0, (sum, item) => sum + (item['amount'] as num).toDouble());

    return Column(
      children: [
        _buildSummaryCard('Total Cobrado Hoy', totalCollected),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.data.length,
            itemBuilder: (context, index) {
              final item = state.data[index];
              final clientName = item['loans']?['clients']?['name'] ?? 'N/A';
              final loanNumber = item['loans']?['loan_number'] ?? 'N/A';
              final collectorName = item['collector']?['full_name'] ?? 'N/A';
              final amount = (item['amount'] as num).toDouble();
              final timestamp = DateTime.parse(item['payment_timestamp']);

              return Card(
                color: const Color(0xFF1B2333),
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Préstamo: $loanNumber | Cobrador: $collectorName',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(amount),
                        style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        timeFormat.format(timestamp.toLocal()),
                        style: const TextStyle(color: Colors.grey, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPrestamosTab(ReportesState state) {
    if (state.isLoading || state.errorMessage != null || state.data.isEmpty) {
      return _buildLoadingOrError(state);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.data.length,
      itemBuilder: (context, index) {
        final item = state.data[index];
        final clientName = item['clients']?['name'] ?? 'N/A';
        final loanNumber = item['loan_number'] ?? 'N/A';
        final collectorName = item['collector']?['full_name'] ?? 'N/A';
        final remaining = (item['remaining_amount'] as num).toDouble();
        final overdueDays = item['overdue_days'] as int;

        return Card(
          color: const Color(0xFF1B2333),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (overdueDays > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                        child: Text(
                          '$overdueDays d mora',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Préstamo: $loanNumber', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Cobrador: $collectorName', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Saldo Restante:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(currencyFormat.format(remaining), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoraTab(ReportesState state) {
    if (state.isLoading || state.errorMessage != null || state.data.isEmpty) {
      return _buildLoadingOrError(state);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.data.length,
      itemBuilder: (context, index) {
        final item = state.data[index];
        final clientName = item['clients']?['name'] ?? 'N/A';
        final phone = item['clients']?['phone'] ?? 'N/A';
        final trafficLight = item['clients']?['traffic_light'] ?? 'GREEN';
        final collectorName = item['collector']?['full_name'] ?? 'N/A';
        final overdueDays = item['overdue_days'] as int;
        final moraAmount = (item['mora_amount'] as num).toDouble();

        Color trafficColor;
        switch (trafficLight) {
          case 'RED': trafficColor = Colors.red; break;
          case 'YELLOW': trafficColor = Colors.yellow; break;
          default: trafficColor = Colors.green;
        }

        return Card(
          color: const Color(0xFF1B2333),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: trafficColor, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text(clientName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '$overdueDays DÍAS',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Tel: $phone', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                Text('Cobrador: $collectorName', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const Divider(color: Colors.white10, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Valor en Mora:', style: TextStyle(color: Colors.grey, fontSize: 13)),
                    Text(currencyFormat.format(moraAmount), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCobradoresTab(ReportesState state) {
    if (state.isLoading || state.errorMessage != null || state.data.isEmpty) {
      return _buildLoadingOrError(state);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.data.length,
      itemBuilder: (context, index) {
        final item = state.data[index];
        final name = item['full_name'] ?? 'N/A';
        final phone = item['phone'] ?? 'N/A';
        final activeLoans = item['active_loans'] as int;
        final collectedToday = (item['collected_today'] as num).toDouble();

        return Card(
          color: const Color(0xFF1B2333),
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF2563EB).withValues(alpha: 0.2),
                  child: Text(name[0].toUpperCase(), style: const TextStyle(color: Color(0xFF2563EB))),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(phone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('$activeLoans Préstamos', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormat.format(collectedToday),
                      style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, double value) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF2563EB), const Color(0xFF2563EB).withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            currencyFormat.format(value),
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
