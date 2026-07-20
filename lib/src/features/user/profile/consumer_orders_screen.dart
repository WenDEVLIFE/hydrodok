import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Consumer Orders Screen:
/// Shows the current user's purchase history with order items and statuses.
class ConsumerOrdersScreen extends StatefulWidget {
  const ConsumerOrdersScreen({super.key});

  @override
  State<ConsumerOrdersScreen> createState() => _ConsumerOrdersScreenState();
}

class _ConsumerOrdersScreenState extends State<ConsumerOrdersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      List<dynamic> response;
      try {
        response = await Supabase.instance.client
            .from('orders')
            .select('''
              *,
              order_items(
                *,
                products:product_id(*)
              )
            ''')
            .eq('buyer_id', user.id)
            .order('created_at', ascending: false);
      } catch (e) {
        debugPrint('Detailed order_items query failed, falling back to simple orders: $e');
        response = await Supabase.instance.client
            .from('orders')
            .select('*')
            .eq('buyer_id', user.id)
            .order('created_at', ascending: false);
      }

      final orders = List<Map<String, dynamic>>.from(response);

      // Fetch farm names separately because orders.farmer_id references auth.users,
      // not farms.id.
      for (final order in orders) {
        final farmerId = order['farmer_id'] as String?;
        if (farmerId == null) continue;
        try {
          final farmRes = await Supabase.instance.client
              .from('farms')
              .select('farm_name')
              .eq('owner_id', farmerId)
              .maybeSingle();
          order['farm_name'] = farmRes?['farm_name'] as String? ?? 'Unknown Farm';
        } catch (e) {
          debugPrint('ConsumerOrdersScreen farm lookup failed: $e');
          order['farm_name'] = 'Unknown Farm';
        }
      }

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('ConsumerOrdersScreen load error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load orders: $e')),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'completed':
      case 'delivered':
        return ColorUtils.forestGreen;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'rejected':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'My Orders',
            style: AppTypography.heading3(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: ColorUtils.darkText),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadOrders,
                child: _orders.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.shoppingBag,
                                    size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No orders yet',
                                  style: AppTypography.bodyLarge(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Browse farms on the map and place your first order!',
                                  style: AppTypography.bodySmall(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
                      ),
              ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final status = order['status'] as String? ?? 'pending';
    final total = (order['total'] as num?)?.toDouble() ??
        (order['total_price'] as num?)?.toDouble() ?? 0;
    final createdAt = order['created_at'] as String? ?? '';
    final farmName = order['farm_name'] as String? ?? 'Unknown Farm';
    final deliveryAddr = order['delivery_address'] as String? ?? '';
    final items = List<Map<String, dynamic>>.from(order['order_items'] as List<dynamic>? ?? []);

    String timeStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        timeStr = '${dt.month}/${dt.day}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  farmName,
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTypography.caption(
                    color: _statusColor(status),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            timeStr,
            style: AppTypography.caption(color: Colors.grey.shade500),
          ),
          if (deliveryAddr.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(LucideIcons.mapPin, size: 12, color: ColorUtils.forestGreen),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    deliveryAddr,
                    style: AppTypography.caption(color: Colors.grey.shade600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const Divider(height: 24),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: ColorUtils.sageGreen.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(LucideIcons.leaf,
                        color: ColorUtils.forestGreen, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Produce Order',
                      style: AppTypography.bodySmall(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    'PHP ${total.toStringAsFixed(0)}',
                    style: AppTypography.bodySmall(
                      color: ColorUtils.forestGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            )
          else
            ...items.map((item) {
              final product = item['products'] as Map<String, dynamic>?;
              final name = product?['name'] as String? ?? 'Unknown Product';
              final quantity = item['quantity'] as int? ?? 0;
              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;
              final unit = product?['unit'] as String? ?? 'kg';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: ColorUtils.sageGreen.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(LucideIcons.leaf,
                          color: ColorUtils.forestGreen, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.bodySmall(
                              color: ColorUtils.darkText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '$quantity $unit',
                            style: AppTypography.caption(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'PHP ${subtotal.toStringAsFixed(0)}',
                      style: AppTypography.bodySmall(
                        color: ColorUtils.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.bodyMedium(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'PHP ${total.toStringAsFixed(0)}',
                style: AppTypography.subtitle1(
                  color: ColorUtils.forestGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
