/// The two user roles supported by the app.
enum UserRole { farmer, consumer }

/// Farmer-specific details collected during registration.
class FarmDetails {
  final String farmName;
  final String location;
  final String produceType;

  const FarmDetails({
    required this.farmName,
    required this.location,
    required this.produceType,
  });
}

/// All data needed to create a new user account.
///
/// Carried from the registration form through to the OTP verification step;
/// the actual account is created only after the OTP is verified.
class SignUpData {
  final String name;
  final String email;
  final String contactNumber;
  final String password;
  final UserRole role;
  final FarmDetails? farm;

  const SignUpData({
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.password,
    required this.role,
    this.farm,
  });
}
