import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/models/farm.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/typography.dart';
import 'farm_detail_screen.dart';

/// Mock farms — fallback when live database has no verified farms.
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
  List<Farm> _farmsList = _mockFarms;
  List<Map<String, dynamic>> _rawFarmMaps = [];

  // Realtime stream for verified farms
  late final Stream<List<Map<String, dynamic>>> _farmsStream;

  @override
  void initState() {
    super.initState();
    _determinePosition();
    _initStream();
  }

  void _initStream() {
    // Realtime: auto-updates when a farm is verified/unverified or location changes
    _farmsStream = Supabase.instance.client
        .from('farms')
        .stream(primaryKey: ['id'])
        .map((rows) => rows.where((r) => r['verification_status'] == 'verified').toList());
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

  void _onMarkerTapped(Farm farm) async {
    setState(() => _selectedFarm = farm);
    _mapController.move(
      LatLng(farm.latitude, farm.longitude),
      _mapController.camera.zoom,
    );

    // Fetch the full farm row to ensure owner_id and all fields are present.
    Map<String, dynamic> rawFarm = _rawFarmMaps.firstWhere(
      (r) => r['id'] == farm.id,
      orElse: () => <String, dynamic>{},
    );

    if (rawFarm.isEmpty || rawFarm['owner_id'] == null) {
      try {
        final response = await Supabase.instance.client
            .from('farms')
            .select('*')
            .eq('id', farm.id)
            .maybeSingle();
        if (response != null) rawFarm = response;
      } catch (e) {
        debugPrint('Failed to fetch full farm data: $e');
      }
    }

    if (rawFarm.isEmpty) return;

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FarmDetailScreen(farm: rawFarm),
        ),
      );
    }
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
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _farmsStream,
                  builder: (context, snapshot) {
                    // Update farms list from realtime stream
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      final rows = snapshot.data!;
                      final liveFarms = rows.map((data) {
                        final lat = (data['latitude'] as num?)?.toDouble() ?? 14.5995;
                        final lng = (data['longitude'] as num?)?.toDouble() ?? 120.9842;
                        final name = data['farm_name'] as String? ?? 'Verified Hydro Farm';
                        final produceList = data['produce_types'] as List<dynamic>?;
                        final produce = (produceList != null && produceList.isNotEmpty)
                            ? produceList.first.toString()
                            : 'Hydroponics';

                        return Farm(
                          id: data['id'] as String? ?? UniqueKey().toString(),
                          name: name,
                          product: produce,
                          rating: 4.9,
                          reviewCount: 24,
                          unitsInStock: 5000,
                          pricePerKg: 120,
                          latitude: lat,
                          longitude: lng,
                        );
                      }).toList();

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _farmsList = liveFarms;
                            _rawFarmMaps = rows;
                          });
                        }
                      });
                    }

                    return Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: const LatLng(14.5995, 120.9842),
                            initialZoom: 14,
                            onTap: (_, __) => setState(() => _selectedFarm = null),
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://api.maptiler.com/maps/streets-v2/'
                                  '{z}/{x}/{y}.png?key=$apiKey',
                              userAgentPackageName: 'com.hydrodok.app',
                            ),
                            MarkerLayer(markers: _buildMarkers()),
                          ],
                        ),

                        // Zoom controls
                        Positioned(
                          right: 16,
                          bottom: 24,
                          child: _buildZoomControls(),
                        ),
                      ],
                    );
                  },
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
    for (final farm in _farmsList) {
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
