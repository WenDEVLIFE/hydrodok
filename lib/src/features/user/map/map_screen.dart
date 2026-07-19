import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/models/farm.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';

/// Mock farms — replace with real Supabase data later.
final _mockFarms = <Farm>[
  const Farm(
    id: '1',
    name: 'Bukid Kabataan Shelter',
    product: 'Lettuce',
    rating: 4.8,
    reviewCount: 52,
    unitsInStock: 10000,
    pricePerKg: 100,
    latitude: 14.5995,
    longitude: 120.9842,
  ),
  const Farm(
    id: '2',
    name: 'Green Roots Farm',
    product: 'Basil',
    rating: 4.5,
    reviewCount: 38,
    unitsInStock: 5000,
    pricePerKg: 150,
    latitude: 14.6050,
    longitude: 120.9900,
  ),
  const Farm(
    id: '3',
    name: 'Aqua Harvest Co.',
    product: 'Kangkong',
    rating: 4.2,
    reviewCount: 19,
    unitsInStock: 8000,
    pricePerKg: 80,
    latitude: 14.5920,
    longitude: 120.9780,
  ),
];

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  Farm? _selectedFarm;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return; // Silently skip — map still works
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {
      // Location unavailable — no blue dot
    }
  }

  void _onMarkerTapped(Farm farm) {
    setState(() => _selectedFarm = farm);
    _mapController.move(
      LatLng(farm.latitude, farm.longitude),
      _mapController.camera.zoom,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final apiKey = dotenv.env['MAPTILER_API_KEY'] ?? '';

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: ColorUtils.offWhite,
        colorScheme: ColorUtils.lightColorScheme,
        useMaterial3: true,
      ),
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // ── Header ───────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Column(
                  children: [
                    Text(
                      'Nearby Farms',
                      style: AppTypography.heading3(
                        color: ColorUtils.darkText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSearchBar(),
                  ],
                ),
              ),

              // ── Map ──────────────────────────────────────────────────────
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter:
                            const LatLng(14.5995, 120.9842),
                        initialZoom: 14,
                        onTap: (_, __) =>
                            setState(() => _selectedFarm = null),
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://api.maptiler.com/maps/streets-v2/'
                              '{z}/{x}/{y}.png?key=$apiKey',
                          userAgentPackageName: 'com.hydrodok.app',
                        ),
                        MarkerLayer(markers: _buildMarkers()),
                      ],
                    ),

                    // Zoom controls
                    Positioned(
                      right: 16,
                      bottom: _selectedFarm != null ? 180 : 24,
                      child: _buildZoomControls(),
                    ),

                    // Selected-farm info card
                    if (_selectedFarm != null)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: _buildFarmCard(_selectedFarm!),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: AppTypography.bodyMedium(color: ColorUtils.darkText),
        decoration: InputDecoration(
          hintText: 'Search farms or products...',
          hintStyle: AppTypography.bodyMedium(
            color: Colors.grey.shade500,
          ),
          prefixIcon: Icon(
            LucideIcons.search,
            color: Colors.grey.shade500,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Markers ────────────────────────────────────────────────────────────────

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // Farm markers
    for (final farm in _mockFarms) {
      final isSelected = _selectedFarm?.id == farm.id;
      markers.add(
        Marker(
          point: LatLng(farm.latitude, farm.longitude),
          width: isSelected ? 160 : 40,
          height: isSelected ? 70 : 46,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(farm),
            child: isSelected
                ? _buildSelectedMarker(farm)
                : _buildDefaultMarker(),
          ),
        ),
      );
    }

    // User location blue dot
    if (_userLocation != null) {
      markers.add(
        Marker(
          point: _userLocation!,
          width: 20,
          height: 20,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  Widget _buildDefaultMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: ColorUtils.forestGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.sprout,
            color: Colors.white,
            size: 16,
          ),
        ),
        CustomPaint(
          size: const Size(12, 8),
          painter: _MarkerTrianglePainter(ColorUtils.forestGreen),
        ),
      ],
    );
  }

  Widget _buildSelectedMarker(Farm farm) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: ColorUtils.terracotta, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            farm.name,
            style: AppTypography.caption(
              color: ColorUtils.darkText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: ColorUtils.terracotta,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(
            LucideIcons.sprout,
            color: Colors.white,
            size: 14,
          ),
        ),
      ],
    );
  }

  // ── Zoom controls ──────────────────────────────────────────────────────────

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _zoomButton(LucideIcons.plus, () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom + 1,
            );
          }),
          Container(height: 1, width: 32, color: Colors.grey.shade300),
          _zoomButton(LucideIcons.minus, () {
            _mapController.move(
              _mapController.camera.center,
              _mapController.camera.zoom - 1,
            );
          }),
        ],
      ),
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Icon(icon, size: 18, color: ColorUtils.darkText),
      ),
    );
  }

  // ── Farm info card ─────────────────────────────────────────────────────────

  Widget _buildFarmCard(Farm farm) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Farm name row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: ColorUtils.forestGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  LucideIcons.diamond,
                  color: ColorUtils.forestGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  farm.name,
                  style: AppTypography.subtitle1(
                    color: ColorUtils.darkText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Product + rating
          Row(
            children: [
              Text(
                farm.product,
                style: AppTypography.bodyMedium(
                  color: ColorUtils.darkText,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${farm.rating}',
                style: AppTypography.bodySmall(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 2),
              Text(
                '(${farm.reviewCount})',
                style: AppTypography.bodySmall(
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Stock + price + CTA
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_formatNumber(farm.unitsInStock)} units in stock',
                      style: AppTypography.bodySmall(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'PHP ${farm.pricePerKg.toStringAsFixed(0)} / kg',
                      style: AppTypography.subtitle1(
                        color: ColorUtils.forestGreen,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: navigate to farm detail
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorUtils.forestGreen,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  elevation: 0,
                ),
                child: Text(
                  'View Farm',
                  style: AppTypography.button(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)},000';
    }
    return n.toString();
  }
}

/// Paints a small downward triangle beneath the marker circle.
class _MarkerTrianglePainter extends CustomPainter {
  final Color color;
  _MarkerTrianglePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
