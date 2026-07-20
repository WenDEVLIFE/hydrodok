import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Admin Product Approval Screen:
/// Review pending product submissions from farmers, approve or reject them.
/// Approved products become visible on the farmer's public listing.
class MarketplaceManagementScreen extends StatefulWidget {
  const MarketplaceManagementScreen({super.key});

  @override
  State<MarketplaceManagementScreen> createState() =>
      _MarketplaceManagementScreenState();
}

class _MarketplaceManagementScreenState
    extends State<MarketplaceManagementScreen> {
  String _activeFilter = 'Pending'; // All | Pending | Approved | Rejected
  bool _isLoading = true;
  List<Map<String, dynamic>> _products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      var query = supabase
          .from('products')
          .select('*, profiles!farmer_id(full_name)');

      if (_activeFilter == 'Pending') {
        query = query.eq('status', 'pending');
      } else if (_activeFilter == 'Approved') {
        query = query.eq('status', 'approved');
      } else if (_activeFilter == 'Rejected') {
        query = query.eq('status', 'rejected');
      }

      final response = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (_) {
      _products = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveProduct(String productId) async {
    try {
      // Get product with farmer info for notification
      final productData = await Supabase.instance.client
          .from('products')
          .select('name, farmer_id')
          .eq('id', productId)
          .maybeSingle();

      try {
        await Supabase.instance.client.from('products').update({
          'status': 'approved',
          'rejection_reason': null,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', productId);
      } catch (_) {
        await Supabase.instance.client.from('products').update({
          'status': 'approved',
        }).eq('id', productId);
      }

      // Notify the farmer
      final farmerId = productData?['farmer_id'] as String?;
      final productName = productData?['name'] as String? ?? 'Product';
      if (farmerId != null) {
        try {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': farmerId,
            'title': 'Product Approved! 🎉',
            'message': 'Your product "$productName" has been approved and is now live!',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product Approved!'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
      _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving product: $e')),
        );
      }
    }
  }

  Future<void> _rejectProduct(String productId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the reason for rejection (this will be sent to the farmer):',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'e.g., Product does not meet quality standards',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Rejection', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final reason = reasonController.text.trim();

      // Get product with farm owner info for notification
      final productData = await Supabase.instance.client
          .from('products')
          .select('name, farmer_id')
          .eq('id', productId)
          .maybeSingle();

      try {
        await Supabase.instance.client.from('products').update({
          'status': 'rejected',
          'rejection_reason': reason.isEmpty ? 'Did not meet requirements.' : reason,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', productId);
      } catch (_) {
        await Supabase.instance.client.from('products').update({
          'status': 'rejected',
        }).eq('id', productId);
      }

      // Notify the farmer
      final ownerId = productData?['farms']?['owner_id'] as String?;
      final productName = productData?['name'] as String? ?? 'Product';
      if (ownerId != null) {
        try {
          await Supabase.instance.client.from('notifications').insert({
            'user_id': ownerId,
            'title': 'Product Rejected',
            'message': 'Your product "$productName" was rejected. Reason: ${reason.isEmpty ? "Did not meet requirements" : reason}.',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product Rejected and Farmer Notified.')),
        );
      }
      _fetchProducts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Approval',
                    style: AppTypography.heading2(color: ColorUtils.darkText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and approve farmer product listings before they go live.',
                    style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: ColorUtils.forestGreen),
                onPressed: _fetchProducts,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Filter Tabs ─────────────────────────────────────────────────
          Row(
            children: [
              _buildFilterChip('Pending', LucideIcons.clock),
              const SizedBox(width: 8),
              _buildFilterChip('Approved', LucideIcons.checkCheck),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', LucideIcons.xCircle),
              const SizedBox(width: 8),
              _buildFilterChip('All', LucideIcons.layers),
            ],
          ),
          const SizedBox(height: 20),

          // ── Products List ───────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.package, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No $_activeFilter products',
                              style: AppTypography.bodyLarge(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (ctx, index) => _buildProductCard(_products[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _activeFilter == label;
    return FilterChip(
      selected: isSelected,
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? ColorUtils.pureWhite : ColorUtils.darkText,
      ),
      label: Text(label),
      labelStyle: TextStyle(
        color: isSelected ? ColorUtils.pureWhite : ColorUtils.darkText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      selectedColor: ColorUtils.forestGreen,
      backgroundColor: Colors.grey.shade200,
      onSelected: (_) {
        setState(() => _activeFilter = label);
        _fetchProducts();
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productId = product['id'] as String? ?? '';
    final name = product['name'] as String? ?? 'Unnamed Product';
    final description = product['description'] as String? ?? '';
    final price = (product['price_per_kg'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'kg';
    final stock = product['stock_quantity'] as int? ?? 0;
    final status = product['status'] as String? ?? 'pending';
    final rejectionReason = product['rejection_reason'] as String?;

    // Get farmer info from joined profiles
    final profiles = product['profiles'] as Map<String, dynamic>?;
    final farmerName = profiles?['full_name'] as String? ?? 'Unknown Farmer';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: product name + status badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: ColorUtils.forestGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.leaf, color: ColorUtils.forestGreen, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.heading3(color: ColorUtils.darkText, fontSize: 18),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),

          // Details row: farm, farmer, price, stock
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(LucideIcons.user, size: 16, color: Colors.grey),
                backgroundColor: Colors.grey.shade100,
                label: Text(
                  'By $farmerName',
                  style: AppTypography.bodySmall(color: Colors.grey.shade700),
                ),
              ),
              Chip(
                avatar: const Icon(LucideIcons.banknote, size: 16, color: ColorUtils.forestGreen),
                backgroundColor: Colors.grey.shade100,
                label: Text(
                  '₱${price.toStringAsFixed(0)} / $unit',
                  style: AppTypography.bodySmall(
                    color: ColorUtils.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Chip(
                avatar: const Icon(LucideIcons.package, size: 16, color: Colors.grey),
                backgroundColor: Colors.grey.shade100,
                label: Text(
                  '$stock in stock',
                  style: AppTypography.bodySmall(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),

          // Rejection reason (if rejected)
          if (status == 'rejected' && rejectionReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.alertTriangle, size: 16, color: Colors.redAccent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Rejection Reason: $rejectionReason',
                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Action buttons (only for pending)
          if (status == 'pending') ...[
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: const Icon(LucideIcons.x, size: 18),
                  label: const Text('Reject'),
                  onPressed: () => _rejectProduct(productId),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.forestGreen,
                    foregroundColor: ColorUtils.pureWhite,
                  ),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Approve'),
                  onPressed: () => _approveProduct(productId),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case 'approved':
        bg = Colors.green.shade100;
        text = Colors.green.shade900;
        label = 'Approved';
      case 'rejected':
        bg = Colors.red.shade100;
        text = Colors.red.shade900;
        label = 'Rejected';
      default:
        bg = Colors.orange.shade100;
        text = Colors.orange.shade900;
        label = 'Pending Approval';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
