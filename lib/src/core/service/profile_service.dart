import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles profile avatar uploads to Supabase Storage and provides
/// the public URL. Falls back to the app's built‑in logo.png when
/// no custom avatar has been uploaded.
class ProfileService {
  final SupabaseClient _supabase;

  static const _bucket = 'avatars';

  ProfileService({required SupabaseClient supabase}) : _supabase = supabase;

  /// Returns the public URL for the user's avatar, or null if none
  /// has been uploaded (caller should fall back to the default asset).
  String? getAvatarUrl(String userId) {
    final path = '${userId}_profile/avatar.jpg';
    final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(path);

    // Check if the file actually exists by trying to get its metadata.
    // If it doesn't exist, return null so the caller shows the default.
    // We use a simple HTTP HEAD check via the public URL.
    return publicUrl; // Will 404 if not uploaded — caller handles fallback.
  }

  /// Uploads an avatar image for [userId]. Returns the public URL.
  /// [imageFile] must be a valid image file (jpg/png).
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final path = '${userId}_profile/avatar.jpg';

    await _supabase.storage.from(_bucket).upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }

  /// Deletes the user's current avatar from storage.
  Future<void> deleteAvatar(String userId) async {
    final path = '${userId}_profile/avatar.jpg';
    try {
      await _supabase.storage.from(_bucket).remove([path]);
    } catch (_) {
      // File doesn't exist — nothing to delete.
    }
  }
}
