import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Admin Banner Manager:
/// Create, preview, and delete pop-up banners shown to farmers/consumers
/// when they open the app. Uses Supabase realtime — changes appear instantly
/// on all connected client devices.
class BannerManagerScreen extends StatefulWidget {
  const BannerManagerScreen({super.key});

  @override
  State<BannerManagerScreen> createState() => _BannerManagerScreenState();
}

class _BannerManagerScreenState extends State<BannerManagerScreen> {
  late final Stream<List<Map<String, dynamic>>> _bannersStream;
  List<Map<String, dynamic>> _banners = [];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _bannersStream = Supabase.instance.client
        .from('banners')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Map<String, dynamic>? get _selectedBanner =>
      _banners.isNotEmpty && _selectedIndex < _banners.length
          ? _banners[_selectedIndex]
          : null;

  Future<void> _deleteBanner(String bannerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this banner? '
            'It will be removed from all user devices immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client.from('banners').delete().eq('id', bannerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Banner deleted — removed from all devices.')),
        );
        setState(() => _selectedIndex = 0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting banner: $e')),
        );
      }
    }
  }

  Future<void> _showAddBannerDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final ctaController = TextEditingController(text: 'Learn More');
    final urlController = TextEditingController();
    String status = 'live';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Banner'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Farming Seminar Invite',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Banner message shown to users...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ctaController,
                    decoration: const InputDecoration(
                      labelText: 'Button Label',
                      hintText: 'e.g. Learn More / Watch Video / Join Stream',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Redirect URL / Link (YouTube, Zoom, Meet, etc.)',
                      hintText: 'e.g. https://youtube.com/... or https://zoom.us/j/...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'live', child: Text('Live (show now)')),
                      DropdownMenuItem(value: 'scheduled', child: Text('Scheduled')),
                      DropdownMenuItem(value: 'expired', child: Text('Expired (hidden)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => status = v);
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.terracotta,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titleController.text.trim().isEmpty ||
                    contentController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Title and content are required.')),
                  );
                  return;
                }
                try {
                  final user = Supabase.instance.client.auth.currentUser;
                  await Supabase.instance.client.from('banners').insert({
                    'title': titleController.text.trim(),
                    'content': contentController.text.trim(),
                    'cta_label': ctaController.text.trim().isEmpty
                        ? 'Learn More'
                        : ctaController.text.trim(),
                    'cta_url': urlController.text.trim(),
                    'status': status,
                    'created_by': user?.id,
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Publish'),
            ),
          ],
        ),
      ),
    );

    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Banner published — live on all devices.')),
      );
    }
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
                      'Banner Manager',
                      style: AppTypography.heading2(color: ColorUtils.darkText),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Create pop-up banners shown when farmers/consumers open the app. '
                      'Changes appear instantly on all devices.',
                      style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showAddBannerDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.terracotta,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(
                  'New Banner',
                  style: AppTypography.button(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // ── Main Content Area (List + Live Preview) ──────────────────
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _bannersStream,
              builder: (context, snapshot) {
                _banners = snapshot.data ?? [];

                if (snapshot.connectionState == ConnectionState.waiting &&
                    _banners.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_banners.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.imageOff, size: 48, color: Colors.grey),
                        const SizedBox(height: 12),
                        Text(
                          'No banners yet. Tap "New Banner" to create one.',
                          style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Left Column: Banners List ─────────────────────────
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIVE & SCHEDULED',
                            style: AppTypography.overline(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: ListView.separated(
                              itemCount: _banners.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final banner = _banners[index];
                                final isSelected = _selectedIndex == index;
                                return _BannerCard(
                                  banner: banner,
                                  isSelected: isSelected,
                                  onTap: () => setState(() => _selectedIndex = index),
                                  onDelete: () => _deleteBanner(banner['id'] as String),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                    // ── Right Column: Mobile Device Live Preview ───────────
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE PREVIEW — APP POP-UP',
                            style: AppTypography.overline(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: Center(
                              child: _selectedBanner != null
                                  ? _buildPhoneFrame(_selectedBanner!)
                                  : const Icon(LucideIcons.smartphone,
                                      size: 120, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Mobile Phone Frame Widget ─────────────────────────────────────────────

  Widget _buildPhoneFrame(Map<String, dynamic> banner) {
    final content = (banner['content'] as String?)?.replaceAll('"', '') ?? '';
    final ctaLabel = (banner['cta_label'] as String?) ?? 'Learn More';

    return Container(
      width: 260,
      height: 480,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          color: const Color(0xFFF2F7F2),
          child: Stack(
            children: [
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: ColorUtils.sageGreen.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ColorUtils.terracotta, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ColorUtils.terracotta.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.bell,
                          color: ColorUtils.terracotta,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        content,
                        textAlign: TextAlign.center,
                        style: AppTypography.subtitle2(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorUtils.terracotta,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 0,
                          ),
                          child: Text(
                            ctaLabel,
                            style: AppTypography.button(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Banner Card Widget ─────────────────────────────────────────────────────

class _BannerCard extends StatelessWidget {
  final Map<String, dynamic> banner;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _BannerCard({
    required this.banner,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorUtils.terracotta.withValues(alpha: 0.08)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? ColorUtils.terracotta : Colors.grey.shade300,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ColorUtils.terracotta.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                LucideIcons.image,
                color: ColorUtils.terracotta,
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    banner['title'] as String? ?? '',
                    style: AppTypography.subtitle1(
                      color: ColorUtils.darkText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['content'] as String? ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _buildStatusBadge(banner['status'] as String? ?? 'live'),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(LucideIcons.trash2, size: 16, color: Colors.redAccent),
              onPressed: onDelete,
              tooltip: 'Delete',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final (String label, Color bg) = switch (status) {
      'live' => ('Live', ColorUtils.forestGreen),
      'scheduled' => ('Scheduled', const Color(0xFF2979FF)),
      _ => ('Expired', Colors.grey.shade600),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 5),
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
}