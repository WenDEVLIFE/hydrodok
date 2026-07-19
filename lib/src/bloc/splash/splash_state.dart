/// Possible states of the splash screen lifecycle.
sealed class SplashState {
  const SplashState();
}

/// Initial idle state — splash hasn't started yet.
final class SplashInitial extends SplashState {
  const SplashInitial();
}

/// Brand animation is playing; loading indicator visible.
final class SplashInProgress extends SplashState {
  const SplashInProgress();
}

/// Splash sequence finished — widget should navigate to the next screen.
final class SplashCompleted extends SplashState {
  const SplashCompleted();
}
