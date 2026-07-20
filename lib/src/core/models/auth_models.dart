/// The two user roles supported by the app.
enum UserRole { farmer, consumer }

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

  const SignUpData({
    required this.name,
    required this.email,
    required this.contactNumber,
    required this.password,
    required this.role,
  });
}
