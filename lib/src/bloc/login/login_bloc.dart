import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/repositories/auth_repository.dart';
import 'login_event.dart';
import 'login_state.dart';

/// Manages the login form: validates input, handles submission, and emits
/// loading / success / failure states.
final class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _authRepository;

  LoginBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const LoginInitial()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  String _email = '';
  String _password = '';

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    _email = event.email;
    // Clear any previous failure when the user starts typing again.
    if (state is LoginFailure) {
      emit(const LoginInitial());
    }
  }

  void _onPasswordChanged(LoginPasswordChanged event, Emitter<LoginState> emit) {
    _password = event.password;
    if (state is LoginFailure) {
      emit(const LoginInitial());
    }
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // ── Client‑side validation ────────────────────────────────────────
    final email = _email.trim();
    final password = _password.trim();

    if (email.isEmpty) {
      emit(const LoginFailure('Please enter your email'));
      return;
    }

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      emit(const LoginFailure('Please enter a valid email'));
      return;
    }

    if (password.isEmpty) {
      emit(const LoginFailure('Please enter your password'));
      return;
    }

    if (password.length < 6) {
      emit(const LoginFailure('Password must be at least 6 characters'));
      return;
    }

    // ── Submission ────────────────────────────────────────────────────
    emit(const LoginLoading());

    try {
      await _authRepository.signIn(email, password);
      emit(const LoginSuccess());
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }
}
