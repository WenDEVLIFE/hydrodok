import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hydrodok/src/bloc/login/login_bloc.dart';
import 'package:hydrodok/src/bloc/login/login_event.dart';
import 'package:hydrodok/src/bloc/login/login_state.dart';
import 'package:hydrodok/src/core/repositories/auth_repository.dart';
import 'package:hydrodok/src/core/model/user_session.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

/// Matcher for [LoginFailure] with [error] text.
Matcher isLoginFailure(String error) => isA<LoginFailure>()
    .having((s) => s.error, 'error', error);

/// Test session returned by the auth repo after a successful login.
final _testSession = UserSession(
  uid: 'test-uid',
  email: 'test@example.com',
  fullName: 'Test User',
  phoneNumber: '1234567890',
  role: 'farmer',
  profileImageUrl: '',
  farmName: '',
  farmAddress: '',
  farmProduceTypes: const [],
);

void main() {
  late AuthRepository authRepository;
  late LoginBloc bloc;

  setUp(() {
    authRepository = _MockAuthRepository();
    bloc = LoginBloc(authRepository: authRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('initial state', () {
    test('emits LoginInitial as initial state', () {
      expect(bloc.state, isA<LoginInitial>());
    });
  });

  group('field changes', () {
    test('updates email on LoginEmailChanged', () {
      bloc.add(const LoginEmailChanged('test@example.com'));
      expect(bloc.state, isA<LoginInitial>());
    });

    test('clears failure on email change', () async {
      // Trigger a validation failure
      bloc.add(const LoginSubmitted());

      // Wait for the failure to be emitted
      await expectLater(
        bloc.stream,
        emits(isLoginFailure('Please enter your email')),
      );

      // Now change email — should clear the failure
      bloc.add(const LoginEmailChanged('new@example.com'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<LoginInitial>());
    });

    test('clears failure on password change', () async {
      bloc.add(const LoginSubmitted());
      await expectLater(
        bloc.stream,
        emits(isLoginFailure('Please enter your email')),
      );

      bloc.add(const LoginPasswordChanged('newpass'));
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state, isA<LoginInitial>());
    });
  });

  group('validation', () {
    test('rejects empty email', () async {
      bloc.add(const LoginSubmitted());
      await expectLater(
        bloc.stream,
        emits(isLoginFailure('Please enter your email')),
      );
    });

    test('rejects invalid email format', () async {
      bloc.add(const LoginEmailChanged('notanemail'));
      bloc.add(const LoginSubmitted());
      await expectLater(
        bloc.stream,
        emits(isLoginFailure('Please enter a valid email')),
      );
    });

    test('rejects empty password', () async {
      bloc.add(const LoginEmailChanged('test@example.com'));
      bloc.add(const LoginSubmitted());
      await expectLater(
        bloc.stream,
        emits(isLoginFailure('Please enter your password')),
      );
    });

    test('rejects short password (< 6 chars)', () async {
      bloc.add(const LoginEmailChanged('test@example.com'));
      bloc.add(const LoginPasswordChanged('abc'));
      bloc.add(const LoginSubmitted());
      await expectLater(
        bloc.stream,
        emits(isLoginFailure('Password must be at least 6 characters')),
      );
    });
  });

  group('submission', () {
    test('emits LoginLoading then LoginSuccess on valid credentials',
        () async {
      when(() => authRepository.signIn('test@example.com', 'password123'))
          .thenAnswer((_) async {});
      when(() => authRepository.getCurrentSession())
          .thenAnswer((_) async => _testSession);

      bloc.add(const LoginEmailChanged('test@example.com'));
      bloc.add(const LoginPasswordChanged('password123'));
      bloc.add(const LoginSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<LoginLoading>(), isA<LoginSuccess>()]),
      );
    });

    test('emits LoginLoading then LoginFailure when signIn throws', () async {
      when(() => authRepository.signIn('test@example.com', 'wrongpass'))
          .thenThrow(Exception('Invalid email or password'));

      bloc.add(const LoginEmailChanged('test@example.com'));
      bloc.add(const LoginPasswordChanged('wrongpass'));
      bloc.add(const LoginSubmitted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<LoginLoading>(),
          isLoginFailure('Exception: Invalid email or password'),
        ]),
      );
    });
  });
}
