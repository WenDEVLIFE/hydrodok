import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'otp_event.dart';
import 'otp_state.dart';

/// Manages OTP code input, verification, and resend lifecycle.
///
/// Currently simulates the verification call so the UI can be developed in
/// isolation. When Supabase auth is ready, inject an authentication
/// use‑case / repository and replace the `Future.delayed`.
final class OtpBloc extends Bloc<OtpEvent, OtpState> {
  OtpBloc() : super(const OtpInitial()) {
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpVerifySubmitted>(_onVerifySubmitted);
    on<OtpResendRequested>(_onResendRequested);
  }

  String _code = '';

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    _code = event.code;
    // Clear any previous failure when the user starts typing again.
    if (state is OtpFailure) {
      emit(const OtpInitial());
    }
  }

  Future<void> _onVerifySubmitted(
    OtpVerifySubmitted event,
    Emitter<OtpState> emit,
  ) async {
    if (_code.length != 6) {
      emit(const OtpFailure('Please enter the complete 6-digit code'));
      return;
    }

    emit(const OtpLoading());

    try {
      // TODO: Replace with Supabase OTP verification
      //   await _authRepository.verifyOtp(code: _code);
      await Future<void>.delayed(const Duration(seconds: 1));

      emit(const OtpSuccess());
    } catch (e) {
      emit(OtpFailure(e.toString()));
    }
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState> emit,
  ) async {
    emit(const OtpResending());

    try {
      // TODO: Replace with Supabase resend OTP
      //   await _authRepository.resendOtp();
      await Future<void>.delayed(const Duration(milliseconds: 800));

      emit(const OtpInitial());
    } catch (e) {
      emit(OtpFailure(e.toString()));
    }
  }
}
