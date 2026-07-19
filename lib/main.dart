import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/repositories/auth_repository.dart';
import 'src/core/service/email_service.dart';
import 'src/core/utils/color_utils.dart';
import 'src/core/utils/typography.dart';
import 'src/features/login/login_screen.dart';
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
    RepositoryProvider<AuthRepository>.value(
      value: authRepository,
      child: const HydrodokApp(),
    ),
  );
}

Future<bool> initializeSupabase() async {
  try {
    await dotenv.load();

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      publishableKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );

    final supabase = Supabase.instance.client;

    // Simple connectivity test
    await supabase.from('profiles').select('id').limit(1);

    print('✅ Connected to Supabase');
    return true;
  } catch (e) {
    print('❌ Failed to connect to Supabase');
    print(e);
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
      home: const SplashScreen(nextScreen: _AfterSplash()),
    );
  }
}

/// What the user sees after the splash animation finishes.
/// Routes to login; on success, goes to the home placeholder.
class _AfterSplash extends StatelessWidget {
  const _AfterSplash();

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(onSuccess: _HomePlaceholder());
  }
}

/// Temporary home while the app is in early development.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hydrodok'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.radar,
                size: 64,
                color: ColorUtils.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Your hydroponic farm manager',
                style: AppTypography.heading3(
                  color: ColorUtils.pureWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You are logged in!',
                style: AppTypography.bodyMedium(
                  color: ColorUtils.pureWhite.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
