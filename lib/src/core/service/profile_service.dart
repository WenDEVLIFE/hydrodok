  import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles profile avatar uploads to Supabase Storage and provides
/// the public URL. Falls back to the app's built‑in logo.png when
/// no custom avatar has been uploaded.
class ProfileService {
  final SupabaseClient _supabase;

  static const _bucket = 'avatars';

  ProfileService({required SupabaseClient supabase}) : _supabase = supabase;

  /// Returns the user's profile row [avatar_url] value, or null if empty.
  Future<String?> getStoredAvatarUrl(String userId) async {
    final result = await _supabase
        .from('profiles')
        .select('avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (result == null) return null;
    final url = result['avatar_url'] as String?;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  /// Uploads an avatar image for [userId] and updates the profile's
  /// avatar_url in the database. Returns the public URL.
  /// [imageFile] must be a valid image file (jpg/png).
  Future<String> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    final path = '$userId/avatar.jpg';

    await _supabase.storage.from(_bucket).upload(
          path,
          imageFile,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/jpeg',
          ),
        );

    final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(path);

    // Persist the URL in the profile row so the app knows
    // an avatar has been uploaded.
    await _supabase.from('profiles').update({
      'avatar_url': publicUrl,
    }).eq('id', userId);

    return publicUrl;
  }

  /// Deletes the user's current avatar from storage and clears
  /// avatar_url in the profile row.
  Future<void> deleteAvatar(String userId) async {
    final path = '$userId/avatar.jpg';
    try {
      await _supabase.storage.from(_bucket).remove([path]);
    } catch (_) {
      // File doesn't exist — nothing to delete.
    }
    // Also clear the avatar_url in the profile.
    await _supabase.from('profiles').update({
      'avatar_url': '',
    }).eq('id', userId);
  }
}
