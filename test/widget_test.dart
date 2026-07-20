import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hydrodok/src/core/model/user_session.dart';
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

  @override
  Future<void> signIn(String email, String password) async {}

  @override
  Future<UserSession?> getCurrentSession() async => null;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('App renders splash screen successfully',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      RepositoryProvider<AuthRepository>.value(
        value: _FakeAuthRepository(),
        child: const HydrodokApp(),
      ),
    );

    // Verify the app built without error by checking for Scaffold
    expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
  });
}
