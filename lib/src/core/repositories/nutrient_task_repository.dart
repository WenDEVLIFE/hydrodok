import 'package:supabase_flutter/supabase_flutter.dart';

import '../service/nutrient_task_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Abstract Nutrient & Task Repository Interface
// ─────────────────────────────────────────────────────────────────────────────

abstract class NutrientTaskRepository {
  /// Logs a new nutrient application.
  Future<Map<String, dynamic>> logNutrient({
    required String farmId,
    required String nutrientName,
    required double amount,
    String? notes,
  });

  /// Fetches all nutrient logs for a farm.
  Future<List<Map<String, dynamic>>> getNutrientLogs(String farmId);

  /// Streams nutrient logs for a farm in real time.
  Stream<List<Map<String, dynamic>>> watchNutrientLogs(String farmId);

  /// Adds a new farm task.
  Future<Map<String, dynamic>> addTask({
    required String farmId,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
  });

  /// Updates status of a task (e.g. 'pending' or 'completed').
  Future<void> updateTaskStatus(String taskId, String status);

  /// Deletes a task.
  Future<void> deleteTask(String taskId);

  /// Fetches all tasks for a farm.
  Future<List<Map<String, dynamic>>> getFarmTasks(String farmId);

  /// Streams farm tasks for a farm in real time.
  Stream<List<Map<String, dynamic>>> watchFarmTasks(String farmId);
}

// ─────────────────────────────────────────────────────────────────────────────
//  Supabase Implementation
// ─────────────────────────────────────────────────────────────────────────────

class SupabaseNutrientTaskRepository implements NutrientTaskRepository {
  final NutrientTaskService _service;

  SupabaseNutrientTaskRepository({
    NutrientTaskService? service,
    SupabaseClient? supabaseClient,
  }) : _service = service ??
            NutrientTaskService(
              supabase: supabaseClient ?? Supabase.instance.client,
            );

  @override
  Future<Map<String, dynamic>> logNutrient({
    required String farmId,
    required String nutrientName,
    required double amount,
    String? notes,
  }) {
    return _service.logNutrient(
      farmId: farmId,
      nutrientName: nutrientName,
      amount: amount,
      notes: notes,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getNutrientLogs(String farmId) {
    return _service.getNutrientLogs(farmId);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchNutrientLogs(String farmId) {
    return _service.watchNutrientLogs(farmId);
  }

  @override
  Future<Map<String, dynamic>> addTask({
    required String farmId,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
  }) {
    return _service.addTask(
      farmId: farmId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
    );
  }

  @override
  Future<void> updateTaskStatus(String taskId, String status) {
    return _service.updateTaskStatus(taskId, status);
  }

  @override
  Future<void> deleteTask(String taskId) {
    return _service.deleteTask(taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> getFarmTasks(String farmId) {
    return _service.getFarmTasks(farmId);
  }

  @override
  Stream<List<Map<String, dynamic>>> watchFarmTasks(String farmId) {
    return _service.watchFarmTasks(farmId);
  }
}
