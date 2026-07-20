import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Global platform settings persisted in Supabase.
class PlatformSettings {
  final String id;
  final bool maintenanceMode;
  final bool requireFarmVerification;
  final bool enableAutoMod;
  final bool emailNotifications;
  final String adminContactEmail;
  final int maxListingsPerFarmer;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const PlatformSettings({
    this.id = 'global',
    this.maintenanceMode = false,
    this.requireFarmVerification = true,
    this.enableAutoMod = true,
    this.emailNotifications = true,
    this.adminContactEmail = 'admin@agriconnect.ph',
    this.maxListingsPerFarmer = 10,
    this.createdAt,
    this.updatedAt,
  });

  factory PlatformSettings.fromJson(Map<String, dynamic> json) {
    return PlatformSettings(
      id: json['id'] as String? ?? 'global',
      maintenanceMode: json['maintenance_mode'] as bool? ?? false,
      requireFarmVerification: json['require_farm_verification'] as bool? ?? true,
      enableAutoMod: json['enable_auto_mod'] as bool? ?? true,
      emailNotifications: json['email_notifications'] as bool? ?? true,
      adminContactEmail: json['admin_contact_email'] as String? ?? 'admin@agriconnect.ph',
      maxListingsPerFarmer: json['max_listings_per_farmer'] as int? ?? 10,
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'maintenance_mode': maintenanceMode,
      'require_farm_verification': requireFarmVerification,
      'enable_auto_mod': enableAutoMod,
      'email_notifications': emailNotifications,
      'admin_contact_email': adminContactEmail,
      'max_listings_per_farmer': maxListingsPerFarmer,
    };
  }

  PlatformSettings copyWith({
    String? id,
    bool? maintenanceMode,
    bool? requireFarmVerification,
    bool? enableAutoMod,
    bool? emailNotifications,
    String? adminContactEmail,
    int? maxListingsPerFarmer,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlatformSettings(
      id: id ?? this.id,
      maintenanceMode: maintenanceMode ?? this.maintenanceMode,
      requireFarmVerification: requireFarmVerification ?? this.requireFarmVerification,
      enableAutoMod: enableAutoMod ?? this.enableAutoMod,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      adminContactEmail: adminContactEmail ?? this.adminContactEmail,
      maxListingsPerFarmer: maxListingsPerFarmer ?? this.maxListingsPerFarmer,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}

/// Service for admin settings persistence and admin user creation.
class AdminSettingsService {
  final SupabaseClient _supabase;

  AdminSettingsService({required SupabaseClient supabase}) : _supabase = supabase;

  /// Reads the global platform settings row.
  /// Falls back to a default instance if the row is missing.
  Future<PlatformSettings> getSettings() async {
    try {
      final row = await _supabase
          .from('platform_settings')
          .select()
          .eq('id', 'global')
          .maybeSingle();

      if (row == null) return const PlatformSettings();
      return PlatformSettings.fromJson(row);
    } catch (e) {
      debugPrint('getSettings failed: $e');
      throw Exception('Failed to load platform settings: $e');
    }
  }

  /// Upserts the global platform settings row.
  Future<void> saveSettings(PlatformSettings settings) async {
    try {
      final payload = settings.toJson()
        ..['updated_at'] = DateTime.now().toIso8601String();

      await _supabase.from('platform_settings').upsert(payload);
    } catch (e) {
      debugPrint('saveSettings failed: $e');
      throw Exception('Failed to save platform settings: $e');
    }
  }

  /// Calls the server-side RPC that creates a new admin user in auth.users
  /// and the public.profiles table.
  Future<void> createAdminUser({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      await _supabase.rpc(
        'create_admin_user',
        params: {
          'email': email,
          'password': password,
          'full_name': fullName,
        },
      );
    } catch (e) {
      debugPrint('createAdminUser failed: $e');
      throw Exception('Failed to create admin user: $e');
    }
  }

  /// Fetches all profiles with role = 'admin'.
  Future<List<Map<String, dynamic>>> getAdminProfiles() async {
    try {
      final result = await _supabase
          .from('profiles')
          .select('*')
          .eq('role', 'admin')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(result);
    } catch (e) {
      debugPrint('getAdminProfiles failed: $e');
      throw Exception('Failed to load admin profiles: $e');
    }
  }

  /// Deletes an admin or user account by target user ID.
  Future<void> deleteUserAccount(String userId) async {
    try {
      await _supabase.rpc(
        'delete_user_account',
        params: {'target_user_id': userId},
      );
    } catch (e) {
      debugPrint('deleteUserAccount RPC failed: $e, attempting direct profile delete');
      try {
        await _supabase.from('profiles').delete().eq('id', userId);
      } catch (e2) {
        debugPrint('deleteUserAccount direct delete also failed: $e2');
        throw Exception('Failed to delete account: $e2');
      }
    }
  }
}
