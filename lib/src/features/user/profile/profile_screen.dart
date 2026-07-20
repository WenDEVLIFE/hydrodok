import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/repositories/auth_repository.dart';
import '../../../core/model/user_session.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import '../../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserSession? _session;
  bool _isLoading = true;
  bool _isFarmer = false;
  String _initials = '';
  String _displayName = '';
  String _location = '';

  @override
  void initState() {
    super.initState();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final session = await authRepo.getCurrentSession();
      if (session != null && mounted) {
        setState(() {
          _session = session;
          _isFarmer = session.role == 'farmer';
          _isLoading = false;
          _displayName = session.fullName.isNotEmpty
              ? session.fullName
              : 'Unknown User';
          _location = session.farmAddress.isNotEmpty
              ? session.farmAddress
              : 'Location not set';
          _initials = _buildInitials(session.fullName);
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ─────────────────────────────────────
                      Text(
                        'My Profile',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Profile card (realtime) ───────────────────
                      _buildProfileCard(),
                      const SizedBox(height: 24),

                      // ── Account mode toggle ───────────────────────
                      Text(
                        'Account Mode',
                        style: AppTypography.subtitle1(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAccountModeToggle(),
                      const SizedBox(height: 8),
                      Text(
                        _isFarmer
                            ? "Switch anytime — you're currently browsing as a Farmer (seller)"
                            : "Switch anytime — you're currently browsing as a Consumer (buyer)",
                        style: AppTypography.bodySmall(
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Stats row (static) ────────────────────────
                      _buildStatsRow(),
                      const SizedBox(height: 24),

                      // ── Menu items (static) ───────────────────────
                      _buildMenuItem(
                        title: _isFarmer ? 'My Farm Listings' : 'My Orders',
                        subtitle: _isFarmer ? '3 products listed' : '12 orders',
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Batch Pooling Requests',
                        subtitle: '1 active request',
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Issue Reports',
                        subtitle: 'Report a problem to Admin',
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Order History',
                        subtitle: '128 completed orders',
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Settings',
                        subtitle: 'Notifications, privacy, help',
                      ),
                      const SizedBox(height: 20),

                      // ── Logout Button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleLogout(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD84040)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(
                            LucideIcons.logOut,
                            color: Color(0xFFD84040),
                            size: 18,
                          ),
                          label: Text(
                            'Log Out',
                            style: AppTypography.button(
                              color: const Color(0xFFD84040),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content:
            const Text('Are you sure you want to log out of HydroDok?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Log Out',
              style: TextStyle(color: Color(0xFFD84040)),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.signOut();
    } catch (_) {}

    if (!context.mounted) return;

    final authRepo = context.read<AuthRepository>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => LoginScreen(
          authRepository: authRepo,
        ),
      ),
      (route) => false,
    );
  }

  // ── Profile card (realtime from session) ────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorUtils.sageGreen.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Avatar with initials from session
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: ColorUtils.forestGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: AppTypography.heading4(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _displayName,
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                if (_isFarmer && _session?.farmName != null &&
                    _session!.farmName.isNotEmpty) ...[
                  Text(
                    _session!.farmName,
                    style: AppTypography.bodySmall(
                      color: ColorUtils.forestGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${_session?.email ?? ''}',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle,
                        size: 10,
                        color: _isFarmer
                            ? ColorUtils.forestGreen
                            : Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _isFarmer ? 'Farmer' : 'Consumer',
                      style: AppTypography.bodySmall(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Account mode toggle ─────────────────────────────────────────────────

  Widget _buildAccountModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(32),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildToggleOption(
            icon: LucideIcons.diamond,
            label: 'Farmer',
            isActive: _isFarmer,
            onTap: () => setState(() => _isFarmer = true),
          ),
          _buildToggleOption(
            icon: LucideIcons.monitor,
            label: 'Consumer',
            isActive: !_isFarmer,
            onTap: () => setState(() => _isFarmer = false),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? ColorUtils.forestGreen : Colors.transparent,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.bodyMedium(
                  color: isActive ? Colors.white : Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats row (static) ──────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          value: _isFarmer ? '3' : '12',
          label: _isFarmer ? 'Active Listings' : 'Orders',
        ),
        const SizedBox(width: 10),
        _buildStatCard(value: '128', label: 'Orders Fulfilled'),
        const SizedBox(width: 10),
        _buildStatCard(value: '5.0', label: 'Rating'),
      ],
    );
  }

  Widget _buildStatCard(
      {required String value, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.heading4(
                color: ColorUtils.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.caption(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Menu items (static) ─────────────────────────────────────────────────

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.subtitle2(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            LucideIcons.chevronRight,
            size: 20,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }
}
