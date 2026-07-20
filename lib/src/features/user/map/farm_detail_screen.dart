import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/service/farm_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
/// Farm Detail Screen:
/// Shows farm info, available products, reviews, and actions.
/// Opened from the map when a user taps a farm marker.
class FarmDetailScreen extends StatefulWidget {
  final Map<String, dynamic> farm;

  const FarmDetailScreen({super.key, required this.farm});

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _reviews = [];
  List<Map<String, dynamic>> _farmImages = [];
  bool _isLoading = true;
  double _averageRating = 0;
  int _reviewCount = 0;
  int _currentImagePage = 0;
  final PageController _imagePageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      final ownerId = widget.farm['owner_id'] as String?;
      final farmId = widget.farm['id'] as String?;
      debugPrint('FarmDetailScreen farm map: ${widget.farm}');
      debugPrint('ownerId: $ownerId, farmId: $farmId');

      // Load approved products for this farmer
      List<Map<String, dynamic>> products = [];
      if (ownerId != null) {
        try {
          // Try with status filter (after moderation migration)
          final productsResponse = await supabase
              .from('products')
              .select('*')
              .eq('farmer_id', ownerId)
              .eq('status', 'approved')
              .order('created_at', ascending: false);
          products = List<Map<String, dynamic>>.from(productsResponse);
        } catch (e) {
          debugPrint('Product query with status failed: $e');
          // Fallback: query without status filter
          try {
            final productsResponse = await supabase
                .from('products')
                .select('*')
                .eq('farmer_id', ownerId)
                .order('created_at', ascending: false);
            products = List<Map<String, dynamic>>.from(productsResponse);
          } catch (e2) {
            debugPrint('Product query without status also failed: $e2');
          }
        }
      }

      // Load reviews
      List<Map<String, dynamic>> reviews = [];
      double avgRating = 0;
      int reviewCount = 0;
      if (farmId != null) {
        try {
          final reviewsResponse = await supabase
              .from('farm_reviews')
              .select('*, profiles:user_id(full_name, avatar_url)')
              .eq('farm_id', farmId)
              .order('created_at', ascending: false);
          reviews = List<Map<String, dynamic>>.from(reviewsResponse);

          if (reviews.isNotEmpty) {
            final total = reviews.fold<int>(0, (sum, r) => sum + ((r['rating'] as int?) ?? 0));
            avgRating = total / reviews.length;
            reviewCount = reviews.length;
          }
        } catch (e) {
          debugPrint('Reviews query failed: $e');
        }
      }

      // Load farm images
      List<Map<String, dynamic>> farmImages = [];
      if (farmId != null) {
        farmImages = await FarmService(supabase: supabase)
            .getFarmImages(farmId);
      }

