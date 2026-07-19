import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One-time migration helper that uploads `assets/logo.png` to the current
/// user's avatar path in the avatars storage bucket.
///
/// Uploads to `$userId/avatar.jpg` so the RLS policy
/// `(storage.foldername(name))[1] = auth.uid()` passes.
///
/// Call from anywhere in the app:
/// ```dart
/// await AvatarBackfill.setDefaultAvatar(Supabase.instance.client, userId: userId);
/// ```
class AvatarBackfill {
  /// Ensures the current user has a default avatar in storage.
  ///
  /// 1. Uploads `assets/logo.png` to `avatars/$userId/avatar.jpg` (upsert).
  /// 2. Updates the user's `avatar_url` to the public URL.
  ///
  /// [supabase] — the Supabase client.
  /// [userId] — the user to backfill (must match the current session).
  /// [logoFile] — optional pre-loaded file (useful in tests).
  static Future<String> setDefaultAvatar(
    SupabaseClient supabase, {
    required String userId,
    File? logoFile,
  }) async {
    final file = logoFile ?? await _tempFileFromAsset();
    final path = '$userId/avatar.jpg';

    // Upload to the user's own path (RLS friendly)
    await supabase.storage.from('avatars').upload(
          path,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );

    final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);

    // Update the profile row
    await supabase
        .from('profiles')
        .update({'avatar_url': publicUrl})
        .eq('id', userId);

    return publicUrl;
  }

  /// Writes `assets/logo.png` from the asset bundle to a temp file.
  static Future<File> _tempFileFromAsset() async {
    final bytes =
        await rootBundle.load('assets/logo.png').then((b) => b.buffer.asUint8List());
    final dir = await getTemporaryDirectory();
    final tempFile = File('${dir.path}/logo_backfill.png');
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }
}
