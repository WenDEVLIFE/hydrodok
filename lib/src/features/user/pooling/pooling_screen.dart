import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
// ── Data ────────────────────────────────────────────────────────────────────

class PoolingRequest {
  final String initials;
  final String name;
  final String farmName;
  final String distance;
  final String need;

  const PoolingRequest({
    required this.initials,
    required this.name,
    required this.farmName,
    required this.distance,
    required this.need,
  });
}

const _helpRequests = <PoolingRequest>[
  PoolingRequest(
    initials: 'M',
    name: 'Mario Reyes',
    farmName: 'Mahogany Farm',
    distance: '1.2 km away',
    need: 'Needs 2,000 units tomatoes',
  ),
  PoolingRequest(
    initials: 'B',
    name: 'Ben Torres',
    farmName: 'Sta. Nino Urban Farm',
    distance: '3.5 km away',
    need: 'Needs 800 units bell pepper',
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class PoolingScreen extends StatelessWidget {
  const PoolingScreen({super.key});

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
                // ── Title ──────────────────────────────────────────────
                Text(
                  'Batch Pooling',
                  style: AppTypography.heading3(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Info banner ────────────────────────────────────────
                _buildInfoBanner(),
                const SizedBox(height: 24),

                // ── Active request ────────────────────────────────────
                Text(
                  'Your Active Request',
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActiveRequest(),
                const SizedBox(height: 28),

                // ── Help requests ─────────────────────────────────────
                Text(
                  'Requests You Can Help With',
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(_helpRequests.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < _helpRequests.length - 1 ? 10 : 0,
                    ),
                    child: _HelpRequestCard(request: _helpRequests[i]),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Info banner ──────────────────────────────────────────────────────────

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF90CAF9),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            LucideIcons.layoutGrid,
            color: const Color(0xFF2979FF),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Short on stock for a big order?',
                  style: AppTypography.subtitle2(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Request nearby farmers to pool their harvest so you can fulfill it together.',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Active request card ──────────────────────────────────────────────────

  Widget _buildActiveRequest() {
    const int needed = 15000;
    const int inStock = 10000;
    const int shortBy = needed - inStock;
    final double progress = inStock / needed;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ColorUtils.terracotta.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lettuce order: ${_fmt(needed)} units needed',
            style: AppTypography.subtitle2(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'You have ${_fmt(inStock)} in stock — short by ${_fmt(shortBy)} units',
            style: AppTypography.bodySmall(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 12),

          // Progress bar + percentage
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      ColorUtils.terracotta,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${(progress * 100).round()}%',
                style: AppTypography.bodySmall(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Footer row
          Row(
            children: [
              Expanded(
                child: Text(
                  '2 farmers already offered to help',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: navigate to offers
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'View Offers',
                  style: AppTypography.button(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      if (remainder == 0) return '$thousands,000';
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}

// ── Help request card ──────────────────────────────────────────────────────

class _HelpRequestCard extends StatelessWidget {
  final PoolingRequest request;
  const _HelpRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: ColorUtils.forestGreen,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  request.initials,
                  style: AppTypography.bodyMedium(
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
                      request.name,
                      style: AppTypography.subtitle2(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.farmName} · ${request.distance}',
                      style: AppTypography.bodySmall(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Need + CTA
          Row(
            children: [
              Expanded(
                child: Text(
                  request.need,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.darkText,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: offer stock flow
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Offer Stock',
                  style: AppTypography.button(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
