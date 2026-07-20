import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Client/Consumer Batch Pooling Screen:
/// Shows active collective produce pooling campaigns.
class PoolingScreen extends StatefulWidget {
  const PoolingScreen({super.key});

  @override
  State<PoolingScreen> createState() => _PoolingScreenState();
}

class _PoolingScreenState extends State<PoolingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _batchPools = [];

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  Future<void> _loadPools() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('batch_pools')
          .select('*, batch_members(*)')
          .order('created_at', ascending: false);

      final pools = List<Map<String, dynamic>>.from(response);
      if (mounted) {
        setState(() {
          _batchPools = pools;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('PoolingScreen load error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load pooling campaigns: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _loadPools,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Batch Pooling',
                          style: AppTypography.heading3(
                            color: ColorUtils.darkText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoBanner(),
                        const SizedBox(height: 24),
                        Text(
                          'Active Pooling Campaigns',
                          style: AppTypography.subtitle1(
                            color: ColorUtils.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),

                if (_isLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_batchPools.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(LucideIcons.users, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No active pooling campaigns',
                            style: AppTypography.bodyLarge(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Farmers can create pools from the farmer dashboard.',
                            style: AppTypography.bodySmall(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.only(
                            bottom: index < _batchPools.length - 1 ? 12 : 0,
                          ),
                          child: _PoolCard(pool: _batchPools[index]),
                        ),
                        childCount: _batchPools.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEDF4FC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF90CAF9),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.layoutGrid,
            color: Color(0xFF2979FF),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Collective farmer orders',
                  style: AppTypography.subtitle2(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Farmers pool their harvest to fulfill larger orders. You can view live progress here.',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PoolCard extends StatelessWidget {
  final Map<String, dynamic> pool;
  const _PoolCard({required this.pool});

  @override
  Widget build(BuildContext context) {
    final title = pool['title'] as String? ?? 'Collective Batch Pool';
    final crop = pool['crop_name'] as String? ?? pool['crop'] as String? ?? 'Produce';
    final target = (pool['target_quantity'] as num?)?.toDouble() ??
        (pool['target_weight'] as num?)?.toDouble() ?? 100.0;
    final current = (pool['current_quantity'] as num?)?.toDouble() ??
        (pool['current_weight'] as num?)?.toDouble() ?? 0.0;
    final price = (pool['target_price'] as num?)?.toDouble() ?? 0.0;
    final members = List<Map<String, dynamic>>.from(pool['batch_members'] as List<dynamic>? ?? []);
    final participants = members.length;
    final status = (pool['status'] as String? ?? 'Open').toLowerCase();
    final isFilled = status == 'filled' || current >= target;
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: ColorUtils.forestGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  crop,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.forestGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFilled ? ColorUtils.sageGreen.withOpacity(0.2) : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFilled ? 'GOAL MET' : status.toUpperCase(),
                  style: TextStyle(
                    color: isFilled ? ColorUtils.forestGreen : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppTypography.bodyMedium(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isFilled ? ColorUtils.sageGreen : ColorUtils.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${current.toInt()} / ${target.toInt()} kg (${(progress * 100).toStringAsFixed(0)}%)',
                style: AppTypography.bodySmall(color: Colors.grey.shade600),
              ),
              Text(
                'PHP ${price.toStringAsFixed(0)} / kg',
                style: AppTypography.bodySmall(
                  color: ColorUtils.forestGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(LucideIcons.users, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '$participants farmer${participants == 1 ? '' : 's'} joined',
                style: AppTypography.bodySmall(color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
