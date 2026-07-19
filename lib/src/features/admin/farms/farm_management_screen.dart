import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

enum FarmVerificationStatus { pending, verified, suspended }

class ManagedFarm {
  final String id;
  final String farmName;
  final String ownerName;
  final String location;
  final String hydroponicType; // Deep Water Culture, NFT, Drip
  final String docProof;
  final String dateRegistered;
  final FarmVerificationStatus status;

  const ManagedFarm({
    required this.id,
    required this.farmName,
    required this.ownerName,
    required this.location,
    required this.hydroponicType,
    required this.docProof,
    required this.dateRegistered,
    required this.status,
  });
}

const _managedFarms = <ManagedFarm>[
  ManagedFarm(
    id: '1',
    farmName: 'Bukid Kabataan Shelter',
    ownerName: 'Rosa Santos',
    location: 'Taal, Calabarzon',
    hydroponicType: 'NFT System',
    docProof: 'Permit_2026_Verified.pdf',
    dateRegistered: 'Jul 10, 2026',
    status: FarmVerificationStatus.verified,
  ),
  ManagedFarm(
    id: '2',
    farmName: 'Mahogany Farm',
    ownerName: 'Mario Reyes',
    location: 'Trias, Cavite',
    hydroponicType: 'Deep Water Culture (DWC)',
    docProof: 'LGU_Clearance_Doc.pdf',
    dateRegistered: 'Jul 15, 2026',
    status: FarmVerificationStatus.pending,
  ),
  ManagedFarm(
    id: '3',
    farmName: 'Green Valley Hydroponics',
    ownerName: 'Liza Cruz',
    location: 'Malabon, Metro Manila',
    hydroponicType: 'Drip System',
    docProof: 'Business_Permit_Pending.pdf',
    dateRegistered: 'Jul 16, 2026',
    status: FarmVerificationStatus.pending,
  ),
  ManagedFarm(
    id: '4',
    farmName: 'Sto. Nino Urban Farm',
    ownerName: 'Ben Torres',
    location: 'General Trias, Cavite',
    hydroponicType: 'NFT System',
    docProof: 'Permit_Verified_2026.pdf',
    dateRegistered: 'Jun 28, 2026',
    status: FarmVerificationStatus.verified,
  ),
  ManagedFarm(
    id: '5',
    farmName: 'Unverified Agro Hydro',
    ownerName: 'Unknown Owner',
    location: 'Unverified Location',
    hydroponicType: 'Unknown',
    docProof: 'No documents submitted',
    dateRegistered: 'Jul 02, 2026',
    status: FarmVerificationStatus.suspended,
  ),
];

// ── Screen Widget ──────────────────────────────────────────────────────────

class FarmManagementScreen extends StatefulWidget {
  const FarmManagementScreen({super.key});

  @override
  State<FarmManagementScreen> createState() => _FarmManagementScreenState();
}

class _FarmManagementScreenState extends State<FarmManagementScreen> {
  String _activeFilter = 'All'; // All | Pending | Verified | Suspended
  final _searchController = TextEditingController();

