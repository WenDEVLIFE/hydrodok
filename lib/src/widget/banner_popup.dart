import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/utils/color_utils.dart';
import '../core/utils/typography.dart';

/// Realtime banner popup that shows admin-published banners when the user
/// opens a screen. Listens to the `banners` table via Supabase Realtime
/// and shows ALL `live` banners (skipping ones the user has dismissed).
///
/// Usage in a screen's build method:
/// ```dart
/// return BannerPopup(child: MyScreen());
/// ```
///
/// The popup appears on top of screens only when there are new live banners
/// the user hasn't dismissed yet.
class BannerPopup extends StatefulWidget {
  final Widget child;

  const BannerPopup({super.key, required this.child});

  @override
  State<BannerPopup> createState() => _BannerPopupState();
}

class _BannerPopupState extends State<BannerPopup> {
  late final Stream<List<Map<String, dynamic>>> _bannersStream;

  @override
  void initState() {
    super.initState();
    // Listen to ALL banners (live + scheduled + expired) via realtime.
    // We filter to 'live' in-memory so dismissal tracking works correctly.
    _bannersStream = Supabase.instance.client
        .from('banners')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _bannersStream,
      builder: (context, snapshot) {
        final allBanners = snapshot.data ?? [];

        // Filter to 'live' banners only
        final liveBanners = allBanners
            .where((b) => (b['status'] as String?) == 'live')
            .toList();

        return Stack(
          children: [
            widget.child,
            if (liveBanners.isNotEmpty) _buildBannerStack(liveBanners),
          ],
        );
      },
    );
  }

  Widget _buildBannerStack(List<Map<String, dynamic>> banners) {
    return Positioned.fill(
      child:FutureBuilder<SharedPreferences>(
        future: _loadPrefs(),
        builder: (context, prefsSnapshot) {
          if (!prefsSnapshot.hasData) return const SizedBox.shrink();
          final prefs = prefsSnapshot.data!;

          // Filter out dismissed banners
          final dismissedKey = 'banner_dismissed_';
          final visibleBanners = banners.where((b) {
            final id = b['id'] as String?;
            return id != null && prefs.getBool('$dismissedKey$id') != true;
          }).toList();

          if (visibleBanners.isEmpty) return const SizedBox.shrink();

          return _DismissibleBannerStack(
            banners: visibleBanners,
            onDismiss: (id) async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('$dismissedKey$id', true);
            },
          );
        },
      ),
    );
  }

  Future<SharedPreferences> _loadPrefs() => SharedPreferences.getInstance();
}

/// A stack of dismissible banner dialogs. Shows the first (latest) banner.
/// When dismissed, shows the next one if any remain.
class _DismissibleBannerStack extends StatefulWidget {
  final List<Map<String, dynamic>> banners;
  final Future<void> Function(String id) onDismiss;

  const _DismissibleBannerStack({
    required this.banners,
    required this.onDismiss,
  });

  @override
  State<_DismissibleBannerStack> createState() => _DismissibleBannerStackState();
}

class _DismissibleBannerStackState extends State<_DismissibleBannerStack> {
  late List<Map<String, dynamic>> _pendingBanners;

  @override
  void initState() {
    super.initState();
    _pendingBanners = List.from(widget.banners);
  }

  void _dismissCurrent() {
    final current = _pendingBanners.first;
    final id = current['id'] as String?;
    if (id != null) widget.onDismiss(id);
    if (mounted) setState(() => _pendingBanners.removeAt(0));
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingBanners.isEmpty) return const SizedBox.shrink();

    final banner = _pendingBanners.first;
    final title = banner['title'] as String? ?? '';
    final content = (banner['content'] as String?)?.replaceAll('"', '') ?? '';
    final ctaLabel = banner['cta_label'] as String? ?? 'Learn More';
    final ctaUrl = banner['cta_url'] as String? ?? '';

    return Container(
      width: double.infinity,
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: ColorUtils.terracotta, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: _dismissCurrent,
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(LucideIcons.x, size: 16, color: Colors.grey),
                  ),
                ),
              ),
              // Bell icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: ColorUtils.terracotta.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.bell,
                  color: ColorUtils.terracotta,
                  size: 24,
                ),
              ),
              const SizedBox(height: 16),
              // Title
              if (title.isNotEmpty)
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 8),
              // Content
              Text(
                content,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium(color: ColorUtils.darkText),
              ),
              const SizedBox(height: 20),
              // CTA button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (ctaUrl.isNotEmpty) {
                      String formattedUrl = ctaUrl.trim();
                      if (!formattedUrl.startsWith('http://') &&
                          !formattedUrl.startsWith('https://')) {
                        formattedUrl = 'https://$formattedUrl';
                      }
                      final uri = Uri.parse(formattedUrl);
                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          await launchUrl(uri, mode: LaunchMode.platformDefault);
                        }
                      } catch (e) {
                        debugPrint('Could not launch banner URL $ctaUrl: $e');
                      }
                    }
                    _dismissCurrent();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.terracotta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                  child: Text(
                    ctaLabel,
                    style: AppTypography.button(color: Colors.white, fontSize: 13),
                  ),
                ),
              ),
              if (_pendingBanners.length > 1) ...[
                const SizedBox(height: 12),
                Text(
                  '${_pendingBanners.length - 1} more announcement${_pendingBanners.length - 1 > 1 ? 's' : ''}...',
                  style: AppTypography.caption(color: Colors.grey.shade500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}