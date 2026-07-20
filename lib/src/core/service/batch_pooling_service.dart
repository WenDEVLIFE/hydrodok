import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Batch Pooling CRUD & Farmer contributions for collective produce orders.
class BatchPoolingService {
  final SupabaseClient _supabase;

  BatchPoolingService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches all active & past batch pools with member details.
  Future<List<Map<String, dynamic>>> getBatchPools() async {
    try {
      final response = await _supabase
          .from('batch_pools')
          .select('*, batch_members(*)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('BatchPoolingService getBatchPools error: $e');
      try {
        final fallback = await _supabase
            .from('batch_pools')
            .select('*')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(fallback);
      } catch (e2) {
        debugPrint('BatchPoolingService fallback failed: $e2');
        return [];
      }
    }
  }

  /// Creates a new batch pool campaign.
  Future<Map<String, dynamic>> createBatchPool({
    required String title,
    required String cropName,
    required double targetQuantity,
    double targetPrice = 0,
    String? deadline,
  }) async {
    final user = _supabase.auth.currentUser;
    final payload = <String, dynamic>{
      'title': title,
      'crop_name': cropName,
      'target_quantity': targetQuantity,
      'current_quantity': 0,
      'target_price': targetPrice,
      'status': 'Open',
    };
    if (user != null) payload['created_by'] = user.id;
    if (deadline != null && deadline.isNotEmpty) payload['deadline'] = deadline;

    final response = await _supabase
        .from('batch_pools')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Contributes produce quantity to an existing batch pool.
  Future<void> contributeToPool({
    required String batchId,
    required double quantity,
    required double currentQuantity,
    required double targetQuantity,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to contribute.');

    // 1. Insert member record
    await _supabase.from('batch_members').insert({
      'batch_id': batchId,
      'farmer_id': user.id,
      'quantity': quantity,
    });

    // 2. Update pool current_quantity and status
    final newCurrent = currentQuantity + quantity;
    final newStatus = newCurrent >= targetQuantity ? 'Filled' : 'Open';

    await _supabase.from('batch_pools').update({
      'current_quantity': newCurrent,
      'status': newStatus,
    }).eq('id', batchId);
  }
}
