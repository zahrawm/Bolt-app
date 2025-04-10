import 'package:bolt_app/screen/location_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _MapHomeScreenState();
}

class _MapHomeScreenState extends State<HomeScreen> {
  GoogleMapController? _mapController;

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(5.6037, -0.1870),
    zoom: 12,
  );

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
          ),

          Positioned(
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
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => LocationScreen(),
                              ),
                            );
                          },
                          child: AbsorbPointer(
                            child: TextField(
                              decoration: InputDecoration(
                                prefixIcon: Icon(Icons.search),
                                hintText: "Where to?",
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

                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: _optionBox(
                          Icons.fastfood,
                          "Bolt Food",
                          "Fast delivery",
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _optionBox(
                          Icons.local_shipping,
                          "Bolt Send",
                          "Parcel delivery",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  _locationTile(
                    Icons.access_time,
                    "Circle VIP Bus Terminal",
                    "Ring Road Central, Accra",
                  ),
                  _locationTile(
                    Icons.shopping_bag,
                    "Accra Mall",
                    "Spintex Road, Accra",
                  ),
                  _locationTile(
                    Icons.directions_bus,
                    "Madina Zongo Junction",
                    "Ga",
                  ),

                  const SizedBox(height: 10),

                  ListTile(
                    leading: Container(
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(
                        Icons.calendar_today,
                        color: Colors.green,
                      ),
                    ),
                    title: const Text(
                      "Always arrive on time",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text("Calendar connection makes it easy"),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home), 
            label: 'Home',
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: "Rides",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Account"),
        ],
      ),
    );
  }

  Widget _optionBox(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Colors.green),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
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
}
