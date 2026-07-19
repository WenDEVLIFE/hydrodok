import '../../core/models/auth_models.dart';

/// Possible states of the registration form lifecycle.
sealed class RegisterState {
  const RegisterState();
}

/// Form is idle — no validation errors, no submission in flight.
final class RegisterInitial extends RegisterState {
  const RegisterInitial();
}

/// Submission is in progress — show a loading indicator.
final class RegisterLoading extends RegisterState {
  const RegisterLoading();
}

/// OTP sent — navigate to the OTP verification screen with the collected data.
final class RegisterOtpSent extends RegisterState {
  final SignUpData data;
  const RegisterOtpSent(this.data);
}

/// Registration failed — show an error message.
final class RegisterFailure extends RegisterState {
  final String error;
  const RegisterFailure(this.error);
}
