import 'package:flutter/material.dart';

import '../core/utils/color_utils.dart';
import '../core/utils/typography.dart';


/// A custom text field widget that matches the Narcissus design aesthetic
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? Function(String?)? validator;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onTap,
    this.validator,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isFocused = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label,
            style: AppTypography.subtitle2(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : ColorUtils.softBlack,
            ),
          ),
        ),

        // Text field with animation
        ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.errorText != null
                    ? Colors
                          .redAccent // Error color
                    : (_isFocused
                          ? ColorUtils.primary
                          : Colors.transparent), // Focus -> Primary
                width: 2,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: ColorUtils.accent.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: TextFormField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              validator: widget.validator,
              style: AppTypography.bodyLarge(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : ColorUtils.softBlack,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: AppTypography.bodyLarge(
                  color:
                      (Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : ColorUtils.softBlack)
                          .withValues(alpha: 0.4),
                ),
                prefixIcon: widget.prefixIcon,
                suffixIcon: widget.suffixIcon,
                border: InputBorder.none,
                errorStyle: const TextStyle(height: 0),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ),

        // Error message
        if (widget.errorText != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.redAccent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: AppTypography.caption(color: Colors.redAccent),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
