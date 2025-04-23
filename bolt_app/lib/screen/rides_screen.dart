
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:async';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/foundation.dart' show kIsWeb;

class UserHomePage extends StatefulWidget {
  final String userId;

  const UserHomePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  bool hasShownAlert = false;
  List<Map<String, dynamic>> nearbyDrivers = [];
  Position? currentPosition;
  String currentAddress = "Fetching address...";
  String locationStatus = "Initializing location services...";
  StreamSubscription<Position>? positionStream;
  GoogleMapController? mapController;
  final Set<Marker> _markers = {};
  bool isLoading = true;
  bool mapLoadError = false;

  final coordFormat = intl.NumberFormat("0.000000", "en_US");

  final String apiKey = "AIzaSyBs6tAanmW11XywKUCqxvFe_oGMGUOGskY";

  @override
  void initState() {
    super.initState();

    // Give a bit more time on web platforms
    Future.delayed(Duration(milliseconds: kIsWeb ? 1000 : 300), () {
      if (mounted) {
        _initializeLocationServices();
      }
    });
    _checkNotifications();
  }

  @override
  void dispose() {
    positionStream?.cancel();
    mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocationServices() async {
    try {
      setState(() {
        locationStatus = "Checking location permissions...";
        isLoading = true;
      });

      // First, check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          locationStatus =
              "Location services are disabled. Please enable them in your device settings.";
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Location services are disabled. Please enable them in your device settings.',
            ),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                if (kIsWeb) {
                  // For web, just show a message since we can't directly open settings
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enable location in your browser settings'),
                    ),
                  );
                } else {
                  Geolocator.openLocationSettings();
                }
              },
            ),
          ),
        );
        return;
      }

      // If services are enabled, proceed to request permission
      await _requestLocationPermission();
    } catch (e) {
      setState(() {
        locationStatus = "Error initializing location services: $e";
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize location services: $e')),
      );
    }
  }

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        setState(() {
          locationStatus = "Requesting location permission...";
        });

        // For web platforms, show a more descriptive message
        if (kIsWeb) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please allow location access in the browser prompt'),
              duration: Duration(seconds: 5),
            ),
          );
        }

        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          setState(() {
            locationStatus =
                "Location permission denied. Please enable location permissions in browser settings.";
            isLoading = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location permissions are denied'),
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  if (!kIsWeb) {
                    Geolocator.openAppSettings();
                  } else {
                    // For web, just show instructions
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Click the location icon in your browser address bar and allow access'),
                      ),
                    );
                  }
                },
              ),
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          locationStatus =
              "Location permissions are permanently denied. Please enable them in browser settings.";
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location permissions are permanently denied'),
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                if (!kIsWeb) {
                  Geolocator.openAppSettings();
                } else {
                  // For web, provide specific instructions for Chrome
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('In Chrome, click the lock icon in the address bar → Site settings → Allow location'),
                      duration: Duration(seconds: 8),
                    ),
                  );
                }
              },
            ),
          ),
        );
        return;
      }

      setState(() {
        locationStatus = "Location permission granted. Getting position...";
      });

      _startLocationTracking();
    } catch (e) {
      setState(() {
        locationStatus = "Error requesting permissions: $e";
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error requesting location permissions: $e')),
      );
    }
  }

  void _startLocationTracking() {
    setState(() {
      locationStatus = "Getting current position...";
    });

    // For web, use specific settings
    _getCurrentPositionWithFallbacks().then((position) {
      if (position != null) {
        _handleNewPosition(position);
      } else {
        setState(() {
          locationStatus =
              "Unable to determine your location. Please try again and ensure location access is allowed in your browser.";
          isLoading = false;
        });
      }
    });

    // Set up position stream with appropriate settings for web
    try {
      // Different settings for web vs. mobile
      LocationSettings locationSettings = kIsWeb
          ? LocationSettings(
              accuracy: LocationAccuracy.high,
            )
          : LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10,
            );

      positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          _handleNewPosition(position);
        },
        onError: (e) {
          print("Position stream error: $e");
          // Show error to user so they're aware
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Location stream error: $e. Will try to recover.'),
                duration: Duration(seconds: 3),
              ),
            );
          }
        },
      );
    } catch (e) {
      print("Error setting up position stream: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error tracking location: $e')),
        );
      }
    }
  }

 
  Future<Position?> _getCurrentPositionWithFallbacks() async {
    
    if (kIsWeb) {
      try {
      
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        );
      } catch (e) {
        print("Web high accuracy position failed: $e");
        
        try {
          
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.lowest,
            timeLimit: Duration(seconds: 15),
          );
        } catch (e) {
          print("Web lowest accuracy position failed: $e");
          return null;
        }
      }
    } else {
    
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        );
      } catch (e) {
        print("High accuracy position failed: $e");

        try {
          return await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.reduced,
            timeLimit: Duration(seconds: 10),
          );
        } catch (e) {
          print("Reduced accuracy position failed: $e");

          try {
            return await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.lowest,
              timeLimit: Duration(seconds: 8),
            );
          } catch (e) {
            print("Lowest accuracy position failed: $e");

            try {
              return await Geolocator.getLastKnownPosition();
            } catch (e) {
              print("Last known position failed: $e");
              return null;
            }
          }
        }
      }
    }
  }

  void _handleNewPosition(Position position) {
    setState(() {
      currentPosition = position;
      locationStatus = "Position updated";
      isLoading = false;
    });

    _getAddressFromLatLng(position);

    if (widget.userId != null && widget.userId.isNotEmpty) {
      _updateUserLocation(position);
    } else {
      print("Warning: User ID is null or empty, skipping Firestore update");
    }

    _fetchNearbyDrivers(position);

    _updateMarkers();

    if (mapController != null) {
      _animateToCurrentLocation();
    }
    
    
    if (kIsWeb) {
      print("Web location: ${position.latitude}, ${position.longitude}, accuracy: ${position.accuracy}m");
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      setState(() {
        currentAddress = "Fetching address...";
      });

      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(
        Duration(seconds: kIsWeb ? 15 : 10),
        onTimeout: () {
          throw TimeoutException("Address lookup timed out");
        },
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        String address = "";

        if (place.street != null && place.street!.isNotEmpty) {
          address += place.street!;
        }

        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          address +=
              address.isNotEmpty
                  ? ", ${place.subLocality}"
                  : place.subLocality!;
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ", ${place.locality}" : place.locality!;
        }

        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          address +=
              address.isNotEmpty ? ", ${place.postalCode}" : place.postalCode!;
        }

        if (place.country != null && place.country!.isNotEmpty) {
          address += address.isNotEmpty ? ", ${place.country}" : place.country!;
        }

        setState(() {
          currentAddress =
              address.isNotEmpty ? address : "Address not available";
        });
      } else {
        setState(() {
          currentAddress = "No address found for this location";
        });
      }
    } catch (e) {
      print("Error getting address: $e");
      setState(() {
        currentAddress = "Unable to get address";
      });
    }
  }

  void _updateMarkers() {
    if (currentPosition == null) return;

    setState(() {
      _markers.clear();

    
      _markers.add(
        Marker(
          markerId: MarkerId('user'),
          position: LatLng(
            currentPosition!.latitude,
            currentPosition!.longitude,
          ),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: 'Lat: ${coordFormat.format(currentPosition!.latitude)}, Lng: ${coordFormat.format(currentPosition!.longitude)}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      for (var driver in nearbyDrivers) {
        GeoPoint location = driver['location'];
        _markers.add(
          Marker(
            markerId: MarkerId(driver['id']),
            position: LatLng(location.latitude, location.longitude),
            infoWindow: InfoWindow(
              title: driver['name'],
              snippet: '${driver['distance']} meters away',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        );
      }
    });
  }

  void _animateToCurrentLocation() {
    if (currentPosition != null && mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(
              currentPosition!.latitude,
              currentPosition!.longitude,
            ),
            zoom: 15,
          ),
        ),
      );
    }
  }

  Future<void> _updateUserLocation(Position position) async {
    if (widget.userId == null || widget.userId.isEmpty) {
      print("Error: User ID is empty or null");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .set({
            "location": GeoPoint(position.latitude, position.longitude),
            "address": currentAddress,
            "isOnline": true,
            "lastUpdated": FieldValue.serverTimestamp(),
            "accuracy": position.accuracy, // Store accuracy for debugging
            "locationSource": kIsWeb ? "web" : "mobile", // Track source
          }, SetOptions(merge: true));
    } catch (e) {
      print("Error updating Firestore: $e");
    }
  }

  void _fetchNearbyDrivers(Position userPos) async {
    try {
      final drivers = await FirebaseFirestore.instance
          .collection("drivers")
          .where("isOnline", isEqualTo: true)
          .get()
          .timeout(
            Duration(seconds: 8),
            onTimeout: () {
              throw TimeoutException("Firestore query timed out");
            },
          );

      List<Map<String, dynamic>> driversData = [];

      for (var doc in drivers.docs) {
        try {
          GeoPoint driverLocation = doc["location"];
          double distance = Geolocator.distanceBetween(
            userPos.latitude,
            userPos.longitude,
            driverLocation.latitude,
            driverLocation.longitude,
          );

          if (distance < 1000) {
            driversData.add({
              'id': doc.id,
              'distance': distance.round(),
              'name': doc['name'] ?? 'Unknown Driver',
              'location': driverLocation,
              'address': doc['address'] ?? 'Address not available',
            });

            if (distance < 100 &&
                widget.userId != null &&
                widget.userId.isNotEmpty) {
              try {
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                      "to": doc.id,
                      "from": widget.userId,
                      "message": "A user is nearby!",
                      "timestamp": FieldValue.serverTimestamp(),
                      "seen": false,
                    });
              } catch (e) {
                print("Error sending notification: $e");
              }
            }
          }
        } catch (e) {
          print("Error processing driver ${doc.id}: $e");
        }
      }

      driversData.sort((a, b) => a['distance'].compareTo(b['distance']));

      setState(() {
        nearbyDrivers = driversData;
      });

      _updateMarkers();
    } catch (e) {
      print("Error fetching drivers: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching nearby drivers')),
        );
      }
    }
  }

  void _checkNotifications() {
    if (widget.userId == null || widget.userId.isEmpty) {
      print("Warning: User ID is null or empty, skipping notification check");
      return;
    }

    try {
      FirebaseFirestore.instance
          .collection("notifications")
          .where("to", isEqualTo: widget.userId)
          .where("seen", isEqualTo: false)
          .snapshots()
          .listen(
            (snapshot) {
              for (var doc in snapshot.docs) {
                _showAlert(doc["message"]);
                doc.reference.update({"seen": true});
              }
            },
            onError: (e) {
              print("Error in notification listener: $e");
            },
          );
    } catch (e) {
      print("Error setting up notification listener: $e");
    }
  }

  void _showAlert(String msg) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text("Notification"),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("OK"),
              ),
            ],
          ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    try {
      setState(() {
        mapController = controller;
        mapLoadError = false;
      });

      if (currentPosition != null) {
        _animateToCurrentLocation();
      }
    } catch (e) {
      print("Error in map controller creation: $e");
      setState(() {
        mapLoadError = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Map initialization error: $e'),
            duration: Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Widget _buildMapView() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(locationStatus),
          ],
        ),
      );
    }

    if (currentPosition == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(locationStatus),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeLocationServices,
              child: Text("Try Again"),
            ),
            if (kIsWeb) ...[
              SizedBox(height: 16),
              Text(
                "Make sure you allow location access in your browser", 
                textAlign: TextAlign.center,
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      );
    }

    if (mapLoadError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 48, color: Colors.orange),
            SizedBox(height: 16),
            Text("Map failed to load"),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  mapLoadError = false;
                });
              },
              child: Text("Try Again"),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: LatLng(currentPosition!.latitude, currentPosition!.longitude),
        zoom: 15,
      ),
      markers: _markers,
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      mapToolbarEnabled: true,
      onMapCreated: _onMapCreated,
      zoomControlsEnabled: true,
      compassEnabled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("User App"),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              if (currentPosition != null) {
                _fetchNearbyDrivers(currentPosition!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Refreshing nearby drivers')),
                );
              } else {
                _initializeLocationServices();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Trying to get location again...')),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 1, child: _buildMapView()),

        
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[200],
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Your Location:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 4),
                Text(
                  currentPosition == null ? locationStatus : currentAddress,
                  style: TextStyle(fontSize: 14),
                ),
                if (currentPosition != null) ...[
                  Text(
                    "Coordinates: ${coordFormat.format(currentPosition!.latitude)}, ${coordFormat.format(currentPosition!.longitude)}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),

                  Text(
                    "Accuracy: ±${currentPosition!.accuracy.toStringAsFixed(1)} meters",
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                  ),
                ],
              ],
            ),
          ),

          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Nearby Drivers",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        "${nearbyDrivers.length} found",
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      currentPosition == null
                          ? Center(
                            child: Text(
                              "Location needed to find nearby drivers",
                            ),
                          )
                          : nearbyDrivers.isEmpty
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.no_transfer,
                                  size: 48,
                                  color: Colors.orange,
                                ),
                                SizedBox(height: 16),
                                Text("No nearby drivers found"),
                                SizedBox(height: 8),
                                Text(
                                  "Try expanding your search area",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                          : ListView.builder(
                            itemCount: nearbyDrivers.length,
                            itemBuilder: (context, index) {
                              final driver = nearbyDrivers[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.green,
                                  child: Icon(
                                    Icons.directions_car,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(driver['name']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${driver['distance']} meters away'),
                                    Text(
                                      driver['address'],
                                      style: TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.navigation),
                                  onPressed: () {
                                    GeoPoint location = driver['location'];
                                    mapController?.animateCamera(
                                      CameraUpdate.newCameraPosition(
                                        CameraPosition(
                                          target: LatLng(
                                            location.latitude,
                                            location.longitude,
                                          ),
                                          zoom: 16,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                isThreeLine: true,
                              );
                            },
                          ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "location",
            child: Icon(Icons.my_location),
            onPressed: () {
              if (currentPosition != null) {
                _animateToCurrentLocation();
              } else {
                _initializeLocationServices();
              }
            },
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "refresh",
            backgroundColor: Colors.green,
            child: Icon(Icons.refresh),
            onPressed: () {
              if (currentPosition != null) {
                _getCurrentPositionWithFallbacks().then((position) {
                  if (position != null) {
                    _handleNewPosition(position);
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Location updated')));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update location')),
                    );
                  }
                });
              } else {
                _initializeLocationServices();
              }
            },
          ),
         
          if (kIsWeb)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: FloatingActionButton(
                heroTag: "webHighAccuracy",
                backgroundColor: Colors.orange,
                child: Icon(Icons.gps_fixed),
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Requesting high accuracy location...')),
                  );
                  try {
                    Position position = await Geolocator.getCurrentPosition(
                      desiredAccuracy: LocationAccuracy.bestForNavigation,
                      timeLimit: Duration(seconds: 25),
                    );
                    _handleNewPosition(position);
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ),
        ],
      ),
      // Add a Chrome-specific debug panel for web
      persistentFooterButtons: kIsWeb ? [
        TextButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: Text("Web Location Debug"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("To get exact location in Chrome:"),
                    SizedBox(height: 8),
                    Text("1. Ensure you've allowed location access"),
                    Text("2. Check that Chrome has precise location enabled in your OS settings"),
                    Text("3. Try the high accuracy button (orange)"),
                    if (currentPosition != null) ...[
                      SizedBox(height: 16),
                      Text("Current Data:"),
                      Text("Lat: ${currentPosition!.latitude}"),
                      Text("Lng: ${currentPosition!.longitude}"),
                      Text("Accuracy: ±${currentPosition!.accuracy}m"),
                    ],
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("OK"),
                  ),
                ],
              ),
            );
          },
          child: Text("Web Location Help"),
        ),
      ] : null,
    );
  }
}
