import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

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

  TextEditingController searchController = TextEditingController();
  List<dynamic> searchResults = [];
  bool isSearching = false;
  FocusNode searchFocusNode = FocusNode();

  Future<String> getAddressFromLatLng(double lat, double lng) async {
    final apiKey = 'AIzaSyBs6tAanmW11XywKUCqxvFe_oGMGUOGskY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey',
    );

    final response = await http.get(url);

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

  Future<void> searchPlaces(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        isSearching = false;
      });
      return;
    }

    setState(() {
      isSearching = true;
    });

    final apiKey = 'AIzaSyBs6tAanmW11XywKUCqxvFe_oGMGUOGskY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$apiKey&components=country:gh',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          setState(() {
            searchResults = data['predictions'];
            isSearching = false;
          });
        } else {
          print("Places API error: ${data['status']}");
          setState(() {
            searchResults = [];
            isSearching = false;
          });
        }
      } else {
        print("HTTP error: ${response.statusCode}");
        setState(() {
          searchResults = [];
          isSearching = false;
        });
      }
    } catch (e) {
      print("Error searching places: $e");
      setState(() {
        searchResults = [];
        isSearching = false;
      });
    }
  }

  Future<void> getPlaceDetails(String placeId) async {
    final apiKey = 'AIzaSyBs6tAanmW11XywKUCqxvFe_oGMGUOGskY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$apiKey&fields=geometry,formatted_address,name',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK') {
          final location = data['result']['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final formattedAddress = data['result']['formatted_address'];

          final newLocation = LatLng(lat, lng);

          setState(() {
            selectedLocation = newLocation;
            locationName = formattedAddress;
            searchResults = [];
            searchController.text = formattedAddress;
            searchFocusNode.unfocus();
          });

          _updateMarkers();
          _createPolyline();

          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: newLocation, zoom: 16),
              ),
            );
          }
        } else {
          print("Place Details API error: ${data['status']}");
        }
      } else {
        print("HTTP error: ${response.statusCode}");
      }
    } catch (e) {
      print("Error getting place details: $e");
    }
  }

  void _handleSearchSubmission(String query) async {
    if (query.isEmpty) return;

    setState(() {
      isSearching = true;
    });

    final apiKey = 'AIzaSyBs6tAanmW11XywKUCqxvFe_oGMGUOGskY';
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?address=$query&key=$apiKey&components=country:gh',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final location = data['results'][0]['geometry']['location'];
          final lat = location['lat'];
          final lng = location['lng'];
          final formattedAddress = data['results'][0]['formatted_address'];

          final newLocation = LatLng(lat, lng);

          setState(() {
            selectedLocation = newLocation;
            locationName = formattedAddress;
            searchResults = [];
            searchController.text = formattedAddress;
            searchFocusNode.unfocus();
            isSearching = false;
          });

          _updateMarkers();
          _createPolyline();

          if (mapController != null) {
            mapController!.animateCamera(
              CameraUpdate.newCameraPosition(
                CameraPosition(target: newLocation, zoom: 16),
              ),
            );
          }
        } else {
          print("Geocoding API error: ${data['status']}");
          setState(() {
            isSearching = false;
          });
        }
      } else {
        print("HTTP error: ${response.statusCode}");
        setState(() {
          isSearching = false;
        });
      }
    } catch (e) {
      print("Error geocoding address: $e");
      setState(() {
        isSearching = false;
      });
    }
  }

  Future<BitmapDescriptor> _resizeImageAsset(
    String path,
    int width,
    int height,
  ) async {
    final ByteData data = await rootBundle.load(path);

    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );

    ui.FrameInfo fi = await codec.getNextFrame();

    final ByteData? byteData = await fi.image.toByteData(
      format: ui.ImageByteFormat.png,
    );

    if (byteData != null) {
      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    } else {
      throw Exception('Failed to resize image');
    }
  }

  void _setCustomPersonIcon() async {
    try {
      personIcon = await _resizeImageAsset('assets/man.png', 40, 40);
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
        Marker(
          markerId: MarkerId("selected-location"),
          position: selectedLocation,
          draggable: true,
          onDragEnd: _onMapTapped,
          icon: BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(title: "Pickup Location"),
        ),
        Marker(
          markerId: MarkerId("user-location"),
          position: userLocation,
          icon: personIcon,
          infoWindow: InfoWindow(title: "Your Location"),
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
      searchResults = [];
      searchFocusNode.unfocus();
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
        searchController.text = address;
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

    getAddressFromLatLng(
      selectedLocation.latitude,
      selectedLocation.longitude,
    ).then((address) {
      setState(() {
        locationName = address;
        searchController.text = address;
      });
    });
    Timer? searchDebounce;
    searchController.addListener(() {
      if (searchDebounce?.isActive ?? false) searchDebounce!.cancel();
      searchDebounce = Timer(const Duration(milliseconds: 500), () {
        if (searchController.text.isNotEmpty) {
          searchPlaces(searchController.text);
        }
      });
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: Text('Pick Location')),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: searchController,
                        focusNode: searchFocusNode,
                        decoration: InputDecoration(
                          hintText: 'Search for a location',
                          prefixIcon: Icon(Icons.search),
                          suffixIcon:
                              searchController.text.isNotEmpty
                                  ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      searchController.clear();
                                      setState(() {
                                        searchResults = [];
                                      });
                                    },
                                  )
                                  : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onSubmitted: _handleSearchSubmission,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
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
                      mapToolbarEnabled: true,
                    ),

                    Center(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 40),
                        child: Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                color: Colors.white,
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      locationName,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),
                    MyButton(text: 'Confirm pickup', color: Colors.green),
                  ],
                ),
              ),
            ],
          ),

          if (searchResults.isNotEmpty)
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                constraints: BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    final result = searchResults[index];
                    return ListTile(
                      leading: Icon(Icons.location_on, color: Colors.blue),
                      title: Text(result['structured_formatting']['main_text']),
                      subtitle: Text(
                        result['structured_formatting']['secondary_text'] ?? '',
                      ),
                      onTap: () {
                        getPlaceDetails(result['place_id']);
                      },
                    );
                  },
                ),
              ),
            ),

          if (isSearching)
            Positioned(
              top: 72,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(16),
                color: Colors.white,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
