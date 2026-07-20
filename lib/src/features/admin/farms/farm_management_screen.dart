import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/service/farm_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Admin Farm Verification & Map Publishing Management Screen:
///
/// Refactored to focus exclusively on reviewing incoming farmer verification
/// requests, inspecting attached documents & coordinates, and approving
/// farms to publish them live to the public MapScreen.
class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  late final FarmService _farmService;
  String _activeFilter = 'Pending'; // Pending | Verified | Rejected
  bool _isLoading = true;
  List<Map<String, dynamic>> _farms = [];

  @override
  void initState() {
    super.initState();
    _farmService = FarmService(supabase: Supabase.instance.client);
    _fetchFarms();
  }

  Future<void> _fetchFarms() async {
    setState(() => _isLoading = true);
    try {
      if (_activeFilter == 'Pending') {
        _farms = await _farmService.getPendingFarms();
      } else if (_activeFilter == 'Verified') {
        _farms = await _farmService.getVerifiedFarms();
      } else {
        final res = await Supabase.instance.client
            .from('farms')
            .select('*')
            .eq('verification_status', 'rejected');
        _farms = List<Map<String, dynamic>>.from(res);
      }
    } catch (_) {
      // Fallback mock data if network/table not loaded
      _farms = [
        {
          'id': 'farm-1',
          'farm_name': 'Pamahalaang Hydro Greens',
          'address': 'General Trias, Cavite',
          'latitude': 14.3858,
          'longitude': 120.8804,
          'produce_types': ['Lettuce', 'Spinach'],
          'verification_status': 'pending',
          'verification_doc_url': 'https://example.com/doc.pdf',
        },
      ];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveFarm(String farmId) async {
    try {
      await _farmService.approveFarmVerification(farmId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm Approved & Published to Map!'),
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
    try {
      await _farmService.rejectFarmVerification(farmId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification Request Rejected'),
            backgroundColor: Colors.orange,
          ),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title ────────────────────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Verification & Map Approvals',
                style: AppTypography.heading2(color: ColorUtils.darkText),
              ),
              const SizedBox(height: 4),
              Text(
                'Review incoming farmer registrations, verify document proofs, and approve farms to publish them on the public map.',
                style: AppTypography.bodyMedium(color: Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Filter Tabs ─────────────────────────────────────────────────
          Row(
            children: [
              _buildFilterChip('Pending', LucideIcons.clock),
              const SizedBox(width: 8),
              _buildFilterChip('Verified', LucideIcons.badgeCheck),
              const SizedBox(width: 8),
              _buildFilterChip('Rejected', LucideIcons.xCircle),
            ],
          ),
          const SizedBox(height: 20),

          // ── Farms List ──────────────────────────────────────────────────
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

          // Document Proof preview link
          if (docUrl != null && docUrl.isNotEmpty) ...[
            Row(
              children: [
                const Icon(LucideIcons.fileText, size: 16, color: ColorUtils.forestGreen),
                const SizedBox(width: 6),
                Text(
                  'Verification Proof Document Attached',
                  style: AppTypography.bodySmall(
                    color: ColorUtils.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
