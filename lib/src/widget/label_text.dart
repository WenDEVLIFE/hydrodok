import 'package:flutter/widgets.dart';

import '../core/utils/typography.dart';

class LabelText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const LabelText(this.text, {super.key, this.color, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTypography.overline(color: color),
      textAlign: textAlign,
    );
  }
}
