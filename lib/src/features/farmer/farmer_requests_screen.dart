import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service/crop_request_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

/// Screen for managing incoming buyer crop requests and submitting price quotes
class FarmerRequestsScreen extends StatefulWidget {
  const FarmerRequestsScreen({super.key});

  @override
  State<FarmerRequestsScreen> createState() => _FarmerRequestsScreenState();
}

class _FarmerRequestsScreenState extends State<FarmerRequestsScreen> {
  late final CropRequestService _requestService;
  bool _isLoading = true;
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _requests = [];

  @override
  void initState() {
    super.initState();
    _requestService = CropRequestService();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() => _isLoading = true);
    final list = await _requestService.getCropRequests();
    if (mounted) {
      setState(() {
        _requests = list;
        _isLoading = false;
      });
    }
  }

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
            onPressed: () async {
              final price = double.tryParse(priceController.text.trim()) ?? 0;
              if (price <= 0) return;

              final reqId = request['id'] as String;
              try {
                await _requestService.submitQuote(
                  requestId: reqId,
                  offeredPrice: price,
                  notes: notesController.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadRequests();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Quote submitted to buyer!'),
                      backgroundColor: ColorUtils.forestGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit quote: $e')),
                  );
                }
              }
            },
            child: const Text('Send Quote', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCreateRequestDialog() {
    final cropController = TextEditingController();
    final qtyController = TextEditingController();
    final budgetController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.plusCircle, color: ColorUtils.forestGreen),
            SizedBox(width: 8),
            Text('Post Crop Request'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: cropController,
                decoration: const InputDecoration(
                  labelText: 'Crop / Produce Name',
                  hintText: 'e.g. Romaine Lettuce',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Required Quantity (kg)',
                  hintText: 'e.g. 150',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Budget (PHP/kg, Optional)',
                  hintText: 'e.g. 160',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: notesController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Notes / Special Requirements',
                  hintText: 'e.g. Weekly recurring order',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
            onPressed: () async {
              final crop = cropController.text.trim();
              final qty = double.tryParse(qtyController.text.trim()) ?? 0;
              final budget = double.tryParse(budgetController.text.trim());

              if (crop.isEmpty || qty <= 0) return;

              try {
                await _requestService.createCropRequest(
                  cropName: crop,
                  quantityKg: qty,
                  budgetPrice: budget,
                  notes: notesController.text.trim(),
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                _loadRequests();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Crop request posted!'),
                      backgroundColor: ColorUtils.forestGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to post request: $e')),
                  );
                }
              }
            },
            child: const Text('Post Request', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: Column(
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
                        ? ListView(
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                              Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(LucideIcons.inbox, size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text('No buyer requests found', style: AppTypography.bodyMedium(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, index) {
                              final req = filtered[index];
                              final buyer = req['buyer_name'] as String? ?? 'Buyer';
                              final crop = req['crop_name'] as String? ?? 'Produce';
                              final qty = (req['quantity_kg'] as num?)?.toDouble() ?? 0;
                              final date = req['target_date'] as String? ?? '';
                              final budget = (req['buyer_budget_price'] as num?)?.toDouble() ?? 0;
                              final status = (req['status'] as String? ?? 'Open').toLowerCase();
                              final notes = req['notes'] as String? ?? '';

                              final (String statusLabel, Color statusColor) = switch (status) {
                                'quoted' => ('Quote Sent', ColorUtils.terracotta),
                                'accepted' => ('Accepted', ColorUtils.forestGreen),
                                'declined' => ('Declined', Colors.red),
                                _ => ('Open Request', Colors.blue),
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
                                          style: AppTypography.subtitle1(
                                            color: ColorUtils.darkText,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: statusColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(6),
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
                                    const SizedBox(height: 6),
                                    Text(
                                      '$crop — ${qty.toStringAsFixed(0)} kg required',
                                      style: AppTypography.bodyMedium(
                                        color: ColorUtils.forestGreen,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (date.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text('Needed by: $date', style: AppTypography.caption(color: Colors.grey.shade600)),
                                    ],
                                    if (budget > 0) ...[
                                      const SizedBox(height: 2),
                                      Text('Target Budget: PHP ${budget.toStringAsFixed(0)} / kg', style: AppTypography.caption(color: Colors.grey.shade600)),
                                    ],
                                    if (notes.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Text(notes, style: AppTypography.bodySmall(color: Colors.grey.shade700)),
                                    ],
                                    const SizedBox(height: 12),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (status == 'open' || status == 'new')
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
                                            onPressed: () => _showSubmitQuoteDialog(req),
                                            child: const Text('Submit Quote', style: TextStyle(color: Colors.white)),
                                          ),
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRequestDialog,
        backgroundColor: ColorUtils.forestGreen,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Post Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
