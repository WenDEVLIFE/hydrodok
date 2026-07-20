import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hydrodok/src/core/models/auth_models.dart';
import 'package:hydrodok/src/core/repositories/auth_repository.dart';
import 'package:hydrodok/src/core/service/email_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Manual mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockEmailService extends Mock implements EmailService {}

// ─────────────────────────────────────────────────────────────────────────────
//  A minimal AuthRepository that only uses SharedPreferences for OTP
//  management (overrides all Supabase-calling methods).
// ─────────────────────────────────────────────────────────────────────────────

class _OtpOnlyRepository extends SupabaseAuthRepository {
  _OtpOnlyRepository({
    required SupabaseClient supabase,
    required super.emailService,
    required super.prefs,
  }) : super(supabase: supabase);

  @override
  Future<bool> checkEmailExists(String email) async => false;

  @override
  Future<bool> checkNameExists(String name) async => false;

  @override
  Future<void> signUp(SignUpData data) async {}
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late MockSupabaseClient supabase;
  late MockEmailService emailService;
  late SharedPreferences prefs;
  late _OtpOnlyRepository repository;

  setUp(() async {
    supabase = MockSupabaseClient();
    emailService = MockEmailService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    repository = _OtpOnlyRepository(
      supabase: supabase,
      emailService: emailService,
      prefs: prefs,
    );
  });

  group('generateAndSendOtp', () {
    test('stores 6-digit code and sends email', () async {
      when(() => emailService.sendOtp(any(), any()))
          .thenAnswer((_) async => Future.value());

      await repository.generateAndSendOtp('test@example.com');

      // Verify OTP was stored
      final storedCode = prefs.getString('otp_code_test@example.com');
      expect(storedCode, isNotNull);
      expect(storedCode!.length, 6);
      expect(int.tryParse(storedCode), isNotNull);

      // Verify timestamp was stored
      final storedTs = prefs.getInt('otp_ts_test@example.com');
      expect(storedTs, isNotNull);
      expect(storedTs, greaterThan(0));

      // Verify email was sent
      verify(() => emailService.sendOtp('test@example.com', storedCode))
          .called(1);
    });
  });

  group('verifyOtp', () {
    test('returns true for correct code', () async {
      when(() => emailService.sendOtp(any(), any()))
          .thenAnswer((_) async => Future.value());

      await repository.generateAndSendOtp('test@example.com');
      final storedCode = prefs.getString('otp_code_test@example.com')!;

      final result = await repository.verifyOtp('test@example.com', storedCode);
      expect(result, isTrue);
    });

    test('returns false for wrong code', () async {
      when(() => emailService.sendOtp(any(), any()))
          .thenAnswer((_) async => Future.value());

      await repository.generateAndSendOtp('test@example.com');

      final result = await repository.verifyOtp('test@example.com', '000000');
      expect(result, isFalse);
    });

    test('returns false when no OTP stored', () async {
      final result = await repository.verifyOtp('unknown@test.com', '123456');
      expect(result, isFalse);
    });
  });

  group('getRemainingOtpSeconds', () {
    test('returns 0 when no OTP stored', () async {
      final result = await repository.getRemainingOtpSeconds(
        'no-otp@test.com',
      );
      expect(result, 0);
    });

    test('returns remaining seconds when OTP is active', () async {
      when(() => emailService.sendOtp(any(), any()))
          .thenAnswer((_) async => Future.value());

      await repository.generateAndSendOtp('test@example.com');

      final result = await repository.getRemainingOtpSeconds(
        'test@example.com',
      );
      expect(result, greaterThan(0));
      expect(result, lessThanOrEqualTo(600));
    });
  });

  group('clearOtp', () {
    test('removes stored OTP data', () async {
      when(() => emailService.sendOtp(any(), any()))
          .thenAnswer((_) async => Future.value());

      await repository.generateAndSendOtp('test@example.com');
      expect(prefs.containsKey('otp_code_test@example.com'), isTrue);

      await repository.clearOtp('test@example.com');

      expect(prefs.containsKey('otp_code_test@example.com'), isFalse);
      expect(prefs.containsKey('otp_ts_test@example.com'), isFalse);
    });
  });

