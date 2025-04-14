import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'dart:async';
import 'package:flutter/services.dart';

import 'package:bolt_app/widgets/button.dart';

class MapPickerScreen extends StatefulWidget {
  @override
  _MapPickerScreenState createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  GoogleMapController? mapController;
  LatLng selectedLocation = LatLng(5.6037, -0.1870);
  LatLng userLocation = LatLng(5.6000, -0.1700);
  String locationName = "Fetching address...";
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  BitmapDescriptor personIcon = BitmapDescriptor.defaultMarker;

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final apiKey = 'AIzaSyBs6tAanmW11XywKUCqxvFe_oGMGUOGskY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
    );

    final response = await http.get(url);
    print('Raw response: ${response.body}');

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'OK' &&
          data['results'] != null &&
          data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      } else {
        print("Google API status: ${data['status']}");
        return 'No address found';
      }
    } else {
      print("HTTP error: ${response.statusCode} | Body: ${response.body}");
      return 'Failed to fetch address';
    }
  }

  void _setCustomPersonIcon() async {
    // Load the image directly from assets
    try {
      final ByteData byteData = await rootBundle.load('assets/man.png');
      final Uint8List byteList = byteData.buffer.asUint8List();
      personIcon = BitmapDescriptor.fromBytes(byteList);
      _updateMarkers();
    } catch (e) {
      print('Error loading custom icon: $e');
      _setDefaultPersonIcon();
    }
  }

  void _setDefaultPersonIcon() {
    personIcon = BitmapDescriptor.defaultMarkerWithHue(
      BitmapDescriptor.hueAzure,
    );
    _updateMarkers();
  }

  void _updateMarkers() {
    setState(() {
      _markers = {
        // Selected location marker
        Marker(
          markerId: MarkerId("selected-location"),
          position: selectedLocation,
          draggable: true,
          onDragEnd: _onMapTapped,
          icon: BitmapDescriptor.defaultMarker,
        ),
        // User location marker with person icon
        Marker(
          markerId: MarkerId("user-location"),
          position: userLocation,
          icon: personIcon,
        ),
      };
    });
  }

  void _createPolyline() {
    setState(() {
      _polylines = {
        Polyline(
          polylineId: PolylineId("route"),
          color: Colors.blue,
          width: 5,
          points: [userLocation, selectedLocation],
          patterns: [PatternItem.dash(20), PatternItem.gap(10)],
        ),
      };
    });
  }

  void _onMapTapped(LatLng position) async {
    setState(() {
      selectedLocation = position;
      locationName = "Fetching address...";
    });

    _updateMarkers();
    _createPolyline();

    try {
      final address = await getAddressFromLatLng(
        position.latitude,
        position.longitude,
      );
      setState(() {
        locationName = address;
      });
    } catch (e) {
      print('Error fetching address: $e');
      setState(() {
        locationName = "Failed to get address";
      });
    }
  }

  @override
  void initState() {
    super.initState();

    
    _setCustomPersonIcon();

    _updateMarkers();
    _createPolyline();
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
                zoom: 14,
              ),
              markers: _markers,
              polylines: _polylines,
              onTap: _onMapTapped,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
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
