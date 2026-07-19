import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/auth_models.dart';
import '../../core/repositories/auth_repository.dart';
import 'otp_event.dart';
import 'otp_state.dart';

/// Manages OTP code input, verification, resend lifecycle, and
/// a 10‑minute expiry countdown.
///
/// The actual account creation ([AuthRepository.signUp]) is called here
/// only AFTER the OTP is successfully verified.
final class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final AuthRepository _authRepository;
  final SignUpData _signUpData;
  Timer? _expiryTimer;

  OtpBloc({
    required AuthRepository authRepository,
    required SignUpData signUpData,
  })  : _authRepository = authRepository,
        _signUpData = signUpData,
        super(const OtpInitial()) {
    on<OtpCodeChanged>(_onCodeChanged);
    on<OtpVerifySubmitted>(_onVerifySubmitted);
    on<OtpResendRequested>(_onResendRequested);
    on<OtpTimerTicked>(_onTimerTicked);
  }

  /// Exposed so the UI can read the email for display before the bloc
  /// processes any events.
  String get signUpDataEmail => _signUpData.email;

  String _code = '';

  /// Starts the expiry countdown. Call this once the screen mounts.
  void startTimer() {
    _expiryTimer?.cancel();
    _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      add(const OtpTimerTicked());
    });
    add(const OtpTimerTicked()); // immediate first tick
  }

  @override
  Future<void> close() {
    _expiryTimer?.cancel();
    return super.close();
  }

  void _onCodeChanged(OtpCodeChanged event, Emitter<OtpState> emit) {
    _code = event.code;
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
      // Immediately check expiry via the repository's stored timestamp.
      final remaining = await _authRepository.getRemainingOtpSeconds(
        _signUpData.email,
      );
      if (remaining <= 0) {
        emit(const OtpExpired());
        return;
      }

      final valid = await _authRepository.verifyOtp(
        _signUpData.email,
        _code,
      );
      if (!valid) {
        emit(const OtpFailure('Invalid code. Please try again.'));
        return;
      }

      // ── OTP verified — now create the account ───────────────────
      await _authRepository.signUp(_signUpData);
      await _authRepository.clearOtp(_signUpData.email);

      _expiryTimer?.cancel();
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
      await _authRepository.generateAndSendOtp(_signUpData.email);
      // Restart the countdown
      _expiryTimer?.cancel();
      _expiryTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        add(const OtpTimerTicked());
      });
      add(const OtpTimerTicked()); // immediate tick
      emit(const OtpInitial());
    } catch (e) {
      emit(OtpFailure(e.toString()));
    }
  }

  Future<void> _onTimerTicked(
    OtpTimerTicked event,
    Emitter<OtpState> emit,
  ) async {
    final remaining = await _authRepository.getRemainingOtpSeconds(
      _signUpData.email,
    );
    if (remaining <= 0) {
      _expiryTimer?.cancel();
      emit(const OtpExpired());
      return;
    }
    // Only emit if we're in an initial state (not loading / success / failure)
    if (state is OtpInitial) {
      emit(OtpInitial(remainingSeconds: remaining));
    }
  }
}
