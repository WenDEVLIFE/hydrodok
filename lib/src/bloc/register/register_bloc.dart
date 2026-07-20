import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/auth_models.dart';
import '../../core/repositories/auth_repository.dart';
import 'register_event.dart';
import 'register_state.dart';

/// Manages the registration form: validates all fields, handles role selection,
/// checks uniqueness, sends OTP, and emits [RegisterOtpSent] with the
/// collected [SignUpData] so the UI can navigate to the OTP screen.
///
/// The actual account creation ([AuthRepository.signUp]) happens only after
/// OTP verification (in [OtpBloc]), not here.
final class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRepository _authRepository;

  RegisterBloc({required AuthRepository authRepository})
      : _authRepository = authRepository,
        super(const RegisterInitial()) {
    on<RegisterNameChanged>(_onNameChanged);
    on<RegisterEmailChanged>(_onEmailChanged);
    on<RegisterContactNumberChanged>(_onContactNumberChanged);
    on<RegisterPasswordChanged>(_onPasswordChanged);
    on<RegisterConfirmPasswordChanged>(_onConfirmPasswordChanged);
    on<RegisterRoleChanged>(_onRoleChanged);
    on<RegisterSubmitted>(_onSubmitted);
  }

  String _name = '';
  String _email = '';
  String _contactNumber = '';
  String _password = '';
  String _confirmPassword = '';
  UserRole _role = UserRole.farmer;

  void _onNameChanged(RegisterNameChanged event, Emitter<RegisterState> emit) {
    _name = event.name;
    if (state is RegisterFailure) emit(const RegisterInitial());
  }

  void _onEmailChanged(
      RegisterEmailChanged event, Emitter<RegisterState> emit) {
    _email = event.email;
    if (state is RegisterFailure) emit(const RegisterInitial());
  }

  void _onContactNumberChanged(
      RegisterContactNumberChanged event, Emitter<RegisterState> emit) {
    _contactNumber = event.contactNumber;
    if (state is RegisterFailure) emit(const RegisterInitial());
  }

  void _onPasswordChanged(
      RegisterPasswordChanged event, Emitter<RegisterState> emit) {
    _password = event.password;
    if (state is RegisterFailure) emit(const RegisterInitial());
  }

  void _onConfirmPasswordChanged(
      RegisterConfirmPasswordChanged event, Emitter<RegisterState> emit) {
    _confirmPassword = event.confirmPassword;
    if (state is RegisterFailure) emit(const RegisterInitial());
  }

  void _onRoleChanged(RegisterRoleChanged event, Emitter<RegisterState> emit) {
    _role = event.role;
    if (state is RegisterFailure) emit(const RegisterInitial());
  }

  Future<void> _onSubmitted(
    RegisterSubmitted event,
    Emitter<RegisterState> emit,
  ) async {
    // ── Shared field validation ─────────────────────────────────────
    final name = _name.trim();
    final email = _email.trim();
    final contactNumber = _contactNumber.trim();
    final password = _password.trim();
    final confirmPassword = _confirmPassword.trim();

    if (name.isEmpty) {
      return emit(const RegisterFailure('Please enter your full name'));
    }
    if (email.isEmpty) {
      return emit(const RegisterFailure('Please enter your email'));
    }
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return emit(const RegisterFailure('Please enter a valid email'));
    }
    if (contactNumber.isEmpty) {
      return emit(const RegisterFailure('Please enter your contact number'));
    }
    if (password.isEmpty) {
      return emit(const RegisterFailure('Please enter a password'));
    }
    if (password.length < 6) {
      return emit(
          const RegisterFailure('Password must be at least 6 characters'));
    }
    if (confirmPassword.isEmpty) {
      return emit(const RegisterFailure('Please confirm your password'));
    }
    if (password != confirmPassword) {
      return emit(const RegisterFailure('Passwords do not match'));
    }

    // ── Uniqueness checks ──────────────────────────────────────────
    emit(const RegisterLoading());

    try {
      final emailExists = await _authRepository.checkEmailExists(email);
      if (emailExists) {
        return emit(const RegisterFailure(
            'An account with this email already exists'));
      }

      final nameExists = await _authRepository.checkNameExists(name);
      if (nameExists) {
        return emit(
            const RegisterFailure('This full name is already registered'));
      }

      // ── Build sign-up data & send OTP ──────────────────────────────
      final data = SignUpData(
        name: name,
        email: email,
        contactNumber: contactNumber,
        password: password,
        role: _role,
      );

      await _authRepository.generateAndSendOtp(email);

      emit(RegisterOtpSent(data));
    } catch (e) {
      emit(RegisterFailure(e.toString()));
    }
  }
}
