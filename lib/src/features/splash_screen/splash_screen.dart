import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/color_utils.dart';
import '../../widget/logo_widget.dart';
import '../login/login_screen.dart';
import '../onboarding/onboarding_gate.dart';

/// A clean, modern splash screen that displays the brand logo with a subtle
/// fade + scale animation, then checks for an existing Supabase session.
///
/// If a valid session is found it routes directly via [OnboardingGate] based
/// on the user's role and onboarding state.
/// Otherwise it routes to [LoginScreen] and the role is determined at login.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  // Resolved once the session check completes.
  Widget? _destination;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeIn = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );

    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();

    // Check for an existing session in parallel with the animation.
    _checkSession();

    Timer(const Duration(milliseconds: 2200), _navigate);
  }

  Future<void> _checkSession() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final session = await authRepo.getCurrentSession();
      if (session != null && mounted) {
        setState(() {
          _destination = OnboardingGate(session: session);
        });
      }
    } catch (_) {
      // No session or network error — fall through to login.
    }
  }

  void _navigate() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _destination ?? LoginScreen(
              authRepository: context.read<AuthRepository>(),
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorUtils.primary,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Opacity(
          opacity: _fadeIn.value,
          child: Transform.scale(
            scale: _scaleIn.value,
            child: child,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(flex: 3),
              const LogoWidget(),
              const Spacer(flex: 2),
              _LoadingDots(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three bouncing dots — subtle, modern loading indicator that kicks in
/// just after the logo animation finishes.
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final delay = i * 0.15;
            final t = (_controller.value - delay).clamp(0.0, 1.0);
            final bounce = (t < 0.5)
                ? 4.0 * t * t
                : 1.0 - 4.0 * (t - 0.5) * (t - 0.5);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Transform.translate(
                offset: Offset(0, -bounce * 6),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: ColorUtils.sageGreen.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
