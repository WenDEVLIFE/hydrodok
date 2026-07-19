/// Events that drive the login form state machine.
sealed class LoginEvent {
  const LoginEvent();
}

/// Emitted when the user types in the email field.
final class LoginEmailChanged extends LoginEvent {
  final String email;
  const LoginEmailChanged(this.email);
}

/// Emitted when the user types in the password field.
final class LoginPasswordChanged extends LoginEvent {
  final String password;
  const LoginPasswordChanged(this.password);
}

/// Emitted when the user taps the submit / sign-in button.
final class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}
