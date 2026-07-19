import '../../core/model/user_session.dart';

/// Possible states of the login form lifecycle.
sealed class LoginState {
  const LoginState();
}

/// Form is idle — no validation errors, no submission in flight.
final class LoginInitial extends LoginState {
  const LoginInitial();
}

/// Submission is in progress — show a loading indicator.
final class LoginLoading extends LoginState {
  const LoginLoading();
}

/// Authentication succeeded — navigate to the correct shell.
final class LoginSuccess extends LoginState {
  final UserSession session;
  const LoginSuccess(this.session);
}

/// Authentication failed — show an error message.
final class LoginFailure extends LoginState {
  final String error;
  const LoginFailure(this.error);
}
