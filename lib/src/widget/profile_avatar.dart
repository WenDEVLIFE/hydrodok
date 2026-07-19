import 'package:flutter/material.dart';
import '../core/utils/color_utils.dart';

/// Displays a user's profile picture.
///
/// If [imageUrl] is null or empty, falls back to the app's built‑in logo
/// asset (`assets/logo.png`). The [radius] controls the size.
class ProfileAvatar extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final VoidCallback? onTap;

  const ProfileAvatar({
    super.key,
    this.imageUrl,
    this.radius = 28.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: CircleAvatar(
        radius: radius,
        backgroundColor: ColorUtils.primary.withValues(alpha: 0.15),
        backgroundImage: hasImage ? NetworkImage(imageUrl!) : null,
        child: hasImage
            ? null
            : ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Image.asset(
                  'assets/logo.png',
                  width: radius * 2,
                  height: radius * 2,
                  fit: BoxFit.cover,
                ),
              ),
      ),
    );
  }
}
