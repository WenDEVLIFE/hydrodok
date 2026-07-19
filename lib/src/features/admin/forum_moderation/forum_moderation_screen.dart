import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

enum ModerationStatus { flagged, approved, removed }

class ModeratedForumPost {
  final String id;
  final String authorName;
  final String authorRole;
  final String initials;
  final Color avatarColor;
  final String categoryLabel;
  final Color categoryColor;
  final String timeAgo;
  final String postContent;
  final String reportReason;
  final int reportCount;
  final ModerationStatus status;

  const ModeratedForumPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.initials,
    required this.avatarColor,
    required this.categoryLabel,
    required this.categoryColor,
    required this.timeAgo,
    required this.postContent,
    required this.reportReason,
    required this.reportCount,
    required this.status,
  });
}

const _forumPosts = <ModeratedForumPost>[
  ModeratedForumPost(
    id: '1',
    authorName: 'Mario Reyes',
    authorRole: 'Consumer',
    initials: 'M',
    avatarColor: Color(0xFF2979FF),
    categoryLabel: 'Selling',
    categoryColor: ColorUtils.terracotta,
    timeAgo: '1h ago',
    postContent:
        'Selling 10,000 units imported lettuce at 50% below market price! Direct DM for payment link.',
    reportReason: 'Reported by 3 users: Suspected scam / unverified payment link',
    reportCount: 3,
    status: ModerationStatus.flagged,
  ),
  ModeratedForumPost(
    id: '2',
    authorName: 'Anon User',
    authorRole: 'Consumer',
    initials: 'A',
    avatarColor: Color(0xFFD84040),
    categoryLabel: 'Q&A',
    categoryColor: Color(0xFF2979FF),
    timeAgo: '3h ago',
    postContent:
        'Join my external crypto farm telegram channel for instant profit hydroponics guarantee!',
    reportReason: 'Reported by 5 users: Spam & unsolicited commercial promotion',
    reportCount: 5,
    status: ModerationStatus.flagged,
  ),
  ModeratedForumPost(
    id: '3',
    authorName: 'Rosa Santos',
    authorRole: 'Farmer',
    initials: 'R',
    avatarColor: ColorUtils.forestGreen,
    categoryLabel: 'Tips',
    categoryColor: ColorUtils.forestGreen,
    timeAgo: '5h ago',
    postContent:
        'Reminder to check your EC meter calibration every 2 weeks during heavy harvest cycles.',
    reportReason: 'Reported by 1 user: Flagged by mistake (Approved by Admin)',
    reportCount: 1,
    status: ModerationStatus.approved,
  ),
  ModeratedForumPost(
    id: '4',
    authorName: 'BadActor_99',
    authorRole: 'Consumer',
    initials: 'B',
    avatarColor: Colors.grey,
    categoryLabel: 'Selling',
    categoryColor: ColorUtils.terracotta,
    timeAgo: '1d ago',
    postContent:
        'Free fertilizer giveaway click here: http://suspicious-link-fake.com',
    reportReason: 'Phishing / Harmful external link',
    reportCount: 8,
    status: ModerationStatus.removed,
  ),
];

// ── Screen Widget ──────────────────────────────────────────────────────────

class ForumModerationScreen extends StatefulWidget {
  const ForumModerationScreen({super.key});

  @override
  State<ForumModerationScreen> createState() => _ForumModerationScreenState();
}

class _ForumModerationScreenState extends State<ForumModerationScreen> {
  String _activeFilter = 'All'; // All | Flagged | Approved | Removed
  final _searchController = TextEditingController();

