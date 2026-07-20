import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/model/user_session.dart';
import '../../../core/repositories/auth_repository.dart';
import '../../../core/repositories/farm_repository.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import '../../farmer/batch_pooling_screen.dart';
import '../../farmer/farm_listing_screen.dart';
import '../../farmer/farm_settings_screen.dart';
import '../../farmer/farmer_orders_screen.dart';
import '../../farmer/farmer_requests_screen.dart';
import 'consumer_orders_screen.dart';
import 'delivery_addresses_screen.dart';
import '../../farmer/issue_reports_screen.dart';
import '../../login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final FarmRepository _farmRepository;
  UserSession? _session;
  bool _isLoading = true;
  bool _isFarmer = false;
  String _initials = '';
  String _displayName = '';
  String _location = '';

  // Farmer verification details
  String? _farmId;
  String _verificationStatus = 'unverified';
  String? _rejectionReason;
  String? _docUrl;

  // Farmer rating/review stats (from farm_reviews)
  double _avgRating = 0;
  int _reviewCount = 0;
  int _productCount = 0;
  int _orderCount = 0;

  @override
  void initState() {
    super.initState();
    _farmRepository = SupabaseFarmRepository();
    _loadSession();
  }

  Future<void> _loadSession() async {
    try {
      final authRepo = context.read<AuthRepository>();
      final session = await authRepo.getCurrentSession();
      if (session != null && mounted) {
        final isFarmer = session.role == 'farmer';
        setState(() {
          _session = session;
          _isFarmer = isFarmer;
          _displayName = session.fullName.isNotEmpty ? session.fullName : 'Unknown User';
          _location = session.farmAddress.isNotEmpty ? session.farmAddress : 'Location not set';
          _initials = _buildInitials(session.fullName);
        });

        if (isFarmer) {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            final farm = await _farmRepository.getFarmByOwnerId(userId);
            if (farm != null && mounted) {
              final farmId = farm['id'] as String?;
              setState(() {
                _farmId = farmId;
                _verificationStatus = farm['verification_status'] as String? ?? 'unverified';
                _rejectionReason = farm['rejection_reason'] as String?;
                _docUrl = farm['verification_doc_url'] as String?;
              });

              // Load real product count
              try {
                final productsRes = await Supabase.instance.client
                    .from('products')
                    .select('id')
                    .eq('farmer_id', userId);
                final count = (productsRes as List).length;
                if (mounted) setState(() => _productCount = count);
              } catch (e) {
                debugPrint('Profile: product count failed: $e');
              }

              // Load real rating & review count from farm_reviews
              if (farmId != null) {
                try {
                  final reviews = await Supabase.instance.client
                      .from('farm_reviews')
                      .select('rating')
                      .eq('farm_id', farmId);
                  final list = List<Map<String, dynamic>>.from(reviews);
                  if (list.isNotEmpty && mounted) {
                    final total = list.fold<int>(
                      0, (sum, r) => sum + ((r['rating'] as int?) ?? 0));
                    setState(() {
                      _avgRating = total / list.length;
                      _reviewCount = list.length;
                    });
                  }
                } catch (e) {
                  debugPrint('Profile: reviews load failed: $e');
                }
              }
            }
          }
        } else {
          final userId = Supabase.instance.client.auth.currentUser?.id;
          if (userId != null) {
            // Load real order count for consumers
            try {
              final ordersRes = await Supabase.instance.client
                  .from('orders')
                  .select('id')
                  .eq('buyer_id', userId);
              final count = (ordersRes as List).length;
              if (mounted) setState(() => _orderCount = count);
            } catch (e) {
              debugPrint('Profile: order count failed: $e');
            }
          }
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _buildInitials(String fullName) {
    if (fullName.isEmpty) return '?';
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return parts.first[0].toUpperCase();
  }

  Future<void> _openResubmitDialog() async {
    File? selectedDoc;
    String selectedDocType = 'business_permit';
    final picker = ImagePicker();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(LucideIcons.fileText, color: ColorUtils.forestGreen),
              const SizedBox(width: 8),
              const Text('Farm Verification Document'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Upload official proof (Business Permit, DTI Registration, Barangay Clearance, or Valid ID) to get your farm verified.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 14),

              // Document type dropdown
              DropdownButtonFormField<String>(
                value: selectedDocType,
                decoration: const InputDecoration(
                  labelText: 'Document Type',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'business_permit', child: Text('Business Permit')),
                  DropdownMenuItem(value: 'dti_registration', child: Text('DTI Registration')),
                  DropdownMenuItem(value: 'barangay_clearance', child: Text('Barangay Clearance')),
                  DropdownMenuItem(value: 'valid_id', child: Text('Government Valid ID')),
                ],
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedDocType = val);
                },
              ),
              const SizedBox(height: 14),

              // Document photo preview / pick button
              if (selectedDoc != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    selectedDoc!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 85,
                  );
                  if (picked != null) {
                    setModalState(() => selectedDoc = File(picked.path));
                  }
                },
                icon: Icon(selectedDoc == null ? LucideIcons.upload : LucideIcons.refreshCw),
                label: Text(selectedDoc == null ? 'Select Photo / Document' : 'Change Document'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
              onPressed: selectedDoc != null
                  ? () => Navigator.of(ctx).pop(true)
                  : null,
              icon: const Icon(LucideIcons.check, size: 18, color: Colors.white),
              label: const Text('Submit Verification', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (confirm != true || selectedDoc == null) return;

    setState(() => _isLoading = true);
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _farmRepository.submitVerification(userId, selectedDoc!, selectedDocType);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Verification document submitted successfully! Awaiting Admin review.'),
              backgroundColor: ColorUtils.forestGreen,
            ),
          );
        }
        await _loadSession();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading document: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title ─────────────────────────────────────
                      Text(
                        'My Profile',
                        style: AppTypography.heading3(
                          color: ColorUtils.darkText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Profile card (realtime) ───────────────────
                      _buildProfileCard(),
                      const SizedBox(height: 16),

                      // ── Verification Status Banner (Farmer only) ──
                      if (_isFarmer) ...[
                        _buildVerificationBanner(),
                        const SizedBox(height: 24),
                      ],

                      // ── Stats row ─────────────────────────────────
                      _buildStatsRow(),
                      const SizedBox(height: 24),

                      // ── Menu items ────────────────────────────────
                      _buildMenuItem(
                        title: _isFarmer ? 'My Farm Listing' : 'My Orders',
                        subtitle: _isFarmer ? 'View farm profile, coordinates & listed produce' : 'Track ongoing purchases',
                        icon: _isFarmer ? LucideIcons.sprout : LucideIcons.shoppingBag,
                        onTap: () {
                          if (_isFarmer) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FarmListingScreen()),
                            );
                          } else {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const ConsumerOrdersScreen()),
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Saved Delivery Addresses',
                        subtitle: 'Manage default & shipping locations',
                        icon: LucideIcons.mapPin,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const DeliveryAddressesScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Batch Pooling Requests',
                        subtitle: 'Collective farmer produce pooling',
                        icon: LucideIcons.users,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const BatchPoolingScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      if (_isFarmer) ...[
                        _buildMenuItem(
                          title: 'Buyer Crop Requests',
                          subtitle: 'View bulk crop requests & submit quotes',
                          icon: LucideIcons.inbox,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FarmerRequestsScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildMenuItem(
                          title: 'Customer Orders',
                          subtitle: 'Manage order fulfillment & status',
                          icon: LucideIcons.shoppingBag,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const FarmerOrdersScreen()),
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                      ],
                      _buildMenuItem(
                        title: 'Issue Reports',
                        subtitle: 'Report a system or technical problem',
                        icon: LucideIcons.alertTriangle,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const IssueReportsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      _buildMenuItem(
                        title: 'Settings',
                        subtitle: 'Notifications, farm status & payout details',
                        icon: LucideIcons.settings,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const FarmSettingsScreen()),
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // ── Logout Button ─────────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _handleLogout(context),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD84040)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          icon: const Icon(
                            LucideIcons.logOut,
                            color: Color(0xFFD84040),
                            size: 18,
                          ),
                          label: Text(
                            'Log Out',
                            style: AppTypography.button(
                              color: const Color(0xFFD84040),
                              fontWeight: FontWeight.w600,
                            ),
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

  Widget _buildVerificationBanner() {
    Color bg = Colors.amber.shade50;
    Color border = Colors.amber.shade300;
    IconData icon = LucideIcons.alertCircle;
    Color iconColor = Colors.amber.shade900;
    String title = 'Unverified Farm';
    String description = 'Upload document proof to get verified and published on the public farm map.';

    if (_verificationStatus == 'verified') {
      bg = Colors.green.shade50;
      border = Colors.green.shade300;
      icon = LucideIcons.badgeCheck;
      iconColor = ColorUtils.forestGreen;
      title = 'Verified Hydroponic Farm';
      description = 'Your farm is verified by Admin and published live on the public map!';
    } else if (_verificationStatus == 'pending') {
      bg = Colors.orange.shade50;
      border = Colors.orange.shade300;
      icon = LucideIcons.clock;
      iconColor = Colors.orange.shade900;
      title = 'Verification Pending Review';
      description = 'Your proof document was submitted and is currently under review by HydroDok Admins.';
    } else if (_verificationStatus == 'rejected') {
      bg = Colors.red.shade50;
      border = Colors.red.shade300;
      icon = LucideIcons.alertTriangle;
      iconColor = Colors.red.shade900;
      title = 'Verification Denied';
      description = _rejectionReason != null
          ? 'Reason: $_rejectionReason\nTap below to re-submit your document.'
          : 'Your verification was denied by Admin. Please re-submit clear document proof.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: AppTypography.bodySmall(color: Colors.black87),
          ),
          if (_verificationStatus == 'unverified' || _verificationStatus == 'rejected') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorUtils.forestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(LucideIcons.upload, size: 16),
              label: Text(_verificationStatus == 'rejected' ? 'Re-submit Verification' : 'Verify My Farm'),
              onPressed: _openResubmitDialog,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorUtils.sageGreen.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: ColorUtils.forestGreen,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _initials,
              style: AppTypography.heading4(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _displayName,
                      style: AppTypography.subtitle1(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (_isFarmer && _verificationStatus == 'verified') ...[
                      const SizedBox(width: 6),
                      const Icon(LucideIcons.badgeCheck, color: ColorUtils.forestGreen, size: 18),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (_isFarmer && _session?.farmName != null && _session!.farmName.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        _session!.farmName,
                        style: AppTypography.bodySmall(
                          color: ColorUtils.forestGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  '${_session?.email ?? ''}',
                  style: AppTypography.bodySmall(
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 10, color: _isFarmer ? ColorUtils.forestGreen : Colors.blue),
                    const SizedBox(width: 6),
                    Text(
                      _isFarmer ? 'Farmer' : 'Consumer',
                      style: AppTypography.bodySmall(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildStatsRow() {
    if (!_isFarmer) {
      // Consumers only see applicable stats.
      return Row(
        children: [
          Expanded(child: _buildStatItem('Orders', '$_orderCount')),
        ],
      );
    }

    // Farmers see products, rating, and reviews.
    final ratingLabel = _reviewCount > 0 ? '${_avgRating.toStringAsFixed(1)} ★' : '— ★';

    return Row(
      children: [
        Expanded(child: _buildStatItem('Products', '$_productCount')),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Rating', ratingLabel)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatItem('Reviews', '$_reviewCount')),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(value, style: AppTypography.heading4(color: ColorUtils.darkText, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label, style: AppTypography.caption(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required String subtitle,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: ColorUtils.forestGreen),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.subtitle2(color: ColorUtils.darkText, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of HydroDok?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Log Out', style: TextStyle(color: Color(0xFFD84040))),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    try {
      final authRepo = context.read<AuthRepository>();
      await authRepo.signOut();
    } catch (_) {}

    if (!context.mounted) return;

    final authRepo = context.read<AuthRepository>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginScreen(authRepository: authRepo)),
      (route) => false,
    );
  }
}
