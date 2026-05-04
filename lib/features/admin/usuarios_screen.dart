import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../usuarios/usuarios_provider.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});

  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  bool _isCreatingUser = false;
  List<Map<String, dynamic>> _roles = [];
  bool _isLoadingRoles = true;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _cedulaCtrl = TextEditingController();
  String? _selectedRoleId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(usuariosProvider.notifier).loadUsers();
      _loadRoles();
    });
  }

  Future<void> _loadRoles() async {
    try {
      final response = await Supabase.instance.client
          .from('roles')
          .select('id, name')
          .order('name');
      if (mounted) {
        setState(() {
          _roles = List<Map<String, dynamic>>.from(response);
          _isLoadingRoles = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar roles: $e')),
        );
        setState(() => _isLoadingRoles = false);
      }
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _cedulaCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(Map<String, dynamic> user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B2333),
        title: const Text('Confirmar', style: TextStyle(color: Colors.white)),
        content: Text(
          user['is_active'] == true
              ? '¿Deseas desactivar a ${user['full_name']}?'
              : '¿Deseas activar a ${user['full_name']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.blueAccent)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      ref.read(usuariosProvider.notifier).toggleActive(user['id'], user['is_active'] == true);
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, selecciona un rol')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await ref.read(usuariosProvider.notifier).createUser(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        fullName: _fullNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        cedula: _cedulaCtrl.text.trim(),
        roleId: _selectedRoleId!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Usuario creado')),
        );
        setState(() {
          _isCreatingUser = false;
        });
        _formKey.currentState?.reset();
        _emailCtrl.clear();
        _passwordCtrl.clear();
        _fullNameCtrl.clear();
        _phoneCtrl.clear();
        _cedulaCtrl.clear();
        _selectedRoleId = null;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B2333),
        title: Text(_isCreatingUser ? 'Crear Usuario' : 'Usuarios', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        leading: _isCreatingUser
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _isCreatingUser = false),
              )
            : null,
      ),
      body: _isCreatingUser ? _buildCreateForm() : _buildUserList(),
      floatingActionButton: !_isCreatingUser
          ? FloatingActionButton(
              backgroundColor: Colors.blueAccent,
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => setState(() => _isCreatingUser = true),
            )
          : null,
    );
  }

  Widget _buildUserList() {
    final state = ref.watch(usuariosProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(usuariosProvider.notifier).loadUsers(),
      child: state.isLoading && state.users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && state.users.isEmpty
              ? ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
                        child: Text(
                          state.errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.users.length,
                  itemBuilder: (context, index) {
                    final user = state.users[index];
                    final roleName = user['roles']?['name'] ?? 'Sin rol';
                    final isActive = user['is_active'] == true;

                    return Card(
                      color: const Color(0xFF1B2333),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        onLongPress: () => _toggleUserStatus(user),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      user['full_name'] ?? 'Usuario',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isActive ? Icons.toggle_on : Icons.toggle_off,
                                      color: isActive ? Colors.green : Colors.grey,
                                      size: 32,
                                    ),
                                    onPressed: () => _toggleUserStatus(user),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueAccent.withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      roleName.toString().toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.blueAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? Colors.green.withAlpha(51)
                                          : Colors.red.withAlpha(51),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isActive ? 'ACTIVO' : 'INACTIVO',
                                      style: TextStyle(
                                        color: isActive ? Colors.green : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const Icon(Icons.phone, color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    user['phone'] ?? 'N/A',
                                    style: const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.credit_card, color: Colors.white70, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    user['cedula'] ?? 'N/A',
                                    style: const TextStyle(color: Colors.white70),
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
    );
  }

  Widget _buildCreateForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildTextField(
              controller: _emailCtrl,
              label: 'Correo electrónico',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _passwordCtrl,
              label: 'Contraseña',
              icon: Icons.lock,
              obscureText: true,
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : (v.length < 8 ? 'Mínimo 8 caracteres' : null),
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _fullNameCtrl,
              label: 'Nombre completo',
              icon: Icons.person,
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _phoneCtrl,
              label: 'Teléfono',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _cedulaCtrl,
              label: 'Cédula',
              icon: Icons.credit_card,
              keyboardType: TextInputType.number,
              validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 16),
            _isLoadingRoles
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<String>(
                    initialValue: _selectedRoleId,
                    decoration: InputDecoration(
                      labelText: 'Rol',
                      prefixIcon: const Icon(Icons.badge, color: Colors.white70),
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: const Color(0xFF1B2333),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: const Color(0xFF1B2333),
                    style: const TextStyle(color: Colors.white),
                    items: _roles.map((role) {
                      return DropdownMenuItem<String>(
                        value: role['id'].toString(),
                        child: Text(role['name'].toString()),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setState(() => _selectedRoleId = val);
                    },
                    validator: (v) => v == null ? 'Por favor, selecciona un rol' : null,
                  ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Crear Usuario',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: const Color(0xFF1B2333),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: validator,
    );
  }
}
