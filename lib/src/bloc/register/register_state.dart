/// The two user roles supported by the app.
enum UserRole { farmer, consumer }

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

/// Registration succeeded — navigate to the appropriate screen.
final class RegisterSuccess extends RegisterState {
  const RegisterSuccess();
}

/// Registration failed — show an error message.
final class RegisterFailure extends RegisterState {
  final String error;
  const RegisterFailure(this.error);
}
