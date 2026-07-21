import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/model/user_session.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../login/login_screen.dart';
import 'accounts/account_moderation_screen.dart';
import 'banner_manager/banner_manager_screen.dart';
import 'farms/farm_management_screen.dart';
import 'forum_moderation/forum_moderation_screen.dart';
import 'issue_reports/issue_reports_screen.dart';
import 'marketplace/marketplace_management_screen.dart';
import 'settings/admin_settings_screen.dart';

// ── Sidebar item model ─────────────────────────────────────────────────────

class _SidebarItem {
  final IconData icon;
  final String label;

  const _SidebarItem({required this.icon, required this.label});
}

const _sidebarItems = <_SidebarItem>[
  _SidebarItem(icon: LucideIcons.fileText, label: 'Issue Reports'),
  _SidebarItem(icon: LucideIcons.image, label: 'Banner Manager'),
  _SidebarItem(icon: LucideIcons.users, label: 'Accounts'),
  _SidebarItem(icon: LucideIcons.store, label: 'Marketplace'),
  _SidebarItem(icon: LucideIcons.sprout, label: 'Farms'),
  _SidebarItem(icon: LucideIcons.messageCircle, label: 'Forum Moderation'),
  _SidebarItem(icon: LucideIcons.settings, label: 'Settings'),
];

// ── Admin shell ─────────────────────────────────────────────────────────────

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  UserSession? _userSession;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
  }

  Future<void> _loadUserSession() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final session = await authRepo.getCurrentSession();
      if (mounted) {
        setState(() {
          _userSession = session;
        });
      }
    } catch (e) {
      debugPrint('Failed to load admin session: $e');
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Widget _buildContent() {
    switch (_currentIndex) {
      case 0:
        return const IssueReportsScreen();
      case 1:
        return const BannerManagerScreen();
      case 2:
        return const AccountModerationScreen();
      case 3:
        return const MarketplaceManagementScreen();
      case 4:
        return const FarmManagementScreen();
      case 5:
        return const ForumModerationScreen();
      case 6:
        return const AdminSettingsScreen();
      default:
        return Center(
          child: Text(
            _sidebarItems[_currentIndex].label,
            style: AppTypography.heading3(color: ColorUtils.darkText),
          ),
        );
    }
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
        body: Row(
          children: [
            // ── Sidebar ────────────────────────────────────────────────
            _buildSidebar(),

            // ── Content area ───────────────────────────────────────────
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sidebar ──────────────────────────────────────────────────────────────

  Widget _buildSidebar() {
    return Container(
      width: 240,
      color: ColorUtils.darkBackground,
      child: Column(
        children: [
          // Brand
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
            child: Row(
              children: [
                 Image.asset(
                  'assets/logo.png',
                  width: 36,
                  height: 36,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hydrodok',
                      style: AppTypography.subtitle1(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'ADMIN PANEL',
                      style: AppTypography.overline(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Nav items
          ...List.generate(_sidebarItems.length, (i) {
            final item = _sidebarItems[i];
            final isActive = _currentIndex == i;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = i),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? ColorUtils.forestGreen
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          item.icon,
                          size: 18,
                          color: isActive
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: AppTypography.bodySmall(
                            color: isActive
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                            fontWeight: isActive
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),

          const Spacer(),

          // Admin user card
          Builder(
            builder: (context) {
              final name = (_userSession?.fullName != null && _userSession!.fullName.isNotEmpty)
                  ? _userSession!.fullName
                  : 'Admin User';
              final email = (_userSession?.email != null && _userSession!.email.isNotEmpty)
                  ? _userSession!.email
                  : (_userSession?.role.isNotEmpty == true ? _userSession!.role : 'Admin');
              final initials = _getInitials(name);

              return Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorUtils.darkCard,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodySmall(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption(
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.logOut,
                        color: Color(0xFFD84040),
                        size: 18,
                      ),
                      tooltip: 'Log Out',
                      onPressed: () => _handleAdminLogout(context),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleAdminLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out Admin'),
        content: const Text('Are you sure you want to log out of the Admin Panel?'),
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
}
