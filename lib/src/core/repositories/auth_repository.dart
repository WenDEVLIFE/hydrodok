import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/auth_models.dart';
import '../service/email_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Abstract repository
// ─────────────────────────────────────────────────────────────────────────────

/// Interface for authentication operations used by the auth blocs.
abstract class AuthRepository {
  /// Returns true if a profile with this email already exists.
  Future<bool> checkEmailExists(String email);

  /// Returns true if a profile with this full name already exists.
  Future<bool> checkNameExists(String name);

  /// Generates a 6‑digit OTP, stores it with a timestamp in
  /// SharedPreferences, and sends it via [EmailService].
  Future<void> generateAndSendOtp(String email);

  /// Validates [otp] for [email] against the stored value and checks
  /// that it hasn't expired (10‑minute window).
  Future<bool> verifyOtp(String email, String otp);

  /// Removes the stored OTP for [email] from SharedPreferences.
  Future<void> clearOtp(String email);

  /// Returns the remaining seconds before the OTP expires.
  /// Returns 0 if no OTP is stored or it has already expired.
  Future<int> getRemainingOtpSeconds(String email);

  /// Creates the auth user, profile, and farm (if farmer).
  /// Throws on failure.
  Future<void> signUp(SignUpData data);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Supabase-backed implementation
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _supabase;
  final EmailService _emailService;
  final SharedPreferences _prefs;

  static const _otpTtlSeconds = 600; // 10 minutes

  SupabaseAuthRepository({
    required SupabaseClient supabase,
    required EmailService emailService,
    required SharedPreferences prefs,
  })  : _supabase = supabase,
        _emailService = emailService,
        _prefs = prefs;

  // ── Uniqueness checks ────────────────────────────────────────────────

  @override
  Future<bool> checkEmailExists(String email) async {
    try {
      // Uses a Supabase Database function:
      //   CREATE OR REPLACE FUNCTION check_email_exists(p_email text)
      //   RETURNS boolean LANGUAGE sql SECURITY DEFINER SET search_path = ''
      //   AS $$ SELECT EXISTS (SELECT 1 FROM auth.users WHERE email = p_email); $$;
      final result = await _supabase.rpc('check_email_exists', params: {
        'p_email': email,
      });
      return result as bool;
    } catch (_) {
      // Function doesn't exist yet — assume email is available.
      return false;
    }
  }

  @override
  Future<bool> checkNameExists(String name) async {
    try {
      final result = await _supabase
          .from('profiles')
          .select('id')
          .eq('full_name', name)
          .maybeSingle();
      return result != null;
    } catch (_) {
      return false;
    }
  }

  // ── OTP management ──────────────────────────────────────────────────

  @override
  Future<void> generateAndSendOtp(String email) async {
    final otp = _generateOtp();
    final now = DateTime.now().millisecondsSinceEpoch;

    await _prefs.setString('otp_code_$email', otp);
    await _prefs.setInt('otp_ts_$email', now);

    await _emailService.sendOtp(email, otp);
  }

  @override
  Future<bool> verifyOtp(String email, String otp) async {
    final storedOtp = _prefs.getString('otp_code_$email');
    final storedTs = _prefs.getInt('otp_ts_$email');

    if (storedOtp == null || storedTs == null) return false;

    final elapsed = DateTime.now().millisecondsSinceEpoch - storedTs;
    if (elapsed > _otpTtlSeconds * 1000) return false; // expired

    return storedOtp == otp;
  }

  @override
  Future<void> clearOtp(String email) async {
    await _prefs.remove('otp_code_$email');
    await _prefs.remove('otp_ts_$email');
  }

  @override
  Future<int> getRemainingOtpSeconds(String email) async {
    final storedTs = _prefs.getInt('otp_ts_$email');
    if (storedTs == null) return 0;

    final elapsed = DateTime.now().millisecondsSinceEpoch - storedTs;
    final remaining = _otpTtlSeconds - (elapsed ~/ 1000);
    return remaining.clamp(0, _otpTtlSeconds);
  }

  // ── Sign up (called AFTER OTP verification) ─────────────────────────

  @override
  Future<void> signUp(SignUpData data) async {
    // 1. Create auth user
    final authResult = await _supabase.auth.signUp(
      email: data.email,
      password: data.password,
    );

    final userId = authResult.user?.id;
    if (userId == null) {
      throw Exception('Failed to create user account');
    }

    // 2. Create profile via SECURITY DEFINER function (bypasses RLS)
    await _supabase.rpc('create_user_profile', params: {
      'p_role': data.role.name,
      'p_full_name': data.name,
      'p_contact_number': data.contactNumber,
    });

    // 3. Create farm if farmer
    if (data.role == UserRole.farmer && data.farm != null) {
      await _supabase.rpc('create_farm', params: {
        'p_farm_name': data.farm!.farmName,
        'p_address': data.farm!.location,
        'p_produce_types': [data.farm!.produceType],
      });
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _generateOtp() {
    final rng = Random();
    return List.generate(6, (_) => rng.nextInt(10)).join();
  }
}
