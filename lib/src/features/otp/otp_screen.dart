import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/otp/otp_bloc.dart';
import '../../bloc/otp/otp_event.dart';
import '../../bloc/otp/otp_state.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';

/// Full‑screen OTP verification with a 6‑digit code input.
///
/// On success it navigates to [onSuccess] — typically the home screen.
class OtpScreen extends StatefulWidget {
  final String email;
  final Widget onSuccess;

  const OtpScreen({
    super.key,
    required this.email,
    required this.onSuccess,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();
  final _resendNotifier = ValueNotifier<int>(30);

  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
    // Auto‑focus the hidden field so the keyboard appears immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
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
    return BlocProvider(
      create: (_) => OtpBloc(),
      child: BlocConsumer<OtpBloc, OtpState>(
        listener: (context, state) {
          if (state is OtpSuccess && mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => widget.onSuccess),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is OtpLoading;
          final isResending = state is OtpResending;
          final errorText = switch (state) {
            OtpFailure(error: final e) => e,
            _ => null,
          };

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
                        widget.email,
                        style: AppTypography.bodyMedium(
                          color: ColorUtils.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 36),

                      // ── OTP input ────────────────────────────────────
                      _OtpInput(
                        controller: _codeController,
                        focusNode: _focusNode,
                        onChanged: (value) => context
                            .read<OtpBloc>()
                            .add(OtpCodeChanged(value)),
                      ),
                      const SizedBox(height: 28),

                      // ── Error ────────────────────────────────────────
                      if (errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.error_outline,
                                  size: 16, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Text(
                                errorText,
                                style: AppTypography.caption(
                                  color: Colors.redAccent,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Verify button ────────────────────────────────
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

                      // ── Resend ───────────────────────────────────────
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
                      const SizedBox(height: 16),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        final hasDigit = i < code.length;
        final isFocused = i == code.length;
        return Container(
          width: 48,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 5),
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
