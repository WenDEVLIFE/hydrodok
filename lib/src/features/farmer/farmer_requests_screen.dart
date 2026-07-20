import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

/// Screen for managing incoming buyer crop requests and submitting price quotes
class FarmerRequestsScreen extends StatefulWidget {
  const FarmerRequestsScreen({super.key});

  @override
  State<FarmerRequestsScreen> createState() => _FarmerRequestsScreenState();
}

class _FarmerRequestsScreenState extends State<FarmerRequestsScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, dynamic>> _requests = [
    {
      'id': 'req-1',
      'buyer_name': 'GreenBite Salad Bar',
      'crop_name': 'Hydroponic Romaine Lettuce',
      'quantity_kg': 150.0,
      'target_date': '2026-07-28',
      'buyer_budget_price': 160.0,
      'status': 'new',
      'notes': 'Weekly recurring order needed for main store branch.',
    },
    {
      'id': 'req-2',
      'buyer_name': 'FreshChoice Supermarket',
      'crop_name': 'Butterhead & Lollo Rossa',
      'quantity_kg': 400.0,
      'target_date': '2026-08-01',
      'buyer_budget_price': 175.0,
      'status': 'quoted',
      'quoted_price': 170.0,
      'notes': 'Must be packed in 250g clamshell containers.',
    },
    {
      'id': 'req-3',
      'buyer_name': 'Urban Gourmet Kitchen',
      'crop_name': 'Hydroponic Basil & Mint',
      'quantity_kg': 50.0,
      'target_date': '2026-07-25',
      'buyer_budget_price': 250.0,
      'status': 'accepted',
      'quoted_price': 240.0,
      'notes': 'Urgent requirement for weekend catering events.',
    },
  ];

  void _showSubmitQuoteDialog(Map<String, dynamic> request) {
    final priceController = TextEditingController(
      text: (request['buyer_budget_price'] as num).toString(),
    );
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.fileText, color: ColorUtils.forestGreen),
            SizedBox(width: 8),
            Text('Submit Price Quote'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buyer: ${request['buyer_name']}',
              style: AppTypography.bodyMedium(fontWeight: FontWeight.bold, color: ColorUtils.darkText),
            ),
            Text(
              'Crop: ${request['crop_name']} (${request['quantity_kg']} kg)',
              style: AppTypography.bodySmall(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Your Offered Price (PHP / kg)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Terms / Notes for Buyer (Optional)',
                hintText: 'e.g. Price includes delivery fee',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
            onPressed: () {
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              if (price <= 0) return;

              setState(() {
                request['status'] = 'quoted';
                request['quoted_price'] = price;
              });

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Quote submitted to buyer!'),
                  backgroundColor: ColorUtils.forestGreen,
                ),
              );
            },
            child: const Text('Send Quote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(Map<String, dynamic> request, String newStatus) {
    setState(() {
      request['status'] = newStatus;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newStatus == 'accepted' ? 'Request accepted!' : 'Request declined.'),
        backgroundColor: newStatus == 'accepted' ? ColorUtils.forestGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _requests.where((r) {
      if (_selectedFilter == 'New') return r['status'] == 'new';
      if (_selectedFilter == 'Quoted') return r['status'] == 'quoted';
      if (_selectedFilter == 'Accepted') return r['status'] == 'accepted';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text('Buyer Crop Requests', style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      body: Column(
        children: [
          // ── Filter Chips ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('New'),
                const SizedBox(width: 8),
                _buildFilterChip('Quoted'),
                const SizedBox(width: 8),
                _buildFilterChip('Accepted'),
              ],
            ),
          ),

          // ── Requests List ────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text('No buyer requests found', style: AppTypography.bodyMedium(color: Colors.grey.shade600)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final req = filtered[index];
                      final buyer = req['buyer_name'] as String;
                      final crop = req['crop_name'] as String;
                      final qty = (req['quantity_kg'] as num).toDouble();
                      final date = req['target_date'] as String;
                      final budget = (req['buyer_budget_price'] as num).toDouble();
                      final status = req['status'] as String;
                      final quotedPrice = (req['quoted_price'] as num?)?.toDouble();
                      final notes = req['notes'] as String? ?? '';

                      final (String statusLabel, Color statusColor) = switch (status) {
                        'quoted' => ('Quote Sent', ColorUtils.terracotta),
                        'accepted' => ('Accepted', ColorUtils.sageGreen),
                        'declined' => ('Declined', Colors.red),
                        _ => ('New Request', Colors.blue),
                      };

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
                                Text(
                                  buyer,
                                  style: AppTypography.heading3(color: ColorUtils.darkText, fontSize: 16),
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
                              'Requested: $crop',
                              style: AppTypography.bodyMedium(fontWeight: FontWeight.w600, color: ColorUtils.darkText),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Quantity: ${qty.toInt()} kg',
                                  style: AppTypography.bodySmall(color: Colors.grey.shade600),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Target: $date',
                                  style: AppTypography.bodySmall(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Buyer Budget: PHP ${budget.toStringAsFixed(0)} / kg',
                              style: AppTypography.bodySmall(color: ColorUtils.forestGreen, fontWeight: FontWeight.bold),
                            ),
                            if (quotedPrice != null)
                              Text(
                                'Your Quote: PHP ${quotedPrice.toStringAsFixed(0)} / kg',
                                style: AppTypography.bodySmall(color: ColorUtils.sageGreen, fontWeight: FontWeight.bold),
                              ),
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                '"$notes"',
                                style: AppTypography.bodySmall(color: Colors.grey.shade500).copyWith(fontStyle: FontStyle.italic),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (status == 'new') ...[
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                                    onPressed: () => _updateStatus(req, 'declined'),
                                    child: const Text('Decline'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
                                    onPressed: () => _showSubmitQuoteDialog(req),
                                    child: const Text('Submit Quote', style: TextStyle(color: Colors.white)),
                                  ),
                                ] else if (status == 'quoted') ...[
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.sageGreen),
                                    onPressed: () => _updateStatus(req, 'accepted'),
                                    child: const Text('Mark Accepted', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      );
                    },
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
        color: isSelected ? Colors.white : ColorUtils.darkText,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => setState(() => _selectedFilter = label),
    );
  }
}
