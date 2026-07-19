import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

enum ForumCategory { selling, qna, tips }

class ForumPost {
  final String id;
  final String authorName;
  final String authorRole; // Farmer or Consumer
  final String timeAgo;
  final String initials;
  final Color avatarColor;
  final ForumCategory category;
  final String content;
  final int likes;
  final int comments;

  const ForumPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.timeAgo,
    required this.initials,
    required this.avatarColor,
    required this.category,
    required this.content,
    required this.likes,
    required this.comments,
  });
}

const _mockPosts = <ForumPost>[
  ForumPost(
    id: '1',
    authorName: 'Rosa Santos',
    authorRole: 'Farmer',
    timeAgo: '2h ago',
    initials: 'R',
    avatarColor: ColorUtils.forestGreen,
    category: ForumCategory.selling,
    content:
        'Selling fresh lettuce, 500kg available this week! Message me if interested. Bukid Kabataan Shelter area.',
    likes: 12,
    comments: 4,
  ),
  ForumPost(
    id: '2',
    authorName: 'Mario Reyes',
    authorRole: 'Consumer',
    timeAgo: '5h ago',
    initials: 'M',
    avatarColor: Color(0xFF2979FF),
    category: ForumCategory.qna,
    content:
        'Anyone know why my basil seedlings keep wilting even with regular watering? Using a small home setup.',
    likes: 8,
    comments: 15,
  ),
  ForumPost(
    id: '3',
    authorName: 'Liza Cruz',
    authorRole: 'Farmer',
    timeAgo: '1d ago',
    initials: 'L',
    avatarColor: ColorUtils.forestGreen,
    category: ForumCategory.tips,
    content:
        'Tip: rotating hydroponic nutrient solution every 5 days improved my tomato yield a lot this season.',
    likes: 24,
    comments: 6,
  ),
];

// ── Screen Widget ──────────────────────────────────────────────────────────

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  String _activeCategory = 'All'; // All | Selling | Q&A | Tips

  List<ForumPost> get _filteredPosts {
    if (_activeCategory == 'Selling') {
      return _mockPosts.where((p) => p.category == ForumCategory.selling).toList();
    } else if (_activeCategory == 'Q&A') {
      return _mockPosts.where((p) => p.category == ForumCategory.qna).toList();
    } else if (_activeCategory == 'Tips') {
      return _mockPosts.where((p) => p.category == ForumCategory.tips).toList();
    }
    return _mockPosts;
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
        body: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Row with Title & (+) FAB Button ────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Community Forum',
                      style: AppTypography.heading3(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        // TODO: Open create post bottom sheet/dialog
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: ColorUtils.terracotta,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.plus,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Category Filter Pills ─────────────────────────────
                _buildCategoryFilters(),
                const SizedBox(height: 20),

                // ── Posts List ─────────────────────────────────────────
                ...List.generate(_filteredPosts.length, (index) {
                  final post = _filteredPosts[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index < _filteredPosts.length - 1 ? 14 : 0,
                    ),
                    child: _PostCard(post: post),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    final categories = ['All', 'Selling', 'Q&A', 'Tips'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isActive = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: isActive ? ColorUtils.forestGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? ColorUtils.forestGreen : Colors.grey.shade400,
                    width: 1.2,
                  ),
                ),
                child: Text(
                  cat,
                  style: AppTypography.bodySmall(
                    color: isActive ? Colors.white : ColorUtils.darkText,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Post Card Widget ───────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final ForumPost post;
  const _PostCard({required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  bool _isLiked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.post.avatarColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  widget.post.initials,
                  style: AppTypography.subtitle1(
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
                      widget.post.authorName,
                      style: AppTypography.subtitle2(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.post.authorRole} · ${widget.post.timeAgo}',
                      style: AppTypography.caption(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCategoryBadge(widget.post.category),
            ],
          ),
          const SizedBox(height: 14),

          // Content
          Text(
            widget.post.content,
            style: AppTypography.bodySmall(
              color: ColorUtils.darkText,
            ).copyWith(height: 1.45),
          ),
          const SizedBox(height: 14),

          Divider(height: 1, color: Colors.grey.shade200),
          const SizedBox(height: 10),

          // Footer (Likes, Comments, Share)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: () => setState(() => _isLiked = !_isLiked),
                child: Row(
                  children: [
                    Icon(
                      _isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: _isLiked ? Colors.red : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.post.likes + (_isLiked ? 1 : 0)} likes',
                      style: AppTypography.caption(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Comments: ${widget.post.comments}',
                style: AppTypography.caption(
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                'Share',
                style: AppTypography.caption(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(ForumCategory category) {
    final (String label, Color bg) = switch (category) {
      ForumCategory.selling => ('Selling', ColorUtils.terracotta),
      ForumCategory.qna => ('Q&A', const Color(0xFF2979FF)),
      ForumCategory.tips => ('Tips', ColorUtils.forestGreen),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
