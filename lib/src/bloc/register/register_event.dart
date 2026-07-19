import 'register_state.dart';

/// Events that drive the registration form state machine.
sealed class RegisterEvent {
  const RegisterEvent();
}

final class RegisterNameChanged extends RegisterEvent {
  final String name;
  const RegisterNameChanged(this.name);
}

final class RegisterEmailChanged extends RegisterEvent {
  final String email;
  const RegisterEmailChanged(this.email);
}

final class RegisterContactNumberChanged extends RegisterEvent {
  final String contactNumber;
  const RegisterContactNumberChanged(this.contactNumber);
}

final class RegisterPasswordChanged extends RegisterEvent {
  final String password;
  const RegisterPasswordChanged(this.password);
}

final class RegisterConfirmPasswordChanged extends RegisterEvent {
  final String confirmPassword;
  const RegisterConfirmPasswordChanged(this.confirmPassword);
}

final class RegisterRoleChanged extends RegisterEvent {
  final UserRole role;
  const RegisterRoleChanged(this.role);
}

// ── Farmer‑specific fields ────────────────────────────────────────────────

final class RegisterFarmNameChanged extends RegisterEvent {
  final String farmName;
  const RegisterFarmNameChanged(this.farmName);
}

final class RegisterFarmLocationChanged extends RegisterEvent {
  final String farmLocation;
  const RegisterFarmLocationChanged(this.farmLocation);
}

final class RegisterProduceTypeChanged extends RegisterEvent {
  final String produceType;
  const RegisterProduceTypeChanged(this.produceType);
}

// ── Submit ─────────────────────────────────────────────────────────────────

final class RegisterSubmitted extends RegisterEvent {
  const RegisterSubmitted();
}
