import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Admin Forum Moderation:
/// Review reported community posts, remove violations, and dismiss false reports.
class ForumModerationScreen extends StatefulWidget {
  const ForumModerationScreen({super.key});

  @override
  State<ForumModerationScreen> createState() => _ForumModerationScreenState();
}

class _ForumModerationScreenState extends State<ForumModerationScreen> {
  String _activeFilter = 'Pending'; // All | Pending | Flagged | Approved | Rejected
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
  }

  Future<void> _fetchPosts() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      List<dynamic> response;
      try {
        response = await supabase
            .from('forum_posts')
            .select('*, profiles:author_id(full_name, role, avatar_url)')
            .order('created_at', ascending: false);
      } catch (_) {
        try {
          response = await supabase
              .from('forum_posts')
              .select('*, profiles:user_id(full_name, role, avatar_url)')
              .order('created_at', ascending: false);
        } catch (_) {
          response = await supabase
              .from('forum_posts')
              .select('*')
              .order('created_at', ascending: false);
        }
      }

      final posts = List<Map<String, dynamic>>.from(response);

      // Resolve author profile if missing
      for (final post in posts) {
        if (post['profiles'] == null) {
          final userId = (post['author_id'] ?? post['user_id']) as String?;
          if (userId != null) {
            try {
              final prof = await supabase
                  .from('profiles')
                  .select('full_name, role, avatar_url')
                  .eq('id', userId)
                  .maybeSingle();
              if (prof != null) post['profiles'] = prof;
            } catch (_) {}
          }
        }
      }

      // Fetch latest report reason for posts with reports
      final postsWithReports = posts.where((p) => (p['reports_count'] ?? 0) > 0).toList();
      if (postsWithReports.isNotEmpty) {
        final ids = postsWithReports.map((p) => p['id']).toList();
        List<dynamic> reports;
        try {
          reports = await supabase
              .from('forum_reports')
              .select('post_id, reason, created_at')
              .inFilter('post_id', ids)
              .order('created_at', ascending: false);
        } catch (_) {
          try {
            reports = await supabase
                .from('post_reports')
                .select('post_id, reason, created_at')
                .inFilter('post_id', ids)
                .order('created_at', ascending: false);
          } catch (_) {
            reports = [];
          }
        }

        final reportsList = List<Map<String, dynamic>>.from(reports);
        for (final post in posts) {
          final postReports = reportsList.where((r) => r['post_id'] == post['id']).toList();
          if (postReports.isNotEmpty) {
            post['latest_report_reason'] = postReports.first['reason'];
            post['report_reasons'] = postReports.map((r) => r['reason']).toList();
          }
        }
      }

      if (mounted) setState(() => _posts = posts);
    } catch (e, st) {
      debugPrint('Error fetching posts in moderation screen: $e\n$st');
      if (mounted) setState(() => _posts = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approvePost(String postId) async {
    try {
      await Supabase.instance.client.from('forum_posts').update({'status': 'approved'}).eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post approved — now live in forum.')),
        );
      }
      _fetchPosts();
    } catch (e) {
      try {
        await Supabase.instance.client.rpc('admin_approve_post', params: {'p_post_id': postId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post approved — now live in forum.')),
          );
        }
        _fetchPosts();
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error approving post: $err')),
          );
        }
      }
    }
  }

  Future<void> _rejectPost(String postId) async {
    try {
      await Supabase.instance.client.from('forum_posts').update({'status': 'rejected'}).eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post rejected.')),
        );
      }
      _fetchPosts();
    } catch (e) {
      try {
        await Supabase.instance.client.rpc('admin_reject_post', params: {'p_post_id': postId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post rejected.')),
          );
        }
        _fetchPosts();
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error rejecting post: $err')),
          );
        }
      }
    }
  }

  Future<void> _deletePost(String postId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Post'),
        content: const Text('This will permanently delete the post and all its comments/likes. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('forum_posts').delete().eq('id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post removed.')),
        );
      }
      _fetchPosts();
    } catch (e) {
      try {
        await Supabase.instance.client.rpc('admin_delete_post', params: {'p_post_id': postId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post removed.')),
          );
        }
        _fetchPosts();
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error removing post: $err')),
          );
        }
      }
    }
  }

  Future<void> _dismissReports(String postId) async {
    try {
      await Supabase.instance.client.from('forum_reports').delete().eq('post_id', postId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports dismissed — post stays live.')),
        );
      }
      _fetchPosts();
    } catch (e) {
      try {
        await Supabase.instance.client.rpc('admin_dismiss_reports', params: {'p_post_id': postId});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reports dismissed — post stays live.')),
          );
        }
        _fetchPosts();
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $err')),
          );
        }
      }
    }
  }

  List<Map<String, dynamic>> get _filteredPosts {
    final query = _searchController.text.toLowerCase();
    var result = _posts.where((p) {
      final content = (p['content'] as String? ?? '').toLowerCase();
      final author = ((p['profiles'] as Map?)?['full_name'] as String? ?? '').toLowerCase();
      return content.contains(query) || author.contains(query);
    }).toList();

    switch (_activeFilter) {
      case 'Pending':
        result = result.where((p) {
          final s = (p['status'] as String? ?? 'pending').toLowerCase();
          return s == 'pending';
        }).toList();
      case 'Flagged':
        result = result.where((p) => (p['reports_count'] as int? ?? 0) > 0).toList();
      case 'Approved':
        result = result.where((p) {
          final s = (p['status'] as String? ?? 'approved').toLowerCase();
          return s == 'approved' || s == 'active' || p['status'] == null;
        }).toList();
      case 'Rejected':
        result = result.where((p) {
          final s = (p['status'] as String? ?? '').toLowerCase();
          return s == 'rejected';
        }).toList();
      case 'All':
      default:
        break;
    }

    return result;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final flaggedCount = _posts.where((p) => (p['reports_count'] ?? 0) > 0).length;
    final totalToday = _posts.where((p) {
      try {
        final dt = DateTime.parse(p['created_at']);
        final now = DateTime.now();
        return dt.year == now.year && dt.month == now.month && dt.day == now.day;
      } catch (_) {
        return false;
      }
    }).length;

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Forum Moderation',
                      style: AppTypography.heading2(color: ColorUtils.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review reported community posts, remove violations, and dismiss false reports.',
                      style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: ColorUtils.forestGreen),
                onPressed: _fetchPosts,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats ─────────────────────────────────────────────────────
          _buildStatsRow(flaggedCount, totalToday),
          const SizedBox(height: 24),

          // ── Search & Filters ──────────────────────────────────────────
          _buildSearchAndFilters(),
          const SizedBox(height: 20),

          // ── Posts List ────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPosts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.shieldCheck, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No $_activeFilter posts',
                              style: AppTypography.bodyLarge(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredPosts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) => _ForumPostCard(
                          post: _filteredPosts[index],
                          onApprove: () => _approvePost(_filteredPosts[index]['id'] as String),
                          onReject: () => _rejectPost(_filteredPosts[index]['id'] as String),
                          onDelete: () => _deletePost(_filteredPosts[index]['id'] as String),
                          onDismiss: () => _dismissReports(_filteredPosts[index]['id'] as String),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int flagged, int totalToday) {
    return Row(
      children: [
        _buildStatCard(
          value: flagged.toString(),
          label: 'Flagged Posts',
          valueColor: ColorUtils.terracotta,
          bgColor: const Color(0xFFFFF3E0),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: totalToday.toString(),
          label: 'Total Posts Today',
          valueColor: ColorUtils.forestGreen,
          bgColor: ColorUtils.sageGreen.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: _posts.length.toString(),
          label: 'Total Posts',
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
              style: AppTypography.heading3(color: valueColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

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
              onChanged: (_) => setState(() {}),
              style: AppTypography.bodyMedium(color: ColorUtils.darkText),
              decoration: InputDecoration(
                hintText: 'Search posts or author...',
                hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                prefixIcon: Icon(LucideIcons.search, size: 18, color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterPill('All'),
        const SizedBox(width: 8),
        _buildFilterPill('Pending'),
        const SizedBox(width: 8),
        _buildFilterPill('Flagged'),
        const SizedBox(width: 8),
        _buildFilterPill('Approved'),
        const SizedBox(width: 8),
        _buildFilterPill('Rejected'),
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
  final Map<String, dynamic> post;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const _ForumPostCard({
    required this.post,
    required this.onApprove,
    required this.onReject,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final profile = post['profiles'] as Map<String, dynamic>?;
    final authorName = profile?['full_name'] as String? ?? 'Unknown';
    final role = profile?['role'] as String? ?? 'User';
    final avatarUrl = profile?['avatar_url'] as String?;
    final content = post['content'] as String? ?? '';
    final category = post['category'] as String? ?? 'selling';
    final reportCount = post['reports_count'] as int? ?? 0;
    final latestReason = post['latest_report_reason'] as String?;
    final createdAt = post['created_at'] as String? ?? '';
    final status = post['status'] as String? ?? 'active';

    String timeAgo = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    final initials = authorName.isNotEmpty ? authorName[0].toUpperCase() : '?';
    final isFlagged = reportCount > 0;

    final (categoryLabel, categoryColor) = switch (category) {
      'selling' => ('Selling', ColorUtils.terracotta),
      'qna' => ('Q&A', const Color(0xFF2979FF)),
      'tips' => ('Tips', ColorUtils.forestGreen),
      _ => ('Post', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFlagged ? ColorUtils.terracotta : Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(authorName),
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Text(initials, style: AppTypography.subtitle2(color: Colors.white, fontWeight: FontWeight.w700))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: AppTypography.subtitle2(color: ColorUtils.darkText, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '$role · $timeAgo',
                      style: AppTypography.caption(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: categoryColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  categoryLabel,
                  style: AppTypography.caption(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(isFlagged),
            ],
          ),
          const SizedBox(height: 12),

          // Content
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              content,
              style: AppTypography.bodySmall(color: ColorUtils.darkText).copyWith(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),

          // Report reason
          if (isFlagged && latestReason != null) ...[
            Row(
              children: [
                Icon(LucideIcons.alertCircle, size: 16, color: ColorUtils.terracotta),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Reported by $reportCount user${reportCount > 1 ? 's' : ''}: $latestReason',
                    style: AppTypography.caption(
                      color: ColorUtils.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Actions based on post status
          _buildActions(status, isFlagged),
        ],
      ),
    );
  }

  Widget _buildActions(String status, bool isFlagged) {
    // Pending: Approve / Reject
    if (status == 'pending') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(LucideIcons.x, size: 16),
            label: const Text('Reject'),
            onPressed: onReject,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.forestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('Approve'),
            onPressed: onApprove,
          ),
        ],
      );
    }

    // Rejected: already rejected, can delete
    if (status == 'rejected') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Rejected',
            style: AppTypography.caption(color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: const BorderSide(color: Colors.redAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: const Text('Delete'),
            onPressed: onDelete,
          ),
        ],
      );
    }

    // Approved + Flagged: Dismiss reports / Remove
    if (isFlagged) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorUtils.forestGreen,
              side: const BorderSide(color: ColorUtils.forestGreen),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            icon: const Icon(LucideIcons.check, size: 16),
            label: const Text('Dismiss Reports'),
            onPressed: onDismiss,
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
            ),
            icon: const Icon(LucideIcons.trash2, size: 16),
            label: const Text('Remove Post'),
            onPressed: onDelete,
          ),
        ],
      );
    }

    // Approved, no reports
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Post is live — no reports',
          style: AppTypography.caption(color: ColorUtils.forestGreen, fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.redAccent,
            side: const BorderSide(color: Colors.redAccent),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          icon: const Icon(LucideIcons.trash2, size: 16),
          label: const Text('Remove'),
          onPressed: onDelete,
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isFlagged) {
    final status = post['status'] as String? ?? 'pending';
    final (label, bg) = switch (status) {
      'approved' => isFlagged ? ('Flagged', ColorUtils.terracotta) : ('Approved', ColorUtils.forestGreen),
      'rejected' => ('Rejected', Colors.redAccent),
      _ => ('Pending', const Color(0xFF2979FF)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      ColorUtils.forestGreen,
      const Color(0xFF2979FF),
      ColorUtils.terracotta,
      const Color(0xFF7B1FA2),
      const Color(0xFF00897B),
    ];
    return colors[name.length % colors.length];
  }
}
