import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for community forum: posts, comments, likes, shares, reports.
class ForumService {
  final SupabaseClient _supabase;

  ForumService({required SupabaseClient supabase}) : _supabase = supabase;

  // ── Helper Table Name Resolvers ──────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _selectPosts(String? category, {bool approvedOnly = true}) async {
    final dbCat = (category != null && category != 'All') ? _mapCategory(category) : null;

    try {
      var query = _supabase.from('forum_posts').select('*, profiles:author_id(full_name, role, avatar_url)');
      if (approvedOnly) query = query.eq('status', 'approved');
      if (dbCat != null) query = query.eq('category', dbCat);
      final res = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      try {
        var query = _supabase.from('forum_posts').select('*, profiles:user_id(full_name, role, avatar_url)');
        if (approvedOnly) query = query.eq('status', 'approved');
        if (dbCat != null) query = query.eq('category', dbCat);
        final res = await query.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (_) {
        var query = _supabase.from('forum_posts').select('*');
        if (approvedOnly) query = query.eq('status', 'approved');
        if (dbCat != null) query = query.eq('category', dbCat);
        final res = await query.order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      }
    }
  }

  // ── Posts ───────────────────────────────────────────────────────────────

  /// Get all APPROVED posts with author info, optional category filter.
  Future<List<Map<String, dynamic>>> getPosts({String? category}) async {
    return _selectPosts(category, approvedOnly: true);
  }

