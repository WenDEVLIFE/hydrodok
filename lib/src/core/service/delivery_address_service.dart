import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for managing user delivery addresses in `delivery_addresses` table.
class DeliveryAddressService {
  final SupabaseClient _supabase;

  DeliveryAddressService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Fetches all delivery addresses for the current user.
  Future<List<Map<String, dynamic>>> getUserAddresses() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final response = await _supabase
          .from('delivery_addresses')
          .select('*')
          .eq('profile_id', user.id)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DeliveryAddressService getUserAddresses error: $e');
      return [];
    }
  }

  /// Adds a new delivery address for the current user.
  Future<Map<String, dynamic>?> addAddress({
    required String address,
    String label = 'Home',
    double? latitude,
    double? longitude,
    bool isDefault = false,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated.');

    if (isDefault) {
      // Unset previous defaults
      try {
        await _supabase
            .from('delivery_addresses')
            .update({'is_default': false})
            .eq('profile_id', user.id);
      } catch (_) {}
    }

    final payload = <String, dynamic>{
      'profile_id': user.id,
      'label': label.trim().isEmpty ? 'Home' : label.trim(),
      'address': address.trim(),
      'is_default': isDefault,
    };
    if (latitude != null) payload['latitude'] = latitude;
    if (longitude != null) payload['longitude'] = longitude;

    final response = await _supabase
        .from('delivery_addresses')
        .insert(payload)
        .select()
        .single();

    return Map<String, dynamic>.from(response);
  }

  /// Sets an address as the default for the current user.
  Future<void> setDefaultAddress(String addressId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // Unset all defaults first
    await _supabase
        .from('delivery_addresses')
        .update({'is_default': false})
        .eq('profile_id', user.id);

    // Set target address as default
    await _supabase
        .from('delivery_addresses')
        .update({'is_default': true})
        .eq('id', addressId);
  }

  /// Deletes a delivery address by ID.
  Future<void> deleteAddress(String addressId) async {
    await _supabase
        .from('delivery_addresses')
        .delete()
        .eq('id', addressId);
  }
}
