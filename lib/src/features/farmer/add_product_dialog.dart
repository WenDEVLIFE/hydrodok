import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/service/product_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';

/// Bottom-sheet dialog for adding a new product to the farmer's farm.
class AddProductDialog extends StatefulWidget {
  final VoidCallback onProductAdded;

  const AddProductDialog({
    super.key,
    required this.onProductAdded,
  });

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  String _selectedUnit = 'kg';
  bool _isSubmitting = false;

  static const _units = ['kg', 'bundle', 'piece', 'pack', 'sack'];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final service = ProductService(supabase: Supabase.instance.client);
      await service.createProduct(
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        pricePerKg: double.tryParse(_priceController.text) ?? 0,
        unit: _selectedUnit,
        stockQuantity: int.tryParse(_stockController.text) ?? 0,
      );

      if (mounted) {
        widget.onProductAdded();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added! Awaiting admin approval.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
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
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
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

              // Title
              Text(
                'Add New Product',
                style: AppTypography.heading3(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Product will be reviewed by admin before publishing.',
                style: AppTypography.bodySmall(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),

              // Product Name
              _buildTextField(
                controller: _nameController,
                label: 'Product Name',
                hint: 'e.g. Fresh Lettuce, Basil',
                icon: LucideIcons.leaf,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              // Description
              _buildTextField(
                controller: _descController,
                label: 'Description',
                hint: 'Describe your product...',
                icon: LucideIcons.fileText,
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              // Price + Unit row
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Price',
                      hint: '0.00',
                      icon: LucideIcons.banknote,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unit',
                          style: AppTypography.bodySmall(
                            color: ColorUtils.darkText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(10),

                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              focusColor: ColorUtils.accent,
                              value: _selectedUnit,
                              isExpanded: true,
                              style: AppTypography.bodyMedium(color: ColorUtils.darkText), // Add this line
                              items: _units
                                  .map((u) => DropdownMenuItem(
                                  value: u,
                                  child: Text(
                                    u,
                                    style: AppTypography.bodyMedium(color: ColorUtils.darkText), // Optionally here too
                                  )
                              ))
                                  .toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedUnit = v);
                              },
                              dropdownColor: Colors.white, // Optional: change dropdown background
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Stock
              _buildTextField(
                controller: _stockController,
                label: 'Stock Quantity',
                hint: '0',
                icon: LucideIcons.package,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (int.tryParse(v) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  label: _isSubmitting ? 'Adding...' : 'Add Product',
                  onPressed: _isSubmitting ? () {} : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.bodySmall(
            color: ColorUtils.darkText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: AppTypography.bodyMedium(color: ColorUtils.darkText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium(color: Colors.grey.shade400),
            prefixIcon: Icon(icon, color: ColorUtils.forestGreen, size: 18),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: ColorUtils.forestGreen),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
