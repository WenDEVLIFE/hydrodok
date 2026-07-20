import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/service/forum_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import '../../../widget/custom_button.dart';

/// Bottom-sheet dialog for creating a new forum post.
class AddPostDialog extends StatefulWidget {
  final VoidCallback onPostCreated;

  const AddPostDialog({super.key, required this.onPostCreated});

  @override
  State<AddPostDialog> createState() => _AddPostDialogState();
}

class _AddPostDialogState extends State<AddPostDialog> {
  final _contentController = TextEditingController();
  String _selectedCategory = 'selling';
  bool _isSubmitting = false;

  static const _categories = [
    ('Selling', 'selling'),
    ('Q&A', 'qna'),
    ('Tips', 'tips'),
  ];

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_contentController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final service = ForumService(supabase: Supabase.instance.client);
      await service.createPost(
        category: _selectedCategory,
        content: _contentController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post submitted! It will appear after admin approval.')),
        );
        widget.onPostCreated();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create Post',
              style: AppTypography.heading3(
                color: ColorUtils.darkText,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All posts require admin approval before going live.',
              style: AppTypography.bodySmall(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            Text(
              'Category',
              style: AppTypography.bodySmall(
                color: ColorUtils.darkText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat.$2;
                return ChoiceChip(
                  selected: isSelected,
                  label: Text(cat.$1),
                  selectedColor: ColorUtils.forestGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : ColorUtils.darkText,
                  ),
                  onSelected: (_) =>
                      setState(() => _selectedCategory = cat.$2),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Share something with the community...',
                hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: ColorUtils.forestGreen),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: _isSubmitting ? 'Posting...' : 'Post',
                onPressed: _isSubmitting ? () {} : _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
