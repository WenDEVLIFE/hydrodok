import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles Buyer Crop Requests & Farmer price quotes.
class CropRequestService {
  final SupabaseClient _supabase;

  CropRequestService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches all buyer crop requests with submitted farmer quotes.
  Future<List<Map<String, dynamic>>> getCropRequests() async {
    try {
      final response = await _supabase
          .from('buyer_crop_requests')
          .select('*, crop_quotes(*)')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('CropRequestService getCropRequests error: $e');
      try {
        final fallback = await _supabase
            .from('buyer_crop_requests')
            .select('*')
            .order('created_at', ascending: false);
        return List<Map<String, dynamic>>.from(fallback);
      } catch (e2) {
        debugPrint('CropRequestService fallback failed: $e2');
        return [];
      }
    }
  }

  /// Creates a new buyer crop request (e.g. bulk produce requirement).
  Future<Map<String, dynamic>> createCropRequest({
    required String cropName,
    required double quantityKg,
    double? budgetPrice,
    String? targetDate,
    String notes = '',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to create a crop request.');

    // Fetch user profile full_name if available
    String buyerName = 'Consumer';
    try {
      final profile = await _supabase
          .from('profiles')
          .select('full_name')
          .eq('id', user.id)
          .maybeSingle();
      if (profile != null && profile['full_name'] != null) {
        buyerName = profile['full_name'] as String;
      }
    } catch (_) {}

    final payload = <String, dynamic>{
      'buyer_id': user.id,
      'buyer_name': buyerName,
      'crop_name': cropName,
      'quantity_kg': quantityKg,
      'notes': notes,
      'status': 'Open',
    };
    if (budgetPrice != null) payload['buyer_budget_price'] = budgetPrice;
    if (targetDate != null && targetDate.isNotEmpty) payload['target_date'] = targetDate;

    final response = await _supabase
        .from('buyer_crop_requests')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Submits a farmer price quote for a specific buyer crop request.
  Future<void> submitQuote({
    required String requestId,
    required double offeredPrice,
    String notes = '',
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Must be logged in to submit a quote.');

    // 1. Insert quote
    await _supabase.from('crop_quotes').insert({
      'request_id': requestId,
      'farmer_id': user.id,
      'offered_price': offeredPrice,
      'notes': notes,
      'status': 'Pending',
    });

    // 2. Update request status to 'Quoted' if currently 'Open'
    try {
      await _supabase
          .from('buyer_crop_requests')
          .update({'status': 'Quoted'})
          .eq('id', requestId)
          .eq('status', 'Open');
    } catch (_) {}
  }
}