      if (mounted) {
        setState(() {
          _products = products;
          _reviews = reviews;
          _farmImages = farmImages;
          _averageRating = avgRating;
          _reviewCount = reviewCount;
          _isLoading = false;
        });
      }
    } catch (e, stack) {
      debugPrint('FarmDetailScreen _loadData error: $e');
      debugPrint(stack.toString());
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load farm data: $e')),
        );
      }
    }
  }

  Future<void> _leaveReview() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to leave a review.')),
      );
      return;
    }

    final farmId = widget.farm['id'] as String?;
    if (farmId == null) return;

    double selectedRating = 5;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Leave a Review'),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < selectedRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                      onPressed: () => setDialogState(() => selectedRating = index + 1),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Share your experience...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.forestGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      await Supabase.instance.client.from('farm_reviews').insert({
        'farm_id': farmId,
        'user_id': user.id,
        'rating': selectedRating.toInt(),
        'comment': commentController.text.trim(),
      });

      // Recalculate farm rating
      await Supabase.instance.client.rpc('recalculate_farm_rating',
          params: {'p_farm_id': farmId});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted!')),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _orderProduct(Map<String, dynamic> product) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to order.')),
      );
      return;
    }

    final farmId = widget.farm['id'] as String?;
    final productId = product['id'] as String?;
    final farmerId = product['farmer_id'] as String?;
    final price = (product['price_per_kg'] as num?)?.toDouble() ?? 0;

    if (farmId == null || productId == null || farmerId == null) return;

    final quantityController = TextEditingController(text: '1');
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Order Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Price: PHP ${price.toStringAsFixed(0)} / ${product['unit'] ?? 'kg'}'),
            const SizedBox(height: 12),
            TextField(
              controller: quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorUtils.forestGreen,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Place Order'),
          ),
        ],
      ),
    );

    if (result != true) return;

    final quantity = int.tryParse(quantityController.text) ?? 1;
    final total = price * quantity;

    if (quantity <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity.')),
        );
      }
      return;
    }

    try {
      await Supabase.instance.client.rpc('create_order_with_items', params: {
        'p_buyer_id': user.id,
        'p_farmer_id': farmerId,
        'p_status': 'pending',
        'p_items': [
          {
            'product_id': productId,
            'quantity': quantity,
            'subtotal': total,
          }
        ],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  void _messageFarm() {
    // TODO: navigate to chat or open messaging
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Messaging coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final farmName = widget.farm['farm_name'] as String? ?? 'Unnamed Farm';
    final address = widget.farm['address'] as String? ?? 'No address';
    final produce = (widget.farm['produce_types'] as List<dynamic>?)
            ?.map((e) => e as String)
            .join(', ') ??
        'Hydroponics';

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      ),
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                slivers: [
                  // Header image area
                  SliverAppBar(
                    expandedHeight: 260,
                    pinned: true,
                    backgroundColor: ColorUtils.sageGreen,
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    flexibleSpace: FlexibleSpaceBar(
                      background: _farmImages.isEmpty
                          // Fallback gradient when no images uploaded yet
                          ? Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    ColorUtils.sageGreen,
                                    ColorUtils.forestGreen.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 60,
                                    left: 40,
                                    child: _circle(80, Colors.white.withOpacity(0.15)),
                                  ),
                                  Positioned(
                                    top: 100,
                                    right: 60,
                                    child: _circle(60, Colors.white.withOpacity(0.1)),
                                  ),
                                  Positioned(
                                    bottom: 40,
                                    left: 120,
                                    child: _circle(100, Colors.white.withOpacity(0.12)),
                                  ),
                                ],
                              ),
                            )
                          // Image carousel
                          : Stack(
                              fit: StackFit.expand,
                              children: [
                                PageView.builder(
                                  controller: _imagePageController,
                                  itemCount: _farmImages.length,
                                  onPageChanged: (i) =>
                                      setState(() => _currentImagePage = i),
                                  itemBuilder: (context, index) {
                                    final url = _farmImages[index]['image_url']
                                            as String? ??
                                        '';
                                    return Image.network(
                                      url,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: ColorUtils.sageGreen,
                                        child: const Icon(
                                          LucideIcons.image,
                                          color: Colors.white54,
                                          size: 40,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                // Dark gradient overlay for readability
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 80,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        colors: [
                                          Colors.black.withOpacity(0.55),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                // Dot indicators
                                if (_farmImages.length > 1)
                                  Positioned(
                                    bottom: 12,
                                    left: 0,
                                    right: 0,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _farmImages.length,
                                        (i) => AnimatedContainer(
                                          duration: const Duration(
                                              milliseconds: 200),
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 3),
                                          width:
                                              _currentImagePage == i ? 20 : 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _currentImagePage == i
                                                ? Colors.white
                                                : Colors.white54,
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                    ),
                    actions: [
                      Container(
                        margin: const EdgeInsets.only(right: 16, top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ColorUtils.forestGreen,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          produce,
                          style: AppTypography.caption(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Farm info card
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                              const Icon(LucideIcons.mapPin,
                                  color: ColorUtils.terracotta, size: 20),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildStars(_averageRating),
                              const SizedBox(width: 6),
                              Text(
                                '${_averageRating.toStringAsFixed(1)} ($_reviewCount reviews)',
                                style: AppTypography.bodySmall(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            address,
                            style: AppTypography.bodySmall(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Products section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Available Products',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  if (_products.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'No products available yet.',
                          style: AppTypography.bodyMedium(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductCard(_products[index]),
                        childCount: _products.length,
                      ),
                    ),

                  // Reviews section
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Reviews',
                            style: AppTypography.heading3(
                              color: ColorUtils.darkText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _leaveReview,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Write Review'),
                            style: TextButton.styleFrom(
                              foregroundColor: ColorUtils.forestGreen,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (_reviews.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text(
                          'No reviews yet. Be the first!',
                          style: AppTypography.bodyMedium(color: Colors.grey.shade500),
                        ),
                      ),
                    )
                  else
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildReviewCard(_reviews[index]),
                        childCount: _reviews.length,
                      ),
                    ),

                  // Message Farm button
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Need a large order?',
                                  style: AppTypography.bodyMedium(
                                    color: ColorUtils.darkText,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Farmer can request Pooling if low on stock',
                                  style: AppTypography.bodySmall(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _messageFarm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorUtils.terracotta,
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
                            child: Text(
                              'Message Farm',
                              style: AppTypography.button(
                                color: Colors.white,
                                fontSize: 13,
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
    );
  }

  Widget _circle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rating.round() ? Icons.star : Icons.star_border,
          color: Colors.amber,
          size: 18,
        );
      }),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final name = product['name'] as String? ?? '';
    final price = (product['price_per_kg'] as num?)?.toDouble() ?? 0;
    final unit = product['unit'] as String? ?? 'kg';
    final stock = product['stock_quantity'] as int? ?? 0;
    final inStock = stock > 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: ColorUtils.sageGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.leaf,
              color: ColorUtils.forestGreen,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  inStock ? '${_formatNumber(stock)} units' : 'Out of stock',
                  style: AppTypography.bodySmall(
                    color: inStock ? Colors.grey.shade600 : Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'PHP ${price.toStringAsFixed(0)} / $unit',
                style: AppTypography.bodySmall(
                  color: ColorUtils.forestGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: inStock ? () => _orderProduct(product) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: inStock ? ColorUtils.forestGreen : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  elevation: 0,
                ),
                child: Text(
                  inStock ? 'Order' : 'Unavailable',
                  style: AppTypography.caption(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final profile = review['profiles'] as Map<String, dynamic>?;
    final name = profile?['full_name'] as String? ?? 'Unknown';
    final rating = review['rating'] as int? ?? 0;
    final comment = review['comment'] as String? ?? '';
    final createdAt = review['created_at'] as String? ?? '';

    String timeStr = '';
    if (createdAt.isNotEmpty) {
      try {
        final dt = DateTime.parse(createdAt);
        final diff = DateTime.now().difference(dt);
        if (diff.inDays < 30) {
          timeStr = '${diff.inDays}d ago';
        } else {
          timeStr = '${dt.month}/${dt.day}/${dt.year}';
        }
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ColorUtils.forestGreen,
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: AppTypography.caption(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTypography.bodySmall(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: AppTypography.caption(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              _buildStars(rating.toDouble()),
            ],
          ),
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              comment,
              style: AppTypography.bodyMedium(color: ColorUtils.darkText),
            ),
          ],
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)},000';
    }
    return n.toString();
  }
}
