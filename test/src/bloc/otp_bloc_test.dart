import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hydrodok/src/bloc/otp/otp_bloc.dart';
import 'package:hydrodok/src/bloc/otp/otp_event.dart';
import 'package:hydrodok/src/bloc/otp/otp_state.dart';
import 'package:hydrodok/src/core/models/auth_models.dart';
import 'package:hydrodok/src/core/repositories/auth_repository.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository authRepository;
  late OtpBloc bloc;

  setUpAll(() {
    registerFallbackValue(_signUpData);
  });

  setUp(() {
    authRepository = MockAuthRepository();

    when(() => authRepository.verifyOtp(any(), any()))
        .thenAnswer((_) async => true);
    when(() => authRepository.signUp(any()))
        .thenAnswer((_) async {});
    when(() => authRepository.clearOtp(any()))
        .thenAnswer((_) async {});
    when(() => authRepository.generateAndSendOtp(any()))
        .thenAnswer((_) async {});
    when(() => authRepository.getRemainingOtpSeconds(any()))
        .thenAnswer((_) async => 600);

    bloc = OtpBloc(
      authRepository: authRepository,
      signUpData: _signUpData,
    );
  });

  tearDown(() {
    bloc.close();
  });

  test('emits OtpInitial as initial state', () {
    expect(bloc.state, isA<OtpInitial>());
  });

  test('updates code on OtpCodeChanged', () async {
    bloc.add(const OtpCodeChanged('123456'));
    expect(bloc.signUpDataEmail, 'juan@example.com');
  });

  test('clears failure state on new input', () async {
    bloc.emit(const OtpFailure('Invalid code'));
    bloc.add(const OtpCodeChanged('1'));

    final emitted = await bloc.stream.firstWhere((s) => s is OtpInitial);
    expect(emitted, isA<OtpInitial>());
  });

  test('validation rejects incomplete code', () async {
    bloc.add(const OtpCodeChanged('12345'));
    bloc.add(const OtpVerifySubmitted());

    final emitted = await bloc.stream.firstWhere((s) => s is OtpFailure);
    expect((emitted as OtpFailure).error, contains('6-digit'));
  });

  test('validation rejects expired OTP', () async {
    when(() => authRepository.getRemainingOtpSeconds(any()))
        .thenAnswer((_) async => 0);

    bloc.add(const OtpCodeChanged('123456'));
    bloc.add(const OtpVerifySubmitted());

    final emitted = await bloc.stream.firstWhere((s) => s is OtpExpired);
    expect(emitted, isA<OtpExpired>());
  });

  test('validation rejects invalid code', () async {
    when(() => authRepository.verifyOtp(any(), any()))
        .thenAnswer((_) async => false);

    bloc.add(const OtpCodeChanged('654321'));
    bloc.add(const OtpVerifySubmitted());

    final emitted = await bloc.stream.firstWhere((s) => s is OtpFailure);
    expect((emitted as OtpFailure).error, contains('Invalid'));
  });

  test('success verifies OTP, calls signUp, emits OtpSuccess', () async {
    bloc.add(const OtpCodeChanged('123456'));
    bloc.add(const OtpVerifySubmitted());

    final emitted = await bloc.stream.firstWhere((s) => s is OtpSuccess);
    expect(emitted, isA<OtpSuccess>());

    verify(() => authRepository.verifyOtp('juan@example.com', '123456')).called(1);
    verify(() => authRepository.signUp(_signUpData)).called(1);
  });

  test('resend generates new OTP and resets to OtpInitial', () async {
    bloc.add(const OtpResendRequested());

    await bloc.stream.firstWhere((s) => s is OtpInitial);

    verify(() => authRepository.generateAndSendOtp('juan@example.com')).called(1);
  });

  test('emits OtpFailure when verifyOtp throws', () async {
    when(() => authRepository.verifyOtp(any(), any()))
        .thenThrow(Exception('Verification server down'));

    bloc.add(const OtpCodeChanged('123456'));
    bloc.add(const OtpVerifySubmitted());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<OtpLoading>(),
        isA<OtpFailure>(),
      ]),
    );
  });
}

// ── Test data ─────────────────────────────────────────────────────────────

const _signUpData = SignUpData(
  name: 'Juan Dela Cruz',
  email: 'juan@example.com',
  contactNumber: '09171234567',
  password: 'password123',
  role: UserRole.farmer,
);
