import 'package:bolt_app/widgets/button.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng selectedLocation = LatLng(5.6037, -0.1870);
  String locationName = "Fetching address...";

  void _onMapTapped(LatLng position) async {
    setState(() {
      selectedLocation = position;
      locationName = "Fetching address...";
    });

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          locationName = "${place.name}, ${place.locality}, ${place.country}";
        });
      } else {
        setState(() {
          locationName = "Unknown location";
        });
      }
    } catch (e) {
      setState(() {
        locationName = "Failed to get address";
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _onMapTapped(selectedLocation);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: Column(
        children: [
          SizedBox(
            height: screenHeight * 0.5,
            child: GoogleMap(
              onMapCreated: (controller) => mapController = controller,
              initialCameraPosition: CameraPosition(
                target: selectedLocation,
                zoom: 10,
              ),
              markers: {
                Marker(
                  markerId: MarkerId("selected-location"),
                  position: selectedLocation,
                  draggable: true,
                  onDragEnd: (pos) => _onMapTapped(pos),
                ),
              },
              onTap: _onMapTapped,
            ),
          ),
          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Selected Location:\n$locationName',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),

          const SizedBox(height: 30),

          MyButton(text: 'Confirm pickup', color: Colors.green),
        ],
      ),
    );
  }
}
