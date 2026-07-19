/// Events that drive the splash screen state machine.
sealed class SplashEvent {
  const SplashEvent();
}

/// Triggers the splash sequence: show branding, wait, then navigate.
final class StartSplash extends SplashEvent {
  const StartSplash();
}
