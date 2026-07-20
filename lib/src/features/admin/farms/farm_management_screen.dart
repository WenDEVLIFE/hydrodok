import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/farm_repository.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Admin Farm Management Screen:
/// Verification & Map Approval Center where admins review incoming farmer verification
/// requests, inspect attached document proof, specify denial reasons if rejecting,
/// and approve verified farms to be published live on the public consumer map.
class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  late final FarmRepository _farmRepository;
  bool _isLoading = true;
  String _activeFilter = 'Pending'; // 'Pending', 'Verified', 'Rejected', 'All'
  List<Map<String, dynamic>> _farms = [];

  @override
  void initState() {
    super.initState();
    _farmRepository = SupabaseFarmRepository();
    _fetchFarms();
  }

  Future<void> _fetchFarms() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      var query = supabase.from('farms').select('*');

      if (_activeFilter == 'Pending') {
        query = query.eq('verification_status', 'pending');
      } else if (_activeFilter == 'Verified') {
        query = query.eq('verification_status', 'verified');
      } else if (_activeFilter == 'Rejected') {
        query = query.eq('verification_status', 'rejected');
      }

      final response = await query;
      if (mounted) {
        setState(() {
          _farms = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (_) {
      _farms = [];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveFarm(String farmId) async {
    try {
      await _farmRepository.approveFarmVerification(farmId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm Approved & Published to Public Map!'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
      _fetchFarms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving farm: $e')),
        );
      }
    }
  }

  Future<void> _rejectFarm(String farmId) async {
    final reasonController = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deny Farm Verification'),
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
                hintText: 'e.g., Document unreadable or invalid ID proof',
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
      await _farmRepository.rejectFarmVerification(farmId, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Farm Verification Rejected and Farmer Notified.')),
        );
      }
      _fetchFarms();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error rejecting farm: $e')),
        );
      }
    }
  }

  void _showDocumentPreview(String docUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Verification Document Proof',
                    style: AppTypography.heading3(color: ColorUtils.darkText, fontSize: 18),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  docUrl,
                  height: 350,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Container(
                    height: 200,
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Text('Failed to load document image'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(ctx).pop(),
                icon: const Icon(LucideIcons.check),
                label: const Text('Close Preview'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Farm Verification & Map Publishing',
                    style: AppTypography.heading2(color: ColorUtils.darkText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review submitted verification documents and publish approved farms to the map.',
                    style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: ColorUtils.forestGreen),
                onPressed: _fetchFarms,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Filter Tabs ────────────────────────────────────────────────
          Row(
            children: [
              _buildFilterChip('Pending', LucideIcons.clock),
              const SizedBox(width: 8),
              _buildFilterChip('Verified', LucideIcons.checkCheck),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', LucideIcons.xCircle),
              const SizedBox(width: 8),
              _buildFilterChip('All', LucideIcons.layers),
            ],
          ),
          const SizedBox(height: 20),

          // ── Farms List ─────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _farms.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.checkCheck, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No $_activeFilter farm verification requests',
                              style: AppTypography.bodyLarge(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _farms.length,
                        itemBuilder: (ctx, index) => _buildFarmCard(_farms[index]),
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
        _fetchFarms();
      },
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm) {
    final farmId = farm['id'] as String? ?? '';
    final name = farm['farm_name'] as String? ?? 'Unnamed Farm';
    final address = farm['address'] as String? ?? 'No address provided';
    final lat = farm['latitude'];
    final lng = farm['longitude'];
    final produce = (farm['produce_types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .join(', ') ??
        'Hydroponics';
    final docUrl = farm['verification_doc_url'] as String?;
    final status = farm['verification_status'] as String? ?? 'pending';
    final rejectionReason = farm['rejection_reason'] as String?;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    backgroundColor: ColorUtils.sageGreen,
                    radius: 20,
                    child: Icon(LucideIcons.sprout, color: ColorUtils.darkText, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: AppTypography.heading3(color: ColorUtils.darkText, fontSize: 18),
                      ),
                      Row(
                        children: [
                          const Icon(LucideIcons.mapPin, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            address,
                            style: AppTypography.bodySmall(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              _buildStatusBadge(status),
            ],
          ),
          const SizedBox(height: 16),

          // Coordinates & Produce Details
          Row(
            children: [
              Chip(
                backgroundColor: Colors.grey.shade100,
                label: Text(
                  lat != null && lng != null
                      ? 'Coords: $lat, $lng'
                      : 'No coordinates pinned',
                  style: AppTypography.bodySmall(color: Colors.grey.shade700),
                ),
              ),
              const SizedBox(width: 8),
              Chip(
                backgroundColor: ColorUtils.sageGreen.withOpacity(0.3),
                label: Text(
                  'Crops: $produce',
                  style: AppTypography.bodySmall(color: ColorUtils.darkText),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Document Proof preview button
          if (docUrl != null && docUrl.isNotEmpty) ...[
            InkWell(
              onTap: () => _showDocumentPreview(docUrl),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: ColorUtils.sageGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorUtils.forestGreen.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.fileText, size: 16, color: ColorUtils.forestGreen),
                    const SizedBox(width: 8),
                    Text(
                      'View Attached Document Proof',
                      style: AppTypography.bodySmall(
                        color: ColorUtils.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.externalLink, size: 14, color: ColorUtils.forestGreen),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          if (status == 'rejected' && rejectionReason != null) ...[
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
            const SizedBox(height: 12),
          ],

          // Admin Action Buttons
          if (status == 'pending') ...[
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                  ),
                  icon: const Icon(LucideIcons.x, size: 18),
                  label: const Text('Reject Verification'),
                  onPressed: () => _rejectFarm(farmId),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.forestGreen,
                    foregroundColor: ColorUtils.pureWhite,
                  ),
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Approve & Publish to Map'),
                  onPressed: () => _approveFarm(farmId),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.orange.shade100;
    Color text = Colors.orange.shade900;
    String label = 'Pending Approval';

    if (status == 'verified') {
      bg = Colors.green.shade100;
      text = Colors.green.shade900;
      label = 'Verified & Published';
    } else if (status == 'rejected') {
      bg = Colors.red.shade100;
      text = Colors.red.shade900;
      label = 'Rejected';
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
