import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';

/// Screen for managing and creating collective crop batch pooling campaigns
class BatchPoolingScreen extends StatefulWidget {
  const BatchPoolingScreen({super.key});

  @override
  State<BatchPoolingScreen> createState() => _BatchPoolingScreenState();
}

class _BatchPoolingScreenState extends State<BatchPoolingScreen> {
  // Sample active batch pools
  final List<Map<String, dynamic>> _batchPools = [
    {
      'id': 'pool-1',
      'title': 'Collective Hydroponic Butterhead Lettuce Pool',
      'crop': 'Butterhead Lettuce',
      'target_weight': 500.0,
      'current_weight': 340.0,
      'target_price': 160.0,
      'participants': 6,
      'cutoff_days': 4,
      'status': 'active',
    },
    {
      'id': 'pool-2',
      'title': 'Bulk Hydroponic Cherry Tomatoes Pool',
      'crop': 'Cherry Tomatoes',
      'target_weight': 300.0,
      'current_weight': 280.0,
      'target_price': 220.0,
      'participants': 4,
      'cutoff_days': 2,
      'status': 'active',
    },
    {
      'id': 'pool-3',
      'title': 'Batch Romaine Lettuce Order for Supermarket Chain',
      'crop': 'Romaine Lettuce',
      'target_weight': 1000.0,
      'current_weight': 1000.0,
      'target_price': 150.0,
      'participants': 12,
      'cutoff_days': 0,
      'status': 'filled',
    },
  ];

  void _showCreatePoolDialog() {
    final cropController = TextEditingController();
    final weightController = TextEditingController();
    final priceController = TextEditingController();
    final minContribController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  Text('Create Batch Pool', style: AppTypography.heading3(color: ColorUtils.darkText)),
                  IconButton(
                    icon: const Icon(LucideIcons.x),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cropController,
                decoration: const InputDecoration(
                  labelText: 'Crop / Produce Name',
                  hintText: 'e.g. Hydroponic Romaine Lettuce',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target Total Weight (kg)',
                        hintText: 'e.g. 500',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Target Price (PHP/kg)',
                        hintText: 'e.g. 180',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: minContribController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Min Contribution per Farmer (kg)',
                  hintText: 'e.g. 25',
                  border: OutlineInputBorder(),
                ),
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
                  onPressed: () {
                    final crop = cropController.text.trim();
                    final weight = double.tryParse(weightController.text) ?? 0;
                    final price = double.tryParse(priceController.text) ?? 0;
                    if (crop.isEmpty || weight <= 0) return;

                    setState(() {
                      _batchPools.insert(0, {
                        'id': 'pool-${DateTime.now().millisecondsSinceEpoch}',
                        'title': 'Collective $crop Batch Pool',
                        'crop': crop,
                        'target_weight': weight,
                        'current_weight': 0.0,
                        'target_price': price,
                        'participants': 1,
                        'cutoff_days': 7,
                        'status': 'active',
                      });
                    });

                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Batch pooling campaign published!'),
                        backgroundColor: ColorUtils.forestGreen,
                      ),
                    );
                  },
                  child: const Text('Publish Batch Pool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          children: const [
            Icon(LucideIcons.users, color: ColorUtils.forestGreen),
            SizedBox(width: 8),
            Text('Pledge Produce to Pool'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              pool['title'] as String,
              style: AppTypography.bodyMedium(fontWeight: FontWeight.bold, color: ColorUtils.darkText),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Quantity to Contribute (kg)',
                hintText: 'e.g. 50',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
            onPressed: () {
              final added = double.tryParse(qtyController.text.trim()) ?? 0;
              if (added <= 0) return;

              setState(() {
                final current = (pool['current_weight'] as num).toDouble();
                final target = (pool['target_weight'] as num).toDouble();
                pool['current_weight'] = (current + added).clamp(0.0, target);
                pool['participants'] = (pool['participants'] as int) + 1;
                if (pool['current_weight'] >= target) {
                  pool['status'] = 'filled';
                }
              });

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pledge recorded! Thanks for pooling.'),
                  backgroundColor: ColorUtils.forestGreen,
                ),
              );
            },
            child: const Text('Confirm Pledge', style: TextStyle(color: Colors.white)),
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
        title: Text('Produce Batch Pooling', style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePoolDialog,
        backgroundColor: ColorUtils.forestGreen,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Create Pool', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Intro Card ──────────────────────────────────────────────────
            Container(
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
                    child: const Icon(LucideIcons.users, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Collective Farmer Pooling',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Combine produce yields with neighboring farmers to fulfill bulk commercial orders at higher prices.',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Active Batch Pools Section ──────────────────────────────────
            Text('Active Batch Pooling Campaigns', style: AppTypography.heading3(color: ColorUtils.darkText)),
            const SizedBox(height: 12),

            ..._batchPools.map((pool) {
              final title = pool['title'] as String;
              final crop = pool['crop'] as String;
              final targetW = (pool['target_weight'] as num).toDouble();
              final currentW = (pool['current_weight'] as num).toDouble();
              final price = (pool['target_price'] as num).toDouble();
              final participants = pool['participants'] as int;
              final cutoff = pool['cutoff_days'] as int;
              final isFilled = pool['status'] == 'filled' || currentW >= targetW;
              final progress = (currentW / targetW).clamp(0.0, 1.0);

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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: ColorUtils.forestGreen.withValues(alpha: 0.1),
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
                            color: isFilled ? ColorUtils.sageGreen.withValues(alpha: 0.2) : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFilled ? 'GOAL MET' : '$cutoff days left',
                            style: TextStyle(
                              color: isFilled ? ColorUtils.sageGreen : Colors.orange.shade800,
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

                    // Progress Bar
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
                              '$participants farmers joined',
                              style: AppTypography.bodySmall(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                        if (!isFilled)
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorUtils.forestGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            onPressed: () => _showJoinPoolDialog(pool),
                            child: const Text('Pledge Produce', style: TextStyle(color: Colors.white, fontSize: 12)),
                          )
                        else
                          const Text(
                            'Completed',
                            style: TextStyle(color: ColorUtils.sageGreen, fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
