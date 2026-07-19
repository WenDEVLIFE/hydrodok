import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../core/utils/color_utils.dart';
import 'button_text.dart';

class CustomButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const CustomButton({
    super.key, 
    required this.label, 
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      color: Theme.of(context).colorScheme.primary,
      onPressed: isLoading ? null : onPressed,
      child: isLoading 
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : ButtonText(label, color: ColorUtils.pureWhite),
    );
  }
}
