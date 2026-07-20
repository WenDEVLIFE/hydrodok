import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/service/forum_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import 'add_post_dialog.dart';
import 'comments_dialog.dart';
import 'report_post_dialog.dart';

// ── Screen Widget ──────────────────────────────────────────────────────────

class ForumScreen extends StatefulWidget {
  const ForumScreen({super.key});

  @override
  State<ForumScreen> createState() => _ForumScreenState();
}

class _ForumScreenState extends State<ForumScreen> {
  static const _categories = ['All', 'Selling', 'Q&A', 'Tips'];
  static const _categoryToDb = {
    'All': 'All',
    'Selling': 'selling',
    'Q&A': 'qna',
    'Tips': 'tips',
  };

  String _activeCategory = 'All';

  final _forumService = ForumService(supabase: Supabase.instance.client);

  String get _dbCategory => _categoryToDb[_activeCategory]!;

  void _showAddPostSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPostDialog(
        onPostCreated: () {
          // Realtime stream will refresh the list automatically.
        },
      ),
    );
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
                      onTap: _showAddPostSheet,
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
                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _forumService.watchPosts(category: _dbCategory),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting &&
                        !snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'Error loading posts: ${snapshot.error}',
                            style: AppTypography.bodyMedium(
                              color: Colors.redAccent,
                            ),
                          ),
                        ),
                      );
                    }

                    final posts = snapshot.data ?? [];

                    if (posts.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Center(
                          child: Text(
                            'No posts yet. Be the first to share!',
                            style: AppTypography.bodyMedium(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: List.generate(posts.length, (index) {
                        final post = posts[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index < posts.length - 1 ? 14 : 0,
                          ),
                          child: _PostCard(
                            key: ValueKey(post['id'] as String?),
                            post: post,
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isActive = _activeCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _activeCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isActive ? ColorUtils.forestGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive
                        ? ColorUtils.forestGreen
                        : Colors.grey.shade400,
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
  final Map<String, dynamic> post;

  const _PostCard({super.key, required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> {
  late final Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
  }

  Future<Map<String, dynamic>?> _loadProfile() async {
    // First try the embedded join (only present on REST, not realtime stream)
    final embedded = widget.post['profiles'];
    if (embedded is Map<String, dynamic> && embedded['full_name'] != null) {
      return embedded;
    }

    final userId = (widget.post['author_id'] ?? widget.post['user_id']) as String?;
    if (userId == null || userId.toString().isEmpty) return null;

    try {
      final result = await Supabase.instance.client
          .from('profiles')
          .select('full_name, role, avatar_url')
          .eq('id', userId)
          .maybeSingle();
      return result;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final postId = widget.post['id'] as String? ?? '';
    final content = widget.post['content'] as String? ?? '';
    final category = widget.post['category'] as String? ?? 'selling';
    final createdAt = widget.post['created_at'] as String? ?? '';
    final commentsCount = (widget.post['comments_count'] as num?)?.toInt() ?? 0;

    return FutureBuilder<Map<String, dynamic>?>(
      future: _profileFuture,
      builder: (context, profileSnapshot) {
        final profile = profileSnapshot.data;
        final rawName = (profile?['full_name'] as String?)?.trim() ?? '';
        final authorName = rawName.isNotEmpty ? rawName : 'Farmer';
        final rawRole = (profile?['role'] as String?) ?? 'member';
        final role = _capitalize(rawRole);
        final avatarUrl = (profile?['avatar_url'] as String?) ?? '';
        final initials = _initials(authorName);

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
                  _buildAvatar(avatarUrl, initials),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authorName,
                          style: AppTypography.subtitle2(
                            color: ColorUtils.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$role · ${_timeAgo(createdAt)}',
                          style: AppTypography.caption(
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCategoryBadge(category),
                ],
              ),
              const SizedBox(height: 14),

              // Content
              Text(
                content,
                style: AppTypography.bodySmall(
                  color: ColorUtils.darkText,
                ).copyWith(height: 1.45),
              ),
              const SizedBox(height: 14),

              Divider(height: 1, color: Colors.grey.shade200),
              const SizedBox(height: 10),

              // Footer (Likes, Comments, Share, More)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      _LikeButton(
                        key: ValueKey('like-$postId'),
                        postId: postId,
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: LucideIcons.messageCircle,
                        label: '$commentsCount',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => CommentsDialog(postId: postId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      _ActionButton(
                        icon: LucideIcons.share2,
                        label: 'Share',
                        onTap: () => _handleShare(postId, content),
                      ),
                    ],
                  ),
                  _buildMoreMenu(postId),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String avatarUrl, String initials) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: ColorUtils.forestGreen,
      backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
      child: avatarUrl.isEmpty
          ? Text(
              initials,
              style: AppTypography.subtitle1(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryBadge(String category) {
    final (String label, Color bg) = switch (category.toLowerCase()) {
      'selling' => ('Selling', ColorUtils.terracotta),
      'qna' => ('Q&A', const Color(0xFF2979FF)),
      'tips' => ('Tips', ColorUtils.forestGreen),
      _ => ('Other', Colors.grey),
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

  Widget _buildMoreMenu(String postId) {
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.moreHorizontal, color: Colors.grey.shade600),
      onSelected: (value) async {
        if (value != 'report') return;
        final reported = await showDialog<bool>(
          context: context,
          builder: (_) => ReportPostDialog(postId: postId),
        );
        if (reported == true && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report submitted. Thank you.')),
          );
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              Icon(LucideIcons.flag, size: 18),
              SizedBox(width: 8),
              Text('Report'),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _handleShare(String postId, String content) async {
    try {
      await ForumService(supabase: Supabase.instance.client).sharePost(postId);
      await SharePlus.instance.share(ShareParams(text: content));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
      }
    }
  }

  static String _capitalize(String value) {
    if (value.isEmpty) return value;
    return '${value[0].toUpperCase()}${value.substring(1)}';
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  static String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 30) return '${diff.inDays}d ago';
      return '${(diff.inDays / 30).floor()}mo ago';
    } catch (_) {
      return '';
    }
  }
}

// ── Like Button Widget ─────────────────────────────────────────────────────

class _LikeButton extends StatefulWidget {
  final String postId;

  const _LikeButton({
    required Key key,
    required this.postId,
  }) : super(key: key);

  @override
  State<_LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<_LikeButton> {
  bool? _isLiked;
  int _likesCount = 0;

  final _service = ForumService(supabase: Supabase.instance.client);

  @override
  void initState() {
    super.initState();
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      // Load actual likes count from forum_likes table
      final countRes = await Supabase.instance.client
          .from('forum_likes')
          .select('id')
          .eq('post_id', widget.postId);
      final count = (countRes as List).length;

      // Load whether current user liked it
      final liked = await _service.isLiked(widget.postId);

      if (mounted) {
        setState(() {
          _likesCount = count;
          _isLiked = liked;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLiked = false);
    }
  }

  Future<void> _toggleLike() async {
    final previous = _isLiked ?? false;
    setState(() {
      _isLiked = !previous;
      _likesCount += _isLiked! ? 1 : -1;
    });

    try {
      final result = await _service.toggleLike(widget.postId);
      if (mounted) {
        setState(() => _isLiked = result);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = previous;
          _likesCount += previous ? 1 : -1;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update like: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final liked = _isLiked ?? false;

    return InkWell(
      onTap: _toggleLike,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            liked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: liked ? Colors.red : Colors.grey.shade600,
          ),
          const SizedBox(width: 4),
          Text(
            '$_likesCount',
            style: AppTypography.caption(
              color: Colors.grey.shade600,
              fontWeight: liked ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic Action Button ──────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.caption(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
