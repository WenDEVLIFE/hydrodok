import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFarmer = true; // true = Farmer, false = Consumer

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Title ────────────────────────────────────────────
                Text(
                  'My Profile',
                  style: AppTypography.heading3(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Profile card ─────────────────────────────────────
                _buildProfileCard(),
                const SizedBox(height: 24),

                // ── Account mode toggle ──────────────────────────────
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

                // ── Stats row ────────────────────────────────────────
                _buildStatsRow(),
                const SizedBox(height: 24),

                // ── Menu items ───────────────────────────────────────
                _buildMenuItem(
                  title: 'My Farm Listings',
                  subtitle: '3 products listed',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Profile card ─────────────────────────────────────────────────────────

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
          // Avatar with initials
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFFE8A020), // warm orange
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              'MA',
              style: AppTypography.heading4(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Name, location, rating
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MakMak Augh',
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Taal, Calabarzon, PH',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    ...List.generate(
                      5,
                      (_) => const Icon(
                        Icons.star,
                        size: 16,
                        color: Color(0xFFE8A020),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '5.0',
                      style: AppTypography.bodySmall(
                        color: ColorUtils.darkText,
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

  // ── Account mode toggle ──────────────────────────────────────────────────

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

  // ── Stats row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(value: '3', label: 'Active Listings'),
        const SizedBox(width: 10),
        _buildStatCard(value: '128', label: 'Orders Fulfilled'),
        const SizedBox(width: 10),
        _buildStatCard(value: '5.0', label: 'Rating'),
      ],
    );
  }

  Widget _buildStatCard({required String value, required String label}) {
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

  // ── Menu items ───────────────────────────────────────────────────────────

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
