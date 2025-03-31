import 'package:emergency_app/provider/location_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class LiveLocationMapScreen extends StatelessWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LiveLocationMapScreen({
    Key? key,
    this.initialLatitude,
    this.initialLongitude,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Real Time Location Tracker",
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildFloatingButton(
                    Icons.my_location, provider.moveToCurrentLocation),
                SizedBox(width: 10),
                _buildFloatingButton(Icons.map, provider.toggleMapType),
              ],
            ),
          );
        },
      ),
      body: Consumer<LocationProvider>(
        builder: (context, provider, child) {
          // If we have initial coordinates, use them
          if (initialLatitude != null && initialLongitude != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.showSenderLocation(
                LatLng(initialLatitude!, initialLongitude!),
              );
            });
          }

          if (provider.myLocationMarker == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: initialLatitude != null && initialLongitude != null
                      ? LatLng(initialLatitude!, initialLongitude!)
                      : provider.myLocationMarker!,
                  zoom: 20,
                ),
                onMapCreated: (GoogleMapController mapCtrl) {
                  provider.mapController = mapCtrl;
                  if (initialLatitude == null || initialLongitude == null) {
                    provider.moveToCurrentLocation();
                  }
                },
                onTap: (LatLng position) {
                  provider.userInteractedWithMap = true;
                },
                polylines: provider.polyLines,
                markers: provider.markers,
                myLocationEnabled: true,
                mapType: provider.mapType,
                buildingsEnabled: true,
                tiltGesturesEnabled: true,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, VoidCallback onPressed) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: Colors.blueAccent,
      elevation: 5,
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