  List<ManagedFarm> get _filteredFarms {
    if (_activeFilter == 'Pending') {
      return _managedFarms
          .where((f) => f.status == FarmVerificationStatus.pending)
          .toList();
    } else if (_activeFilter == 'Verified') {
      return _managedFarms
          .where((f) => f.status == FarmVerificationStatus.verified)
          .toList();
    } else if (_activeFilter == 'Suspended') {
      return _managedFarms
          .where((f) => f.status == FarmVerificationStatus.suspended)
          .toList();
    }
    return _managedFarms;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm Approvals & Management',
                      style: AppTypography.heading2(
                        color: ColorUtils.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review pending farm registrations, verify hydroponic setups, and manage registered farms',
                      style: AppTypography.bodyMedium(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Register farm on behalf of owner
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.sprout, size: 18),
                label: Text(
                  'Register New Farm',
                  style: AppTypography.button(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats Summary Row ─────────────────────────────────────────
          _buildStatsRow(),
          const SizedBox(height: 24),

          // ── Search & Filter Controls ──────────────────────────────────
          _buildSearchAndFilters(),
          const SizedBox(height: 20),

          // ── Farms Data Table ──────────────────────────────────────────
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ── Stats Row Widget ─────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          value: '6',
          label: 'Pending Approvals',
          valueColor: ColorUtils.terracotta,
          bgColor: const Color(0xFFFFF3E0),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '28',
          label: 'Verified Active Farms',
          valueColor: ColorUtils.forestGreen,
          bgColor: ColorUtils.sageGreen.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '2',
          label: 'Suspended Farms',
          valueColor: ColorUtils.darkText,
          bgColor: Colors.grey.shade100,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String value,
    required String label,
    required Color valueColor,
    required Color bgColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: AppTypography.heading3(
                color: valueColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Search & Filter Bar ──────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              style: AppTypography.bodyMedium(color: ColorUtils.darkText),
              decoration: InputDecoration(
                hintText: 'Search farm name or owner...',
                hintStyle: AppTypography.bodyMedium(
                  color: Colors.grey.shade400,
                ),
                prefixIcon: Icon(
                  LucideIcons.search,
                  size: 18,
                  color: Colors.grey.shade400,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        _buildFilterPill('All'),
        const SizedBox(width: 8),
        _buildFilterPill('Pending'),
        const SizedBox(width: 8),
        _buildFilterPill('Verified'),
        const SizedBox(width: 8),
        _buildFilterPill('Suspended'),
      ],
    );
  }

  Widget _buildFilterPill(String label) {
    final isActive = _activeFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? ColorUtils.forestGreen : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall(
            color: isActive ? Colors.white : ColorUtils.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ── Table Widget ─────────────────────────────────────────────────────────

  Widget _buildTable() {
    final farms = _filteredFarms;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              _headerCell('FARM & OWNER', flex: 3),
              _headerCell('LOCATION & SYSTEM', flex: 3),
              _headerCell('PROOF DOCUMENT', flex: 2),
              _headerCell('STATUS', flex: 2),
              _headerCell('ACTIONS', flex: 2, alignRight: true),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: farms.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              return _buildRow(farms[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text,
      {required int flex, bool alignRight = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: AppTypography.overline(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRow(ManagedFarm farm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Farm & Owner
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.farmName,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Owner: ${farm.ownerName}',
                  style: AppTypography.caption(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Location & Hydroponic System
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  farm.location,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  farm.hydroponicType,
                  style: AppTypography.caption(
                    color: ColorUtils.forestGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // Proof Document
          Expanded(
            flex: 2,
            child: Row(
              children: [
                const Icon(
                  LucideIcons.fileCheck,
                  size: 16,
                  color: Color(0xFF2979FF),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    farm.docProof,
                    style: AppTypography.caption(
                      color: const Color(0xFF2979FF),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(farm.status),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(farm),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(FarmVerificationStatus status) {
    final (String label, Color bg) = switch (status) {
      FarmVerificationStatus.verified => ('Verified', ColorUtils.forestGreen),
      FarmVerificationStatus.pending =>
        ('Pending Verification', ColorUtils.terracotta),
      FarmVerificationStatus.suspended =>
        ('Suspended', const Color(0xFFD84040)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: AppTypography.caption(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ManagedFarm farm) {
    switch (farm.status) {
      case FarmVerificationStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: Verify farm
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                elevation: 0,
              ),
              child: Text(
                'Verify',
                style: AppTypography.caption(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      case FarmVerificationStatus.verified:
        return OutlinedButton(
          onPressed: () {
            // TODO: View details
          },
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
          ),
          child: Text(
            'Details',
            style: AppTypography.caption(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case FarmVerificationStatus.suspended:
        return ElevatedButton(
          onPressed: () {
            // TODO: Review suspension
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2979FF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            elevation: 0,
          ),
          child: Text(
            'Review',
            style: AppTypography.caption(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
    }
  }
}