  group('getCurrentSession', () {
    late _MockGoTrueClient mockAuth;
    late _MockSupabaseQueryBuilder mockProfileQuery;
    late _MockSupabaseQueryBuilder mockFarmQuery;
    late _MockPostgrestFilter mockProfileFilter;
    late _MockPostgrestFilter mockFarmFilter;
    late _TestableRepository testableRepo;

    setUp(() {
      mockAuth = _MockGoTrueClient();
      mockProfileQuery = _MockSupabaseQueryBuilder();
      mockFarmQuery = _MockSupabaseQueryBuilder();
      mockProfileFilter = _MockPostgrestFilter();
      mockFarmFilter = _MockPostgrestFilter();

      // Auth chain
      when(() => supabase.auth).thenReturn(mockAuth);

      // Profile query chain
      when(() => supabase.from('profiles')).thenAnswer((_) => mockProfileQuery);
      when(() => mockProfileQuery.select(any())).thenAnswer((_) => mockProfileFilter);
      when(() => mockProfileFilter.eq(any(), any())).thenAnswer((_) => mockProfileFilter);

      // Farm query chain
      when(() => supabase.from('farms')).thenAnswer((_) => mockFarmQuery);
      when(() => mockFarmQuery.select(any())).thenAnswer((_) => mockFarmFilter);
      when(() => mockFarmFilter.eq(any(), any())).thenAnswer((_) => mockFarmFilter);

      testableRepo = _TestableRepository(
        supabase: supabase,
        emailService: emailService,
        prefs: prefs,
      );
    });

    test('selects onboarding_completed from profiles', () async {
      when(() => mockAuth.currentUser).thenReturn('test-uid'.toUser());
      when(() => mockProfileFilter.maybeSingle()).thenAnswer(
        (_) => _ControlledTransformBuilder({
          'full_name': 'Farmer John',
          'contact_number': '09123456789',
          'role': 'farming',
          'avatar_url': '',
          'onboarding_completed': false,
        }),
      );
      when(() => mockFarmFilter.maybeSingle()).thenAnswer(
        (_) => _ControlledTransformBuilder({
          'farm_name': 'Green Acres',
          'address': '123 Farm St',
          'produce_types': ['Rice', 'Corn'],
        }),
      );

      final session = await testableRepo.getCurrentSession();

      expect(session, isNotNull);
      expect(session!.onboardingCompleted, isFalse);
      expect(session.farmName, 'Green Acres');
      expect(session.fullName, 'Farmer John');
      final captured =
          verify(() => mockProfileQuery.select(captureAny())).captured;
      expect((captured.first as String).contains('onboarding_completed'),
          isTrue);
    });

    test('defaults onboardingCompleted to true when profile lacks the column', () async {
      when(() => mockAuth.currentUser).thenReturn('test-uid'.toUser());
      when(() => mockProfileFilter.maybeSingle()).thenAnswer(
        (_) => _ControlledTransformBuilder({
          'full_name': 'Legacy Farmer',
          'contact_number': '09123456789',
          'role': 'farming',
          'avatar_url': '',
          // no onboarding_completed key
        }),
      );
      when(() => mockFarmFilter.maybeSingle()).thenAnswer(
        (_) => _ControlledTransformBuilder(null),
      );

      final session = await testableRepo.getCurrentSession();

      expect(session, isNotNull);
      expect(session!.onboardingCompleted, isTrue);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Controlled PostgrestTransformBuilder that returns predetermined data
//  when awaited (avoids mocktail's inability to stub Future on mocks).
// ─────────────────────────────────────────────────────────────────────────────

class _ControlledTransformBuilder
    extends PostgrestTransformBuilder<Map<String, dynamic>?> {
  _ControlledTransformBuilder(this._data)
      : super(
          PostgrestBuilder<
            Map<String, dynamic>?,
            Map<String, dynamic>?,
            Map<String, dynamic>?
          >(
            url: Uri.parse('http://localhost/'),
            headers: <String, String>{},
          ),
        );

  final Map<String, dynamic>? _data;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>?)? onValue, {
    Function? onError,
  }) {
    if (onValue != null) {
      final result = onValue(_data);
      if (result is Future<R>) return result;
      return Future<R>.value(result as R);
    }
    return Future<R>.value(null as R);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Chain mocks for Supabase query builder (getCurrentSession tests)
// ─────────────────────────────────────────────────────────────────────────────

class _MockGoTrueClient extends Mock implements GoTrueClient {}

class _MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class _MockPostgrestFilter
    extends Mock implements PostgrestFilterBuilder<PostgrestList> {}

class _TestableRepository extends SupabaseAuthRepository {
  _TestableRepository({
    required SupabaseClient supabase,
    required super.emailService,
    required super.prefs,
  }) : super(supabase: supabase);

  @override
  Future<bool> checkEmailExists(String email) async => false;

  @override
  Future<bool> checkNameExists(String name) async => false;

  @override
  Future<void> signUp(SignUpData data) async {}
}

// ─────────────────────────────────────────────────────────────────────────────
//  Additional test setup shared by getCurrentSession tests
// ─────────────────────────────────────────────────────────────────────────────

extension on String {
  // Helper to create a User instance from minimal data
  User toUser() {
    final now = DateTime.now().toIso8601String();
    return User(
      id: this,
      appMetadata: <String, dynamic>{},
      userMetadata: null,
      aud: 'authenticated',
      email: 'farmer@test.com',
      createdAt: now,
    );
  }
}
