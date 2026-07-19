import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/register/register_bloc.dart';
import '../../bloc/register/register_event.dart';
import '../../bloc/register/register_state.dart';
import '../../core/models/auth_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';
import '../../widget/logo_widget.dart';
import '../otp/otp_screen.dart';

/// Full‑screen registration form with shared fields, role toggle, and
/// conditional farmer‑specific fields (farm name, location, produce type).
///
/// On [RegisterOtpSent] it navigates to [OtpScreen] for email verification,
/// then finally to [LoginScreen].
class RegisterScreen extends StatelessWidget {
  /// Widget to navigate to after the final login (passed through OTP → Login).
  final Widget onSuccess;

  const RegisterScreen({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return BlocProvider(
      create: (_) => RegisterBloc(authRepository: authRepository),
      child: _RegisterForm(onSuccess: onSuccess),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  final Widget onSuccess;
  const _RegisterForm({required this.onSuccess});

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _farmNameController = TextEditingController();
  final _farmLocationController = TextEditingController();
  final _produceTypeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  UserRole _selectedRole = UserRole.farmer;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _produceTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RegisterBloc, RegisterState>(
      listener: (context, state) {
        if (state is RegisterOtpSent && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OtpScreen(
                signUpData: state.data,
                onSuccess: widget.onSuccess,
              ),
            ),
          );
        }
        if (state is RegisterFailure && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: ColorUtils.darkBackground,
              title: const Text('Registration Failed',
                  style: TextStyle(color: Colors.white)),
              content: Text(state.error,
                  style: const TextStyle(color: Colors.white70)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text('OK',
                      style: TextStyle(color: ColorUtils.primary)),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is RegisterLoading;

        return Scaffold(
          backgroundColor: ColorUtils.darkBackground,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const LogoWidget(),
                    const SizedBox(height: 24),

                    // ── Heading ─────────────────────────────────────
                    Text(
                      'Create Account',
                      style: AppTypography.heading3(
                        color: ColorUtils.pureWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join as a Farmer or Consumer',
                      style: AppTypography.bodyMedium(
                        color: ColorUtils.pureWhite.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Role selector ───────────────────────────────
                    _RoleSelector(
                      initial: _selectedRole,
                      onChanged: (role) {
                        setState(() => _selectedRole = role);
                        context
                            .read<RegisterBloc>()
                            .add(RegisterRoleChanged(role));
                      },
                    ),
                    const SizedBox(height: 28),

                    // ═══════════════════════════════════════════════
                    //  SHARED FIELDS
                    // ═══════════════════════════════════════════════

                    CustomTextField(
                      label: 'Full Name',
                      hint: 'Juan Dela Cruz',
                      controller: _nameController,
                      prefixIcon: const Icon(Icons.person_outline),
                      onChanged: (value) => context
                          .read<RegisterBloc>()
                          .add(RegisterNameChanged(value)),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Email',
                      hint: 'you@example.com',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      onChanged: (value) => context
                          .read<RegisterBloc>()
                          .add(RegisterEmailChanged(value)),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Contact Number',
                      hint: '0917xxxxxxx',
                      controller: _contactController,
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      onChanged: (value) => context
                          .read<RegisterBloc>()
                          .add(RegisterContactNumberChanged(value)),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Password',
                      hint: 'At least 6 characters',
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
                          .read<RegisterBloc>()
                          .add(RegisterPasswordChanged(value)),
                    ),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: 'Confirm Password',
                      hint: 'Re-enter your password',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                            () => _obscureConfirm = !_obscureConfirm),
                      ),
                      onChanged: (value) => context
                          .read<RegisterBloc>()
                          .add(RegisterConfirmPasswordChanged(value)),
                    ),

                    // ═══════════════════════════════════════════════
                    //  FARMER‑SPECIFIC FIELDS
                    // ═══════════════════════════════════════════════
                    if (_selectedRole == UserRole.farmer) ...[
                      const SizedBox(height: 24),
                      _SectionHeader('Farm Details'),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Farm / Business Name',
                        hint: 'e.g. Green Valley Farm',
                        controller: _farmNameController,
                        prefixIcon: const Icon(Icons.store_outlined),
                        onChanged: (value) => context
                            .read<RegisterBloc>()
                            .add(RegisterFarmNameChanged(value)),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Farm Location',
                        hint: 'e.g. Brgy. San Jose, General Trias',
                        controller: _farmLocationController,
                        prefixIcon: const Icon(Icons.location_on_outlined),
                        onChanged: (value) => context
                            .read<RegisterBloc>()
                            .add(RegisterFarmLocationChanged(value)),
                      ),
                      const SizedBox(height: 16),

                      CustomTextField(
                        label: 'Primary Produce Type',
                        hint: 'e.g. Lettuce, Tomatoes, Pechay',
                        controller: _produceTypeController,
                        prefixIcon: const Icon(Icons.eco_outlined),
                        onChanged: (value) => context
                            .read<RegisterBloc>()
                            .add(RegisterProduceTypeChanged(value)),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Submit ──────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        label: isLoading ? 'Creating account…' : 'Sign Up',
                        onPressed: isLoading
                            ? null
                            : () => context
                                .read<RegisterBloc>()
                                .add(const RegisterSubmitted()),
                        isLoading: isLoading,
                      ),
                    ),
                    const SizedBox(height: 24),

                    _SignInLink(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Section header for grouped fields
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
            color: ColorUtils.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.subtitle1(
            color: ColorUtils.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Role toggle
// ─────────────────────────────────────────────────────────────────────────────

class _RoleSelector extends StatefulWidget {
  final UserRole initial;
  final ValueChanged<UserRole> onChanged;
  const _RoleSelector({required this.initial, required this.onChanged});

  @override
  State<_RoleSelector> createState() => _RoleSelectorState();
}

class _RoleSelectorState extends State<_RoleSelector> {
  late UserRole _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            'I am a…',
            style: AppTypography.subtitle2(color: ColorUtils.pureWhite),
          ),
        ),
        Row(
          children: [
            Expanded(child: _chip(UserRole.farmer)),
            const SizedBox(width: 12),
            Expanded(child: _chip(UserRole.consumer)),
          ],
        ),
      ],
    );
  }

  Widget _chip(UserRole role) {
    final isSelected = _selected == role;
    final label = role == UserRole.farmer ? 'Farmer' : 'Consumer';
    final icon = role == UserRole.farmer
        ? Icons.agriculture_outlined
        : Icons.shopping_bag_outlined;
    final selectedColor = role == UserRole.farmer
        ? ColorUtils.primary
        : ColorUtils.terracotta;

    return GestureDetector(
      onTap: () {
        if (_selected != role) {
          setState(() => _selected = role);
          widget.onChanged(role);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? selectedColor
                : ColorUtils.pureWhite.withValues(alpha: 0.25),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? ColorUtils.pureWhite
                  : ColorUtils.pureWhite.withValues(alpha: 0.6),
              size: 28,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTypography.subtitle2(
                color: isSelected
                    ? ColorUtils.pureWhite
                    : ColorUtils.pureWhite.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  "Already have an account? Sign in" link
// ─────────────────────────────────────────────────────────────────────────────

class _SignInLink extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTypography.bodyMedium(
            color: ColorUtils.pureWhite.withValues(alpha: 0.6),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Text(
            'Sign in',
            style: AppTypography.bodyMedium(
              color: ColorUtils.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
