import 'package:bolt_app/screen/account_screen.dart';
import 'package:bolt_app/screen/rides_screen.dart';
import 'package:bolt_app/screen/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'location_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;
  String selectedLocationText = "Where to?";
  LatLng? selectedDestination;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(5.6037, -0.1870),
    zoom: 9,
  );

  void _updateMapWithLocation(LatLng location, String address) {
    setState(() {
      selectedDestination = location;
      selectedLocationText = address;

      _markers = {
        Marker(
          markerId: const MarkerId("destination"),
          position: location,
          infoWindow: InfoWindow(title: address),
        ),
      };

      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: location, zoom: 14),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: (controller) => _mapController = controller,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            markers: _markers,
            polylines: _polylines,
          ),
          _buildBottomSheet(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomSheet(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LocationScreen(),
                        ),
                      );

                      if (result != null && result is Map<String, dynamic>) {
                        if (result.containsKey('location') &&
                            result.containsKey('address')) {
                          _updateMapWithLocation(
                            result['location'] as LatLng,
                            result['address'] as String,
                          );
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: selectedLocationText,
                          filled: true,
                          fillColor: Colors.grey[200],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.schedule, color: Colors.green),
                  onPressed: () {},
                ),
              ],
            ),
            if (selectedDestination != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedLocationText,
                            style: TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${selectedDestination!.latitude.toStringAsFixed(5)}, ${selectedDestination!.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _locationTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.black54),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: () {},
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home, "Home", Colors.green, () {}),
              _buildNavItem(Icons.calendar_today, "Rides", Colors.grey, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RidesScreen()),
                );
              }),
              _buildNavItem(Icons.person, "Account", Colors.grey, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AccountScreen(),
                  ),
                );
              }),
              _buildNavItem(Icons.settings, "Settings", Colors.grey, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
