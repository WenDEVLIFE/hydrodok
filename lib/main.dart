import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/repositories/auth_repository.dart';
import 'src/core/service/email_service.dart';
import 'src/core/service/profile_service.dart';
import 'src/core/utils/color_utils.dart';
import 'src/features/splash_screen/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await initializeSupabase();

  final authRepository = SupabaseAuthRepository(
    supabase: Supabase.instance.client,
    emailService: EmailService(),
    prefs: prefs,
  );

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<ProfileService>.value(
          value: ProfileService(supabase: Supabase.instance.client),
        ),
      ],
      child: const HydrodokApp(),
    ),
  );
}

Future<bool> initializeSupabase() async {
  try {
    if (!kIsWeb) {
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        debugPrint('dotenv.load skipped: $e');
      }
    }

    final supabaseUrl = (kIsWeb ? null : dotenv.env['SUPABASE_URL']) ??
        const String.fromEnvironment(
          'SUPABASE_URL',
          defaultValue: 'https://jhmzjebwyiknvltcljck.supabase.co',
        );
    final supabaseKey = (kIsWeb ? null : dotenv.env['SUPABASE_ANON_KEY']) ??
        const String.fromEnvironment(
          'SUPABASE_ANON_KEY',
          defaultValue:
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpobXpqZWJ3eWlrbnZsdGNsamNrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODQzNzUzNTgsImV4cCI6MjA5OTk1MTM1OH0.qQBGMC6ancDlk1EOTedya6lkVCSxShILTZZUy8qBQFw',
        );

    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );

    debugPrint('✅ Connected to Supabase');
    return true;
  } catch (e) {
    debugPrint('❌ Failed to connect to Supabase: $e');
    return false;
  }
}

class HydrodokApp extends StatelessWidget {
  const HydrodokApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hydrodok',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: ColorUtils.darkBackground,
        colorScheme: ColorUtils.darkColorScheme,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
