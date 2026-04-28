
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/auth_provider.dart';
import '../features/auth/login_screen.dart';
import '../features/caja/caja_screen.dart';
import '../features/shared/widgets/main_layout.dart';
import '../features/shared/perfil_screen.dart';
import '../features/collector/cobros_screen.dart';
import '../features/collector/clientes_screen.dart';
import '../features/collector/prestamos_screen.dart';
import '../features/admin/usuarios_screen.dart';
import '../features/admin/fondos_screen.dart';
import '../features/admin/reportes_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/caja',
            builder: (context, state) => const CajaScreen(),
          ),
          GoRoute(
            path: '/cobros',
            builder: (context, state) => const CobrosScreen(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesScreen(),
          ),
          GoRoute(
            path: '/prestamos',
            builder: (context, state) => const PrestamosScreen(),
          ),
          GoRoute(
            path: '/usuarios',
            builder: (context, state) => const UsuariosScreen(),
          ),
          GoRoute(
            path: '/fondos',
            builder: (context, state) => const FondosScreen(),
          ),
          GoRoute(
            path: '/reportes',
            builder: (context, state) => const ReportesScreen(),
          ),
          GoRoute(
            path: '/perfil',
            builder: (context, state) => const PerfilScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn) {
        return isLoggingIn ? null : '/login';
      }

      if (isLoggingIn) {
        final role = authState.user?.roleName?.toLowerCase() ?? '';
        if (role == 'admin' || role == 'auxiliar') {
          return '/dashboard';
        } else if (role == 'cobrador') {
          return '/caja';
        }
      }

      return null;
    },
  );
});
