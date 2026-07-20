import 'package:flutter/material.dart';
import 'package:hydrodok/src/widget/custom_text_field.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/body_text.dart';
import '../../widget/body_text_large.dart';
import '../../widget/body_text_small.dart';

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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: BodyTextLarge(
          'Farm Settings',
          color: ColorUtils.darkText,
        ),
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
            BodyTextLarge(
              'Operational Status',
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
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
                    activeTrackColor: ColorUtils.sageGreen,
                    activeThumbColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.store, color: ColorUtils.forestGreen),
                    title: BodyText(
                      'Accepting Customer Orders',
                      fontWeight: FontWeight.w500,
                    ),
                    subtitle: BodyTextSmall(
                      'Allow buyers to place direct orders for your produce',
                      color: Colors.grey.shade600,
                    ),
                    value: _isAcceptingOrders,
                    onChanged: (val) => setState(() => _isAcceptingOrders = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: ColorUtils.sageGreen,
                    activeThumbColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.users, color: ColorUtils.forestGreen),
                    title: BodyText(
                      'Auto-Suggest Batch Pooling',
                      fontWeight: FontWeight.w500,
                    ),
                    subtitle: BodyTextSmall(
                      'Automatically recommend relevant batch pooling campaigns',
                      color: Colors.grey.shade600,
                    ),
                    value: _autoJoinPooling,
                    onChanged: (val) => setState(() => _autoJoinPooling = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Notifications Preferences ──────────────────────────────────
            BodyTextLarge(
              'Notifications & Alerts',
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
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
                    activeTrackColor: ColorUtils.sageGreen,
                    activeThumbColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.bell, color: ColorUtils.forestGreen),
                    title: BodyText(
                      'New Order Alerts',
                      fontWeight: FontWeight.w500,
                    ),
                    subtitle: BodyTextSmall(
                      'Receive instant notifications when customers buy produce',
                      color: Colors.grey.shade600,
                    ),
                    value: _orderNotifications,
                    onChanged: (val) => setState(() => _orderNotifications = val),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    activeTrackColor: ColorUtils.sageGreen,
                    activeThumbColor: ColorUtils.forestGreen,
                    secondary: const Icon(LucideIcons.droplets, color: ColorUtils.forestGreen),
                    title: BodyText(
                      'Water & System Alerts',
                      fontWeight: FontWeight.w500,
                    ),
                    subtitle: BodyTextSmall(
                      'Get notified of maintenance schedules and nutrient logs',
                      color: Colors.grey.shade600,
                    ),
                    value: _waterQualityAlerts,
                    onChanged: (val) => setState(() => _waterQualityAlerts = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── GCash / Payout Details ──────────────────────────────────────
            BodyTextLarge(
              'Produce Sales Payout Account',
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
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
                    children: [
                      const Icon(LucideIcons.wallet, color: ColorUtils.forestGreen),
                      const SizedBox(width: 8),
                      BodyTextLarge(
                        'GCash Payout Details',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: ColorUtils.darkText,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  CustomTextField(label: 'GCash Name', controller: _gcashNameController),
                  const SizedBox(height: 12),
                  CustomTextField(label: 'GCash Number', controller: _gcashNumberController)
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
                child: BodyText(
                  'Save Settings',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}