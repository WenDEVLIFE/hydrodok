import 'dart:io';

import 'package:storage_client/storage_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles farm profile updates, photo uploads, and verification
/// document management using Supabase Storage and the farms table.
///
/// Follows the same pattern as [ProfileService]: takes [SupabaseClient]
/// in the constructor and uses storage + DB internally.
class FarmService {
  final SupabaseClient _supabase;
  final StorageFileApi _storage;

  static const _bucket = 'farm-images';

  FarmService({
    required SupabaseClient supabase,
    StorageFileApi? storageBucket,
  })  : _supabase = supabase,
        _storage = storageBucket ?? supabase.storage.from(_bucket);

  /// Updates the farm's description and/or photo URL in the `farms` table
  /// for the row matching [ownerId]. Always sets `updated_at` to now.
  Future<void> updateFarm(
    String ownerId, {
    String? description,
    String? photoUrl,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (description != null) updates['description'] = description;
    if (photoUrl != null) updates['photo_url'] = photoUrl;

    await _supabase.from('farms').update(updates).eq('owner_id', ownerId);
  }

  /// Uploads a farm photo for [ownerId] to the `farm-images` bucket at
  /// path `{ownerId}/farm_photo.jpg`. Uses upsert so the photo is
  /// overwritten on re-upload. Returns the public URL.
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
  /// table to set `verification_status = 'pending'` and store the public
  /// URL in `verification_doc_url`. Returns the public URL.
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

  /// Skips verification for [ownerId] by setting
  /// `verification_status = 'unverified'` on the `farms` table.
  Future<void> skipVerification(String ownerId) async {
    await _supabase.from('farms').update({
      'verification_status': 'unverified',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('owner_id', ownerId);
  }
}
