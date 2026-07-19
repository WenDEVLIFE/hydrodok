import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  bool _maintenanceMode = false;
  bool _requireFarmVerification = true;
  bool _enableAutoMod = true;
  bool _emailNotifications = true;

  final _emailController =
      TextEditingController(text: 'admin@agriconnect.ph');
  final _maxListingsController = TextEditingController(text: '10');

  @override
  void dispose() {
    _emailController.dispose();
    _maxListingsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Settings',
                        style: AppTypography.heading2(
                          color: ColorUtils.darkText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'System configurations, platform parameters, and admin team access',
                        style: AppTypography.bodyMedium(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Settings saved successfully!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.forestGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(LucideIcons.save, size: 18),
                  label: Text(
                    'Save Changes',
                    style: AppTypography.button(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Section 1: System Configuration ───────────────────────
            _buildSectionCard(
              title: 'System & Platform Configuration',
              icon: LucideIcons.sliders,
              children: [
                _buildSwitchTile(
                  title: 'System Maintenance Mode',
                  subtitle:
                      'Temporarily disable user app logins for system maintenance',
                  value: _maintenanceMode,
                  onChanged: (v) => setState(() => _maintenanceMode = v),
                ),
                const Divider(height: 24),
                _buildTextFieldTile(
                  title: 'Admin Contact Email',
                  subtitle: 'Primary email for system alerts and notifications',
                  controller: _emailController,
                ),
                const Divider(height: 24),
                _buildSwitchTile(
                  title: 'Email Alert Notifications',
                  subtitle: 'Receive instant email alerts on high-priority issue reports',
                  value: _emailNotifications,
                  onChanged: (v) => setState(() => _emailNotifications = v),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 2: Verification & Moderation Rules ───────────
            _buildSectionCard(
              title: 'Verification & Moderation Controls',
              icon: LucideIcons.shieldCheck,
              children: [
                _buildSwitchTile(
                  title: 'Mandatory Farm Verification',
                  subtitle:
                      'Require admin farm approval before a farmer can post marketplace listings',
                  value: _requireFarmVerification,
                  onChanged: (v) =>
                      setState(() => _requireFarmVerification = v),
                ),
                const Divider(height: 24),
                _buildSwitchTile(
                  title: 'Automated Forum Spam Filter',
                  subtitle:
                      'Auto-flag community posts containing unverified external payment links',
                  value: _enableAutoMod,
                  onChanged: (v) => setState(() => _enableAutoMod = v),
                ),
                const Divider(height: 24),
                _buildTextFieldTile(
                  title: 'Max Product Listings Per Farmer',
                  subtitle:
                      'Maximum active produce listings allowed per verified farmer account',
                  controller: _maxListingsController,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 3: Admin Access Control ────────────────────────
            _buildSectionCard(
              title: 'Admin Access Control & Team',
              icon: LucideIcons.users,
              children: [
                _buildAdminUserItem(
                  name: 'Juan Dela Cruz',
                  email: 'juan.admin@agriconnect.ph',
                  role: 'Super Admin',
                  initials: 'JD',
                ),
                const Divider(height: 20),
                _buildAdminUserItem(
                  name: 'Maria Santos',
                  email: 'maria.office@agriconnect.ph',
                  role: 'Office Admin',
                  initials: 'MS',
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Invite new admin
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  icon: const Icon(LucideIcons.userPlus, size: 16),
                  label: Text(
                    'Add Admin Team Member',
                    style: AppTypography.button(
                      color: ColorUtils.darkText,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ────────────────────────────────────────────────────────

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: ColorUtils.forestGreen),
              const SizedBox(width: 10),
              Text(
                title,
                style: AppTypography.subtitle1(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeTrackColor: ColorUtils.forestGreen,
        ),
      ],
    );
  }

  Widget _buildTextFieldTile({
    required String title,
    required String subtitle,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 20),
        SizedBox(
          width: 220,
          child: TextField(
            controller: controller,
            style: AppTypography.bodySmall(color: ColorUtils.darkText),
            decoration: InputDecoration(
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminUserItem({
    required String name,
    required String email,
    required String role,
    required String initials,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: ColorUtils.forestGreen,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: AppTypography.caption(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: AppTypography.bodySmall(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                email,
                style: AppTypography.caption(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            role,
            style: AppTypography.caption(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}
