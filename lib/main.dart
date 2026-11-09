import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/auth_gate.dart';
import 'services/app_preferences.dart';

const String _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String _supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await AppPreferences.initialize();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  if (_supabaseUrl.isEmpty || _supabasePublishableKey.isEmpty) {
    runApp(const SupabaseConfigMissingApp());
    return;
  }

  await Supabase.initialize(
    url: _supabaseUrl,
    publishableKey: _supabasePublishableKey,
  );

  runApp(const MotoRideApp());
}

class MotoRideApp extends StatelessWidget {
  const MotoRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppPreferences.themeMode,
      builder: (context, themeMode, _) => MaterialApp(
      title: 'Strava Motos',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A1F),
          primary: const Color(0xFFFF5A1F),
          secondary: const Color(0xFF181818),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFF8F5),
          foregroundColor: Color(0xFF181818),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xFF181818),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: Color(0xFFF0E8E4)),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE7DDD8)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFFF5A1F), width: 1.6),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5A1F),
            foregroundColor: Colors.white,
            minimumSize: const Size(48, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF5A1F),
          brightness: Brightness.dark,
          primary: const Color(0xFFFF6A35),
          secondary: const Color(0xFFE7A184),
          surface: const Color(0xFF1D1D1D),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1716),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1D1D1D), elevation: 1, margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18), side: const BorderSide(color: Color(0xFF35302E))),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true, fillColor: const Color(0xFF242424),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF49413E))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFFF6A35), width: 1.6)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF5A1F), foregroundColor: Colors.white, minimumSize: const Size(48, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), textStyle: const TextStyle(fontWeight: FontWeight.w700)),
        ),
        useMaterial3: true,
      ),
      builder: (context, child) => LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth < 520
              ? constraints.maxWidth
              : 520.0;
          final background = Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF101010)
              : const Color(0xFFECE7E4);
          final surface = Theme.of(context).scaffoldBackgroundColor;
          return ColoredBox(
            color: background,
            child: Center(
              child: Container(
                width: width,
                height: constraints.maxHeight,
                decoration: BoxDecoration(
                  color: surface,
                  boxShadow: constraints.maxWidth > 520
                      ? const [
                          BoxShadow(
                            color: Color(0x1F181818),
                            blurRadius: 28,
                            offset: Offset(0, 8),
                          ),
                        ]
                      : null,
                ),
                child: child ?? const SizedBox.shrink(),
              ),
            ),
          );
        },
      ),
      home: const AuthGate(),
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '';
        // Flutter's Navigator also receives Android OAuth callback URLs as
        // route information (for example `/?code=...`). Let Supabase handle
        // the code exchange, while keeping the app on its auth gate route.
        if (routeName.startsWith('/?code=') ||
            routeName.startsWith('/#access_token=')) {
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const AuthGate(),
          );
        }
        return null;
      },
    ));
  }
}

class SupabaseConfigMissingApp extends StatelessWidget {
  const SupabaseConfigMissingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF111111),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.settings_rounded,
                  color: Color(0xFFFF5A1F),
                  size: 56,
                ),
                SizedBox(height: 16),
                Text(
                  'Configuração do Supabase ausente',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Inicie o aplicativo informando SUPABASE_URL e SUPABASE_PUBLISHABLE_KEY.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