  /// Realtime stream of APPROVED posts.
  Stream<List<Map<String, dynamic>>> watchPosts({String? category}) async* {
    final dbCategory = (category != null && category != 'All') ? _mapCategory(category) : null;

    final stream = _supabase
        .from('forum_posts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    yield* stream.map((rows) {
      var filtered = rows.where((r) {
        final s = (r['status'] as String? ?? 'approved').toLowerCase();
        return s == 'approved' || s == 'active';
      }).toList();
      if (dbCategory != null) {
        filtered = filtered.where((r) => r['category'] == dbCategory).toList();
      }
      return filtered;
    });
  }

  /// Get pending/rejected posts for the current user.
  Future<List<Map<String, dynamic>>> getMyPendingPosts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final res = await _supabase
          .from('forum_posts')
          .select('*')
          .eq('author_id', user.id)
          .neq('status', 'approved')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (_) {
      try {
        final res = await _supabase
            .from('forum_posts')
            .select('*')
            .eq('user_id', user.id)
            .neq('status', 'approved')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(res);
      } catch (_) {
        return [];
      }
    }
  }

  String _mapCategory(String uiCategory) {
    return switch (uiCategory) {
      'Selling' => 'selling',
      'Q&A' => 'qna',
      'Tips' => 'tips',
      _ => uiCategory.toLowerCase(),
    };
  }

  /// Create a new post.
  Future<void> createPost({
    required String category,
    required String content,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase.from('forum_posts').insert({
        'author_id': user.id,
        'category': category,
        'content': content,
        'image_url': imageUrl ?? '',
        'status': 'pending',
      });
    } catch (_) {
      await _supabase.from('forum_posts').insert({
        'user_id': user.id,
        'category': category,
        'content': content,
        'image_url': imageUrl ?? '',
        'status': 'pending',
      });
    }
  }

  /// Delete own post.
  Future<void> deletePost(String postId) async {
    await _supabase.from('forum_posts').delete().eq('id', postId);
  }

  // ── Comments ────────────────────────────────────────────────────────────

  /// Get comments for a post with author info.
  Future<List<Map<String, dynamic>>> getComments(String postId) async {
    try {
      final result = await _supabase
          .from('forum_comments')
          .select('*, profiles:author_id(full_name, role, avatar_url)')
          .eq('post_id', postId)
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      try {
        final result = await _supabase
            .from('forum_comments')
            .select('*, profiles:user_id(full_name, role, avatar_url)')
            .eq('post_id', postId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(result);
      } catch (_) {
        final result = await _supabase
            .from('forum_comments')
            .select('*')
            .eq('post_id', postId)
            .order('created_at', ascending: true);
        return List<Map<String, dynamic>>.from(result);
      }
    }
  }

  /// Realtime stream of comments for a post.
  Stream<List<Map<String, dynamic>>> watchComments(String postId) {
    return _supabase
        .from('forum_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: true);
  }

  /// Add a comment to a post and update count.
  Future<void> addComment({
    required String postId,
    required String content,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase.from('forum_comments').insert({
        'post_id': postId,
        'author_id': user.id,
        'content': content,
      });
    } catch (_) {
      try {
        await _supabase.from('forum_comments').insert({
          'post_id': postId,
          'user_id': user.id,
          'content': content,
        });
      } catch (_) {
        await _supabase.rpc('add_post_comment', params: {
          'p_post_id': postId,
          'p_user_id': user.id,
          'p_content': content,
        });
      }
    }
  }

  // ── Likes ───────────────────────────────────────────────────────────────

  /// Toggle like on a post. Returns new like state.
  Future<bool> toggleLike(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    bool alreadyLiked = await isLiked(postId);

    if (alreadyLiked) {
      await _supabase.from('forum_likes').delete().eq('post_id', postId).eq('user_id', user.id);
      return false;
    } else {
      await _supabase.from('forum_likes').insert({'post_id': postId, 'user_id': user.id});
      return true;
    }
  }

  /// Check if current user liked a post.
  Future<bool> isLiked(String postId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final res = await _supabase
          .from('forum_likes')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();
      return res != null;
    } catch (_) {
      return false;
    }
  }

  // ── Reports ─────────────────────────────────────────────────────────────

  /// Report a post (saves to forum_reports AND issue_reports).
  Future<void> reportPost({
    required String postId,
    required String reason,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    // 1. Insert into forum_reports
    try {
      await _supabase.from('forum_reports').insert({
        'post_id': postId,
        'author_id': user.id,
        'reporter_id': user.id,
        'reason': reason,
      });
    } catch (e) {
      try {
        await _supabase.from('forum_reports').insert({
          'post_id': postId,
          'reason': reason,
        });
      } catch (_) {}
    }

    // 2. Insert into issue_reports table so it displays in Issue Reports
    try {
      await _supabase.from('issue_reports').insert({
        'reporter_id': user.id,
        'title': 'Reported Forum Post',
        'description': 'Forum Post ID $postId reported by user. Reason: $reason',
        'status': 'under_review',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Retry with minimal payload if any column is constrained
      try {
        await _supabase.from('issue_reports').insert({
          'reporter_id': user.id,
          'title': 'Reported Forum Post',
          'description': reason,
        });
      } catch (_) {}
    }
  }

  // ── Share ───────────────────────────────────────────────────────────────

  /// Increment share count.
  Future<void> sharePost(String postId) async {
    try {
      await _supabase.rpc('increment_post_shares', params: {
        'p_post_id': postId,
      });
    } catch (_) {}
  }

  // ── Admin Moderation ────────────────────────────────────────────────────

  /// Approve a pending post.
  Future<void> approvePost(String postId) async {
    try {
      await _supabase.from('forum_posts').update({'status': 'approved'}).eq('id', postId);
    } catch (_) {
      await _supabase.rpc('admin_approve_post', params: {'p_post_id': postId});
    }
  }

  /// Reject a pending post.
  Future<void> rejectPost(String postId) async {
    try {
      await _supabase.from('forum_posts').update({'status': 'rejected'}).eq('id', postId);
    } catch (_) {
      await _supabase.rpc('admin_reject_post', params: {'p_post_id': postId});
    }
  }

  /// Get all posts for admin moderation.
  Future<List<Map<String, dynamic>>> getAllPostsForModeration() async {
    try {
      final result = await _supabase
          .from('forum_posts')
          .select('*, profiles:author_id(full_name, role, avatar_url)')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    } catch (_) {
      final result = await _supabase
          .from('forum_posts')
          .select('*')
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(result);
    }
  }
}
