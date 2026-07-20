import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
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
                  Text(
                    'Pamahalaang Hydro Greens',
                    style: AppTypography.bodySmall(color: Colors.grey.shade600),
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
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 600));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Farm Status & Verification Card ──────────────────────
                  _buildFarmStatusCard(),
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
                        value: '4 Crops',
                        subtitle: 'Lettuce, Spinach, Basil',
                        icon: LucideIcons.leaf,
                        color: ColorUtils.forestGreen,
                      ),
                      _buildMetricCard(
                        title: 'Water / pH Level',
                        value: '6.2 pH',
                        subtitle: 'EC: 1.8 mS/cm (Optimal)',
                        icon: LucideIcons.droplet,
                        color: const Color(0xFF64B5F6),
                      ),
                      _buildMetricCard(
                        title: 'Tasks Due Today',
                        value: '3 Pending',
                        subtitle: 'Nutrient refill, check pumps',
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
                    subtitle: 'System 1 - General Trias Unit',
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
                    title: 'Harvesting Batch #4 - Romaine',
                    subtitle: '25kg ready for pooling',
                    isDone: false,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
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

  // ── Farm Status Card ────────────────────────────────────────────────────

  Widget _buildFarmStatusCard() {
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
                  'Pamahalaang Hydro Greens',
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
                  color: ColorUtils.sageGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: ColorUtils.sageGreen),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.badgeCheck,
                        color: ColorUtils.sageGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Verified',
                      style: AppTypography.bodySmall(
                        color: ColorUtils.sageGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(LucideIcons.mapPin, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                'General Trias, Cavite',
                style: AppTypography.bodySmall(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Status: Optimal',
                style: AppTypography.bodyMedium(
                  color: ColorUtils.sageGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Last synced 5m ago',
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
    return NavigationBar(
      selectedIndex: _currentTabIndex,
      backgroundColor: Colors.white,
      indicatorColor: ColorUtils.forestGreen.withOpacity(0.1),
      onDestinationSelected: (index) {
        setState(() => _currentTabIndex = index);
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(LucideIcons.layoutDashboard, color: Colors.grey),
          selectedIcon: Icon(LucideIcons.layoutDashboard,
              color: ColorUtils.forestGreen),
          label: 'Dashboard',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.map, color: Colors.grey),
          selectedIcon: Icon(LucideIcons.map, color: ColorUtils.forestGreen),
          label: 'Map',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.messageSquare, color: Colors.grey),
          selectedIcon: Icon(LucideIcons.messageSquare,
              color: ColorUtils.forestGreen),
          label: 'Forum',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.users, color: Colors.grey),
          selectedIcon: Icon(LucideIcons.users, color: ColorUtils.forestGreen),
          label: 'Pooling',
        ),
        NavigationDestination(
          icon: Icon(LucideIcons.user, color: Colors.grey),
          selectedIcon: Icon(LucideIcons.user, color: ColorUtils.forestGreen),
          label: 'Profile',
        ),
      ],
    );
  }
}
