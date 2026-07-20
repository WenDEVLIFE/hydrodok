import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for handling issue reports and support tickets data operations
class IssueReportRepository {
  final SupabaseClient _supabase;

  IssueReportRepository({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Watch live real-time stream of all issue reports
  Stream<List<Map<String, dynamic>>> watchIssueReports() {
    return _supabase
        .from('issue_reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  /// Create a new issue report ticket
  Future<void> createIssueReport({
    required String title,
    required String description,
    String? category,
    String? priority,
    String? farmId,
  }) async {
    final user = _supabase.auth.currentUser;
    final payload = <String, dynamic>{
      if (user != null) 'reporter_id': user.id,
      if (farmId != null) 'farm_id': farmId,
      'title': title,
      'description': description,
      'status': 'under_review',
      'created_at': DateTime.now().toIso8601String(),
    };

    if (category != null) payload['category'] = category;
    if (priority != null) payload['priority'] = priority;

    try {
      await _supabase.from('issue_reports').insert(payload);
    } catch (_) {
      // Retry with minimal payload if DB schema lacks optional columns
      await _supabase.from('issue_reports').insert({
        if (user != null) 'reporter_id': user.id,
        'title': title,
        'description': description,
        'status': 'under_review',
      });
    }
  }

  /// Update status of an issue report ticket (Admin action)
  Future<void> updateReportStatus(String reportId, String status) async {
    await _supabase
        .from('issue_reports')
        .update({'status': status})
        .eq('id', reportId);
  }

  /// Resolve full_name for reporter_id
  Future<String?> getReporterName(String reporterId) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', reporterId)
          .maybeSingle();
      return res?['full_name'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Resolve farm_name for farm_id
  Future<String?> getFarmName(String farmId) async {
    try {
      final res = await _supabase
          .from('farms')
          .select('farm_name')
          .eq('id', farmId)
          .maybeSingle();
      return res?['farm_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
