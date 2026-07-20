import 'package:flutter/material.dart';
import '../../core/model/user_session.dart';
import '../../widget/banner_popup.dart';
import '../admin/admin_shell.dart';
import '../farmer/farmer_dashboard_screen.dart';
import '../main_shell.dart';
import 'onboarding_screen.dart';

/// Route guard component that inspects the authenticated [UserSession].
///
/// Directs the user to the correct screen based on role and onboarding status:
/// - Admin → [AdminShell] (no banner popup — admins manage banners)
/// - Farmer with onboarding_completed == false → [OnboardingScreen]
/// - Farmer with onboarding_completed == true → [BannerPopup] wrapping [FarmerDashboardScreen]
/// - Consumer → [BannerPopup] wrapping [MainShell]
class OnboardingGate extends StatelessWidget {
  final UserSession session;

  const OnboardingGate({
    super.key,
    required this.session,
  });

  @override
  Widget build(BuildContext context) {
    if (session.role.toLowerCase() == 'admin') {
      return const AdminShell();
    }

    if (session.role.toLowerCase() == 'farmer') {
      if (!session.onboardingCompleted) {
        return OnboardingScreen(ownerId: session.uid);
      }
      return const BannerPopup(child: FarmerDashboardScreen());
    }

    // Default for consumer or unspecified roles
    return const BannerPopup(child: MainShell());
  }
}
