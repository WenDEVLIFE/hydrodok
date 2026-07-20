import 'dart:io';

/// Possible states of the farmer onboarding lifecycle.
sealed class OnboardingState {
  const OnboardingState();
}

/// Just started — no step has been entered yet.
final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

/// Step 1: Farm Profile form.
final class Step1FarmProfile extends OnboardingState {
  final String name;
  final String address;
  final List<String> produceTypes;
  final String description;
  final File? farmPhotoFile;
  final bool isSubmitting;
  final String? errorMessage;

  const Step1FarmProfile({
    this.name = '',
    this.address = '',
    this.produceTypes = const [],
    this.description = '',
    this.farmPhotoFile,
    this.isSubmitting = false,
    this.errorMessage,
  });

  Step1FarmProfile copyWith({
    String? name,
    String? address,
    List<String>? produceTypes,
    String? description,
    File? farmPhotoFile,
    bool? isSubmitting,
    String? errorMessage,
    bool clearPhoto = false,
    bool clearError = false,
  }) {
    return Step1FarmProfile(
      name: name ?? this.name,
      address: address ?? this.address,
      produceTypes: produceTypes ?? this.produceTypes,
      description: description ?? this.description,
      farmPhotoFile: clearPhoto ? null : (farmPhotoFile ?? this.farmPhotoFile),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError
          ? null
          : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Step 2: Document verification.
final class Step2Verification extends OnboardingState {
  final File? documentFile;
  final String docType;
  final bool isSubmitting;
  final String? errorMessage;

  const Step2Verification({
    this.documentFile,
    this.docType = '',
    this.isSubmitting = false,
    this.errorMessage,
  });

  Step2Verification copyWith({
    File? documentFile,
    String? docType,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return Step2Verification(
      documentFile: documentFile ?? this.documentFile,
      docType: docType ?? this.docType,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Onboarding is complete — all steps finished successfully.
/// The UI should navigate to the FarmerDashboard on this state.
final class OnboardingCompleted extends OnboardingState {
  const OnboardingCompleted();
}
