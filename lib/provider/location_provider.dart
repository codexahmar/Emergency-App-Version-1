import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  Position? position;
  LatLng? myLocationMarker;
  List<LatLng> routeCoords = [];
  Set<Polyline> polyLines = {};
  Set<Marker> markers = {};
  MapType mapType = MapType.hybrid;
  bool userInteractedWithMap = false;
  GoogleMapController? mapController;
  String currentAddress = "Fetching...";
  bool isInitializing = true; // Add loading state

  LocationProvider() {
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      isInitializing = true;
      notifyListeners();

      // First check and request permissions
      if (!await _checkPermission()) {
        final hasPermission = await _requestPermission();
        if (!hasPermission) {
          isInitializing = false;
          notifyListeners();
          return;
        }
      }

      // Then check GPS
      if (!await _checkGpsServiceEnable()) {
        await _requestGpsServiceEnable();
        if (!await _checkGpsServiceEnable()) {
          isInitializing = false;
          notifyListeners();
          return;
        }
      }

      // Get last known position first for faster initial display
      Position? lastKnownPosition = await Geolocator.getLastKnownPosition();
      if (lastKnownPosition != null) {
        position = lastKnownPosition;
        updateLocation(lastKnownPosition);
      }

      // Then get current position with timeout
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        if (position != null) {
          updateLocation(position!);
        }
      } catch (e) {
        print("Error getting current position: $e");
        // If current position fails but we have last known position, we can still proceed
        if (position == null) {
          isInitializing = false;
          notifyListeners();
          return;
        }
      }

      // Start location updates stream
      listenCurrentLocation();
    } finally {
      isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> getCurrentLocation() async {
    if (await _checkPermission()) {
      if (await _checkGpsServiceEnable()) {
        position = await Geolocator.getCurrentPosition();
        updateLocation(position!);

        if (mapController != null) {
          mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: LatLng(position!.latitude, position!.longitude),
                zoom: 20,
              ),
            ),
          );
        }
      } else {
        _requestGpsServiceEnable();
      }
    } else {
      _requestPermission();
    }
  }

  Future<void> listenCurrentLocation() async {
    if (await _checkPermission()) {
      if (await _checkGpsServiceEnable()) {
        Geolocator.getPositionStream(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).listen((Position newPos) {
          position = newPos;
          updateLocation(newPos);
        });
      } else {
        _requestGpsServiceEnable();
      }
    } else {
      _requestPermission();
    }
  }

  void updateLocation(Position newPosition) async {
    LatLng newLatLng = LatLng(newPosition.latitude, newPosition.longitude);
    myLocationMarker = newLatLng;

    // Only add to route coords if it's not the first position
    if (routeCoords.isEmpty || routeCoords.last != newLatLng) {
      routeCoords.add(newLatLng);
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
          newPosition.latitude, newPosition.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentAddress =
            "${place.locality}, ${place.administrativeArea}, ${place.country}";
      } else {
        currentAddress = "Unknown location";
      }
    } catch (e) {
      print("Error getting address: $e");
      currentAddress = "Location found, address unavailable";
    }

    _updatePolyline();
    _updateMarker();
    notifyListeners();
  }

  void _updatePolyline() {
    polyLines = {
      Polyline(
        polylineId: const PolylineId("route"),
        points: routeCoords,
        color: Colors.blue,
        width: 5,
      )
    };
    notifyListeners();
  }

  void _updateMarker() {
    markers = {
      Marker(
        markerId: const MarkerId("currentLocation"),
        position: myLocationMarker!,
        infoWindow: InfoWindow(
          title: "My Current Location",
          snippet:
              "${myLocationMarker!.latitude}, ${myLocationMarker!.longitude}",
        ),
        onTap: () {
          userInteractedWithMap = false;
          moveToCurrentLocation();
        },
      )
    };
    notifyListeners();
  }

  void moveToCurrentLocation() {
    if (mapController != null && !userInteractedWithMap) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: myLocationMarker!, zoom: 20),
        ),
      );
    }
  }

  void toggleMapType() {
    mapType = (mapType == MapType.hybrid) ? MapType.normal : MapType.hybrid;
    notifyListeners();
  }

  Future<bool> _checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> _requestPermission() async {
    LocationPermission permission = await Geolocator.requestPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  Future<bool> _checkGpsServiceEnable() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  Future<void> _requestGpsServiceEnable() async {
    await Geolocator.openLocationSettings();
  }

  void showSenderLocation(LatLng senderLocation) {
    markers = {
      ...markers,
      Marker(
        markerId: const MarkerId("senderLocation"),
        position: senderLocation,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: const InfoWindow(
          title: "Emergency Location",
          snippet: "Location where emergency was reported",
        ),
      ),
    };

    if (mapController != null) {
      mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: senderLocation,
            zoom: 20,
          ),
        ),
      );
    }
    notifyListeners();
  }
}
