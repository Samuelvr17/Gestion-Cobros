import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gestion_cobros/features/auth/auth_provider.dart';

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    final user = ref.read(authNotifierProvider).user;
    final role = user?.roleName?.toUpperCase() ?? '';

    if (role == 'COBRADOR') {
      if (location == '/caja') return 0;
      if (location == '/cobros') return 1;
      if (location == '/clientes') return 2;
      if (location == '/prestamos') return 3;
    } else if (role == 'ADMIN') {
      if (location == '/dashboard') return 0;
      if (location == '/usuarios') return 1;
      if (location == '/reportes') return 2;
    } else if (role == 'AUXILIAR') {
      if (location == '/dashboard') return 0;
      if (location == '/reportes') return 1;
    }
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    final user = ref.read(authNotifierProvider).user;
    final role = user?.roleName?.toUpperCase() ?? '';

    if (role == 'COBRADOR') {
      switch (index) {
        case 0:
          context.go('/caja');
          break;
        case 1:
          context.go('/cobros');
          break;
        case 2:
          context.go('/clientes');
          break;
        case 3:
          context.go('/prestamos');
          break;
      }
    } else if (role == 'ADMIN') {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/usuarios');
          break;
        case 2:
          context.go('/reportes');
          break;
      }
    } else if (role == 'AUXILIAR') {
      switch (index) {
        case 0:
          context.go('/dashboard');
          break;
        case 1:
          context.go('/reportes');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final user = authState.user;
    final role = user?.roleName?.toUpperCase() ?? '';

    List<BottomNavigationBarItem> navItems = [];
    if (role == 'COBRADOR') {
      navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Caja'),
        const BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Cobros'),
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Clientes'),
        const BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Préstamos'),
      ];
    } else if (role == 'ADMIN') {
      navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Usuarios'),
        const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
      ];
    } else if (role == 'AUXILIAR') {
      navItems = [
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        const BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Reportes'),
      ];
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0C1220),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0C1220),
        elevation: 0,
        title: const Text(
          'Gestión Cobros',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (user != null) ...[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  user.fullName,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.roleName ?? '',
                    style: const TextStyle(color: Color(0xFF2563EB), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => ref.read(authNotifierProvider.notifier).logout(),
            ),
          ],
        ],
      ),
      body: widget.child,
      bottomNavigationBar: navItems.isNotEmpty
          ? BottomNavigationBar(
              backgroundColor: const Color(0xFF0C1220),
              type: BottomNavigationBarType.fixed,
              currentIndex: _calculateSelectedIndex(context),
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: Colors.grey,
              onTap: (index) => _onItemTapped(index, context),
              items: navItems,
            )
          : null,
    );
  }
}
