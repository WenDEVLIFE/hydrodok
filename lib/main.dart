import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'src/core/repositories/auth_repository.dart';
import 'src/core/service/avatar_backfill.dart';
import 'src/core/service/email_service.dart';
import 'src/core/service/profile_service.dart';
import 'src/core/utils/color_utils.dart';
import 'src/core/utils/typography.dart';
import 'src/features/login/login_screen.dart';
import 'src/features/main_shell.dart';
import 'src/features/splash_screen/splash_screen.dart';
import 'src/widget/profile_avatar.dart';

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
    return LoginScreen(
      authRepository: context.read<AuthRepository>(),
      onSuccess: const MainShell(),
    );
  }
}

/// Temporary home while the app is in early development.
class _HomePlaceholder extends StatefulWidget {
  const _HomePlaceholder();

  @override
  State<_HomePlaceholder> createState() => _HomePlaceholderState();
}

class _HomePlaceholderState extends State<_HomePlaceholder> {
  String? _avatarUrl;
  String _userName = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final result = await supabase
        .from('profiles')
        .select('avatar_url, full_name')
        .eq('id', user.id)
        .maybeSingle();

    var avatarUrl = result?['avatar_url'] as String?;
    final name = result?['full_name'] as String? ?? '';

    // If the user still has no avatar_url (e.g. pre-migration profile),
    // ensure the shared default is uploaded and assign it.
    if (avatarUrl == null || avatarUrl.isEmpty) {
      try {
        await AvatarBackfill.run(supabase);
        // Re-fetch after backfill
        final updated = await supabase
            .from('profiles')
            .select('avatar_url')
            .eq('id', user.id)
            .maybeSingle();
        avatarUrl = updated?['avatar_url'] as String?;
      } catch (_) {
        // Backfill failed — ProfileAvatar shows logo.png asset fallback
      }
    }

    if (!mounted) return;
    setState(() {
      _avatarUrl = avatarUrl;
      _userName = name;
      _loading = false;
    });
  }

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
              ProfileAvatar(
                imageUrl: _loading ? null : _avatarUrl,
                radius: 40,
              ),
              const SizedBox(height: 16),
              if (!_loading && _userName.isNotEmpty)
                Text(
                  _userName,
                  style: AppTypography.heading3(
                    color: ColorUtils.pureWhite,
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 8),
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
