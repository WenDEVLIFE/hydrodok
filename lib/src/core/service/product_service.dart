import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles product CRUD and order management for farmers.
class ProductService {
  final SupabaseClient _supabase;

  ProductService({required SupabaseClient supabase}) : _supabase = supabase;

  // ── Products ────────────────────────────────────────────────────────────

  /// Creates a new product. farmer_id = current user. Status defaults to 'pending'.
  Future<void> createProduct({
    required String name,
    required String description,
    required double pricePerKg,
    required String unit,
    required int stockQuantity,
    String? imageUrl,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated. Please log in.');

    // Fetch farm_id if present for this farmer
    String? farmId;
    try {
      final farm = await _supabase
          .from('farms')
          .select('id')
          .eq('owner_id', user.id)
          .maybeSingle();
      farmId = farm?['id'] as String?;
    } catch (_) {}

    final productPayload = <String, dynamic>{
      'farmer_id': user.id,
      'name': name,
      'product_name': name,
      'description': description,
      'price': pricePerKg,
      'price_per_kg': pricePerKg,
      'unit': unit,
      'stock': stockQuantity,
      'stock_quantity': stockQuantity,
      'image_url': imageUrl ?? '',
      'status': 'pending',
    };
    if (farmId != null) {
      productPayload['farm_id'] = farmId;
    }

    try {
      await _supabase.from('products').insert(productPayload);
    } catch (e) {
      final fallbackPayload = Map<String, dynamic>.from(productPayload);
      fallbackPayload.remove('farm_id');
      await _supabase.from('products').insert(fallbackPayload);
    }
  }

  /// Updates a product owned by the farmer.
  Future<void> updateProduct(
    String productId, {
    String? name,
    String? description,
    double? pricePerKg,
    String? unit,
    int? stockQuantity,
    String? imageUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (pricePerKg != null) updates['price_per_kg'] = pricePerKg;
    if (unit != null) updates['unit'] = unit;
    if (stockQuantity != null) updates['stock_quantity'] = stockQuantity;
    if (imageUrl != null) updates['image_url'] = imageUrl;

    await _supabase.from('products').update(updates).eq('id', productId);
  }

  /// Deletes a product.
  Future<void> deleteProduct(String productId) async {
    await _supabase.from('products').delete().eq('id', productId);
  }

  /// Gets all products for the current farmer (by farmer_id = auth.uid()).
  Future<List<Map<String, dynamic>>> getMyProducts() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final result = await _supabase
        .from('products')
        .select('*')
        .eq('farmer_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Realtime stream of products for the current farmer.
  Stream<List<Map<String, dynamic>>> watchMyProducts() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    yield* _supabase
        .from('products')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', user.id)
        .order('created_at', ascending: false);
  }

  // ── Orders ──────────────────────────────────────────────────────────────

  /// Gets all orders for the current farmer's products.
  Future<List<Map<String, dynamic>>> getMyOrders() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return [];

    final result = await _supabase
        .from('orders')
        .select('*, products(name, unit, price_per_kg)')
        .eq('farmer_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Realtime stream of orders for the current farmer.
  Stream<List<Map<String, dynamic>>> watchMyOrders() async* {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    yield* _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('farmer_id', user.id)
        .order('created_at', ascending: false);
  }

  /// Updates order status (confirmed, delivered, cancelled).
  Future<void> updateOrderStatus(String orderId, String status) async {
    await _supabase.from('orders').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }
}
