import 'package:flutter/widgets.dart';
import '../core/utils/typography.dart';

class ButtonText extends StatelessWidget {
  final String text;
  final Color? color;
  final TextAlign? textAlign;

  const ButtonText(this.text, {super.key, this.color, this.textAlign});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.button(color: color),
      textAlign: textAlign,
    );
  }
}
