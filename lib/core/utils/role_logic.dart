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
    
    // Admin and Auxiliar have access to everything for now
    if (r == admin || r == auxiliar) return true;
    
    // Collector specific access
    if (r == cobrador) {
      final allowedPaths = [
        '/caja',
        '/cobros',
        '/clientes',
        '/prestamos',
        '/perfil',
      ];
      return allowedPaths.contains(path);
    }
    
    return false;
  }
}
