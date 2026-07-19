import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One-time migration helper that uploads `assets/logo.png` to the avatars
/// storage bucket and backfills every profile that has null or empty
/// `avatar_url` with the shared default URL.
///
/// Call from anywhere in the app:
/// ```dart
/// await AvatarBackfill.run(Supabase.instance.client);
/// ```
class AvatarBackfill {
  static const _defaultPath = '_default/logo.png';

  /// Runs the full backfill.
  ///
  /// [supabase] — the Supabase client.
  /// [logoFile] — optional pre-loaded file (useful in tests).
  ///               When null, loads from `assets/logo.png` and writes a temp file.
  static Future<int> run(
    SupabaseClient supabase, {
    File? logoFile,
  }) async {
    // 1. Resolve logo file
    final file = logoFile ?? await _tempFileFromAsset();

    // 2. Upload to shared path (idempotent — upsert: true)
    await supabase.storage.from('avatars').upload(
          _defaultPath,
          file,
          fileOptions: const FileOptions(
            upsert: true,
            contentType: 'image/png',
          ),
        );

    final defaultUrl =
        supabase.storage.from('avatars').getPublicUrl(_defaultPath);

    // 3. Fetch profiles with null or empty avatar_url
    //    Supabase or() syntax: comma-separated conditions for the same column
    final profiles = await supabase
        .from('profiles')
        .select('id, avatar_url')
        .or('avatar_url.is.null,avatar_url.eq.');

    if (profiles.isEmpty) return 0;

    // 4. Update each profile
    for (final row in profiles) {
      final id = row['id'] as String;
      await supabase
          .from('profiles')
          .update({'avatar_url': defaultUrl})
          .eq('id', id);
    }

    return profiles.length;
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
