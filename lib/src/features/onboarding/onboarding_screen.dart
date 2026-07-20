import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/service/farm_service.dart';
import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';
import '../../widget/custom_text_field.dart';
import '../farmer/farmer_dashboard_screen.dart';
import 'bloc/onboarding_bloc.dart';
import 'bloc/onboarding_event.dart';
import 'bloc/onboarding_state.dart';
import 'farm_map_picker_dialog.dart';

/// 2-Step Post-Registration Wizard for Farmers:
///
/// **Step 1**: Farm profile details (Name, Address, Interactive Map location picker, Produce types chips, Description, Farm Photo).
/// **Step 2**: Optional verification document upload (DTI/SEC, Barangay clearance, Geotagged photo) or skip.
class OnboardingScreen extends StatelessWidget {
  final String ownerId;

  const OnboardingScreen({
    super.key,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    final farmService = FarmService(supabase: supabase);

    return BlocProvider(
      create: (_) => OnboardingBloc(
        farmService: farmService,
        supabaseClient: supabase,
        ownerId: ownerId,
      )..add(const Step1NameChanged('')),
      child: const _OnboardingView(),
    );
  }
}

class _OnboardingView extends StatefulWidget {
  const _OnboardingView();

  @override
  State<_OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<_OnboardingView> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();

  static const List<String> _availableProduce = [
    'Lettuce',
    'Spinach',
    'Tomatoes',
    'Microgreens',
    'Basil',
    'Bell Peppers',
    'Herbs',
    'Strawberries',
    'Cucumbers',
    'Kale',
  ];

  static const List<Map<String, String>> _docTypes = [
    {'value': 'dti_sec', 'label': 'DTI / SEC Registration'},
    {'value': 'barangay_clearance', 'label': 'Barangay Clearance'},
    {'value': 'geotagged_photo', 'label': 'Geotagged Farm Photo'},
  ];

