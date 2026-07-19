import 'package:flutter/material.dart';

import 'heading_text.dart';

class LogoWidget extends StatelessWidget {
  final double fontSize;
  final Color? color;

  const LogoWidget({super.key, this.fontSize = 48.0, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/logo.png',
            height: fontSize * 2.5,
            width: fontSize * 2.5,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 16),
        Heading1(
          'Hydrodok',
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
