import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hydrodok/src/core/models/auth_models.dart';
import 'package:hydrodok/src/core/repositories/auth_repository.dart';
import 'package:hydrodok/main.dart';

/// A fake repository used for widget tests.
class _FakeAuthRepository extends AuthRepository {
  @override
  Future<bool> checkEmailExists(String email) async => false;

  @override
  Future<bool> checkNameExists(String name) async => false;

  @override
  Future<void> generateAndSendOtp(String email) async {}

  @override
  Future<bool> verifyOtp(String email, String otp) async => true;

  @override
  Future<void> clearOtp(String email) async {}

  @override
  Future<int> getRemainingOtpSeconds(String email) async => 600;

  @override
  Future<void> signUp(SignUpData data) async {}
}

void main() {
  testWidgets('App renders and navigates from splash to login',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: _FakeAuthRepository(),
        child: const HydrodokApp(),
      ),
    );

    // The splash screen shows the LogoWidget; verify the app built
    // without error by checking for the Scaffold.
    expect(find.byType(Scaffold), findsOneWidget);

    // Advance past the splash animation (2.2s delay) + transition (0.4s)
    // Pump multiple frames to let the navigation complete.
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // After splash, we should be on the login screen with "Welcome back"
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to your account'), findsOneWidget);
  });
}