  String _selectedDocType = 'dti_sec';

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onComplete(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const FarmerDashboardScreen(),
      ),
    );
  }

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<MapLocationResult>(
      MaterialPageRoute(
        builder: (_) => const FarmMapPickerDialog(),
        fullscreenDialog: true,
      ),
    );

    if (result != null && context.mounted) {
      final bloc = context.read<OnboardingBloc>();
      _addressController.text = result.address;
      bloc.add(Step1AddressChanged(result.address));
      bloc.add(Step1CoordinatesChanged(result.latLng.latitude, result.latLng.longitude));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Farm coordinates set: ${result.latLng.latitude.toStringAsFixed(4)}, ${result.latLng.longitude.toStringAsFixed(4)}'),
          backgroundColor: ColorUtils.forestGreen,
        ),
      );
    }
  }

  Future<void> _pickFarmPhoto(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && context.mounted) {
        context.read<OnboardingBloc>().add(
              Step1FarmPhotoSelected(File(picked.path)),
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open image picker: $e')),
        );
      }
    }
  }

  Future<void> _pickVerificationDocument(BuildContext context) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked != null && context.mounted) {
        context.read<OnboardingBloc>().add(
              Step2DocumentSelected(File(picked.path), _selectedDocType),
            );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open file picker: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingCompleted) {
          _onComplete(context);
        }
        if (state is Step1FarmProfile && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
        if (state is Step2Verification && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      },
      builder: (context, state) {
        final isStep2 = state is Step2Verification;

        return Scaffold(
          backgroundColor: ColorUtils.darkBackground,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              isStep2 ? 'Step 2: Farm Verification' : 'Step 1: Setup Your Farm',
              style: AppTypography.heading3(color: ColorUtils.pureWhite),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 8),
                // ── Step Indicator Bar ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: ColorUtils.sageGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: isStep2
                                ? ColorUtils.sageGreen
                                : ColorUtils.darkSurface,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Form Body ───────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: isStep2
                        ? _buildStep2(context, state as Step2Verification)
                        : _buildStep1(
                            context,
                            state is Step1FarmProfile
                                ? state
                                : const Step1FarmProfile(),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Step 1: Farm Details ───────────────────────────────────────────────
  Widget _buildStep1(BuildContext context, Step1FarmProfile state) {
    final bloc = context.read<OnboardingBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tell us about your farm',
          style: AppTypography.heading2(color: ColorUtils.sageGreen),
        ),
        const SizedBox(height: 6),
        Text(
          'Complete your farm details to connect with local buyers and access farm tools.',
          style: AppTypography.bodyMedium(color: Colors.white70),
        ),
        const SizedBox(height: 24),

        // Farm Name
        CustomTextField(
          controller: _nameController,
          label: 'Farm / Business Name',
          hint: 'e.g. Pamahalaang Hydro Greens',
          prefixIcon: const Icon(Icons.storefront_rounded, color: Colors.white70),
          onChanged: (val) => bloc.add(Step1NameChanged(val)),
        ),
        const SizedBox(height: 16),

        // Farm Address & Interactive Map Picker Button
        CustomTextField(
          controller: _addressController,
          label: 'Farm Location / Address',
          hint: 'e.g. General Trias, Cavite',
          prefixIcon: const Icon(Icons.location_on_rounded, color: Colors.white70),
          onChanged: (val) => bloc.add(Step1AddressChanged(val)),
        ),
        const SizedBox(height: 8),

        // Select Location on Interactive Map CTA
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: ColorUtils.sageGreen.withOpacity(0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(LucideIcons.mapPin, color: ColorUtils.sageGreen, size: 20),
          label: Text(
            state.latitude != null
                ? 'Location Pinned: ${state.latitude!.toStringAsFixed(4)}, ${state.longitude!.toStringAsFixed(4)}'
                : 'Select Exact Location on Interactive Map',
            style: AppTypography.bodyMedium(
              color: ColorUtils.sageGreen,
              fontWeight: FontWeight.w600,
            ),
          ),
          onPressed: () => _openMapPicker(context),
        ),
        const SizedBox(height: 20),

        // Produce Types Multi-Select
        Text(
          'Primary Crops / Produce *',
          style: AppTypography.bodyLarge(
            color: ColorUtils.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableProduce.map((produce) {
            final isSelected = state.produceTypes.contains(produce);
            return FilterChip(
              selected: isSelected,
              label: Text(produce),
              labelStyle: TextStyle(
                color: isSelected ? ColorUtils.darkText : ColorUtils.pureWhite,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              selectedColor: ColorUtils.sageGreen,
              backgroundColor: ColorUtils.darkCard,
              checkmarkColor: ColorUtils.darkText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected
                      ? ColorUtils.sageGreen
                      : Colors.white24,
                ),
              ),
              onSelected: (selected) {
                final current = List<String>.from(state.produceTypes);
                if (selected) {
                  current.add(produce);
                } else {
                  current.remove(produce);
                }
                bloc.add(Step1ProduceTypesChanged(current));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Description
        CustomTextField(
          controller: _descriptionController,
          label: 'Farm Description (Optional)',
          hint: 'Share a brief summary about your growing methods or farm history...',
          prefixIcon: const Icon(Icons.notes_rounded, color: Colors.white70),
          onChanged: (val) => bloc.add(Step1DescriptionChanged(val)),
        ),
        const SizedBox(height: 24),

        // Photo Upload Container
        Text(
          'Farm Photo (Optional)',
          style: AppTypography.bodyLarge(
            color: ColorUtils.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _pickFarmPhoto(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 140,
            decoration: BoxDecoration(
              color: ColorUtils.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.farmPhotoFile != null
                    ? ColorUtils.sageGreen
                    : Colors.white24,
                width: 1.5,
              ),
            ),
            child: state.farmPhotoFile != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        Image.file(
                          state.farmPhotoFile!,
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.check, color: ColorUtils.sageGreen, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Tap to Change Photo',
                                style: AppTypography.bodyMedium(
                                  color: ColorUtils.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        LucideIcons.imagePlus,
                        color: ColorUtils.sageGreen,
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Tap to select farm photo from gallery',
                        style: AppTypography.bodyMedium(
                          color: Colors.white70,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supports JPG or PNG format',
                        style: AppTypography.bodySmall(color: Colors.white38),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 32),

        // Continue Button
        CustomButton(
          label: 'Continue to Step 2',
          isLoading: state.isSubmitting,
          onPressed: () => bloc.add(const Step1Next()),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ── Step 2: Verification ───────────────────────────────────────────────
  Widget _buildStep2(BuildContext context, Step2Verification state) {
    final bloc = context.read<OnboardingBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: ColorUtils.darkCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: ColorUtils.sageGreen.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ColorUtils.sageGreen.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  LucideIcons.badgeCheck,
                  color: ColorUtils.sageGreen,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earn a Verified Badge',
                      style: AppTypography.heading3(
                        color: ColorUtils.pureWhite,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Verified farms get higher visibility and direct consumer trust in the marketplace.',
                      style: AppTypography.bodySmall(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Verification Document (Optional)',
          style: AppTypography.bodyLarge(
            color: ColorUtils.pureWhite,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),

        // Document Type Dropdown
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: ColorUtils.darkCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDocType,
              dropdownColor: ColorUtils.darkCard,
              isExpanded: true,
              style: AppTypography.bodyMedium(color: ColorUtils.pureWhite),
              items: _docTypes.map((doc) {
                return DropdownMenuItem<String>(
                  value: doc['value'],
                  child: Text(doc['label']!),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedDocType = val);
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Upload Container
        InkWell(
          onTap: () => _pickVerificationDocument(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 140,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorUtils.darkCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: state.documentFile != null
                    ? ColorUtils.sageGreen
                    : Colors.white24,
                width: 1.5,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  state.documentFile != null
                      ? LucideIcons.fileCheck
                      : LucideIcons.uploadCloud,
                  color: state.documentFile != null
                      ? ColorUtils.sageGreen
                      : Colors.white54,
                  size: 36,
                ),
                const SizedBox(height: 10),
                Text(
                  state.documentFile != null
                      ? 'Attached: ${state.documentFile!.path.split('/').last}'
                      : 'Tap to select document file or image',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium(
                    color: state.documentFile != null
                        ? ColorUtils.sageGreen
                        : Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.documentFile != null
                      ? 'Tap to change selected document'
                      : 'Supports JPG, PNG, or PDF formats',
                  style: AppTypography.bodySmall(
                    color: state.documentFile != null
                        ? Colors.white70
                        : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Submit Button
        CustomButton(
          label: 'Submit Verification',
          isLoading: state.isSubmitting,
          onPressed: () => bloc.add(const Step2Submit()),
        ),
        const SizedBox(height: 12),

        // Skip Button
        Center(
          child: TextButton(
            onPressed: state.isSubmitting
                ? null
                : () => bloc.add(const Step2Skip()),
            child: Text(
              'Skip for Now — Complete Later',
              style: AppTypography.bodyMedium(
                color: Colors.white54,
              ).copyWith(decoration: TextDecoration.underline),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
