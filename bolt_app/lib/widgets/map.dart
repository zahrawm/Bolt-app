import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng selectedLocation = LatLng(37.7749, -122.4194); 

  void _onMapTapped(LatLng position) {
    setState(() {
      selectedLocation = position;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: GoogleMap(
        onMapCreated: (controller) => mapController = controller,
        initialCameraPosition: CameraPosition(
          target: selectedLocation,
          zoom: 14.0,
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
         
          Navigator.of(context).pop(selectedLocation);
        },
        label: Text("Select"),
        icon: Icon(Icons.check),
      ),
    );
  }
}