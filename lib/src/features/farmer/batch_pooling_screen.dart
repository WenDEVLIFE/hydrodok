import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service/batch_pooling_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

/// Screen for managing and creating collective crop batch pooling campaigns
class BatchPoolingScreen extends StatefulWidget {
  const BatchPoolingScreen({super.key});

  @override
  State<BatchPoolingScreen> createState() => _BatchPoolingScreenState();
}

class _BatchPoolingScreenState extends State<BatchPoolingScreen> {
  late final BatchPoolingService _poolingService;
  late Future<List<Map<String, dynamic>>> _poolsFuture;

  @override
  void initState() {
    super.initState();
    _poolingService = BatchPoolingService();
    _poolsFuture = _poolingService.getBatchPools();
  }

  void _reloadPools() {
    setState(() {
      _poolsFuture = _poolingService.getBatchPools();
    });
  }
  void _showCreatePoolDialog() {
    debugPrint('BatchPoolingScreen: opening create pool dialog');
    final cropController = TextEditingController();
    final weightController = TextEditingController();
    final priceController = TextEditingController();

    showModalBottomSheet(
      useSafeArea: true,
      isDismissible: true,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
                  Text('Create Batch Pool',
                      style: AppTypography.heading3(color: ColorUtils.darkText)),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: ColorUtils.darkText),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cropController,
                style: AppTypography.bodyMedium(color: ColorUtils.darkText),
                decoration: InputDecoration(
                  labelText: 'Crop / Produce Name',
                  labelStyle: AppTypography.bodySmall(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                  hintText: 'e.g. Hydroponic Romaine Lettuce',
                  hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                  border: const OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: ColorUtils.forestGreen),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.bodyMedium(color: ColorUtils.darkText),
                      decoration: InputDecoration(
                        labelText: 'Target Total Weight (kg)',
                        labelStyle: AppTypography.bodySmall(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: 'e.g. 500',
                        hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: ColorUtils.forestGreen),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      style: AppTypography.bodyMedium(color: ColorUtils.darkText),
                      decoration: InputDecoration(
                        labelText: 'Target Price (PHP/kg)',
                        labelStyle: AppTypography.bodySmall(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                        hintText: 'e.g. 180',
                        hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                        border: const OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: ColorUtils.forestGreen),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.forestGreen,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final crop = cropController.text.trim();
                    final weight = double.tryParse(weightController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (crop.isEmpty || weight <= 0) return;

                    try {
                      await _poolingService.createBatchPool(
                        title: 'Collective $crop Batch Pool',
                        cropName: crop,
                        targetQuantity: weight,
                        targetPrice: price,
                      );
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      _reloadPools();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Batch pooling campaign published!'),
                            backgroundColor: ColorUtils.forestGreen,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to publish pool: $e')),
                        );
                      }
                    }
                  },
                  child: Text('Publish Batch Pool',
                      style: AppTypography.bodyMedium(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showJoinPoolDialog(Map<String, dynamic> pool) {
    final qtyController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.users, color: ColorUtils.forestGreen),
            const SizedBox(width: 8),
            Text(
              'Pledge Produce to Pool',
              style: AppTypography.heading3(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pool['title'] as String,
              style: AppTypography.bodyMedium(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              style: AppTypography.bodyMedium(color: ColorUtils.darkText),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Quantity to Contribute (kg)',
                labelStyle: AppTypography.bodySmall(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
                hintText: 'e.g. 50',
                hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: ColorUtils.forestGreen),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Cancel',
              style: AppTypography.bodyMedium(color: Colors.white),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.forestGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () async {
              final added = double.tryParse(qtyController.text.trim()) ?? 0;
              if (added <= 0) return;

              final poolId = pool['id'] as String;
              final currentW = (pool['current_quantity'] as num?)?.toDouble() ??
                  (pool['current_weight'] as num?)?.toDouble() ??
                  0;
              final targetW = (pool['target_quantity'] as num?)?.toDouble() ??
                  (pool['target_weight'] as num?)?.toDouble() ??
                  100;

              try {
                await _poolingService.contributeToPool(
                  batchId: poolId,
                  quantity: added,
                  currentQuantity: currentW,
                  targetQuantity: targetW,
                );
                if (ctx.mounted) Navigator.of(ctx).pop();
                _reloadPools();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Pledge recorded! Thanks for pooling.'),
                      backgroundColor: ColorUtils.forestGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to pledge produce: $e')),
                  );
                }
              }
            },
            child: Text(
              'Confirm Pledge',
              style: AppTypography.bodyMedium(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text('Produce Batch Pooling',
            style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          debugPrint('BatchPoolingScreen: FAB pressed');
          try {
            _showCreatePoolDialog();
          } catch (e, stack) {
            debugPrint('BatchPoolingScreen: FAB error: $e');
            debugPrint(stack.toString());
          }
        },
        backgroundColor: ColorUtils.forestGreen,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Create Pool',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _poolsFuture,
        builder: (context, snapshot) {
          final batchPools = snapshot.data ?? [];
          debugPrint('BatchPoolingScreen future pools: ${batchPools.length}');
          if (snapshot.hasError) {
            debugPrint('BatchPoolingScreen future error: ${snapshot.error}');
          }

          return RefreshIndicator(
            onRefresh: () async => _reloadPools(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 20),
                  Text('Active Batch Pooling Campaigns',
                      style:
                          AppTypography.heading3(color: ColorUtils.darkText)),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      batchPools.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'Error loading pools: ${snapshot.error}',
                        style:
                            AppTypography.bodySmall(color: Colors.redAccent),
                      ),
                    )
                  else if (batchPools.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No active batch pooling campaigns yet. Tap "+ Create Pool" to start one!',
                        style: AppTypography.bodySmall(
                            color: Colors.grey.shade600),
                      ),
                    )
                  else
                    ...batchPools.map((pool) => _buildPoolCard(pool)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: ColorUtils.mainGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.users,
                color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collective Farmer Pooling',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  'Combine produce yields with neighboring farmers to fulfill bulk commercial orders at higher prices.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPoolCard(Map<String, dynamic> pool) {
    final title = pool['title'] as String? ?? 'Collective Batch Pool';
    final crop =
        pool['crop_name'] as String? ?? pool['crop'] as String? ?? 'Produce';
    final targetW = (pool['target_quantity'] as num?)?.toDouble() ??
        (pool['target_weight'] as num?)?.toDouble() ??
        100.0;
    final currentW = (pool['current_quantity'] as num?)?.toDouble() ??
        (pool['current_weight'] as num?)?.toDouble() ??
        0.0;
    final price = (pool['target_price'] as num?)?.toDouble() ?? 0.0;
    final members =
        List<Map<String, dynamic>>.from(pool['batch_members'] as List<dynamic>? ?? []);
    final participants = members.isNotEmpty
        ? members.length
        : ((pool['participants'] as int?) ?? 0);
    final statusStr = (pool['status'] as String? ?? 'Open').toLowerCase();
    final isFilled = statusStr == 'filled' || currentW >= targetW;
    final progress = targetW > 0 ? (currentW / targetW).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isFilled
                      ? ColorUtils.sageGreen.withValues(alpha: 0.2)
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isFilled
                      ? 'GOAL MET'
                      : (statusStr == 'open' ? 'ACTIVE' : statusStr.toUpperCase()),
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
                '${currentW.toInt()} / ${targetW.toInt()} kg pooled (${(progress * 100).toStringAsFixed(0)}%)',
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
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
              if (!isFilled)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorUtils.forestGreen,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onPressed: () => _showJoinPoolDialog(pool),
                  child: const Text('Pledge Produce',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                )
              else
                const Text(
                  'Completed',
                  style: TextStyle(
                      color: ColorUtils.sageGreen, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
