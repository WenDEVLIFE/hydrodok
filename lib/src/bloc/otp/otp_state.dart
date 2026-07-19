/// Possible states of the OTP verification lifecycle.
sealed class OtpState {
  const OtpState();
}

/// Awaiting user input.
final class OtpInitial extends OtpState {
  final int remainingSeconds;
  const OtpInitial({this.remainingSeconds = 600});
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

/// The OTP has expired — show a message and prompt to resend or go back.
final class OtpExpired extends OtpState {
  const OtpExpired();
}
