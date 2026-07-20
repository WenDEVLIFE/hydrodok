import 'dart:io';

import 'package:storage_client/storage_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles farm profile updates, photo uploads, location coordinates,
/// and verification document management using Supabase Storage and DB.
class FarmService {
  final SupabaseClient _supabase;
  final StorageFileApi _storage;

  static const _bucket = 'farm-images';

  /// Creates a new farm row for [ownerId] with the given details.
  /// Called during onboarding Step 1 (farm registration details are
  /// no longer collected during sign-up).
  Future<void> createFarm({
    required String ownerId,
    required String farmName,
    required String address,
    required List<String> produceTypes,
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) async {
    // Insert the farm row directly (INSERT policy added in migration)
    await _supabase.from('farms').insert({
      'owner_id': ownerId,
      'farm_name': farmName,
      'address': address,
      'produce_types': produceTypes,
      'status': 'active',
      'latitude': latitude ?? 0,
      'longitude': longitude ?? 0,
    });

    // Now update with optional fields
    if (description != null || photoUrl != null) {
      await updateFarm(ownerId, description: description, photoUrl: photoUrl);
    }
  }

  FarmService({
    required SupabaseClient supabase,
    StorageFileApi? storageBucket,
  })  : _supabase = supabase,
        _storage = storageBucket ?? supabase.storage.from(_bucket);

  /// Updates the farm's details (description, photo, latitude, longitude, address)
  /// in the `farms` table for the row matching [ownerId]. Always sets `updated_at` to now.
  Future<void> updateFarm(
    String ownerId, {
    String? description,
    String? photoUrl,
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (description != null) updates['description'] = description;
    if (photoUrl != null) updates['photo_url'] = photoUrl;
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;
    if (address != null) updates['address'] = address;

    await _supabase.from('farms').update(updates).eq('owner_id', ownerId);
  }

  /// Uploads a farm photo for [ownerId] to the `farm-images` bucket at
  /// path `{ownerId}/farm_photo.jpg`. Returns the public URL.
  Future<String> uploadFarmPhoto(String ownerId, File imageFile) async {
    final path = '$ownerId/farm_photo.jpg';

    await _storage.upload(
      path,
      imageFile,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    return _storage.getPublicUrl(path);
  }

  /// Uploads a verification [documentFile] to the `farm-images` bucket at
  /// path `{ownerId}/verification/{docType}.jpg`, then updates the `farms`
  /// table to set `verification_status = 'pending'` and store the public URL.
  Future<String> submitVerification(
    String ownerId,
    File documentFile,
    String docType,
  ) async {
    final path = '$ownerId/verification/$docType.jpg';

    await _storage.upload(
      path,
      documentFile,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'image/jpeg',
      ),
    );

    final publicUrl = _storage.getPublicUrl(path);

    await _supabase.from('farms').update({
      'verification_status': 'pending',
      'verification_doc_url': publicUrl,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('owner_id', ownerId);

    return publicUrl;
  }

  /// Skips verification for [ownerId] by setting `verification_status = 'unverified'`.
  Future<void> skipVerification(String ownerId) async {
    await _supabase.from('farms').update({
      'verification_status': 'unverified',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('owner_id', ownerId);
  }

  /// Fetches only farms that have `verification_status = 'verified'` for publishing to the map.
  Future<List<Map<String, dynamic>>> getVerifiedFarms() async {
    final response = await _supabase
        .from('farms')
        .select('*')
        .eq('verification_status', 'verified');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetches all farms awaiting admin approval (`verification_status = 'pending'`).
  Future<List<Map<String, dynamic>>> getPendingFarms() async {
    final response = await _supabase
        .from('farms')
        .select('*')
        .eq('verification_status', 'pending');
    return List<Map<String, dynamic>>.from(response);
  }

  /// Fetches farm details for a given [ownerId].
  Future<Map<String, dynamic>?> getFarmByOwnerId(String ownerId) async {
    final response = await _supabase
        .from('farms')
        .select('*')
        .eq('owner_id', ownerId)
        .maybeSingle();
    return response;
  }

  /// Approves a farm's verification request (`verification_status = 'verified'`),
  /// publishing it directly to the public farm map.
  Future<void> approveFarmVerification(String farmId) async {
    final response = await _supabase.from('farms').update({
      'verification_status': 'verified',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', farmId).select('owner_id').maybeSingle();

    if (response != null) {
      final ownerId = response['owner_id'] as String?;
      if (ownerId != null) {
        try {
          await _supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'Farm Verification Approved! 🎉',
            'message': 'Your farm has been verified by the Admin and is now published on the live map!',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    }
  }

  /// Rejects a farm's verification request (`verification_status = 'rejected'`).
  Future<void> rejectFarmVerification(String farmId, {String? reason}) async {
    final updates = <String, dynamic>{
      'verification_status': 'rejected',
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (reason != null && reason.isNotEmpty) {
      updates['rejection_reason'] = reason;
    }

    Map<String, dynamic>? farmResponse;
    try {
      farmResponse = await _supabase
          .from('farms')
          .update(updates)
          .eq('id', farmId)
          .select('owner_id, farm_name')
          .maybeSingle();
    } catch (_) {
      farmResponse = await _supabase
          .from('farms')
          .update({
            'verification_status': 'rejected',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', farmId)
          .select('owner_id, farm_name')
          .maybeSingle();
    }

    if (farmResponse != null) {
      final ownerId = farmResponse['owner_id'] as String?;
      if (ownerId != null) {
        try {
          await _supabase.from('notifications').insert({
            'user_id': ownerId,
            'title': 'Farm Verification Denied',
            'message':
                'Your verification request was denied. Reason: ${reason ?? "Document invalid or unclear"}. Please re-upload your document in your Profile section.',
            'read': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    }
  }
}
