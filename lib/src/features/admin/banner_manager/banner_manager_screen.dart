import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

enum BannerStatus { live, scheduled, expired }

class AppBanner {
  final String id;
  final String title;
  final String content;
  final BannerStatus status;

  const AppBanner({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
  });
}

const _banners = <AppBanner>[
  AppBanner(
    id: '1',
    title: 'Farming Seminar Invite',
    content: '"Join Engineer John now for a seminar about farming"',
    status: BannerStatus.live,
  ),
  AppBanner(
    id: '2',
    title: 'Harvest Season Promo',
    content: '"20% off delivery fees this harvest season!"',
    status: BannerStatus.live,
  ),
  AppBanner(
    id: '3',
    title: 'New Feature: Batch Pooling',
    content: '"Try Batch Pooling to fulfill big orders together"',
    status: BannerStatus.scheduled,
  ),
  AppBanner(
    id: '4',
    title: 'Old Seminar Reminder',
    content: '"Reminder: seminar happens this weekend"',
    status: BannerStatus.expired,
  ),
];

// ── Screen Widget ──────────────────────────────────────────────────────────

class BannerManagerScreen extends StatefulWidget {
  const BannerManagerScreen({super.key});

  @override
  State<BannerManagerScreen> createState() => _BannerManagerScreenState();
}

class _BannerManagerScreenState extends State<BannerManagerScreen> {
  int _selectedIndex = 0;

  AppBanner get _selectedBanner => _banners[_selectedIndex];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
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
                      'Banner Manager',
                      style: AppTypography.heading2(
                        color: ColorUtils.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create pop-up banners shown when farmers/consumers open the app',
                      style: AppTypography.bodyMedium(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: New banner modal/form
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(
                  'New Banner',
                  style: AppTypography.button(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Main Content Area (List + Live Preview) ──────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Left Column: Banners List ─────────────────────────
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ACTIVE & SCHEDULED',
                        style: AppTypography.overline(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: _banners.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final banner = _banners[index];
                            final isSelected = _selectedIndex == index;

                            return _BannerCard(
                              banner: banner,
                              isSelected: isSelected,
                              onTap: () =>
                                  setState(() => _selectedIndex = index),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 40),

                // ── Right Column: Mobile Device Live Preview ───────────
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LIVE PREVIEW — APP POP-UP',
                        style: AppTypography.overline(
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: Center(
                          child: _buildPhoneFrame(_selectedBanner),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Phone Frame Widget ─────────────────────────────────────────────

  Widget _buildPhoneFrame(AppBanner banner) {
    return Container(
      width: 260,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: const Color(0xFFF2F7F2), // Light sage green app background
          child: Stack(
            children: [
              // Top App Header Placeholder
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: ColorUtils.sageGreen.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              // Centered Pop-up Modal Banner
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: ColorUtils.terracotta,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bell / Announcement Icon
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ColorUtils.terracotta.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          color: ColorUtils.terracotta,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Banner Text Content
                      Text(
                        banner.content.replaceAll('"', ''),
                        textAlign: TextAlign.center,
                        style: AppTypography.subtitle2(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // CTA Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorUtils.terracotta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: Text(
                            'Learn More',
                            style: AppTypography.button(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner Card Widget ─────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final AppBanner banner;
  final bool isSelected;
  final VoidCallback onTap;

  const _BannerCard({
    required this.banner,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorUtils.terracotta.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorUtils.terracotta : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Icon Box
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ColorUtils.terracotta.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.image,
                color: ColorUtils.terracotta,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner.title,
                    style: AppTypography.subtitle1(
                      color: ColorUtils.darkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner.content,
                    style: AppTypography.bodySmall(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Status Badge
            _buildStatusBadge(banner.status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BannerStatus status) {
    final (String label, Color bg) = switch (status) {
      BannerStatus.live => ('Live', ColorUtils.forestGreen),
      BannerStatus.scheduled => ('Scheduled', const Color(0xFF2979FF)),
      BannerStatus.expired => ('Expired', Colors.grey.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.caption(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
