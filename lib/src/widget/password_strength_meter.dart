import 'package:flutter/material.dart';

import '../core/utils/color_utils.dart';
import '../core/utils/typography.dart';
class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasLowercase => password.contains(RegExp(r'[a-z]'));
  bool get hasDigits => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialCharacters =>
      password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Password Requirements:',
          style: AppTypography.bodySmall(
            color: ColorUtils.softBlack.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _RequirementItem(isMet: hasMinLength, text: 'At least 8 characters'),
        _RequirementItem(
          isMet: hasUppercase,
          text: 'Contains uppercase letter',
        ),
        _RequirementItem(
          isMet: hasLowercase,
          text: 'Contains lowercase letter',
        ),
        _RequirementItem(isMet: hasDigits, text: 'Contains number'),
        _RequirementItem(
          isMet: hasSpecialCharacters,
          text: 'Contains special character',
        ),
      ],
    );
  }
}

class _RequirementItem extends StatelessWidget {
  final bool isMet;
  final String text;

  const _RequirementItem({required this.isMet, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_outline : Icons.circle_outlined,
            size: 16,
            color: isMet ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.caption(
              color: isMet ? ColorUtils.softBlack : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
