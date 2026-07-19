import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data ────────────────────────────────────────────────────────────────────

enum IssueCategory { common, pest, fungal }

class PlantIssue {
  final String title;
  final String description;
  final IssueCategory category;
  final Color iconBackground;
  final Color iconColor;

  const PlantIssue({
    required this.title,
    required this.description,
    required this.category,
    required this.iconBackground,
    required this.iconColor,
  });
}

const _issues = <PlantIssue>[
  PlantIssue(
    title: 'Yellowing Leaves',
    description:
        'Often caused by nutrient deficiency or too much/too little water.',
    category: IssueCategory.common,
    iconBackground: Color(0xFFFFF3E0),
    iconColor: Color(0xFFE8713A),
  ),
  PlantIssue(
    title: 'Aphid Infestation',
    description:
        'Small insects on leaf undersides. Use neem oil spray to treat.',
    category: IssueCategory.pest,
    iconBackground: Color(0xFFFCE4EC),
    iconColor: Color(0xFFD84040),
  ),
  PlantIssue(
    title: 'Powdery Mildew',
    description:
        'White powder-like spots on leaves, usually from poor air circulation.',
    category: IssueCategory.fungal,
    iconBackground: Color(0xFFE3F2FD),
    iconColor: Color(0xFF2979FF),
  ),
  PlantIssue(
    title: 'Root Rot',
    description:
        'Mushy, dark roots from overwatering in hydroponic setups.',
    category: IssueCategory.common,
    iconBackground: Color(0xFFFFF8E1),
    iconColor: Color(0xFFE8713A),
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class PestIdScreen extends StatelessWidget {
  const PestIdScreen({super.key});

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
                  'Pest ID & Guide',
                  style: AppTypography.heading3(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),

                // ── Scan card ──────────────────────────────────────────
                _buildScanCard(context),
                const SizedBox(height: 28),

                // ── Section header ─────────────────────────────────────
                Text(
                  'Common Issues Guide',
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                // ── Issue cards ────────────────────────────────────────
                ...List.generate(_issues.length, (i) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: i < _issues.length - 1 ? 10 : 0,
                    ),
                    child: _IssueCard(issue: _issues[i]),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
      decoration: BoxDecoration(
        color: ColorUtils.sageGreen.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ColorUtils.forestGreen.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: ColorUtils.forestGreen,
                width: 2,
              ),
            ),
            child: const Icon(
              LucideIcons.diamond,
              color: ColorUtils.forestGreen,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),

          // Description
          Text(
            'Take or upload a photo of the\naffected plant',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium(
              color: ColorUtils.darkText,
            ),
          ),
          const SizedBox(height: 16),

          // CTA button
          ElevatedButton(
            onPressed: () {
              // TODO: open camera / image picker
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 12,
              ),
              elevation: 0,
            ),
            child: Text(
              'Scan Plant Photo',
              style: AppTypography.button(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Issue card widget ──────────────────────────────────────────────────────

class _IssueCard extends StatelessWidget {
  final PlantIssue issue;
  const _IssueCard({required this.issue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Colored icon square
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: issue.iconBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              LucideIcons.bug,
              color: issue.iconColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),

          // Title + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        issue.title,
                        style: AppTypography.subtitle2(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _buildCategoryBadge(issue.category),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  issue.description,
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

  Widget _buildCategoryBadge(IssueCategory category) {
    final (String label, Color bg, Color fg) = switch (category) {
      IssueCategory.common => (
        'Common',
        ColorUtils.forestGreen,
        Colors.white,
      ),
      IssueCategory.pest => (
        'Pest',
        const Color(0xFFD84040),
        Colors.white,
      ),
      IssueCategory.fungal => (
        'Fungal',
        const Color(0xFF2979FF),
        Colors.white,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.caption(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
