import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/utils/color_utils.dart';
import '../../core/utils/typography.dart';
import '../../widget/custom_button.dart';

class MapLocationResult {
  final LatLng latLng;
  final String address;

  const MapLocationResult({
    required this.latLng,
    required this.address,
  });
}

/// Full-screen interactive MapTiler map picker dialog with OpenStreetMap Nominatim search:
///
/// - Farmers can search addresses via the search bar.
/// - Map auto-centers on the searched location.
/// - Farmers can tap anywhere on the map to pin their farm's location.
class FarmMapPickerDialog extends StatefulWidget {
  final LatLng initialCenter;
  final String? initialAddress;

  const FarmMapPickerDialog({
    super.key,
    this.initialCenter = const LatLng(14.3858, 120.8804), // Default General Trias, Cavite
    this.initialAddress,
  });

  @override
  State<FarmMapPickerDialog> createState() => _FarmMapPickerDialogState();
}

class _FarmMapPickerDialogState extends State<FarmMapPickerDialog> {
  late final MapController _mapController;
  final TextEditingController _searchController = TextEditingController();

  late LatLng _selectedLocation;
  String _selectedAddress = '';
  bool _isSearching = false;
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _selectedLocation = widget.initialCenter;
    _selectedAddress = widget.initialAddress ?? 'Selected Location';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=json&q=${Uri.encodeComponent(query)}&limit=5',
      );
      final response = await http.get(
        uri,
        headers: {'User-Agent': 'HydrodokApp/1.0'},
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.map((item) {
            return {
              'display_name': item['display_name'] as String,
              'lat': double.parse(item['lat'] as String),
              'lon': double.parse(item['lon'] as String),
            };
          }).toList();
        });
      }
    } catch (_) {
      // Handle network issue gracefully
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSearchResult(Map<String, dynamic> result) {
    final lat = result['lat'] as double;
    final lon = result['lon'] as double;
    final address = result['display_name'] as String;

    final target = LatLng(lat, lon);
    setState(() {
      _selectedLocation = target;
      _selectedAddress = address;
      _searchResults = [];
      _searchController.text = address;
    });

    _mapController.move(target, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final maptilerKey = dotenv.env['MAPTILER_API_KEY'] ?? '';
    final tileUrl = maptilerKey.isNotEmpty
        ? 'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$maptilerKey'
        : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    return Scaffold(
      backgroundColor: ColorUtils.darkBackground,
      appBar: AppBar(
        backgroundColor: ColorUtils.darkCard,
        elevation: 2,
        title: Text(
          'Select Farm Location',
          style: AppTypography.heading3(color: ColorUtils.pureWhite),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.check, color: ColorUtils.sageGreen),
            onPressed: () {
              Navigator.of(context).pop(
                MapLocationResult(
                  latLng: _selectedLocation,
                  address: _selectedAddress,
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map View ──────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: 13.0,
              onTap: (_, point) {
                setState(() {
                  _selectedLocation = point;
                  _selectedAddress =
                      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'com.hydrodok.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedLocation,
                    width: 48,
                    height: 48,
                    child: const Icon(
                      LucideIcons.mapPin,
                      color: ColorUtils.terracotta,
                      size: 44,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Top Search Bar ─────────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: ColorUtils.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: AppTypography.bodyMedium(color: ColorUtils.pureWhite),
                    decoration: InputDecoration(
                      hintText: 'Search location via OpenStreetMap...',
                      hintStyle: AppTypography.bodyMedium(color: Colors.white38),
                      prefixIcon: const Icon(LucideIcons.search, color: ColorUtils.sageGreen),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: ColorUtils.sageGreen,
                                ),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(LucideIcons.arrowRight, color: ColorUtils.sageGreen),
                              onPressed: () => _searchAddress(_searchController.text),
                            ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (val) => _searchAddress(val),
                  ),
                ),

                // Search Results Overlay List
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: ColorUtils.darkCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(color: Colors.white12, height: 1),
                      itemBuilder: (ctx, index) {
                        final item = _searchResults[index];
                        return Material(
                          color: Colors.transparent,
                          child: ListTile(
                            dense: true,
                            leading: const Icon(LucideIcons.mapPin, color: ColorUtils.sageGreen, size: 20),
                            title: Text(
                              item['display_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodySmall(color: ColorUtils.pureWhite),
                            ),
                            onTap: () => _selectSearchResult(item),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // ── Bottom Confirmation Bar ────────────────────────────────────
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ColorUtils.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ColorUtils.sageGreen.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.mapPin, color: ColorUtils.sageGreen, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedAddress,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyMedium(
                            color: ColorUtils.pureWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: AppTypography.bodySmall(color: Colors.white54),
                  ),
                  const SizedBox(height: 14),
                  CustomButton(
                    label: 'Confirm Location',
                    onPressed: () {
                      Navigator.of(context).pop(
                        MapLocationResult(
                          latLng: _selectedLocation,
                          address: _selectedAddress,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
