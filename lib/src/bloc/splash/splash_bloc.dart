import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'splash_event.dart';
import 'splash_state.dart';

/// Manages the splash screen lifecycle:
///   1. Receives [StartSplash]
///   2. Emits [SplashInProgress] immediately
///   3. Waits for the brand animation + minimum display duration
///   4. Emits [SplashCompleted] so the widget navigates away
final class SplashBloc extends Bloc<SplashEvent, SplashState> {
  SplashBloc() : super(SplashInitial()) {
    on<StartSplash>(_onStartSplash);
  }

  Future<void> _onStartSplash(
    StartSplash event,
    Emitter<SplashState> emit,
  ) async {
    emit(SplashInProgress());

    // Give the logo animation time to finish (1.2 s) plus a buffer
    // so the splash is readable.
    await Future<void>.delayed(const Duration(milliseconds: 2200));

    if (!isClosed) emit(SplashCompleted());
  }
}
