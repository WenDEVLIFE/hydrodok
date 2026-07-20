import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../onboarding/farm_map_picker_dialog.dart';
import '../user/forum/forum_screen.dart';
import '../user/map/map_screen.dart';
import '../user/pooling/pooling_screen.dart';
import '../user/profile/profile_screen.dart';

/// Central Dashboard for Hydroponic Farmers
///
/// Farm overview with real-time metrics, quick actions, and
/// today's maintenance schedule. Light theme consistent with
/// the rest of the app (Pooling, Forum, etc.).
class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({super.key});

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _currentTabIndex = 0;

  // ── Realtime stream ─────────────────────────────────────────────────────
  late final Stream<List<Map<String, dynamic>>> _farmStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // Realtime stream: auto-updates when admin approves/rejects
    _farmStream = Supabase.instance.client
        .from('farms')
        .stream(primaryKey: ['id'])
        .eq('owner_id', user.id);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentTabIndex != 0) {
      return Theme(
        data: _lightTheme,
        child: Scaffold(
          body: IndexedStack(
            index: _currentTabIndex - 1,
            children: const [
              MapScreen(),
              ForumScreen(),
              PoolingScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: _buildBottomNav(),
        ),
      );
    }

    return Theme(
      data: _lightTheme,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: ColorUtils.forestGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.sprout,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farmer Dashboard',
                    style: AppTypography.heading3(
                      color: ColorUtils.darkText,
                      fontSize: 18,
                    ),
                  ),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: _farmStream,
                    builder: (context, snapshot) {
                      final farm = snapshot.data?.isNotEmpty == true
                          ? snapshot.data!.first
                          : null;
                      return Text(
                        farm?['farm_name'] as String? ?? 'Loading...',
                        style: AppTypography.bodySmall(color: Colors.grey.shade600),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.bell, color: ColorUtils.darkText),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No new alerts')),
                );
              },
            ),
          ],
        ),
        body: StreamBuilder<List<Map<String, dynamic>>>(
          stream: _farmStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final farm = snapshot.data?.isNotEmpty == true
                ? snapshot.data!.first
                : null;
            final farmName = farm?['farm_name'] as String? ?? 'No Farm Registered';
            final farmAddress = farm?['address'] as String? ?? '';
            final verificationStatus = farm?['verification_status'] as String? ?? 'unverified';
            final types = farm?['produce_types'];
            final produceTypes = types is List ? types.cast<String>() : <String>[];

            return SafeArea(
              child: RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Farm Status & Verification Card ──────────────────────
                      _buildFarmStatusCard(
                        farmName: farmName,
                        farmAddress: farmAddress,
                        verificationStatus: verificationStatus,
                      ),
                      const SizedBox(height: 20),

                      // ── Key Farm Metrics Grid ─────────────────────────────────
                      Text(
                        'Farm Overview',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.4,
                        children: [
                          _buildMetricCard(
                            title: 'Active Batches',
                            value: '${produceTypes.length} Crops',
                            subtitle: produceTypes.isNotEmpty
                                ? produceTypes.join(', ')
                                : 'No crops registered',
                            icon: LucideIcons.leaf,
                            color: ColorUtils.forestGreen,
                          ),
                          _buildMetricCard(
                            title: 'Water / pH Level',
                            value: '—',
                            subtitle: 'Connect sensors to view data',
                            icon: LucideIcons.droplet,
                            color: const Color(0xFF64B5F6),
                          ),
                          _buildMetricCard(
                            title: 'Tasks Due Today',
                            value: '—',
                            subtitle: 'Task manager coming soon',
                            icon: LucideIcons.checkSquare,
                            color: ColorUtils.terracotta,
                          ),
                          _buildMetricCard(
                            title: 'Issue Alerts',
                            value: '0 Active',
                            subtitle: 'All systems operational',
                            icon: LucideIcons.shieldCheck,
                            color: const Color(0xFF81C784),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Quick Actions ────────────────────────────────────────
                      Text(
                        'Quick Actions',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildQuickActionButton(
                            label: 'Log Nutrients',
                            icon: LucideIcons.droplets,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Nutrient logging coming soon'),
                                ),
                              );
                            },
                          ),
                          _buildQuickActionButton(
                            label: 'Add Task',
                            icon: LucideIcons.calendarPlus,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Task manager coming soon'),
                                ),
                              );
                            },
                          ),
                          _buildQuickActionButton(
                            label: 'Report Issue',
                            icon: LucideIcons.alertTriangle,
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Issue reporter coming soon'),
                                ),
                              );
                            },
                          ),
                          _buildQuickActionButton(
                            label: 'Farm Map',
                            icon: LucideIcons.mapPin,
                            onTap: () {
                              setState(() => _currentTabIndex = 1);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Set Farm Location Button ──────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openMapPicker,
                          icon: const Icon(LucideIcons.mapPin, size: 18),
                          label: const Text('Set Farm Location on Map'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ColorUtils.forestGreen,
                            side: const BorderSide(color: ColorUtils.forestGreen),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Today's Maintenance Schedule ─────────────────────────
                      Text(
                        "Today's Maintenance Schedule",
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildScheduleTile(
                        time: '08:00 AM',
                        title: 'Reservoir pH & EC Test',
                        subtitle: 'Check water quality',
                        isDone: true,
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleTile(
                        time: '01:30 PM',
                        title: 'Nutrient Solution Top-up',
                        subtitle: 'Add Masterblend 4-18-38 Formula',
                        isDone: false,
                      ),
                      const SizedBox(height: 8),
                      _buildScheduleTile(
                        time: '05:00 PM',
                        title: 'End-of-Day Inspection',
                        subtitle: 'Walk through and check all systems',
                        isDone: false,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  // ── Light Theme ───────────────────────────────────────────────────────────

  ThemeData get _lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      );

  // ── Map Location Picker ────────────────────────────────────────────────

  Future<void> _openMapPicker() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final result = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute(
        builder: (_) => const FarmMapPickerDialog(),
      ),
    );

    if (result == null) return;

    // Save coordinates to the farm
    try {
      await Supabase.instance.client.from('farms').update({
        'latitude': result.latLng.latitude,
        'longitude': result.latLng.longitude,
        'address': result.address,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('owner_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm location updated!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    }
  }

  // ── Farm Status Card ────────────────────────────────────────────────────

  Widget _buildFarmStatusCard({
    required String farmName,
    required String farmAddress,
    required String verificationStatus,
  }) {
    // Determine status badge based on verification_status
    final (String statusLabel, Color statusColor, IconData statusIcon) =
        switch (verificationStatus) {
      'verified' => ('Verified', ColorUtils.sageGreen, LucideIcons.badgeCheck),
      'pending' => ('Pending', ColorUtils.terracotta, LucideIcons.clock),
      'rejected' => ('Rejected', Colors.red, LucideIcons.xCircle),
      _ => ('Unverified', Colors.grey, LucideIcons.badgeAlert),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: ColorUtils.mainGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  farmName,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.heading2(
                    color: ColorUtils.pureWhite,
                    fontSize: 20,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      statusLabel,
                      style: AppTypography.bodySmall(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (farmAddress.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    farmAddress,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                verificationStatus == 'verified'
                    ? 'System Status: Optimal'
                    : 'Verification: $statusLabel',
                style: AppTypography.bodyMedium(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last synced just now',
                style: AppTypography.bodySmall(color: Colors.white38),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Metric Card ─────────────────────────────────────────────────────────

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall(color: Colors.grey.shade600),
              ),
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.heading3(
                  color: ColorUtils.darkText,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Quick Action Button ─────────────────────────────────────────────────

  Widget _buildQuickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: ColorUtils.forestGreen.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(icon, color: ColorUtils.forestGreen, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTypography.bodySmall(
              color: ColorUtils.darkText,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ── Maintenance Schedule Tile ───────────────────────────────────────────

  Widget _buildScheduleTile({
    required String time,
    required String title,
    required String subtitle,
    required bool isDone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDone
              ? ColorUtils.sageGreen.withOpacity(0.5)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
            color: isDone ? ColorUtils.forestGreen : Colors.grey.shade300,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ).copyWith(
                    decoration: isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: AppTypography.bodySmall(
              color: ColorUtils.forestGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Navigation ──────────────────────────────────────────────────

  Widget _buildBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: ColorUtils.forestGreen,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, LucideIcons.layoutDashboard, 'Dashboard'),
          _buildNavItem(1, LucideIcons.map, 'Map'),
          _buildNavItem(2, LucideIcons.messageSquare, 'Forum'),
          _buildNavItem(3, LucideIcons.users, 'Pooling'),
          _buildNavItem(4, LucideIcons.user, 'Profile'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTabIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentTabIndex = index),
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                color: isSelected ? Colors.white : Colors.black, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
