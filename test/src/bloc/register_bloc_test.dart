import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hydrodok/src/core/models/auth_models.dart';
import 'package:hydrodok/src/core/repositories/auth_repository.dart';
import 'package:hydrodok/src/bloc/register/register_bloc.dart';
import 'package:hydrodok/src/bloc/register/register_event.dart';
import 'package:hydrodok/src/bloc/register/register_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Manual mock
// ─────────────────────────────────────────────────────────────────────────────

class MockAuthRepository extends Mock implements AuthRepository {}

// ─────────────────────────────────────────────────────────────────────────────
//  Fallback values for mocktail
// ─────────────────────────────────────────────────────────────────────────────

class _FakeSignUpData extends Fake implements SignUpData {}

void main() {
  late MockAuthRepository authRepository;
  late RegisterBloc bloc;

  setUpAll(() {
    registerFallbackValue(_FakeSignUpData());
  });

  setUp(() {
    authRepository = MockAuthRepository();

    // Default stubs — override in specific test groups as needed
    when(() => authRepository.checkEmailExists(any()))
        .thenAnswer((_) async => false);
    when(() => authRepository.checkNameExists(any()))
        .thenAnswer((_) async => false);
    when(() => authRepository.generateAndSendOtp(any()))
        .thenAnswer((_) async => Future.value());

    bloc = RegisterBloc(authRepository: authRepository);
  });

  tearDown(() {
    bloc.close();
  });

  // ── Initial state ──────────────────────────────────────────────────────

  test('emits RegisterInitial as initial state', () {
    expect(bloc.state, const RegisterInitial());
  });

  // ── Field-level validation ─────────────────────────────────────────────

  group('field validation', () {
    test('rejects empty name', () async {
      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<RegisterFailure>()),
      );
    });

    test('rejects empty email', () async {
      bloc.add(const RegisterNameChanged('Juan'));
      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<RegisterFailure>()),
      );
    });

    test('rejects invalid email', () async {
      bloc.add(const RegisterNameChanged('Juan'));
      bloc.add(const RegisterEmailChanged('not-an-email'));
      bloc.add(const RegisterContactNumberChanged('09171234567'));
      bloc.add(const RegisterPasswordChanged('password123'));
      bloc.add(const RegisterConfirmPasswordChanged('password123'));
      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<RegisterFailure>()),
      );
    });

    test('rejects missing contact number', () async {
      bloc.add(const RegisterNameChanged('Juan'));
      bloc.add(const RegisterEmailChanged('juan@example.com'));
      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<RegisterFailure>()),
      );
    });

    test('rejects short password', () async {
      bloc.add(const RegisterNameChanged('Juan'));
      bloc.add(const RegisterEmailChanged('juan@example.com'));
      bloc.add(const RegisterContactNumberChanged('09171234567'));
      bloc.add(const RegisterPasswordChanged('12345'));
      bloc.add(const RegisterConfirmPasswordChanged('12345'));
      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<RegisterFailure>()),
      );
    });

    test('rejects mismatched passwords', () async {
      bloc.add(const RegisterNameChanged('Juan'));
      bloc.add(const RegisterEmailChanged('juan@example.com'));
      bloc.add(const RegisterContactNumberChanged('09171234567'));
      bloc.add(const RegisterPasswordChanged('password123'));
      bloc.add(const RegisterConfirmPasswordChanged('different'));
      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emits(isA<RegisterFailure>()),
      );
    });

  });

  // ── Uniqueness checks ─────────────────────────────────────────────────

  group('uniqueness checks', () {
    setUp(() {
      bloc.add(const RegisterNameChanged('Juan Dela Cruz'));
      bloc.add(const RegisterEmailChanged('juan@example.com'));
      bloc.add(const RegisterContactNumberChanged('09171234567'));
      bloc.add(const RegisterPasswordChanged('password123'));
      bloc.add(const RegisterConfirmPasswordChanged('password123'));
    });

    test('rejects duplicate email', () async {
      when(() => authRepository.checkEmailExists('juan@example.com'))
          .thenAnswer((_) async => true);

      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegisterLoading>(),
          isA<RegisterFailure>(),
        ]),
      );
      verify(() => authRepository.checkEmailExists('juan@example.com'))
          .called(1);
    });

    test('rejects duplicate name', () async {
      when(() => authRepository.checkNameExists('Juan Dela Cruz'))
          .thenAnswer((_) async => true);

      bloc.add(const RegisterSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegisterLoading>(),
          isA<RegisterFailure>(),
        ]),
      );
    });
  });

  // ── Success path ───────────────────────────────────────────────────────

  group('success path', () {
    setUp(() {
      bloc.add(const RegisterNameChanged('Juan Dela Cruz'));
      bloc.add(const RegisterEmailChanged('juan@example.com'));
      bloc.add(const RegisterContactNumberChanged('09171234567'));
      bloc.add(const RegisterPasswordChanged('password123'));
      bloc.add(const RegisterConfirmPasswordChanged('password123'));
    });

    test('emits RegisterOtpSent with SignUpData on success', () async {
      bloc.add(const RegisterSubmitted());

      final emitted = await bloc.stream
          .firstWhere((s) => s is RegisterOtpSent || s is RegisterFailure);
      expect(emitted, isA<RegisterOtpSent>());
      final otpSent = emitted as RegisterOtpSent;
      expect(otpSent.data.email, 'juan@example.com');
      expect(otpSent.data.name, 'Juan Dela Cruz');
      expect(otpSent.data.role, UserRole.farmer);

      verify(() => authRepository.generateAndSendOtp('juan@example.com'))
          .called(1);
    });

    test('consumer signup succeeds without farm details', () async {
      bloc.add(const RegisterRoleChanged(UserRole.consumer));
      bloc.add(const RegisterNameChanged('Maria Santos'));
      bloc.add(const RegisterEmailChanged('maria@example.com'));
      bloc.add(const RegisterContactNumberChanged('09179876543'));
      bloc.add(const RegisterPasswordChanged('securepass456'));
      bloc.add(const RegisterConfirmPasswordChanged('securepass456'));

      bloc.add(const RegisterSubmitted());

      final emitted = await bloc.stream
          .firstWhere((s) => s is RegisterOtpSent || s is RegisterFailure);
      expect(emitted, isA<RegisterOtpSent>());
      final otpSent = emitted as RegisterOtpSent;
      expect(otpSent.data.role, UserRole.consumer);
    });
  });

  // ── Error from repository ─────────────────────────────────────────────

  test('emits RegisterFailure when generateAndSendOtp throws', () async {
    bloc.add(const RegisterNameChanged('Juan'));
    bloc.add(const RegisterEmailChanged('juan@example.com'));
    bloc.add(const RegisterContactNumberChanged('09171234567'));
    bloc.add(const RegisterPasswordChanged('password123'));
    bloc.add(const RegisterConfirmPasswordChanged('password123'));

    when(() => authRepository.generateAndSendOtp(any()))
        .thenThrow(Exception('Network error'));

    bloc.add(const RegisterSubmitted());

    await expectLater(
      bloc.stream,
      emitsInOrder([
        isA<RegisterLoading>(),
        isA<RegisterFailure>(),
      ]),
    );
  });
}
