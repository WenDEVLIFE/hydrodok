import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/service/farm_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import 'add_product_dialog.dart';
import '../onboarding/farm_map_picker_dialog.dart';

/// Screen displaying the farmer's complete farm listing, verification status,
/// farm metadata, map location, and products listed under this farm.
class FarmListingScreen extends StatefulWidget {
  const FarmListingScreen({super.key});

  @override
  State<FarmListingScreen> createState() => _FarmListingScreenState();
}

class _FarmListingScreenState extends State<FarmListingScreen> {
  late final Stream<List<Map<String, dynamic>>> _farmStream;
  late final Stream<List<Map<String, dynamic>>> _productsStream;

  List<Map<String, dynamic>> _farmImages = [];
  bool _imagesLoading = false;
  String? _currentFarmId;

  late final FarmService _farmService;

  Map<String, dynamic>? _initialFarm;
  bool _isFarmLoading = true;

  @override
  void initState() {
    super.initState();
    _farmService = FarmService(supabase: Supabase.instance.client);
    _initStreams();
    _loadInitialFarm();
  }

  Future<void> _loadInitialFarm() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isFarmLoading = false);
      return;
    }

    try {
      final farm = await _farmService.getFarmByOwnerId(user.id);
      if (mounted) {
        setState(() {
          _initialFarm = farm;
          _isFarmLoading = false;
        });
        if (farm != null) {
          final farmId = farm['id'] as String?;
          if (farmId != null) _loadFarmImages(farmId);
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isFarmLoading = false);
    }
  }

  void _initStreams() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final client = Supabase.instance.client;

    _farmStream = client
        .from('farms')
        .stream(primaryKey: ['id'])
        .eq('owner_id', user.id);

    _productsStream = client
        .from('products')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  Future<void> _loadFarmImages(String farmId) async {
    if (_imagesLoading) return;
    setState(() => _imagesLoading = true);
    final images = await _farmService.getFarmImages(farmId);
    if (mounted) setState(() {
      _farmImages = images;
      _imagesLoading = false;
    });
  }

  Future<void> _addFarmImage(String farmId) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _imagesLoading = true);
    try {
      await _farmService.uploadFarmImage(farmId, File(picked.path));
      await _loadFarmImages(farmId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo added!'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _imagesLoading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _deleteFarmImage(
      String imageId, String storagePath, String farmId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Remove this photo from your farm gallery?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                const Text('Remove', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _farmService.deleteFarmImage(
          imageId: imageId, storagePath: storagePath);
      await _loadFarmImages(farmId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
      }
    }
  }

  Future<void> _openMapPicker() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final result = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute(
        builder: (_) => const FarmMapPickerDialog(),
      ),
    );

    if (result == null) return;

    try {
      await Supabase.instance.client.from('farms').update({
        'latitude': result.latLng.latitude,
        'longitude': result.latLng.longitude,
        'address': result.address,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('owner_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farm location updated!'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save location: $e')),
        );
      }
    }
  }

  void _showEditFarmDialog(Map<String, dynamic> farm) {
    final nameController = TextEditingController(text: farm['farm_name'] as String? ?? '');
    final descController = TextEditingController(text: farm['description'] as String? ?? '');
    final addressController = TextEditingController(text: farm['address'] as String? ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(LucideIcons.edit3, color: ColorUtils.forestGreen),
            SizedBox(width: 8),
            Text('Edit Farm Details'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Farm Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Hydroponic system type, crops grown...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Farm Address',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
            onPressed: () async {
              final farmId = farm['id'] as String;
              try {
                await Supabase.instance.client.from('farms').update({
                  'farm_name': nameController.text.trim(),
                  'description': descController.text.trim(),
                  'address': addressController.text.trim(),
                  'updated_at': DateTime.now().toIso8601String(),
                }).eq('id', farmId);

                if (mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Farm details updated!'),
                      backgroundColor: ColorUtils.forestGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating farm: $e')),
                  );
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
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
        title: Text('My Farm Listing', style: AppTypography.heading3(color: ColorUtils.darkText)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: ColorUtils.darkText),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _farmStream,
        builder: (context, snapshot) {
          if ((snapshot.connectionState == ConnectionState.waiting || _isFarmLoading) &&
              _initialFarm == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final farm = (snapshot.data?.isNotEmpty == true
              ? snapshot.data!.first
              : null) ?? _initialFarm;

          if (farm == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(LucideIcons.sprout, size: 64, color: ColorUtils.forestGreen),
                    const SizedBox(height: 16),
                    Text(
                      'No Farm Profile Found',
                      style: AppTypography.heading2(color: ColorUtils.darkText),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please complete farm onboarding to manage your listing.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            );
          }

          final farmName = farm['farm_name'] as String? ?? 'My Hydroponic Farm';
          final address = farm['address'] as String? ?? 'Location not set';
          final desc = farm['description'] as String? ?? 'Modern hydroponic farm producing high-grade fresh crops.';
          final photoUrl = farm['farm_photo_url'] as String? ?? '';
          final status = farm['verification_status'] as String? ?? 'unverified';
          final rejectionReason = farm['rejection_reason'] as String? ?? '';
          final lat = farm['latitude'];
          final lng = farm['longitude'];
          final hasLocation = lat != null && lng != null;
          final farmId = farm['id'] as String? ?? '';

          // Load images once when farmId is first known or changes
          if (farmId.isNotEmpty && _currentFarmId != farmId) {
            _currentFarmId = farmId;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadFarmImages(farmId);
            });
          }

          final (String statusLabel, Color statusColor, IconData statusIcon) = switch (status) {
            'verified' => ('Verified Farm', ColorUtils.sageGreen, LucideIcons.badgeCheck),
            'pending' => ('Pending Admin Verification', ColorUtils.terracotta, LucideIcons.clock),
            'rejected' => ('Verification Rejected', Colors.red, LucideIcons.xCircle),
            _ => ('Unverified', Colors.grey, LucideIcons.badgeAlert),
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Farm Header Banner ─────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner photo
                      Stack(
                        children: [
                          Container(
                            height: 160,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                              color: ColorUtils.sageGreen.withValues(alpha: 0.2),
                              image: photoUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                                  : null,
                            ),
                            child: photoUrl.isEmpty
                                ? const Center(
                                    child: Icon(LucideIcons.trees, size: 56, color: ColorUtils.forestGreen),
                                  )
                                : null,
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Details content
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    farmName,
                                    style: AppTypography.heading2(
                                      color: ColorUtils.darkText,
                                      fontSize: 22,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.edit3, color: ColorUtils.forestGreen),
                                  onPressed: () => _showEditFarmDialog(farm),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Icon(LucideIcons.mapPin, size: 16, color: ColorUtils.forestGreen),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: AppTypography.bodySmall(
                                      color: ColorUtils.darkText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (status == 'rejected' && rejectionReason.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'Rejection Reason: $rejectionReason',
                                  style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Map Location Trigger Button ──────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openMapPicker,
                    icon: Icon(hasLocation ? LucideIcons.checkCircle2 : LucideIcons.mapPin, size: 18),
                    label: Text(hasLocation ? 'Update Farm Map Coordinates' : 'Set Farm Location on Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtils.forestGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Farm Photos ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Farm Photos',
                      style: AppTypography.heading3(color: ColorUtils.darkText),
                    ),
                    Text(
                      '${_farmImages.length} photo${_farmImages.length == 1 ? '' : 's'}',
                      style: AppTypography.bodySmall(color: Colors.grey.shade500),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 110,
                  child: _imagesLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _farmImages.length + 1,
                          itemBuilder: (ctx, index) {
                            if (index == _farmImages.length) {
                              return GestureDetector(
                                onTap: farmId.isNotEmpty
                                    ? () => _addFarmImage(farmId)
                                    : null,
                                child: Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: ColorUtils.forestGreen,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.imagePlus,
                                          color: ColorUtils.forestGreen, size: 28),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Add Photo',
                                        style: AppTypography.caption(
                                          color: ColorUtils.forestGreen,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final img = _farmImages[index];
                            final url = img['image_url'] as String? ?? '';
                            final imgId = img['id'] as String? ?? '';
                            final path = img['storage_path'] as String? ?? '';

                            return Stack(
                              children: [
                                Container(
                                  width: 100,
                                  margin: const EdgeInsets.only(right: 10),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Colors.grey.shade200,
                                    image: url.isNotEmpty
                                        ? DecorationImage(
                                            image: NetworkImage(url),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: url.isEmpty
                                      ? const Icon(LucideIcons.image, color: Colors.grey)
                                      : null,
                                ),
                                Positioned(
                                  top: 4,
                                  right: 14,
                                  child: GestureDetector(
                                    onTap: () =>
                                        _deleteFarmImage(imgId, path, farmId),
                                    child: Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(LucideIcons.x,
                                          color: Colors.white, size: 13),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 24),

                // ── Farm System Metrics ──────────────────────────────────────
                Text(
                  'Farm Systems & Specifications',
                  style: AppTypography.heading3(color: ColorUtils.darkText),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        icon: LucideIcons.waves,
                        label: 'System Type',
                        value: 'NFT Hydroponic',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricTile(
                        icon: LucideIcons.activity,
                        label: 'Water Quality',
                        value: 'pH 6.2 • EC 1.8',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Listed Products Under This Farm ──────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Listed Produce Items',
                      style: AppTypography.heading3(color: ColorUtils.darkText),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => AddProductDialog(onProductAdded: () {}),
                        );
                      },
                      icon: const Icon(LucideIcons.plus, size: 16),
                      label: const Text('Add Product'),
                      style: TextButton.styleFrom(foregroundColor: ColorUtils.forestGreen),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _productsStream,
                  builder: (context, prodSnapshot) {
                    final user = Supabase.instance.client.auth.currentUser;
                    final farmId = farm['id'] as String?;

                    final products = (prodSnapshot.data ?? []).where((p) {
                      if (user != null && p['farmer_id'] == user.id) return true;
                      if (farmId != null && p['farm_id'] == farmId) return true;
                      return false;
                    }).toList();

                    if (products.isEmpty) {
                      return Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Center(
                          child: Text(
                            'No produce items listed for this farm yet.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: products.map((p) {
                        final name = p['name'] as String? ?? p['product_name'] as String? ?? 'Produce';
                        final price = (p['price_per_kg'] as num?)?.toDouble() ?? (p['price'] as num?)?.toDouble() ?? 0;
                        final unit = p['unit'] as String? ?? 'kg';
                        final stock = p['stock_quantity'] as int? ?? p['stock'] as int? ?? 0;
                        final prodStatus = p['status'] as String? ?? 'pending';

                        final (String pLabel, Color pColor) = switch (prodStatus.toLowerCase()) {
                          'approved' || 'active' => ('Approved', ColorUtils.sageGreen),
                          'rejected' => ('Rejected', Colors.red),
                          _ => ('Pending Review', ColorUtils.terracotta),
                        };

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: ColorUtils.forestGreen.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.leaf, color: ColorUtils.forestGreen, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: AppTypography.bodyMedium(
                                        color: ColorUtils.darkText,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'PHP ${price.toStringAsFixed(0)} / $unit  •  $stock in stock',
                                      style: AppTypography.bodySmall(color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: pColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  pLabel,
                                  style: TextStyle(
                                    color: pColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
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
          );
        },
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: ColorUtils.forestGreen, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodySmall(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySmall(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.bold,
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
