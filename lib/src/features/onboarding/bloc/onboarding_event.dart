import 'dart:io';

/// Events that drive the farmer onboarding state machine.
sealed class OnboardingEvent {
  const OnboardingEvent();
}

/// The user taps "Continue" on Step 1 (Farm Profile).
/// Validates required fields, uploads photo, updates farm, transitions to Step 2.
final class Step1Next extends OnboardingEvent {
  const Step1Next();
}

// ── Step 1 field changes ─────────────────────────────────────────────────

final class Step1NameChanged extends OnboardingEvent {
  final String name;
  const Step1NameChanged(this.name);
}

final class Step1AddressChanged extends OnboardingEvent {
  final String address;
  const Step1AddressChanged(this.address);
}

final class Step1CoordinatesChanged extends OnboardingEvent {
  final double latitude;
  final double longitude;
  const Step1CoordinatesChanged(this.latitude, this.longitude);
}

final class Step1ProduceTypesChanged extends OnboardingEvent {
  final List<String> produceTypes;
  const Step1ProduceTypesChanged(this.produceTypes);
}

final class Step1DescriptionChanged extends OnboardingEvent {
  final String description;
  const Step1DescriptionChanged(this.description);
}

final class Step1FarmPhotoSelected extends OnboardingEvent {
  final File photo;
  const Step1FarmPhotoSelected(this.photo);
}

// ── Step 2 actions ───────────────────────────────────────────────────────

/// The user taps "Submit" on Step 2 (Verification).
final class Step2Submit extends OnboardingEvent {
  const Step2Submit();
}

/// The user taps "Skip" on Step 2.
final class Step2Skip extends OnboardingEvent {
  const Step2Skip();
}

final class Step2DocumentSelected extends OnboardingEvent {
  final File doc;
  final String docType;
  const Step2DocumentSelected(this.doc, this.docType);
}

/// Resets the onboarding back to the initial state.
final class OnboardingReset extends OnboardingEvent {
  const OnboardingReset();
}
