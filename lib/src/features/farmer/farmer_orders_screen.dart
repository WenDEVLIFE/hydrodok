import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

/// Comprehensive Order Management Screen for Farmers
class FarmerOrdersScreen extends StatefulWidget {
  const FarmerOrdersScreen({super.key});

  @override
  State<FarmerOrdersScreen> createState() => _FarmerOrdersScreenState();
}

class _FarmerOrdersScreenState extends State<FarmerOrdersScreen> {
  String _selectedFilter = 'All';
  late Future<List<Map<String, dynamic>>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Map<String, dynamic>>> _loadOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final response = await Supabase.instance.client
        .from('orders')
        .select('*, order_items(*, products:product_id(name))')
        .eq('farmer_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  void _reloadOrders() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);

      _reloadOrders();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to $newStatus!'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating order: $e')),
        );
      }
    }
  }

  void _showStatusDialog(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final currentStatus = order['status'] as String? ?? 'pending';

    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Update Order Status'),
        children: [
          _statusOption(ctx, orderId, currentStatus, 'pending', 'Pending Confirmation', ColorUtils.terracotta),
          _statusOption(ctx, orderId, currentStatus, 'confirmed', 'Confirmed & Packing', ColorUtils.sageGreen),
          _statusOption(ctx, orderId, currentStatus, 'in_transit', 'Out for Delivery', Colors.blue),
          _statusOption(ctx, orderId, currentStatus, 'delivered', 'Delivered to Customer', ColorUtils.forestGreen),
          _statusOption(ctx, orderId, currentStatus, 'cancelled', 'Cancelled', Colors.red),
        ],
      ),
    );
  }

  Widget _statusOption(
    BuildContext ctx,
    String orderId,
    String current,
    String value,
    String label,
    Color color,
  ) {
    return SimpleDialogOption(
      onPressed: () {
        Navigator.of(ctx).pop();
        if (current != value) {
          _updateOrderStatus(orderId, value);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              current == value ? LucideIcons.checkCircle2 : LucideIcons.circle,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontWeight: current == value ? FontWeight.bold : FontWeight.normal,
                color: ColorUtils.pureWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text('Customer Orders', style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      body: Column(
        children: [
          // ── Status Filter Bar ─────────────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Pending'),
                const SizedBox(width: 8),
                _buildFilterChip('Confirmed'),
                const SizedBox(width: 8),
                _buildFilterChip('In Transit'),
                const SizedBox(width: 8),
                _buildFilterChip('Delivered'),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled'),
              ],
            ),
          ),

          // ── Orders List ──────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _ordersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading orders: ${snapshot.error}',
                        style: AppTypography.bodySmall(color: Colors.redAccent),
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];
                final filtered = orders.where((o) {
                  final status = (o['status'] as String? ?? 'pending').toLowerCase();
                  if (_selectedFilter == 'Pending') return status == 'pending';
                  if (_selectedFilter == 'Confirmed') return status == 'confirmed';
                  if (_selectedFilter == 'In Transit') return status == 'in_transit' || status == 'in transit';
                  if (_selectedFilter == 'Delivered') return status == 'delivered';
                  if (_selectedFilter == 'Cancelled') return status == 'cancelled';
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.shoppingBag, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No $_selectedFilter orders', style: AppTypography.bodyMedium(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _reloadOrders(),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) => _buildOrderCard(filtered[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final status = order['status'] as String? ?? 'pending';
    final totalPrice = (order['total'] as num?)?.toDouble() ?? 0;
    final items = List<Map<String, dynamic>>.from(order['order_items'] as List<dynamic>? ?? []);
    final qty = items.fold<int>(0, (sum, item) => sum + ((item['quantity'] as int?) ?? 0));
    final itemNames = items.map((item) {
      final product = item['products'] as Map<String, dynamic>?;
      return product?['name'] as String? ?? 'Produce';
    }).toList();

    final (String statusLabel, Color statusColor) = switch (status.toLowerCase()) {
      'confirmed' => ('Confirmed', ColorUtils.sageGreen),
      'in_transit' || 'in transit' => ('In Transit', Colors.blue),
      'delivered' => ('Delivered', ColorUtils.forestGreen),
      'cancelled' => ('Cancelled', Colors.red),
      _ => ('Pending', ColorUtils.terracotta),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${orderId.substring(0, 8).toUpperCase()}',
                style: AppTypography.bodyMedium(fontWeight: FontWeight.bold, color: ColorUtils.darkText),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            itemNames.isNotEmpty ? itemNames.join(', ') : 'Produce items',
            style: AppTypography.bodySmall(color: Colors.grey.shade600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$qty item${qty == 1 ? '' : 's'}',
                style: AppTypography.bodySmall(color: Colors.grey.shade600),
              ),
              Text(
                'PHP ${totalPrice.toStringAsFixed(0)}',
                style: AppTypography.heading3(color: ColorUtils.forestGreen, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showStatusDialog(order),
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Update Order Status'),
              style: OutlinedButton.styleFrom(
                foregroundColor: ColorUtils.forestGreen,
                side: const BorderSide(color: ColorUtils.forestGreen),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      selectedColor: ColorUtils.forestGreen,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : ColorUtils.pureWhite,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }
}
