import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_sliding_toast/flutter_sliding_toast.dart';
import '../../bloc/otp/otp_bloc.dart';
import '../../bloc/otp/otp_event.dart';
import '../../bloc/otp/otp_state.dart';
import '../../core/models/auth_models.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';
import '../login/login_screen.dart';

/// Full‑screen OTP verification with a 6‑digit code input.
///
/// On [OtpSuccess] it navigates to [LoginScreen] with [onSuccess] so the
/// login screen knows where to go after the user signs in.
/// The account is created (via [AuthRepository.signUp]) only after
/// successful OTP verification (handled inside [OtpBloc]).
class OtpScreen extends StatefulWidget {
  final SignUpData signUpData;
  final Widget onSuccess;

  const OtpScreen({
    super.key,
    required this.signUpData,
    required this.onSuccess,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

/// Thin wrapper that creates [BlocProvider<OtpBloc>] and delegates to
/// [_OtpScreenBody] so the bloc is available in the body's context.
class _OtpScreenState extends State<OtpScreen> {
  @override
  Widget build(BuildContext context) {
    final authRepository = context.read<AuthRepository>();

    return BlocProvider(
      create: (_) => OtpBloc(
        authRepository: authRepository,
        signUpData: widget.signUpData,
      ),
      child: _OtpScreenBody(onSuccess: widget.onSuccess),
    );
  }
}

/// The actual OTP screen UI — runs as a child of [BlocProvider<OtpBloc>]
/// so it can safely call [OtpBloc.startTimer] via context.
class _OtpScreenBody extends StatefulWidget {
  final Widget onSuccess;
  const _OtpScreenBody({required this.onSuccess});

  @override
  State<_OtpScreenBody> createState() => _OtpScreenBodyState();
}

class _OtpScreenBodyState extends State<_OtpScreenBody> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  final _resendNotifier = ValueNotifier<int>(30);

  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    // Auto‑focus the hidden field so the keyboard appears immediately,
    // and start the OTP expiry countdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      if (mounted) context.read<OtpBloc>().startTimer();
    });
  }

  void _startResendTimer() {
    _resendNotifier.value = 30;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendNotifier.value > 0) {
        _resendNotifier.value--;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    _resendTimer?.cancel();
    _resendNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpBloc, OtpState>(
      listener: (context, state) {
        if (state is OtpSuccess && mounted) {
          InteractiveToast.slideSuccess(
            context: context,
            title: const Text(
              'Account created successfully! You can now sign in.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            toastStyle: const ToastStyle(
              backgroundColor: Color(0xFF1B5E20),
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => LoginScreen(onSuccess: widget.onSuccess),
            ),
            (_) => false, // Clear the navigation stack
          );
        }
        if (state is OtpFailure && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: ColorUtils.darkBackground,
              title: const Text('Verification Failed',
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
        final isLoading = state is OtpLoading;
        final isResending = state is OtpResending;
        final isExpired = state is OtpExpired;

        // Access email from the bloc's signUpData
        String email;
        try {
          // In tests the bloc may not be available
          email = context.read<OtpBloc>().signUpDataEmail;
        } catch (_) {
          email = '';
        }

        final remaining = state is OtpInitial ? state.remainingSeconds : 0;

        return Scaffold(
          backgroundColor: ColorUtils.darkBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Icon ─────────────────────────────────────────
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: ColorUtils.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mail_outline,
                        size: 40,
                        color: ColorUtils.primary,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Heading ──────────────────────────────────────
                    Text(
                      'Verify Email',
                      style: AppTypography.heading3(
                        color: ColorUtils.pureWhite,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the 6-digit code sent to',
                      style: AppTypography.bodyMedium(
                        color: ColorUtils.pureWhite.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: AppTypography.bodyMedium(
                        color: ColorUtils.pureWhite,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // ── Global countdown ─────────────────────────────
                    if (!isExpired)
                      Text(
                        _formatCountdown(remaining),
                        style: AppTypography.caption(
                          color: remaining < 120
                              ? Colors.orangeAccent
                              : ColorUtils.sageGreen,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    const SizedBox(height: 24),

                    // ── Expired state ────────────────────────────────
                    if (isExpired) ...[
                      Icon(
                        Icons.timer_off_outlined,
                        size: 48,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Verification code expired',
                        style: AppTypography.heading3(
                          color: Colors.orangeAccent,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Request a new code to continue.',
                        style: AppTypography.bodyMedium(
                          color: ColorUtils.pureWhite.withValues(alpha: 0.6),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: 'Resend Code',
                          onPressed: () {
                            _startResendTimer();
                            context
                                .read<OtpBloc>()
                                .add(const OtpResendRequested());
                          },
                        ),
                      ),
                    ] else ...[
                      // ── OTP input ──────────────────────────────────
                      _OtpInput(
                        controller: _codeController,
                        focusNode: _focusNode,
                        onChanged: (value) => context
                            .read<OtpBloc>()
                            .add(OtpCodeChanged(value)),
                      ),
                      const SizedBox(height: 28),

                      // ── Verify button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: CustomButton(
                          label: isLoading ? 'Verifying…' : 'Verify',
                          onPressed: isLoading
                              ? null
                              : () => context
                                  .read<OtpBloc>()
                                  .add(const OtpVerifySubmitted()),
                          isLoading: isLoading,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Resend ─────────────────────────────────────
                      _ResendRow(
                        notifier: _resendNotifier,
                        isResending: isResending,
                        onResend: () {
                          _startResendTimer();
                          context
                              .read<OtpBloc>()
                              .add(const OtpResendRequested());
                        },
                      ),
                    ],
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

  String _formatCountdown(int seconds) {
    final min = seconds ~/ 60;
    final sec = seconds % 60;
    return 'Code expires in ${min}:${sec.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  6‑digit OTP input — single hidden TextField with visual digit boxes
// ─────────────────────────────────────────────────────────────────────────────

class _OtpInput extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  const _OtpInput({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => focusNode.requestFocus(),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Invisible text field that captures input
          Opacity(
            opacity: 0,
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              maxLength: 6,
              onChanged: onChanged,
              enableSuggestions: false,
              autocorrect: false,
            ),
          ),
          // Visual boxes
          _OtpBoxes(code: controller.text),
        ],
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  final String code;

  const _OtpBoxes({required this.code});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = 6.0;
        final totalSpacing = spacing * 5;
        final boxSize =
            ((constraints.maxWidth - totalSpacing) / 6).clamp(36.0, 52.0);

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (i) {
            final hasDigit = i < code.length;
            final isFocused = i == code.length;
            return Container(
              width: boxSize,
              height: boxSize + 8,
              margin: EdgeInsets.only(left: i > 0 ? spacing : 0),
              decoration: BoxDecoration(
                color: hasDigit
                    ? ColorUtils.primary.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isFocused
                      ? ColorUtils.primary
                      : hasDigit
                          ? ColorUtils.primary.withValues(alpha: 0.5)
                          : ColorUtils.pureWhite.withValues(alpha: 0.2),
                  width: isFocused ? 2 : 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  hasDigit ? code[i] : '',
                  style: AppTypography.heading3(
                    color: ColorUtils.pureWhite,
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

// ─────────────────────────────────────────────────────────────────────────────
//  Resend link with countdown
// ─────────────────────────────────────────────────────────────────────────────

class _ResendRow extends StatelessWidget {
  final ValueNotifier<int> notifier;
  final bool isResending;
  final VoidCallback onResend;

  const _ResendRow({
    required this.notifier,
    required this.isResending,
    required this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: notifier,
      builder: (context, seconds, _) {
        final canResend = seconds == 0 && !isResending;

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Didn't receive the code? ",
              style: AppTypography.bodyMedium(
                color: ColorUtils.pureWhite.withValues(alpha: 0.6),
              ),
            ),
            if (canResend)
              GestureDetector(
                onTap: onResend,
                child: Text(
                  isResending ? 'Resending…' : 'Resend',
                  style: AppTypography.bodyMedium(
                    color: ColorUtils.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Text(
                'Resend in $seconds s',
                style: AppTypography.bodyMedium(
                  color: ColorUtils.pureWhite.withValues(alpha: 0.4),
                ),
              ),
          ],
        );
      },
    );
  }
}
