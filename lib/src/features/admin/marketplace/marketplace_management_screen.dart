import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data Model ─────────────────────────────────────────────────────────────

enum ProductStatus { active, pending, suspended }

class MarketplaceProduct {
  final String id;
  final String productName;
  final String category; // e.g. Vegetables, Herbs, Fruit Vegetables
  final String farmerName;
  final String farmName;
  final int stockUnits;
  final double pricePerKg;
  final String dateListed;
  final ProductStatus status;

  const MarketplaceProduct({
    required this.id,
    required this.productName,
    required this.category,
    required this.farmerName,
    required this.farmName,
    required this.stockUnits,
    required this.pricePerKg,
    required this.dateListed,
    required this.status,
  });
}

const _products = <MarketplaceProduct>[
  MarketplaceProduct(
    id: '1',
    productName: 'Fresh Butterhead Lettuce',
    category: 'Vegetables',
    farmerName: 'Rosa Santos',
    farmName: 'Bukid Kabataan Shelter',
    stockUnits: 10000,
    pricePerKg: 100.0,
    dateListed: 'Jul 16, 2026',
    status: ProductStatus.active,
  ),
  MarketplaceProduct(
    id: '2',
    productName: 'Hydroponic Sweet Basil',
    category: 'Herbs',
    farmerName: 'Mario Reyes',
    farmName: 'Mahogany Farm',
    stockUnits: 5000,
    pricePerKg: 150.0,
    dateListed: 'Jul 15, 2026',
    status: ProductStatus.active,
  ),
  MarketplaceProduct(
    id: '3',
    productName: 'Cherry Tomatoes Batch #4',
    category: 'Fruit Vegetables',
    farmerName: 'Liza Cruz',
    farmName: 'Green Valley Hydroponics',
    stockUnits: 3200,
    pricePerKg: 180.0,
    dateListed: 'Jul 17, 2026',
    status: ProductStatus.pending,
  ),
  MarketplaceProduct(
    id: '4',
    productName: 'Organic Kangkong Harvest',
    category: 'Vegetables',
    farmerName: 'Ben Torres',
    farmName: 'Sto. Nino Urban Farm',
    stockUnits: 8000,
    pricePerKg: 80.0,
    dateListed: 'Jul 13, 2026',
    status: ProductStatus.active,
  ),
  MarketplaceProduct(
    id: '5',
    productName: 'Red Bell Pepper (Unverified listing)',
    category: 'Fruit Vegetables',
    farmerName: 'Unknown Vendor',
    farmName: 'Unverified Farm',
    stockUnits: 500,
    pricePerKg: 250.0,
    dateListed: 'Jul 12, 2026',
    status: ProductStatus.suspended,
  ),
];

// ── Screen Widget ──────────────────────────────────────────────────────────

class MarketplaceManagementScreen extends StatefulWidget {
  const MarketplaceManagementScreen({super.key});

  @override
  State<MarketplaceManagementScreen> createState() =>
      _MarketplaceManagementScreenState();
}

class _MarketplaceManagementScreenState
    extends State<MarketplaceManagementScreen> {
  String _activeFilter = 'All'; // All | Active | Pending | Suspended
  final _searchController = TextEditingController();

  List<MarketplaceProduct> get _filteredProducts {
    if (_activeFilter == 'Active') {
      return _products.where((p) => p.status == ProductStatus.active).toList();
    } else if (_activeFilter == 'Pending') {
      return _products
          .where((p) => p.status == ProductStatus.pending)
          .toList();
    } else if (_activeFilter == 'Suspended') {
      return _products
          .where((p) => p.status == ProductStatus.suspended)
          .toList();
    }
    return _products;
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
          // ── Title & Subtitle Row ────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketplace Management',
                      style: AppTypography.heading2(
                        color: ColorUtils.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Review, approve, and moderate hydroponic product listings',
                      style: AppTypography.bodyMedium(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Admin create featured listing
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
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(
                  'Add Featured Listing',
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

          // ── Search & Filter Bar ──────────────────────────────────────
          _buildSearchAndFilters(),
          const SizedBox(height: 20),

          // ── Products Table ───────────────────────────────────────────
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
          value: '42',
          label: 'Active Listings',
          valueColor: ColorUtils.forestGreen,
          bgColor: ColorUtils.sageGreen.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '5',
          label: 'Pending Approvals',
          valueColor: ColorUtils.terracotta,
          bgColor: const Color(0xFFFFF3E0),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '₱ 458,000',
          label: 'Total Market Value',
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

  // ── Search & Filters ─────────────────────────────────────────────────────

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
                hintText: 'Search product or farm name...',
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
        _buildFilterPill('Active'),
        const SizedBox(width: 8),
        _buildFilterPill('Pending'),
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
    final products = _filteredProducts;

    return Column(
      children: [
        // Table Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              _headerCell('PRODUCT', flex: 3),
              _headerCell('FARM / VENDOR', flex: 3),
              _headerCell('STOCK & PRICE', flex: 2),
              _headerCell('STATUS', flex: 2),
              _headerCell('ACTIONS', flex: 2, alignRight: true),
            ],
          ),
        ),

        // Table Rows
        Expanded(
          child: ListView.separated(
            itemCount: products.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              return _buildRow(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {required int flex, bool alignRight = false}) {
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

  Widget _buildRow(MarketplaceProduct product) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Product Name & Category
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.productName,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  product.category,
                  style: AppTypography.caption(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Farm & Vendor
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.farmName,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.darkText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'By ${product.farmerName}',
                  style: AppTypography.caption(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),

          // Stock & Price
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₱ ${product.pricePerKg.toStringAsFixed(0)} / kg',
                  style: AppTypography.bodySmall(
                    color: ColorUtils.forestGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatNumber(product.stockUnits)} units available',
                  style: AppTypography.caption(
                    color: Colors.grey.shade600,
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
              child: _buildStatusBadge(product.status),
            ),
          ),

          // Actions
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildActionButtons(product),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ProductStatus status) {
    final (String label, Color bg) = switch (status) {
      ProductStatus.active => ('Active', ColorUtils.forestGreen),
      ProductStatus.pending => ('Pending Approval', ColorUtils.terracotta),
      ProductStatus.suspended => ('Suspended', const Color(0xFFD84040)),
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

  Widget _buildActionButtons(MarketplaceProduct product) {
    switch (product.status) {
      case ProductStatus.pending:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                // TODO: Approve product
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
                'Approve',
                style: AppTypography.caption(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      case ProductStatus.active:
        return OutlinedButton(
          onPressed: () {
            // TODO: Suspend listing
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
            'Suspend',
            style: AppTypography.caption(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      case ProductStatus.suspended:
        return ElevatedButton(
          onPressed: () {
            // TODO: Re-activate or review
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

  String _formatNumber(int n) {
    if (n >= 1000) {
      final thousands = n ~/ 1000;
      final remainder = n % 1000;
      if (remainder == 0) return '$thousands,000';
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return n.toString();
  }
}
