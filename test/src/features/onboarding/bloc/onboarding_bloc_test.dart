import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:postgrest/postgrest.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:hydrodok/src/core/service/farm_service.dart';
import 'package:hydrodok/src/features/onboarding/bloc/onboarding_bloc.dart';
import 'package:hydrodok/src/features/onboarding/bloc/onboarding_event.dart';
import 'package:hydrodok/src/features/onboarding/bloc/onboarding_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Manual mocks
// ─────────────────────────────────────────────────────────────────────────────

class MockFarmService extends Mock implements FarmService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// ─────────────────────────────────────────────────────────────────────────────
//  Controlled PostgrestFilterBuilder — avoids mocktail's inability to stub
//  Future subtypes (PostgrestFilterBuilder implements Future<PostgrestList>).
// ─────────────────────────────────────────────────────────────────────────────

class _ControlledFilter extends PostgrestFilterBuilder<PostgrestList> {
  _ControlledFilter()
      : super(
          PostgrestBuilder<PostgrestList, PostgrestList, PostgrestList>(
            url: Uri.parse('http://localhost/'),
            headers: <String, String>{},
          ),
        );

  @override
  Future<R> then<R>(
    FutureOr<R> Function(PostgrestList)? onValue, {
    Function? onError,
  }) {
    if (onValue != null) {
      final result = onValue(<Map<String, dynamic>>[]);
      if (result is Future<R>) return result;
      return Future<R>.value(result as R);
    }
    return Future<R>.value(null as R);
  }

