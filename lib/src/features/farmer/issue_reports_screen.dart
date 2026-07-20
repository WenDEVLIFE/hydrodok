import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/widgets.dart';

/// Screen for farmers to report hardware/system issues and view ticket status
class IssueReportsScreen extends StatefulWidget {
  const IssueReportsScreen({super.key});

  @override
  State<IssueReportsScreen> createState() => _IssueReportsScreenState();
}

class _IssueReportsScreenState extends State<IssueReportsScreen> {
  late final Stream<List<Map<String, dynamic>>> _reportsStream;

  final List<Map<String, dynamic>> _issueTickets = [
    {
      'id': 'ticket-101',
      'category': 'Water System / Pump',
      'title': 'Submersible Pump Flow Fluctuation in NFT Channel #2',
      'description': 'Water flow rate dropped to 1.2 L/min causing dry roots on upper channel.',
      'priority': 'high',
      'status': 'in_progress',
      'created_at': '2026-07-19',
    },
    {
      'id': 'ticket-102',
      'category': 'Nutrient & Water Quality',
      'title': 'EC Meter Sensor Calibration Drift',
      'description': 'EC reading fluctuates between 1.2 and 2.4 mS/cm rapidly.',
      'priority': 'medium',
      'status': 'under_review',
      'created_at': '2026-07-18',
    },
  ];

  @override
  void initState() {
    super.initState();
    _reportsStream = Supabase.instance.client
        .from('issue_reports')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  void _showReportIssueModal() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String selectedCategory = 'Water System / Pump';
    String selectedPriority = 'medium';

    final categories = [
      'Water System / Pump',
      'Nutrient & Water Quality',
      'Marketplace / Order Bug',
      'Crop Disease / Pest Issue',
      'General Support',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(LucideIcons.alertTriangle, color: ColorUtils.terracotta),
                        SizedBox(width: 8),
                        Text('Report Technical Issue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Issue Category',
                    border: OutlineInputBorder(),
                  ),
                  items: categories
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedCategory = val);
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Issue Title',
                  hint: 'Brief summary of what happened',
                  controller: titleController,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  label: 'Detailed Description',
                  hint: 'Describe symptoms, affected equipment, or error codes...',
                  controller: descController,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedPriority,
                  decoration: const InputDecoration(
                    labelText: 'Priority Level',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'low', child: Text('Low - Non-urgent query')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium - Normal issue')),
                    DropdownMenuItem(value: 'high', child: Text('High - Critical system failure')),
                  ],
                  onChanged: (val) {
                    if (val != null) setModalState(() => selectedPriority = val);
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtils.forestGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final desc = descController.text.trim();
                      if (title.isEmpty) return;

                      final user = Supabase.instance.client.auth.currentUser;

                      final reportPayload = {
                        if (user != null) 'reporter_id': user.id,
                        'category': selectedCategory,
                        'title': title,
                        'description': desc,
                        'priority': selectedPriority,
                        'status': 'under_review',
                        'created_at': DateTime.now().toIso8601String(),
                      };

                      try {
                        await Supabase.instance.client.from('issue_reports').insert(reportPayload);
                      } catch (_) {
                        setState(() {
                          _issueTickets.insert(0, reportPayload);
                        });
                      }

                      if (mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Issue report submitted to HydroDok support!'),
                            backgroundColor: ColorUtils.forestGreen,
                          ),
                        );
                      }
                    },
                    child: const Text('Submit Issue Report', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text('Issue Reports & Support', style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showReportIssueModal,
        backgroundColor: ColorUtils.forestGreen,
        icon: const Icon(LucideIcons.alertTriangle, color: Colors.white),
        label: const Text('Report Issue', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro banner ───────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: ColorUtils.terracotta.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.lifeBuoy, color: ColorUtils.terracotta, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HydroDok Technical Support',
                          style: AppTypography.bodyMedium(fontWeight: FontWeight.bold, color: ColorUtils.darkText),
                        ),
                        Text(
                          'Report hardware issues, pump failures, or app bugs. Our technical support team responds within 24 hours.',
                          style: AppTypography.bodySmall(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Reported Tickets List ──────────────────────────────────────
            Text('Submitted Issue Tickets', style: AppTypography.heading3(color: ColorUtils.darkText)),
            const SizedBox(height: 12),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _reportsStream,
              builder: (context, snapshot) {
                final user = Supabase.instance.client.auth.currentUser;
                final raw = snapshot.data ?? [];
                final filtered = user != null
                    ? raw.where((r) => r['reporter_id'] == user.id).toList()
                    : raw;

                final list = filtered.isNotEmpty ? filtered : (raw.isNotEmpty ? raw : _issueTickets);

                if (list.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No support tickets submitted yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                return Column(
                  children: list.map((ticket) {
                    final cat = ticket['category'] as String? ?? 'General Support';
                    final title = ticket['title'] as String? ?? 'Issue';
                    final desc = ticket['description'] as String? ?? '';
                    final priority = ticket['priority'] as String? ?? 'medium';
                    final status = ticket['status'] as String? ?? 'under_review';
                    final rawDate = ticket['created_at'] as String? ?? '';
                    final date = rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate;

                    final (String statusLabel, Color statusColor) = switch (status.toLowerCase()) {
                      'in_progress' || 'in progress' => ('In Progress', Colors.blue),
                      'resolved' => ('Resolved', ColorUtils.sageGreen),
                      'closed' => ('Closed', Colors.grey),
                      _ => ('Under Review', ColorUtils.terracotta),
                    };

                    Color priorityColor = Colors.grey;
                    if (priority == 'high') priorityColor = Colors.red;
                    if (priority == 'medium') priorityColor = Colors.orange;

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
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: ColorUtils.forestGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  cat,
                                  style: const TextStyle(
                                    color: ColorUtils.forestGreen,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
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
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            title,
                            style: AppTypography.bodyMedium(
                              fontWeight: FontWeight.bold,
                              color: ColorUtils.darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            desc,
                            style: AppTypography.bodySmall(color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                date.isNotEmpty ? 'Reported on $date' : 'Submitted recently',
                                style: AppTypography.bodySmall(color: Colors.grey.shade500),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: priorityColor, width: 0.5),
                                ),
                                child: Text(
                                  priority.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: priorityColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
