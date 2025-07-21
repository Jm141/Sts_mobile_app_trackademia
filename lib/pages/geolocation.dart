import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class GeoLocationPage extends StatefulWidget {
  final double lat;
  final double lng;
  final String studentName;

  const GeoLocationPage({
    super.key,
    required this.lat,
    required this.lng,
    required this.studentName,
  });

  @override
  State<GeoLocationPage> createState() => _GeoLocationPageState();
}

class _GeoLocationPageState extends State<GeoLocationPage> {
  late MapController _mapController;
  late LatLng _targetLocation;
  bool _locationReady = false;
  double _currentZoom = 15.0;
  bool _isMapLoading = true;
  String? _mapError;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _targetLocation = LatLng(widget.lat, widget.lng);
    _initializeMap();
  }

  void _initializeMap() {
    // Ensure the location is valid
    if (widget.lat == 0.0 && widget.lng == 0.0) {
      setState(() {
        _mapError = 'Invalid location coordinates';
        _isMapLoading = false;
      });
      return;
    }

    print('Initializing map with coordinates: ${widget.lat}, ${widget.lng}');
    print('Target location: $_targetLocation');

    setState(() {
      _locationReady = true;
      _isMapLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      final LatLng myLocation = LatLng(position.latitude, position.longitude);
      _mapController.move(myLocation, _currentZoom);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting current location: $e')),
      );
    }
  }

  void _zoomIn() {
    setState(() {
      if (_currentZoom < 18.0) {
        _currentZoom += 1.0;
        _mapController.move(_targetLocation, _currentZoom);
      }
    });
  }

  void _zoomOut() {
    setState(() {
      if (_currentZoom > 4.0) {
        _currentZoom -= 1.0;
        _mapController.move(_targetLocation, _currentZoom);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.studentName} Location'),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: Stack(
        children: [
          if (_isMapLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
            )
          else if (_mapError != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    _mapError!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else if (_locationReady)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _targetLocation,
                initialZoom: _currentZoom,
                maxZoom: 18.0,
                minZoom: 4.0,
                onMapReady: () {
                  print('Map is ready');
                },
                onMapEvent: (MapEvent event) {
                  print('Map event: ${event.runtimeType}');
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.triconnect.app',
                  maxZoom: 18,
                  minZoom: 4,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _targetLocation,
                      width: 100,
                      height: 60,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFF4CAF50),
                            size: 40,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              widget.studentName,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          Positioned(
            top: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: _zoomIn,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: _zoomOut,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(Icons.zoom_out),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'myLocation',
                  onPressed: _getCurrentLocation,
                  backgroundColor: const Color(0xFF4CAF50),
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 