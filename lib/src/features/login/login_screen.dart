import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/login/login_bloc.dart';
import '../../bloc/login/login_event.dart';
import '../../bloc/login/login_state.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/logo_widget.dart';

/// Full‑screen login form with email / password fields, client‑side
/// validation, and a loading / error lifecycle driven by [LoginBloc].
///
/// On successful login it navigates to [onSuccess] so the parent (typically
/// `main.dart`) can decide what "logged in" means for the app.
class LoginScreen extends StatefulWidget {
  /// Widget to navigate to after a successful login.
  final Widget onSuccess;

  const LoginScreen({super.key, required this.onSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LoginBloc(),
      child: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginSuccess && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => widget.onSuccess),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;
          final errorText = switch (state) {
            LoginFailure(error: final e) => e,
            _ => null,
          };

          return Scaffold(
            backgroundColor: ColorUtils.darkBackground,
            body: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Brand ───────────────────────────────────────
                      const SizedBox(height: 16),
                      const LogoWidget(),
                      const SizedBox(height: 32),

                      // ── Heading ─────────────────────────────────────
                      Text(
                        'Welcome back',
                        style: AppTypography.heading3(
                          color: ColorUtils.pureWhite,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sign in to your account',
                        style: AppTypography.bodyMedium(
                          color: ColorUtils.pureWhite.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 40),

                      // ── Email ───────────────────────────────────────
                      CustomTextField(
                        label: 'Email',
                        hint: 'you@example.com',
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        prefixIcon: const Icon(Icons.email_outlined),
                        onChanged: (value) => context
                            .read<LoginBloc>()
                            .add(LoginEmailChanged(value)),
                      ),
                      const SizedBox(height: 20),

                      // ── Password ────────────────────────────────────
                      CustomTextField(
                        label: 'Password',
                        hint: 'Enter your password',
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                        onChanged: (value) => context
                            .read<LoginBloc>()
                            .add(LoginPasswordChanged(value)),
                      ),
                      const SizedBox(height: 12),

                      // ── Error ───────────────────────────────────────
                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline,
                                  size: 18, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorText,
                                  style: AppTypography.caption(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Submit ──────────────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: isLoading ? 'Signing in…' : 'Sign In',
                          onPressed: isLoading
                              ? null
                              : () => context
                                  .read<LoginBloc>()
                                  .add(const LoginSubmitted()),
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
