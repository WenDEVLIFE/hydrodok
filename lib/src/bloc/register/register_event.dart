import '../../core/models/auth_models.dart';

/// Events that drive the registration form state machine.
sealed class RegisterEvent {
  const RegisterEvent();
}

/// Emitted when the user changes their full name.
final class RegisterNameChanged extends RegisterEvent {
  final String name;
  const RegisterNameChanged(this.name);
}

/// Emitted when the user changes their email.
final class RegisterEmailChanged extends RegisterEvent {
  final String email;
  const RegisterEmailChanged(this.email);
}

/// Emitted when the user changes their contact number.
final class RegisterContactNumberChanged extends RegisterEvent {
  final String contactNumber;
  const RegisterContactNumberChanged(this.contactNumber);
}

/// Emitted when the user changes their password.
final class RegisterPasswordChanged extends RegisterEvent {
  final String password;
  const RegisterPasswordChanged(this.password);
}

/// Emitted when the user changes the password confirmation field.
final class RegisterConfirmPasswordChanged extends RegisterEvent {
  final String confirmPassword;
  const RegisterConfirmPasswordChanged(this.confirmPassword);
}

/// Emitted when the user toggles between Farmer / Consumer.
final class RegisterRoleChanged extends RegisterEvent {
  final UserRole role;
  const RegisterRoleChanged(this.role);
}

/// Emitted when the user changes their farm name (farmers only).
final class RegisterFarmNameChanged extends RegisterEvent {
  final String farmName;
  const RegisterFarmNameChanged(this.farmName);
}

/// Emitted when the user changes their farm location.
final class RegisterFarmLocationChanged extends RegisterEvent {
  final String farmLocation;
  const RegisterFarmLocationChanged(this.farmLocation);
}

/// Emitted when the user changes their primary produce type.
final class RegisterProduceTypeChanged extends RegisterEvent {
  final String produceType;
  const RegisterProduceTypeChanged(this.produceType);
}

/// Emitted when the user taps the "Register" / "Create Account" button.
final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted();
}
