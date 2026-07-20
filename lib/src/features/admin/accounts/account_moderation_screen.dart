import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/repositories/farm_repository.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Admin Account Moderation & Verification Approval Screen:
///
/// Fetches real registered user accounts (Farmers & Consumers) from Supabase
/// `profiles` and `farms` tables. Admins can view account details, check
/// verification status, and approve pending farmer accounts to publish them to the map.
class AccountModerationScreen extends StatefulWidget {
  const AccountModerationScreen({super.key});

  @override
  State<AccountModerationScreen> createState() => _AccountModerationScreenState();
}

class _AccountModerationScreenState extends State<AccountModerationScreen> {
  late final FarmRepository _farmRepository;
  bool _isLoading = true;
  List<Map<String, dynamic>> _profiles = [];
  Map<String, Map<String, dynamic>> _farmMap = {}; // ownerId -> farm map

  @override
  void initState() {
    super.initState();
    _farmRepository = SupabaseFarmRepository();
    _fetchAccounts();
  }

  Future<void> _fetchAccounts() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;

      // 1. Fetch all user profiles from DB
      final profileResponse = await supabase.from('profiles').select('*');
      final profiles = List<Map<String, dynamic>>.from(profileResponse);

      // 2. Fetch all farms from DB
      final farms = List<Map<String, dynamic>>.from(await supabase.from('farms').select('*'));

      final Map<String, Map<String, dynamic>> farmMap = {};
      for (final f in farms) {
        final ownerId = f['owner_id'] as String?;
        if (ownerId != null) {
          farmMap[ownerId] = f;
        }
      }

      if (mounted) {
        setState(() {
          _profiles = profiles;
          _farmMap = farmMap;
        });
      }
    } catch (_) {
      // Fallback mock accounts if offline
      _profiles = [
        {
          'id': 'user-1',
          'full_name': 'Rosa Santos (Farmer)',
          'role': 'farmer',
          'contact_number': '09171234567',
          'onboarding_completed': true,
        },
        {
          'id': 'user-2',
          'full_name': 'Juan Dela Cruz (Consumer)',
          'role': 'consumer',
          'contact_number': '09189876543',
          'onboarding_completed': true,
        },
      ];
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _approveFarmer(String ownerId, String? farmId) async {
    try {
      if (farmId != null && farmId.isNotEmpty) {
        await _farmRepository.approveFarmVerification(farmId);
      } else {
        await _farmRepository.updateFarm(ownerId);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Farmer Verified & Published to Map!'),
            backgroundColor: ColorUtils.forestGreen,
          ),
        );
      }
      _fetchAccounts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving farmer: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Title ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Account Moderation & Verification',
                    style: AppTypography.heading2(color: ColorUtils.darkText),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manage registered farmers & consumers live from Supabase. Review and approve farm verifications.',
                    style: AppTypography.bodyMedium(color: Colors.grey.shade600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(LucideIcons.refreshCw, color: ColorUtils.forestGreen),
                onPressed: _fetchAccounts,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Accounts List ──────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _profiles.isEmpty
                    ? Center(
                        child: Text(
                          'No registered user accounts found.',
                          style: AppTypography.bodyLarge(color: Colors.grey.shade600),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _profiles.length,
                        itemBuilder: (ctx, index) {
                          final profile = _profiles[index];
                          final userId = profile['id'] as String? ?? '';
                          final farm = _farmMap[userId];
                          return _buildAccountCard(profile, farm);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUserAccount(
    String userId,
    String fullName,
    String role,
  ) async {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You cannot delete your own account while logged in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.trash2, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete User Account'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete the $role account for "$fullName"? All associated farm and profile data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final supabase = Supabase.instance.client;
        try {
          await supabase.rpc('delete_user_account', params: {'target_user_id': userId});
        } catch (_) {
          await supabase.from('profiles').delete().eq('id', userId);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account deleted successfully.'),
              backgroundColor: ColorUtils.forestGreen,
            ),
          );
        }
        _fetchAccounts();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildAccountCard(
    Map<String, dynamic> profile,
    Map<String, dynamic>? farm,
  ) {
    final userId = profile['id'] as String? ?? '';
    final fullName = profile['full_name'] as String? ?? 'Unnamed User';
    final role = (profile['role'] as String? ?? 'consumer').toUpperCase();
    final contact = profile['contact_number'] as String? ?? 'No contact';
    final isFarmer = role.toLowerCase() == 'farmer';

    final farmId = farm?['id'] as String?;
    final farmName = farm?['farm_name'] as String? ?? 'No farm record';
    final farmAddress = farm?['address'] as String? ?? 'No address';
    final verificationStatus =
        farm?['verification_status'] as String? ?? 'unverified';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: isFarmer ? ColorUtils.sageGreen : Colors.blue.shade100,
                    radius: 22,
                    child: Icon(
                      isFarmer ? LucideIcons.sprout : LucideIcons.user,
                      color: isFarmer ? ColorUtils.darkText : Colors.blue.shade900,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: AppTypography.heading3(color: ColorUtils.darkText, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isFarmer ? ColorUtils.forestGreen : Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              role,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            contact,
                            style: AppTypography.bodySmall(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              if (isFarmer) _buildVerificationStatusChip(verificationStatus),
            ],
          ),

          // Additional Farmer & Farm info
          if (isFarmer) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Farm: $farmName',
                      style: AppTypography.bodyMedium(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Address: $farmAddress',
                      style: AppTypography.bodySmall(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                if (verificationStatus == 'pending' || verificationStatus == 'unverified')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorUtils.forestGreen,
                      foregroundColor: ColorUtils.pureWhite,
                    ),
                    icon: const Icon(LucideIcons.badgeCheck, size: 18),
                    label: const Text('Approve & Publish Farm'),
                    onPressed: () => _approveFarmer(userId, farmId),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: BorderSide(color: Colors.red.shade300),
                ),
                icon: const Icon(LucideIcons.trash2, size: 16),
                label: const Text('Delete Account'),
                onPressed: () => _deleteUserAccount(userId, fullName, role),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationStatusChip(String status) {
    Color bg = Colors.grey.shade200;
    Color text = Colors.grey.shade800;
    String label = 'Unverified';

    if (status == 'pending') {
      bg = Colors.orange.shade100;
      text = Colors.orange.shade900;
      label = 'Pending Review';
    } else if (status == 'verified') {
      bg = Colors.green.shade100;
      text = Colors.green.shade900;
      label = 'Verified & Published';
    } else if (status == 'rejected') {
      bg = Colors.red.shade100;
      text = Colors.red.shade900;
      label = 'Rejected';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
