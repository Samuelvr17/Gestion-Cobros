import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/auth_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Bienvenido, ${user?.fullName ?? "Usuario"}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          Text(
            'Rol: ${user?.roleName ?? "N/A"}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          const Text(
            'Dashboard (Admin/Auxiliar)',
            style: TextStyle(color: Colors.white, fontSize: 24),
          ),
        ],
      ),
    );
  }
}
