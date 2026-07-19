/// Possible states of the OTP verification lifecycle.
sealed class OtpState {
  const OtpState();
}

/// Awaiting user input.
final class OtpInitial extends OtpState {
  const OtpInitial();
}

/// Verifying the submitted code.
final class OtpLoading extends OtpState {
  const OtpLoading();
}

/// Code verified — navigate to the next screen.
final class OtpSuccess extends OtpState {
  const OtpSuccess();
}

/// Code verification failed.
final class OtpFailure extends OtpState {
  final String error;
  const OtpFailure(this.error);
}

/// A resend request is in progress.
final class OtpResending extends OtpState {
  const OtpResending();
}