  List<ModeratedForumPost> get _filteredPosts {
    if (_activeFilter == 'Flagged') {
      return _forumPosts
          .where((p) => p.status == ModerationStatus.flagged)
          .toList();
    } else if (_activeFilter == 'Approved') {
      return _forumPosts
          .where((p) => p.status == ModerationStatus.approved)
          .toList();
    } else if (_activeFilter == 'Removed') {
      return _forumPosts
          .where((p) => p.status == ModerationStatus.removed)
          .toList();
    }
    return _forumPosts;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Subtitle Row ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forum Moderation',
                      style: AppTypography.heading2(
                        color: ColorUtils.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review reported community posts, moderate spam, and enforce community standards',
                      style: AppTypography.bodyMedium(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Auto-mod rules modal
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.grey.shade400),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(LucideIcons.shieldAlert, size: 18),
                label: Text(
                  'Auto-Mod Rules',
                  style: AppTypography.button(
                    color: ColorUtils.darkText,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats Summary Row ─────────────────────────────────────────
          _buildStatsRow(),
          const SizedBox(height: 24),

          // ── Search & Filter Bar ──────────────────────────────────────
          _buildSearchAndFilters(),
          const SizedBox(height: 20),

          // ── Moderated Posts Cards List ───────────────────────────────
          Expanded(
            child: ListView.separated(
              itemCount: _filteredPosts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                return _ForumPostCard(post: _filteredPosts[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats Summary Row ─────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          value: '8',
          label: 'Flagged Posts',
          valueColor: ColorUtils.terracotta,
          bgColor: const Color(0xFFFFF3E0),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '142',
          label: 'Total Posts Today',
          valueColor: ColorUtils.forestGreen,
          bgColor: ColorUtils.sageGreen.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '3',
          label: 'Removed (24h)',
          valueColor: ColorUtils.darkText,
          bgColor: Colors.grey.shade100,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.heading3(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search & Filter Pills ────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium(color: ColorUtils.darkText),
              decoration: InputDecoration(
                hintText: 'Search posts or author...',
                hintStyle: AppTypography.bodyMedium(
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterPill('All'),
        const SizedBox(width: 8),
        _buildFilterPill('Flagged'),
        const SizedBox(width: 8),
        _buildFilterPill('Approved'),
        const SizedBox(width: 8),
        _buildFilterPill('Removed'),
      ],
    );
  }

  Widget _buildFilterPill(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? ColorUtils.forestGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(
            color: isActive ? Colors.white : ColorUtils.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// ── Moderated Forum Post Card Widget ───────────────────────────────────────

class _ForumPostCard extends StatelessWidget {
  final ModeratedForumPost post;
  const _ForumPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author & Header Row
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: post.avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  post.initials,
                  style: AppTypography.subtitle2(
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
                    Row(
                      children: [
                        Text(
                          post.authorName,
                          style: AppTypography.subtitle2(
                            color: ColorUtils.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${post.authorRole}) · ${post.timeAgo}',
                          style: AppTypography.caption(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Category pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: post.categoryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  post.categoryLabel,
                  style: AppTypography.caption(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(post.status),
            ],
          ),
          const SizedBox(height: 12),

          // Post Content Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              post.postContent,
              style: AppTypography.bodySmall(
                color: ColorUtils.darkText,
              ).copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: 10),

          // Report reason banner
          Row(
            children: [
              Icon(
                LucideIcons.alertCircle,
                size: 16,
                color: ColorUtils.terracotta,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  post.reportReason,
                  style: AppTypography.caption(
                    color: ColorUtils.terracotta,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Actions
              _buildActionButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ModerationStatus status) {
    final (String label, Color bg) = switch (status) {
      ModerationStatus.flagged => ('Flagged', ColorUtils.terracotta),
      ModerationStatus.approved => ('Approved', ColorUtils.forestGreen),
      ModerationStatus.removed => ('Removed', const Color(0xFFD84040)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
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

  Widget _buildActionButtons() {
    switch (post.status) {
      case ModerationStatus.flagged:
        return Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: Approve post
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              child: Text(
                'Approve Post',
                style: AppTypography.caption(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                // TODO: Remove post
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD84040),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                elevation: 0,
              ),
              child: Text(
                'Remove Post',
                style: AppTypography.caption(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      case ModerationStatus.approved:
        return Text(
          'Post Live',
          style: AppTypography.caption(
            color: ColorUtils.forestGreen,
            fontWeight: FontWeight.w600,
          ),
        );
      case ModerationStatus.removed:
        return Text(
          'Post Removed',
          style: AppTypography.caption(
            color: Colors.grey.shade500,
          ).copyWith(fontStyle: FontStyle.italic),
        );
    }
  }
}
