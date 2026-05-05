class RoleLogic {
  static const String admin = 'admin';
  static const String auxiliar = 'auxiliar';
  static const String cobrador = 'cobrador';

  static String homeForRole(String? role) {
    final r = role?.toLowerCase() ?? '';
    if (r == admin || r == auxiliar) return '/dashboard';
    if (r == cobrador) return '/caja';
    return '/login';
  }

  static bool canAccess(String? role, String path) {
    if (path == '/login' || path == '/change-password') return true;
    
    final r = role?.toLowerCase() ?? '';
    
    // Universal shared access
    if (path == '/perfil' || path == '/notificaciones') return true;

    // Admin specific access
    if (r == admin) {
      final allowedPaths = [
        '/dashboard',
        '/usuarios',
        '/reportes',
      ];
      return allowedPaths.contains(path);
    }
    
    // Auxiliar specific access
    if (r == auxiliar) {
      final allowedPaths = [
        '/dashboard',
        '/reportes',
      ];
      return allowedPaths.contains(path);
    }
    
    // Collector specific access
    if (r == cobrador) {
      final allowedPaths = [
        '/caja',
        '/cobros',
        '/clientes',
        '/prestamos',
      ];
      return allowedPaths.contains(path);
    }
    
    return false;
  }
}
