import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

// ── Data ────────────────────────────────────────────────────────────────────

enum ReportStatus { open, investigating, resolved }

class IssueReport {
  final String initials;
  final Color avatarColor;
  final String farmer;
  final String issue;
  final String farmLocation;
  final String date;
  final ReportStatus status;

  const IssueReport({
    required this.initials,
    required this.avatarColor,
    required this.farmer,
    required this.issue,
    required this.farmLocation,
    required this.date,
    required this.status,
  });
}

const _reports = <IssueReport>[
  IssueReport(
    initials: 'R',
    avatarColor: ColorUtils.forestGreen,
    farmer: 'Rosa Santos',
    issue: 'Yellowing leaves on lettuce crop',
    farmLocation: 'Bukid Kabataan Shelter',
    date: 'Jul 16',
    status: ReportStatus.open,
  ),
  IssueReport(
    initials: 'M',
    avatarColor: ColorUtils.forestGreen,
    farmer: 'Mario Reyes',
    issue: 'Buyer did not pay after pickup',
    farmLocation: 'Mahogany Farm, Trias',
    date: 'Jul 15',
    status: ReportStatus.open,
  ),
  IssueReport(
    initials: 'L',
    avatarColor: Color(0xFFE8A020),
    farmer: 'Liza Cruz',
    issue: 'Suspected scam consumer account',
    farmLocation: 'Green Valley Hydroponics',
    date: 'Jul 14',
    status: ReportStatus.investigating,
  ),
  IssueReport(
    initials: 'B',
    avatarColor: ColorUtils.forestGreen,
    farmer: 'Ben Torres',
    issue: 'App crashed while posting listing',
    farmLocation: 'Sto. Nino Urban Farm',
    date: 'Jul 13',
    status: ReportStatus.resolved,
  ),
  IssueReport(
    initials: 'A',
    avatarColor: Color(0xFFE8A020),
    farmer: 'Ana Villar',
    issue: 'Pest damage — needs ID help',
    farmLocation: 'Bukid Kabataan Shelter',
    date: 'Jul 12',
    status: ReportStatus.resolved,
  ),
];

// ── Screen ──────────────────────────────────────────────────────────────────

class IssueReportsScreen extends StatefulWidget {
  const IssueReportsScreen({super.key});

  @override
  State<IssueReportsScreen> createState() => _IssueReportsScreenState();
}

class _IssueReportsScreenState extends State<IssueReportsScreen> {
  String _activeFilter = 'All'; // All | Open | Resolved
  final _searchController = TextEditingController();

  List<IssueReport> get _filteredReports {
    if (_activeFilter == 'Open') {
      return _reports
          .where((r) => r.status == ReportStatus.open)
          .toList();
    } else if (_activeFilter == 'Resolved') {
      return _reports
          .where((r) => r.status == ReportStatus.resolved)
          .toList();
    }
    return _reports;
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
          // ── Header row ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Issue Reports',
                      style: AppTypography.heading2(
                        color: ColorUtils.darkText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reports submitted by farmers through the mobile app',
                      style: AppTypography.bodyMedium(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.bell,
                  size: 18,
                  color: ColorUtils.darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Stats cards ─────────────────────────────────────────────
          _buildStatsRow(),
          const SizedBox(height: 24),

          // ── Search + filters ────────────────────────────────────────
          _buildSearchAndFilters(),
          const SizedBox(height: 20),

          // ── Table ───────────────────────────────────────────────────
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ── Stats row ────────────────────────────────────────────────────────────

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatCard(
          value: '14',
          label: 'Open Reports',
          valueColor: ColorUtils.forestGreen,
          bgColor: ColorUtils.sageGreen.withValues(alpha: 0.2),
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '38',
          label: 'Resolved (7d)',
          valueColor: ColorUtils.darkText,
          bgColor: Colors.grey.shade100,
        ),
        const SizedBox(width: 16),
        _buildStatCard(
          value: '4.2 hrs',
          label: 'Avg. Response',
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

  // ── Search + filter pills ────────────────────────────────────────────────

  Widget _buildSearchAndFilters() {
    return Row(
      children: [
        // Search bar
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
                hintText: 'Search reports...',
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

        // Filter pills
        _buildFilterPill('All'),
        const SizedBox(width: 8),
        _buildFilterPill('Open'),
        const SizedBox(width: 8),
        _buildFilterPill('Resolved'),
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

  // ── Table ────────────────────────────────────────────────────────────────

  Widget _buildTable() {
    final reports = _filteredReports;

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
              _headerCell('FARMER', flex: 2),
              _headerCell('ISSUE', flex: 3),
              _headerCell('FARM LOCATION', flex: 2),
              _headerCell('DATE', flex: 1),
              _headerCell('STATUS', flex: 1),
            ],
          ),
        ),

        // Rows
        Expanded(
          child: ListView.separated(
            itemCount: reports.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              return _buildRow(reports[index]);
            },
          ),
        ),

        // Footer
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            children: [
              Text(
                'Showing ${reports.length} of 14 open reports',
                style: AppTypography.bodySmall(
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  // TODO: view all reports
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All Reports',
                      style: AppTypography.button(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(LucideIcons.arrowRight, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTypography.overline(
          color: Colors.grey.shade500,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRow(IssueReport report) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          // Farmer
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: report.avatarColor,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    report.initials,
                    style: AppTypography.caption(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    report.farmer,
                    style: AppTypography.bodySmall(
                      color: ColorUtils.darkText,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Issue
          Expanded(
            flex: 3,
            child: Text(
              report.issue,
              style: AppTypography.bodySmall(
                color: ColorUtils.darkText,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Farm location
          Expanded(
            flex: 2,
            child: Text(
              report.farmLocation,
              style: AppTypography.bodySmall(
                color: Colors.grey.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Date
          Expanded(
            flex: 1,
            child: Text(
              report.date,
              style: AppTypography.bodySmall(
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Status badge
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildStatusBadge(report.status),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ReportStatus status) {
    final (String label, Color bg, Color fg) = switch (status) {
      ReportStatus.open => (
        'Open',
        ColorUtils.forestGreen,
        Colors.white,
      ),
      ReportStatus.investigating => (
        'Investigating',
        ColorUtils.terracotta,
        Colors.white,
      ),
      ReportStatus.resolved => (
        'Resolved',
        ColorUtils.darkText,
        Colors.white,
      ),
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
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
