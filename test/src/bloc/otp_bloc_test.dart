import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hydrodok/src/core/models/auth_models.dart';
import 'package:hydrodok/src/core/repositories/auth_repository.dart';
import 'package:hydrodok/src/bloc/otp/otp_bloc.dart';
import 'package:hydrodok/src/bloc/otp/otp_event.dart';
import 'package:hydrodok/src/bloc/otp/otp_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Manual mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

// ─────────────────────────────────────────────────────────────────────────────
//  Fallback values for mocktail (required for any() matchers on custom types)
// ─────────────────────────────────────────────────────────────────────────────

class _FakeSignUpData extends Fake implements SignUpData {}

void main() {
  late MockAuthRepository authRepository;
  late OtpBloc bloc;

  setUpAll(() {
    registerFallbackValue(_FakeSignUpData());
  });

  setUp(() {
    authRepository = MockAuthRepository();

    // Stub getRemainingOtpSeconds to avoid null errors from the expiry timer
    when(() => authRepository.getRemainingOtpSeconds(any()))
        .thenAnswer((_) async => 500);

    bloc = OtpBloc(authRepository: authRepository, signUpData: _signUpData);
  });

  tearDown(() {
    bloc.close();
  });

  // ── Initial state ──────────────────────────────────────────────────────

  test('emits OtpInitial as initial state', () {
    expect(bloc.state, const OtpInitial());
  });

  // ── Code input ─────────────────────────────────────────────────────────

  test('updates code on OtpCodeChanged', () async {
    bloc.add(const OtpCodeChanged('12'));
    // State stays OtpInitial — just the private _code field is updated
    expect(bloc.state, const OtpInitial());
  });

  test('clears failure state on new input', () async {
    // Submit an incomplete code to get a failure
    bloc.add(const OtpVerifySubmitted());

    // Wait for the failure to be emitted
    await expectLater(
      bloc.stream,
      emits(isA<OtpFailure>()),
    );

    // Type something — should reset to initial (async in bloc)
    // Use pump or a small delay to let the event process
    bloc.add(const OtpCodeChanged('1'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, const OtpInitial());
  });

  // ── Validation ─────────────────────────────────────────────────────────

  group('validation', () {
    test('rejects incomplete code', () async {
      bloc.add(const OtpCodeChanged('123'));
      bloc.add(const OtpVerifySubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<OtpFailure>()),
      );
    });

    test('rejects expired OTP', () async {
      bloc.add(const OtpCodeChanged('123456'));

      when(() => authRepository.getRemainingOtpSeconds('juan@example.com'))
          .thenAnswer((_) async => 0);

      bloc.add(const OtpVerifySubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OtpLoading>(),
          isA<OtpExpired>(),
        ]),
      );
    });

    test('rejects invalid code', () async {
      bloc.add(const OtpCodeChanged('123456'));

      when(() => authRepository.verifyOtp('juan@example.com', '123456'))
          .thenAnswer((_) async => false);

      bloc.add(const OtpVerifySubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OtpLoading>(),
          isA<OtpFailure>(),
        ]),
      );
    });
  });

  // ── Success path ───────────────────────────────────────────────────────

  group('success', () {
    test('verifies OTP, calls signUp, emits OtpSuccess', () async {
      bloc.add(const OtpCodeChanged('654321'));

      when(() => authRepository.verifyOtp('juan@example.com', '654321'))
          .thenAnswer((_) async => true);
      when(() => authRepository.signUp(any()))
          .thenAnswer((_) async => Future.value());
      when(() => authRepository.clearOtp('juan@example.com'))
          .thenAnswer((_) async => Future.value());

      bloc.add(const OtpVerifySubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OtpLoading>(),
          isA<OtpSuccess>(),
        ]),
      );

      verify(() => authRepository.signUp(any())).called(1);
      verify(() => authRepository.clearOtp('juan@example.com')).called(1);
    });
  });

  // ── Resend ─────────────────────────────────────────────────────────────

  group('resend', () {
    test('generates new OTP and resets to OtpInitial', () async {
      when(() => authRepository.generateAndSendOtp('juan@example.com'))
          .thenAnswer((_) async => Future.value());

      bloc.add(const OtpResendRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<OtpResending>(),
          isA<OtpInitial>(),
        ]),
      );
    });
  });

  // ── Error handling ─────────────────────────────────────────────────────

  test('emits OtpFailure when verifyOtp throws', () async {
    bloc.add(const OtpCodeChanged('123456'));

    when(() => authRepository.verifyOtp('juan@example.com', '123456'))
        .thenThrow(Exception('Server error'));

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

// ── Test data (at file level to be accessible to setUp ↑) ───────────────────

const _signUpData = SignUpData(
  name: 'Juan Dela Cruz',
  email: 'juan@example.com',
  contactNumber: '09171234567',
  password: 'password123',
  role: UserRole.farmer,
  farm: FarmDetails(
    farmName: 'Green Valley Farm',
    location: 'General Trias',
    produceType: 'Lettuce',
  ),
);
