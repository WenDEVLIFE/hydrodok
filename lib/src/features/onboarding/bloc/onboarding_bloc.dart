import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/service/farm_service.dart';
import 'onboarding_event.dart';
import 'onboarding_state.dart';

/// Manages the 2-step farmer onboarding wizard:
///
/// 1. **Step 1 — Farm Profile**: validates required fields (name, address,
///    produce types), accepts coordinates from map picker, optionally uploads
///    a farm photo, updates the `farms` table, and transitions to Step 2.
/// 2. **Step 2 — Verification**: optionally uploads a verification document;
///    the farmer may skip. On submit or skip, sets
///    `profiles.onboarding_completed = true` and emits [OnboardingCompleted].
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final FarmService _farmService;
  final SupabaseClient _supabaseClient;
  final String _ownerId;

  OnboardingBloc({
    required FarmService farmService,
    required SupabaseClient supabaseClient,
    String? ownerId,
  })  : _farmService = farmService,
        _supabaseClient = supabaseClient,
        _ownerId = ownerId ?? '',
        super(const OnboardingInitial()) {
    on<Step1Next>(_onStep1Next);
    on<Step1NameChanged>(_onStep1NameChanged);
    on<Step1AddressChanged>(_onStep1AddressChanged);
    on<Step1CoordinatesChanged>(_onStep1CoordinatesChanged);
    on<Step1ProduceTypesChanged>(_onStep1ProduceTypesChanged);
    on<Step1DescriptionChanged>(_onStep1DescriptionChanged);
    on<Step1FarmPhotoSelected>(_onStep1FarmPhotoSelected);
    on<Step2Submit>(_onStep2Submit);
    on<Step2Skip>(_onStep2Skip);
    on<Step2DocumentSelected>(_onStep2DocumentSelected);
    on<OnboardingReset>(_onReset);
  }

  // ── Step 1 field changes ──────────────────────────────────────────────

  void _onStep1NameChanged(Step1NameChanged event, Emitter<OnboardingState> emit) {
    if (state is Step1FarmProfile) {
      emit((state as Step1FarmProfile).copyWith(name: event.name));
    } else {
      emit(Step1FarmProfile(name: event.name));
    }
  }

  void _onStep1AddressChanged(Step1AddressChanged event, Emitter<OnboardingState> emit) {
    if (state is Step1FarmProfile) {
      emit((state as Step1FarmProfile).copyWith(address: event.address));
    } else {
      emit(Step1FarmProfile(address: event.address));
    }
  }

  void _onStep1CoordinatesChanged(
      Step1CoordinatesChanged event, Emitter<OnboardingState> emit) {
    if (state is Step1FarmProfile) {
      emit((state as Step1FarmProfile).copyWith(
        latitude: event.latitude,
        longitude: event.longitude,
      ));
    } else {
      emit(Step1FarmProfile(
        latitude: event.latitude,
        longitude: event.longitude,
      ));
    }
  }

  void _onStep1ProduceTypesChanged(
      Step1ProduceTypesChanged event, Emitter<OnboardingState> emit) {
    if (state is Step1FarmProfile) {
      emit((state as Step1FarmProfile).copyWith(produceTypes: event.produceTypes));
    } else {
      emit(Step1FarmProfile(produceTypes: event.produceTypes));
    }
  }

  void _onStep1DescriptionChanged(
      Step1DescriptionChanged event, Emitter<OnboardingState> emit) {
    if (state is Step1FarmProfile) {
      emit((state as Step1FarmProfile).copyWith(description: event.description));
    } else {
      emit(Step1FarmProfile(description: event.description));
    }
  }

  void _onStep1FarmPhotoSelected(
      Step1FarmPhotoSelected event, Emitter<OnboardingState> emit) {
    if (state is Step1FarmProfile) {
      emit((state as Step1FarmProfile).copyWith(farmPhotoFile: event.photo));
    } else {
      emit(Step1FarmProfile(farmPhotoFile: event.photo));
    }
  }

  // ── Step 1 → Step 2 transition ─────────────────────────────────────────

  Future<void> _onStep1Next(Step1Next event, Emitter<OnboardingState> emit) async {
    final current = state is Step1FarmProfile
        ? state as Step1FarmProfile
        : const Step1FarmProfile();

    // Validate required fields
    if (current.name.trim().isEmpty) {
      emit(current.copyWith(
        errorMessage: 'Farm name is required',
        clearError: false,
      ));
      return;
    }
    if (current.address.trim().isEmpty) {
      emit(current.copyWith(
        errorMessage: 'Farm address is required',
        clearError: false,
      ));
      return;
    }
    if (current.produceTypes.isEmpty) {
      emit(current.copyWith(
        errorMessage: 'Select at least one produce type',
        clearError: false,
      ));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      String? photoUrl;
      if (current.farmPhotoFile != null) {
        photoUrl = await _farmService.uploadFarmPhoto(
          _ownerId,
          current.farmPhotoFile!,
        );
      }

      // Farm is created here during onboarding (no longer in registration)
      await _farmService.createFarm(
        ownerId: _ownerId,
        farmName: current.name,
        address: current.address,
        produceTypes: current.produceTypes,
        description: current.description.isNotEmpty ? current.description : null,
        photoUrl: photoUrl,
      );

      emit(const Step2Verification());
    } catch (e) {
      debugPrint('OnboardingBloc Step1Next error: $e');
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Step 2 document ────────────────────────────────────────────────────

  void _onStep2DocumentSelected(
      Step2DocumentSelected event, Emitter<OnboardingState> emit) {
    if (state is Step2Verification) {
      emit((state as Step2Verification).copyWith(
        documentFile: event.doc,
        docType: event.docType,
      ));
    }
  }

  // ── Step 2 Submit ──────────────────────────────────────────────────────

  Future<void> _onStep2Submit(Step2Submit event, Emitter<OnboardingState> emit) async {
    if (state is! Step2Verification) return;

    final current = state as Step2Verification;

    if (current.documentFile == null) {
      emit(current.copyWith(
        errorMessage: 'Please attach a verification document',
      ));
      return;
    }

    emit(current.copyWith(isSubmitting: true, clearError: true));

    try {
      await _farmService.submitVerification(
        _ownerId,
        current.documentFile!,
        current.docType.isNotEmpty ? current.docType : 'document',
      );

      await _completeOnboarding(emit);
    } catch (e) {
      debugPrint('OnboardingBloc Step2Submit error: $e');
      emit(current.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Step 2 Skip ────────────────────────────────────────────────────────

  Future<void> _onStep2Skip(Step2Skip event, Emitter<OnboardingState> emit) async {
    if (state is! Step2Verification) return;

    emit((state as Step2Verification).copyWith(isSubmitting: true));

    try {
      await _farmService.skipVerification(_ownerId);
      await _completeOnboarding(emit);
    } catch (e) {
      debugPrint('OnboardingBloc Step2Skip error: $e');
      emit((state as Step2Verification).copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      ));
    }
  }

  // ── Reset ─────────────────────────────────────────────────────────────

  void _onReset(OnboardingReset event, Emitter<OnboardingState> emit) {
    emit(const OnboardingInitial());
  }

  // ── Shared completion ─────────────────────────────────────────────────

  /// Sets `profiles.onboarding_completed = true` and emits [OnboardingCompleted].
  Future<void> _completeOnboarding(Emitter<OnboardingState> emit) async {
    await _supabaseClient.from('profiles').update({
      'onboarding_completed': true,
    }).eq('id', _ownerId);

    emit(const OnboardingCompleted());
  }
}
