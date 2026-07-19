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
}
