class UserSession {
  final String uid;
  final String email;
  final String fullName;
  final String phoneNumber;
  final String role;
  final String profileImageUrl;
  final String farmName;
  final String farmAddress;
  final List<String> farmProduceTypes;
  final bool onboardingCompleted;

  UserSession({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.phoneNumber,
    required this.role,
    required this.profileImageUrl,
    required this.farmName,
    required this.farmAddress,
    required this.farmProduceTypes,
    this.onboardingCompleted = true,
  });

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phoneNumber: json['contact_number'] as String? ?? '',
      role: json['role'] as String? ?? '',
      profileImageUrl: json['avatar_url'] as String? ?? '',
      farmName: json['farm_name'] as String? ?? '',
      farmAddress: json['farm_address'] as String? ?? '',
      farmProduceTypes: (json['produce_types'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      onboardingCompleted: json['onboarding_completed'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'full_name': fullName,
      'contact_number': phoneNumber,
      'role': role,
      'avatar_url': profileImageUrl,
      'farm_name': farmName,
      'farm_address': farmAddress,
      'produce_types': farmProduceTypes,
      'onboarding_completed': onboardingCompleted,
    };
  }
}