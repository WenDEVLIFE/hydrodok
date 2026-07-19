/// Events that drive the OTP verification state machine.
sealed class OtpEvent {
  const OtpEvent();
}

/// Emitted every time the user types or deletes a character.
final class OtpCodeChanged extends OtpEvent {
  final String code;
  const OtpCodeChanged(this.code);
}

/// Emitted when the user taps the "Verify" button.
final class OtpVerifySubmitted extends OtpEvent {
  const OtpVerifySubmitted();
}

/// Emitted when the user taps "Resend code".
final class OtpResendRequested extends OtpEvent {
  const OtpResendRequested();
}
