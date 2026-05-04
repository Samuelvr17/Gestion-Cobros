import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';
import '../clientes/clientes_provider.dart';
import '../clientes/cliente_detail_screen.dart';

class ClientesScreen extends ConsumerStatefulWidget {
  const ClientesScreen({super.key});

  @override
  ConsumerState<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends ConsumerState<ClientesScreen> {
  bool _isCreating = false;
  String _searchQuery = '';

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
      await ref.read(clientesProvider.notifier).loadClients(user.id);
    }
  }

  Color _getTrafficLightColor(String? colorStr) {
    if (colorStr == 'GREEN' || colorStr == 'green') return Colors.green;
    if (colorStr == 'YELLOW' || colorStr == 'yellow') return Colors.yellow;
    if (colorStr == 'RED' || colorStr == 'red') return Colors.red;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return _buildCreateForm();
    }
    return _buildListMode();
  }

  Widget _buildListMode() {
    final state = ref.watch(clientesProvider);
    
    final filteredClients = state.clients.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final cedula = (c['cedula'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || cedula.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        title: const Text('Clientes', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B2333),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o cédula...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1B2333),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (state.errorMessage != null && !state.isLoading)
            Padding(
               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
               child: Text(state.errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: state.isLoading && state.clients.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredClients.length,
                      itemBuilder: (context, index) {
                        final client = filteredClients[index];
                        final isPunished = client['is_punished'] == true;

                        return Card(
                          color: const Color(0xFF1B2333),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ClienteDetailScreen(
                                    client: Map<String, dynamic>.from(client as Map),
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getTrafficLightColor(client['traffic_light']),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          client['name'] ?? '',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Cédula: ${client['cedula'] ?? ''}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Tel: ${client['phone'] ?? ''}',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isPunished)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.red),
                                      ),
                                      child: const Text(
                                        'Castigado',
                                        style: TextStyle(color: Colors.red, fontSize: 12),
                                      ),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isCreating = true;
          });
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCreateForm() {
    return _CreateClientForm(
      onBack: () {
        setState(() {
          _isCreating = false;
        });
      },
    );
  }
}

class _CreateClientForm extends ConsumerStatefulWidget {
  final VoidCallback onBack;

  const _CreateClientForm({required this.onBack});

  @override
  ConsumerState<_CreateClientForm> createState() => _CreateClientFormState();
}

class _CreateClientFormState extends ConsumerState<_CreateClientForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _cedulaController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authNotifierProvider).user;
    if (user == null) return;

    await ref.read(clientesProvider.notifier).createClient(
      collectorId: user.id,
      name: _nameController.text.trim(),
      cedula: _cedulaController.text.trim(),
      phone: _phoneController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      notes: _notesController.text.trim(),
    );

    if (!mounted) return;
    
    final state = ref.read(clientesProvider);
    if (state.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cliente creado')),
      );
      widget.onBack();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.errorMessage!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(clientesProvider).isLoading;

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        title: const Text('Nuevo Cliente', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1B2333),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField('Nombre*', _nameController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Cédula*', _cedulaController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Teléfono*', _phoneController, required: true, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField('Dirección*', _addressController, required: true),
              const SizedBox(height: 16),
              _buildTextField('Email', _emailController, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField('Notas', _notesController, maxLines: 3),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Guardar Cliente', style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label, 
    TextEditingController controller, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1B2333),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Este campo es requerido';
              }
              return null;
            }
          : null,
    );
  }
}
