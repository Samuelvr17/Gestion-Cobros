import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/supabase_constants.dart';
import 'router/app_router.dart';
import 'features/auth/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");

  final url = SupabaseConstants.url;
  final anonKey = SupabaseConstants.anonKey;

  if (url.isEmpty || anonKey.isEmpty) {
    throw Exception('SUPABASE_URL o SUPABASE_ANON_KEY no configurados en .env');
  }

  // Initialize Supabase
  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  final container = ProviderContainer();
  // Check session on startup
  await container.read(authNotifierProvider.notifier).checkSession();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Gestión Cobros',
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0C1220),
      ),
      routerConfig: router,
    );
  }
}
