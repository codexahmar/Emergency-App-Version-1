import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationProvider extends ChangeNotifier {
  String currentLocation = 'Fetching location...';
  bool isLoading = true;
  StreamSubscription<Position>? positionStreamSubscription;

  LocationProvider() {
    initLocationService();
  }

  Future<void> initLocationService() async {
    isLoading = true;
    notifyListeners();

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      currentLocation = 'Location services are disabled';
      isLoading = false;
      notifyListeners();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        currentLocation = 'Location permissions are denied';
        isLoading = false;
        notifyListeners();
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      currentLocation = 'Location permissions are permanently denied';
      isLoading = false;
      notifyListeners();
      return;
    }

    // Start listening to location changes
    positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).listen((Position position) {
      updateLocation(position);
    });
  }

  Future<void> updateLocation(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        currentLocation =
            " ${place.locality}, ${place.administrativeArea}, ${place.country}";
      } else {
        currentLocation = 'Location not found';
      }
    } catch (e) {
      currentLocation = 'Location not available';
      print("Error fetching location: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void refreshLocation() {
    initLocationService();
  }

  @override
  void dispose() {
    positionStreamSubscription?.cancel();
    super.dispose();
  }
}
