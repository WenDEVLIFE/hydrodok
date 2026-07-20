import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

/// Farm Operational Configuration & Payout Settings Screen for Farmers
class FarmSettingsScreen extends StatefulWidget {
  const FarmSettingsScreen({super.key});

  @override
  State<FarmSettingsScreen> createState() => _FarmSettingsScreenState();
}

class _FarmSettingsScreenState extends State<FarmSettingsScreen> {
  bool _isAcceptingOrders = true;
  bool _autoJoinPooling = false;
  bool _orderNotifications = true;
  bool _waterQualityAlerts = true;

  final _gcashNumberController = TextEditingController(text: '0917 123 4567');
  final _gcashNameController = TextEditingController(text: 'Juan De La Cruz');

  @override
  void dispose() {
    _gcashNumberController.dispose();
    _gcashNameController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Farm operational settings saved!'),
        backgroundColor: ColorUtils.forestGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text('Farm Settings', style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Operational Status ─────────────────────────────────────────
            Text('Operational Status', style: AppTypography.heading3(color: ColorUtils.darkText)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.store, color: ColorUtils.forestGreen),
                    title: const Text('Accepting Customer Orders'),
                    subtitle: const Text('Allow buyers to place direct orders for your produce'),
                    value: _isAcceptingOrders,
                    onChanged: (val) => setState(() => _isAcceptingOrders = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.users, color: ColorUtils.forestGreen),
                    title: const Text('Auto-Suggest Batch Pooling'),
                    subtitle: const Text('Automatically recommend relevant batch pooling campaigns'),
                    value: _autoJoinPooling,
                    onChanged: (val) => setState(() => _autoJoinPooling = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Notifications Preferences ──────────────────────────────────
            Text('Notifications & Alerts', style: AppTypography.heading3(color: ColorUtils.darkText)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    activeColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.bell, color: ColorUtils.forestGreen),
                    title: const Text('New Order Alerts'),
                    subtitle: const Text('Receive instant notifications when customers buy produce'),
                    value: _orderNotifications,
                    onChanged: (val) => setState(() => _orderNotifications = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.droplets, color: ColorUtils.forestGreen),
                    title: const Text('Water & System Alerts'),
                    subtitle: const Text('Get notified of maintenance schedules and nutrient logs'),
                    value: _waterQualityAlerts,
                    onChanged: (val) => setState(() => _waterQualityAlerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── GCash / Payout Details ──────────────────────────────────────
            Text('Produce Sales Payout Account', style: AppTypography.heading3(color: ColorUtils.darkText)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(LucideIcons.wallet, color: ColorUtils.forestGreen),
                      SizedBox(width: 8),
                      Text(
                        'GCash Payout Details',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gcashNameController,
                    decoration: const InputDecoration(
                      labelText: 'Account Holder Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _gcashNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'GCash Number',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Save Button ────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.forestGreen,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _saveSettings,
                child: const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
