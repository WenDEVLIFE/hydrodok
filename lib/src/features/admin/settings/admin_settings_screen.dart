import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/service/admin_settings_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late final AdminSettingsService _service;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCreatingAdmin = false;

  PlatformSettings? _settings;
  List<Map<String, dynamic>> _adminProfiles = [];

  final _emailController = TextEditingController();
  final _maxListingsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _service = AdminSettingsService(supabase: Supabase.instance.client);
    _loadSettings();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _maxListingsController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getSettings();
      final admins = await _service.getAdminProfiles();

      if (!mounted) return;
      setState(() {
        _settings = settings;
        _adminProfiles = admins;
        _emailController.text = settings.adminContactEmail;
        _maxListingsController.text = settings.maxListingsPerFarmer.toString();
      });
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error loading settings: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    final current = _settings;
    if (current == null) return;

    final maxListings = int.tryParse(_maxListingsController.text.trim());
    if (maxListings == null || maxListings < 1) {
      _showSnackBar('Please enter a valid number for max listings', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = current.copyWith(
        maintenanceMode: _maintenanceMode,
        requireFarmVerification: _requireFarmVerification,
        enableAutoMod: _enableAutoMod,
        emailNotifications: _emailNotifications,
        adminContactEmail: _emailController.text.trim(),
        maxListingsPerFarmer: maxListings,
      );

      await _service.saveSettings(updated);

      if (!mounted) return;
      _showSnackBar('Settings saved successfully!');
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error saving settings: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _createAdminUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    setState(() => _isCreatingAdmin = true);
    try {
      await _service.createAdminUser(
        email: email,
        password: password,
        fullName: fullName,
      );

      if (!mounted) return;
      _showSnackBar('Admin team member added successfully!');
      await _refreshAdminProfiles();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Error creating admin user: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isCreatingAdmin = false);
    }
  }

  Future<void> _refreshAdminProfiles() async {
    try {
      final admins = await _service.getAdminProfiles();
      if (mounted) setState(() => _adminProfiles = admins);
    } catch (e) {
      if (mounted) _showSnackBar('Error refreshing admin list: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFD84040) : ColorUtils.forestGreen,
      ),
    );
  }

  bool get _maintenanceMode => _settings?.maintenanceMode ?? false;
  bool get _requireFarmVerification => _settings?.requireFarmVerification ?? true;
  bool get _enableAutoMod => _settings?.enableAutoMod ?? true;
  bool get _emailNotifications => _settings?.emailNotifications ?? true;

  void _setMaintenanceMode(bool value) =>
      setState(() => _settings = _settings?.copyWith(maintenanceMode: value));
  void _setRequireFarmVerification(bool value) =>
      setState(() => _settings = _settings?.copyWith(requireFarmVerification: value));
  void _setEnableAutoMod(bool value) =>
      setState(() => _settings = _settings?.copyWith(enableAutoMod: value));
  void _setEmailNotifications(bool value) =>
      setState(() => _settings = _settings?.copyWith(emailNotifications: value));

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    }

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
                  onPressed: _isSaving ? null : _saveSettings,
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
                  icon: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.save, size: 18),
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
                  onChanged: _setMaintenanceMode,
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
                  subtitle:
                      'Receive instant email alerts on high-priority issue reports',
                  value: _emailNotifications,
                  onChanged: _setEmailNotifications,
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
                  onChanged: _setRequireFarmVerification,
                ),
                const Divider(height: 24),
                _buildSwitchTile(
                  title: 'Automated Forum Spam Filter',
                  subtitle:
                      'Auto-flag community posts containing unverified external payment links',
                  value: _enableAutoMod,
                  onChanged: _setEnableAutoMod,
                ),
                const Divider(height: 24),
                _buildTextFieldTile(
                  title: 'Max Product Listings Per Farmer',
                  subtitle:
                      'Maximum active produce listings allowed per verified farmer account',
                  controller: _maxListingsController,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Section 3: Admin Access Control ────────────────────────
            _buildSectionCard(
              title: 'Admin Access Control & Team',
              icon: LucideIcons.users,
              children: [
                ..._adminProfiles.asMap().entries.expand((entry) {
                  final profile = entry.value;
                  final adminId = profile['id'] as String? ?? '';
                  final name = profile['full_name'] as String? ?? 'Unnamed Admin';
                  final email = profile['email'] as String? ??
                      profile['phone'] as String? ??
                      'No email';
                  return [
                    _buildAdminUserItem(
                      adminId: adminId,
                      name: name,
                      email: email,
                      role: 'Admin',
                      initials: _initialsFor(name),
                      onDelete: () => _deleteAdminAccount(adminId, name),
                    ),
                    if (entry.key < _adminProfiles.length - 1)
                      const Divider(height: 20),
                  ];
                }),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _isCreatingAdmin ? null : _showAddAdminDialog,
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
                  icon: _isCreatingAdmin
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(LucideIcons.userPlus, size: 16),
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

  Future<void> _showAddAdminDialog() async {
    final emailController = TextEditingController();
    final fullNameController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Add Admin Team Member',
            style: AppTypography.subtitle1(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: fullNameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                    validator: (value) =>
                        value == null || value.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Required';
                      }
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Temporary Password',
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'At least 6 characters';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _createAdminUser(
        email: emailController.text.trim(),
        password: passwordController.text,
        fullName: fullNameController.text.trim(),
      );
    }

    emailController.dispose();
    fullNameController.dispose();
    passwordController.dispose();
  }

  String _initialsFor(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'A';
    final first = parts.first[0].toUpperCase();
    if (parts.length > 1 && parts.last.isNotEmpty) {
      return '$first${parts.last[0].toUpperCase()}';
    }
    return first;
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
    TextInputType? keyboardType,
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
            keyboardType: keyboardType,
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

  Future<void> _deleteAdminAccount(String adminId, String adminName) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (adminId == currentUserId) {
      _showSnackBar('You cannot delete your own account while logged in.', isError: true);
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Admin Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the admin account for "$adminName"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Admin Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteUserAccount(adminId);
        if (mounted) {
          _showSnackBar('Admin account deleted successfully.');
          _refreshAdminProfiles();
        }
      } catch (e) {
        if (mounted) {
          _showSnackBar('Failed to delete admin account: $e', isError: true);
        }
      }
    }
  }

  Widget _buildAdminUserItem({
    required String adminId,
    required String name,
    required String email,
    required String role,
    required String initials,
    required VoidCallback onDelete,
  }) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isSelf = adminId == currentUserId;

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
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
            LucideIcons.trash2,
            size: 18,
            color: isSelf ? Colors.grey.shade400 : Colors.red,
          ),
          tooltip: isSelf ? 'Cannot delete your own account' : 'Delete admin account',
          onPressed: isSelf ? null : onDelete,
        ),
      ],
    );
  }
}