  @override
  PostgrestFilterBuilder<PostgrestList> eq(String column, Object value) {
    return _ControlledFilter();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Fallback values for mocktail
// ─────────────────────────────────────────────────────────────────────────────

class _FileFake extends Fake implements File {}

void main() {
  late MockFarmService farmService;
  late MockSupabaseClient supabase;
  late MockSupabaseQueryBuilder mockProfileQuery;
  late OnboardingBloc bloc;

  setUpAll(() {
    registerFallbackValue(_FileFake());
  });

  setUp(() {
    farmService = MockFarmService();
    supabase = MockSupabaseClient();
    mockProfileQuery = MockSupabaseQueryBuilder();

    when(() => supabase.from('profiles')).thenAnswer((_) => mockProfileQuery);
    when(() => mockProfileQuery.update(any()))
        .thenAnswer((_) => _ControlledFilter());

    // Default stubs — individual tests override if needed
    when(() => farmService.updateFarm(any(),
            description: any(named: 'description'),
            photoUrl: any(named: 'photoUrl')))
        .thenAnswer((_) async {});
    when(() => farmService.uploadFarmPhoto(any(), any()))
        .thenAnswer((_) async => 'https://example.com/photo.jpg');
    when(() => farmService.submitVerification(any(), any(), any()))
        .thenAnswer((_) async => 'https://example.com/doc.jpg');
    when(() => farmService.skipVerification(any()))
        .thenAnswer((_) async {});

    bloc = OnboardingBloc(
      farmService: farmService,
      supabaseClient: supabase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  // ── Initial state ──────────────────────────────────────────────────────

  test('initial state is OnboardingInitial', () {
    expect(bloc.state, const OnboardingInitial());
  });

  // ── Step 1 → Step 2 transition ─────────────────────────────────────────

  group('Step1Next', () {
    test('with valid fields transitions to Step2Verification', () async {
      bloc.add(const Step1NameChanged('Green Valley Farm'));
      bloc.add(const Step1AddressChanged('General Trias'));
      bloc.add(const Step1ProduceTypesChanged(['Lettuce', 'Tomato']));
      bloc.add(const Step1Next());

      final emitted = await bloc.stream
          .firstWhere((s) => s is Step2Verification);
      expect(emitted, isA<Step2Verification>());
    });

    test('with missing required fields shows error and stays on Step1',
        () async {
      bloc.add(const Step1ProduceTypesChanged(['Lettuce']));
      bloc.add(const Step1Next());

      final emitted = await bloc.stream.firstWhere((s) {
        if (s is Step1FarmProfile && s.errorMessage != null) return true;
        return false;
      });
      expect((emitted as Step1FarmProfile).errorMessage, isNotEmpty);
    });

    test('uploads photo and updates farm when photo selected', () async {
      bloc.add(const Step1NameChanged('Green Valley Farm'));
      bloc.add(const Step1AddressChanged('General Trias'));
      bloc.add(const Step1ProduceTypesChanged(['Lettuce']));
      bloc.add(Step1FarmPhotoSelected(File('/dev/null')));
      bloc.add(const Step1Next());

      await bloc.stream
          .firstWhere((s) => s is Step2Verification);

      verify(() => farmService.uploadFarmPhoto(any(), any())).called(1);
      verify(
        () => farmService.updateFarm(
          any(),
          description: any(named: 'description'),
          photoUrl: any(named: 'photoUrl'),
        ),
      ).called(1);
    });

    test('sets errorMessage when uploadFarmPhoto throws', () async {
      when(() => farmService.uploadFarmPhoto(any(), any()))
          .thenThrow(Exception('Upload failed'));

      bloc.add(const Step1NameChanged('Green Valley Farm'));
      bloc.add(const Step1AddressChanged('General Trias'));
      bloc.add(const Step1ProduceTypesChanged(['Lettuce']));
      bloc.add(Step1FarmPhotoSelected(File('/dev/null')));
      bloc.add(const Step1Next());

      final emitted = await bloc.stream.firstWhere((s) {
        if (s is Step1FarmProfile && s.errorMessage != null) return true;
        return false;
      });
      expect((emitted as Step1FarmProfile).errorMessage, isNotEmpty);
    });
  });

  // ── Step 2 Submit ──────────────────────────────────────────────────────

  group('Step2Submit', () {
    setUp(() async {
      // Transition to Step2 first
      bloc.add(const Step1NameChanged('Farm'));
      bloc.add(const Step1AddressChanged('Address'));
      bloc.add(const Step1ProduceTypesChanged(['Rice']));
      bloc.add(const Step1Next());
      await bloc.stream.firstWhere((s) => s is Step2Verification);
    });

    test('with document selected emits OnboardingCompleted', () async {
      bloc.add(Step2DocumentSelected(File('/dev/null'), 'dti'));
      bloc.add(const Step2Submit());

      final emitted = await bloc.stream
          .firstWhere((s) => s is OnboardingCompleted);
      expect(emitted, isA<OnboardingCompleted>());
    });

    test('calls submitVerification and updates profile', () async {
      bloc.add(Step2DocumentSelected(File('/dev/null'), 'dti'));
      bloc.add(const Step2Submit());

      await bloc.stream
          .firstWhere((s) => s is OnboardingCompleted);

      verify(() => farmService.submitVerification(any(), any(), 'dti'))
          .called(1);
    });

    test('without document shows error and stays on Step2', () async {
      bloc.add(const Step2Submit());

      final emitted = await bloc.stream.firstWhere((s) {
        if (s is Step2Verification && s.errorMessage != null) return true;
        return false;
      });
      expect((emitted as Step2Verification).errorMessage, isNotEmpty);
    });
  });

  // ── Step 2 Skip ────────────────────────────────────────────────────────

  group('Step2Skip', () {
    setUp(() async {
      // Transition to Step2 first
      bloc.add(const Step1NameChanged('Farm'));
      bloc.add(const Step1AddressChanged('Address'));
      bloc.add(const Step1ProduceTypesChanged(['Rice']));
      bloc.add(const Step1Next());
      await bloc.stream.firstWhere((s) => s is Step2Verification);
    });

    test('emits OnboardingCompleted', () async {
      bloc.add(const Step2Skip());

      final emitted = await bloc.stream
          .firstWhere((s) => s is OnboardingCompleted);
      expect(emitted, isA<OnboardingCompleted>());
    });

    test('calls skipVerification and updates profile', () async {
      bloc.add(const Step2Skip());

      await bloc.stream
          .firstWhere((s) => s is OnboardingCompleted);

      verify(() => farmService.skipVerification(any())).called(1);
    });
  });

  // ── Full flow ──────────────────────────────────────────────────────────

  group('full flow', () {
    test('Initial → Step1Next → Step2Verification → Step2Submit → Completed',
        () async {
      bloc.add(const Step1NameChanged('Green Valley Farm'));
      bloc.add(const Step1AddressChanged('General Trias'));
      bloc.add(const Step1ProduceTypesChanged(['Lettuce']));
      bloc.add(const Step1Next());

      await bloc.stream.firstWhere((s) => s is Step2Verification);
      expect(bloc.state, isA<Step2Verification>());

      bloc.add(Step2DocumentSelected(File('/dev/null'), 'dti'));
      bloc.add(const Step2Submit());

      final emitted = await bloc.stream
          .firstWhere((s) => s is OnboardingCompleted);
      expect(emitted, isA<OnboardingCompleted>());
    });

    test('Initial → Step1Next → Step2Verification → Step2Skip → Completed',
        () async {
      bloc.add(const Step1NameChanged('Green Valley Farm'));
      bloc.add(const Step1AddressChanged('General Trias'));
      bloc.add(const Step1ProduceTypesChanged(['Lettuce']));
      bloc.add(const Step1Next());

      await bloc.stream.firstWhere((s) => s is Step2Verification);
      expect(bloc.state, isA<Step2Verification>());

      bloc.add(const Step2Skip());

      final emitted = await bloc.stream
          .firstWhere((s) => s is OnboardingCompleted);
      expect(emitted, isA<OnboardingCompleted>());
    });
  });

  // ── OnboardingReset ────────────────────────────────────────────────────

  test('OnboardingReset returns to OnboardingInitial', () async {
    bloc.add(const Step1NameChanged('Farm'));
    bloc.add(const Step1Next());
    bloc.add(const OnboardingReset());

    final emitted = await bloc.stream
        .firstWhere((s) => s is OnboardingInitial);
    expect(emitted, const OnboardingInitial());
  });
}
