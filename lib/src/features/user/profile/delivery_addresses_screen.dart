import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/service/delivery_address_service.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import '../../onboarding/farm_map_picker_dialog.dart';

/// Screen allowing users to view, add, set default, and delete saved delivery addresses.
class DeliveryAddressesScreen extends StatefulWidget {
  const DeliveryAddressesScreen({super.key});

  @override
  State<DeliveryAddressesScreen> createState() => _DeliveryAddressesScreenState();
}

class _DeliveryAddressesScreenState extends State<DeliveryAddressesScreen> {
  late final DeliveryAddressService _addressService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _addresses = [];

  @override
  void initState() {
    super.initState();
    _addressService = DeliveryAddressService();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final list = await _addressService.getUserAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddAddressDialog() async {
    final addressController = TextEditingController();
    String selectedLabel = 'Home';
    bool isDefault = _addresses.isEmpty; // Auto default if first address
    double? selectedLat;
    double? selectedLng;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(LucideIcons.mapPin, color: ColorUtils.forestGreen),
              SizedBox(width: 8),
              Text('Add Delivery Address'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Label',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: ['Home', 'Work', 'Farm', 'Other'].map((label) {
                    final isSelected = selectedLabel == label;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      selectedColor: ColorUtils.forestGreen,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : ColorUtils.darkText,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (val) {
                        if (val) setModalState(() => selectedLabel = label);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Full Address',
                    hintText: 'House/Building No., Street, Barangay, City, Province',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(LucideIcons.map, color: ColorUtils.forestGreen),
                      tooltip: 'Pick on Map',
                      onPressed: () async {
                        final mapResult = await Navigator.of(context).push<MapLocationResult>(
                          MaterialPageRoute(builder: (_) => const FarmMapPickerDialog()),
                        );
                        if (mapResult != null) {
                          setModalState(() {
                            addressController.text = mapResult.address;
                            selectedLat = mapResult.latLng.latitude;
                            selectedLng = mapResult.latLng.longitude;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Set as Default Delivery Address', style: TextStyle(fontSize: 13)),
                  value: isDefault,
                  activeColor: ColorUtils.forestGreen,
                  onChanged: (val) {
                    setModalState(() => isDefault = val ?? false);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: ColorUtils.forestGreen),
              onPressed: () async {
                final addrText = addressController.text.trim();
                if (addrText.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter an address.')),
                  );
                  return;
                }

                try {
                  await _addressService.addAddress(
                    address: addrText,
                    label: selectedLabel,
                    latitude: selectedLat,
                    longitude: selectedLng,
                    isDefault: isDefault,
                  );
                  if (context.mounted) Navigator.of(ctx).pop(true);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save address: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Address', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      _loadAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Saved Delivery Addresses',
            style: AppTypography.heading3(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: ColorUtils.darkText),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadAddresses,
                child: _addresses.isEmpty
                    ? ListView(
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.25),
                          Center(
                            child: Column(
                              children: [
                                Icon(LucideIcons.mapPin, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No saved delivery addresses',
                                  style: AppTypography.bodyLarge(
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap "+ Add Address" below to save your delivery locations.',
                                  style: AppTypography.bodySmall(color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final item = _addresses[index];
                          final id = item['id'] as String;
                          final label = item['label'] as String? ?? 'Home';
                          final address = item['address'] as String? ?? '';
                          final isDefault = item['is_default'] == true;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDefault ? ColorUtils.forestGreen : Colors.grey.shade200,
                                width: isDefault ? 1.5 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: ColorUtils.forestGreen.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        label.toUpperCase(),
                                        style: AppTypography.caption(
                                          color: ColorUtils.forestGreen,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    if (isDefault) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'DEFAULT',
                                          style: AppTypography.caption(
                                            color: Colors.amber.shade900,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const Spacer(),
                                    PopupMenuButton<String>(
                                      icon: const Icon(LucideIcons.moreVertical, size: 18, color: Colors.grey),
                                      onSelected: (val) async {
                                        if (val == 'default') {
                                          await _addressService.setDefaultAddress(id);
                                          _loadAddresses();
                                        } else if (val == 'delete') {
                                          await _addressService.deleteAddress(id);
                                          _loadAddresses();
                                        }
                                      },
                                      itemBuilder: (context) => [
                                        if (!isDefault)
                                          const PopupMenuItem(
                                            value: 'default',
                                            child: Text('Set as Default'),
                                          ),
                                        const PopupMenuItem(
                                          value: 'delete',
                                          child: Text('Delete Address', style: TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  address,
                                  style: AppTypography.bodyMedium(
                                    color: ColorUtils.darkText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _openAddAddressDialog,
          backgroundColor: ColorUtils.forestGreen,
          icon: const Icon(LucideIcons.plus, color: Colors.white),
          label: const Text('Add Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
