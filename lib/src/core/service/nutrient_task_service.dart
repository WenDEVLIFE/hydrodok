import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for nutrient logging and farm task management.
class NutrientTaskService {
  final SupabaseClient _supabase;

  NutrientTaskService({required SupabaseClient supabase}) : _supabase = supabase;

  // ── Nutrient Logs ──────────────────────────────────────────────────────────

  /// Logs a new nutrient application for a given [farmId].
  Future<Map<String, dynamic>> logNutrient({
    required String farmId,
    required String nutrientName,
    required double amount,
    String? notes,
  }) async {
    final payload = <String, dynamic>{
      'farm_id': farmId,
      'nutrient_name': nutrientName,
      'amount': amount,
      'notes': notes ?? '',
    };

    try {
      final response = await _supabase.from('nutrient_logs').insert({
        ...payload,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.message.contains('created_at')) {
        final response = await _supabase.from('nutrient_logs').insert(payload).select().single();
        return Map<String, dynamic>.from(response);
      }
      rethrow;
    }
  }

  /// Gets all nutrient logs for a [farmId].
  Future<List<Map<String, dynamic>>> getNutrientLogs(String farmId) async {
    try {
      final response = await _supabase
          .from('nutrient_logs')
          .select('*')
          .eq('farm_id', farmId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      final response = await _supabase
          .from('nutrient_logs')
          .select('*')
          .eq('farm_id', farmId);

      return List<Map<String, dynamic>>.from(response);
    }
  }

  /// Realtime stream of nutrient logs for a [farmId].
  Stream<List<Map<String, dynamic>>> watchNutrientLogs(String farmId) {
    return _supabase
        .from('nutrient_logs')
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);
  }

  // ── Farm Tasks ─────────────────────────────────────────────────────────────

  /// Realtime stream of tasks for a [farmId].
  Stream<List<Map<String, dynamic>>> watchFarmTasks(String farmId) {
    return _supabase
        .from('farm_tasks')
        .stream(primaryKey: ['id'])
        .eq('farm_id', farmId)
        .order('created_at', ascending: false);
  }

  /// Creates a new maintenance task for a [farmId].
  Future<Map<String, dynamic>> addTask({
    required String farmId,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
  }) async {
    final payload = <String, dynamic>{
      'farm_id': farmId,
      'title': title,
      'description': description ?? '',
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'status': 'pending',
    };

    try {
      final response = await _supabase.from('farm_tasks').insert({
        ...payload,
        'created_at': DateTime.now().toIso8601String(),
      }).select().single();

      return Map<String, dynamic>.from(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST204' || e.message.contains('created_at')) {
        final response = await _supabase.from('farm_tasks').insert(payload).select().single();
        return Map<String, dynamic>.from(response);
      }
      rethrow;
    }
  }

  /// Updates a task's status (e.g. 'pending' -> 'completed').
  Future<void> updateTaskStatus(String taskId, String status) async {
    await _supabase.from('farm_tasks').update({
      'status': status,
    }).eq('id', taskId);
  }

  /// Deletes a task by ID.
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('farm_tasks').delete().eq('id', taskId);
  }

  /// Fetches all tasks for a [farmId].
  Future<List<Map<String, dynamic>>> getFarmTasks(String farmId) async {
    try {
      final response = await _supabase
          .from('farm_tasks')
          .select('*')
          .eq('farm_id', farmId)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    try {
      final response = await _supabase
          .from('farm_tasks')
          .select('*')
          .eq('farm_id', farmId);

      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    // Fallback: try `tasks` table with farm_id or farmer_id (per database.md)
    try {
      final response = await _supabase
          .from('tasks')
          .select('*')
          .eq('farm_id', farmId);
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}

    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        final response = await _supabase
            .from('tasks')
            .select('*')
            .eq('farmer_id', user.id);
        return List<Map<String, dynamic>>.from(response);
      } catch (_) {}
    }

    return [];
  }
}
