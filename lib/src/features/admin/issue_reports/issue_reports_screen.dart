import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import '../../../widget/widgets.dart';

class IssueReportsScreen extends StatefulWidget {
  const IssueReportsScreen({super.key});

  @override
  State<IssueReportsScreen> createState() => _IssueReportsScreenState();
}

class _IssueReportsScreenState extends State<IssueReportsScreen> {
  String _activeFilter = 'All'; // All | Open | Resolved
  final _searchController = TextEditingController();

  late final Stream<List<Map<String, dynamic>>> _reportsStream;
  final Map<String, String> _reporterNames = {};
  final Map<String, String> _farmNames = {};

  @override
  void initState() {
    super.initState();
    _reportsStream = Supabase.instance.client
        .from('issue_reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchMetaForReports(List<Map<String, dynamic>> reports) async {
    final supabase = Supabase.instance.client;
    for (final r in reports) {
      final reporterId = r['reporter_id'] as String?;
      final farmId = r['farm_id'] as String?;

      if (reporterId != null && !_reporterNames.containsKey(reporterId)) {
        try {
          final prof = await supabase
              .from('profiles')
              .select('full_name')
              .eq('id', reporterId)
              .maybeSingle();
          if (prof != null && prof['full_name'] != null) {
            _reporterNames[reporterId] = prof['full_name'] as String;
            if (mounted) setState(() {});
          }
        } catch (_) {}
      }

      if (farmId != null && !_farmNames.containsKey(farmId)) {
        try {
          final farm = await supabase
              .from('farms')
              .select('farm_name')
              .eq('id', farmId)
              .maybeSingle();
          if (farm != null && farm['farm_name'] != null) {
            _farmNames[farmId] = farm['farm_name'] as String;
            if (mounted) setState(() {});
          }
        } catch (_) {}
      }
    }
  }

  Future<void> _updateReportStatus(String reportId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('issue_reports')
          .update({'status': newStatus})
          .eq('id', reportId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ticket updated to ${newStatus.replaceAll('_', ' ').toUpperCase()}'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating ticket: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _reportsStream,
      builder: (context, snapshot) {
        final rawReports = snapshot.data ?? [];
        if (rawReports.isNotEmpty) {
          _fetchMetaForReports(rawReports);
        }

        final query = _searchController.text.toLowerCase();

        var filtered = rawReports.where((r) {
          final title = (r['title'] as String? ?? '').toLowerCase();
          final desc = (r['description'] as String? ?? '').toLowerCase();
          final reporterId = r['reporter_id'] as String?;
          final reporterName = (reporterId != null ? (_reporterNames[reporterId] ?? '') : '').toLowerCase();
          return title.contains(query) || desc.contains(query) || reporterName.contains(query);
        }).toList();

        if (_activeFilter == 'Open') {
          filtered = filtered.where((r) {
            final s = (r['status'] as String? ?? 'under_review').toLowerCase();
            return s != 'resolved' && s != 'closed';
          }).toList();
        } else if (_activeFilter == 'Resolved') {
          filtered = filtered.where((r) {
            final s = (r['status'] as String? ?? '').toLowerCase();
            return s == 'resolved' || s == 'closed';
          }).toList();
        }

        final openCount = rawReports.where((r) {
          final s = (r['status'] as String? ?? 'under_review').toLowerCase();
          return s != 'resolved' && s != 'closed';
        }).length;

        final resolvedCount = rawReports.where((r) {
          final s = (r['status'] as String? ?? '').toLowerCase();
          return s == 'resolved' || s == 'closed';
        }).length;

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
                          'Issue Reports & Support',
                          style: AppTypography.heading2(color: ColorUtils.darkText),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Real-time technical tickets and problem reports submitted by farmers',
                          style: AppTypography.bodyMedium(color: Colors.grey.shade600),
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
                    child: const Icon(LucideIcons.bell, size: 18, color: ColorUtils.darkText),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Stats cards ─────────────────────────────────────────────
              Row(
                children: [
                  _buildStatCard(
                    value: openCount.toString(),
                    label: 'Open Tickets',
                    valueColor: ColorUtils.terracotta,
                    bgColor: const Color(0xFFFFF3E0),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    value: resolvedCount.toString(),
                    label: 'Resolved Tickets',
                    valueColor: ColorUtils.forestGreen,
                    bgColor: ColorUtils.sageGreen.withValues(alpha: 0.2),
                  ),
                  const SizedBox(width: 16),
                  _buildStatCard(
                    value: rawReports.length.toString(),
                    label: 'Total Submitted',
                    valueColor: ColorUtils.darkText,
                    bgColor: Colors.grey.shade100,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Search + filters ────────────────────────────────────────
              Row(
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
                        onChanged: (_) => setState(() {}),
                        style: AppTypography.bodyMedium(color: ColorUtils.darkText),
                        decoration: InputDecoration(
                          hintText: 'Search issue, farmer name, or description...',
                          hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                          prefixIcon: Icon(LucideIcons.search, size: 18, color: Colors.grey.shade400),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _buildFilterPill('All'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Open'),
                  const SizedBox(width: 8),
                  _buildFilterPill('Resolved'),
                ],
              ),
              const SizedBox(height: 20),

              // ── Table ───────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.checkCircle2, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              'No $_activeFilter support reports found.',
                              style: AppTypography.bodyLarge(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                            ),
                            child: Row(
                              children: [
                                _headerCell('FARMER / REPORTER', flex: 2),
                                _headerCell('ISSUE & DESCRIPTION', flex: 3),
                                _headerCell('CATEGORY / FARM', flex: 2),
                                _headerCell('DATE', flex: 1),
                                _headerCell('STATUS & ACTIONS', flex: 2),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                              itemBuilder: (context, index) {
                                final report = filtered[index];
                                final id = report['id'] as String;
                                final title = report['title'] as String? ?? 'Support Request';
                                final desc = report['description'] as String? ?? '';
                                final cat = report['category'] as String? ?? 'General Support';
                                final reporterId = report['reporter_id'] as String?;
                                final farmId = report['farm_id'] as String?;
                                final status = (report['status'] as String? ?? 'under_review').toLowerCase();
                                final rawDate = report['created_at'] as String? ?? '';
                                final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : 'Recent';

                                final farmerName = reporterId != null ? (_reporterNames[reporterId] ?? 'Farmer') : 'Farmer';
                                final farmName = farmId != null ? (_farmNames[farmId] ?? cat) : cat;

                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  child: Row(
                                    children: [
                                      // Reporter
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: ColorUtils.forestGreen,
                                              child: Text(
                                                farmerName.isNotEmpty ? farmerName[0].toUpperCase() : 'F',
                                                style: AppTypography.caption(color: Colors.white, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Flexible(
                                              child: Text(
                                                farmerName,
                                                style: AppTypography.bodySmall(color: ColorUtils.darkText, fontWeight: FontWeight.bold),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Issue & Description
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              title,
                                              style: AppTypography.bodySmall(color: ColorUtils.darkText, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (desc.isNotEmpty)
                                              Text(
                                                desc,
                                                style: AppTypography.caption(color: Colors.grey.shade600),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),

                                      // Farm / Category
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          farmName,
                                          style: AppTypography.bodySmall(color: Colors.grey.shade600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),

                                      // Date
                                      Expanded(
                                        flex: 1,
                                        child: Text(
                                          date,
                                          style: AppTypography.bodySmall(color: Colors.grey.shade600),
                                        ),
                                      ),

                                      // Status Badge & Action Menu
                                      Expanded(
                                        flex: 2,
                                        child: Row(
                                          children: [
                                            _buildStatusBadge(status),
                                            const SizedBox(width: 6),
                                            PopupMenuButton<String>(
                                              icon: const Icon(LucideIcons.moreVertical, size: 16, color: Colors.grey),
                                              onSelected: (val) => _updateReportStatus(id, val),
                                              itemBuilder: (context) => [
                                                const PopupMenuItem(value: 'under_review', child: Text('Mark Under Review')),
                                                const PopupMenuItem(value: 'in_progress', child: Text('Mark In Progress')),
                                                const PopupMenuItem(value: 'resolved', child: Text('Mark Resolved')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              children: [
                                Text(
                                  'Showing ${filtered.length} of ${rawReports.length} total reports',
                                  style: AppTypography.bodySmall(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        );
      },
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
              style: AppTypography.heading3(color: valueColor, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.bodySmall(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
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

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: AppTypography.overline(color: Colors.grey.shade500, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (String label, Color bg, Color fg) = switch (status.toLowerCase()) {
      'resolved' => ('Resolved', ColorUtils.forestGreen, Colors.white),
      'in_progress' => ('In Progress', Colors.blue, Colors.white),
      _ => ('Under Review', ColorUtils.terracotta, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: AppTypography.caption(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}
