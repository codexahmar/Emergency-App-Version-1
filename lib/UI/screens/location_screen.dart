import 'package:emergency_app/services/live_location.dart';
import 'package:flutter/material.dart';

class LocationScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const LocationScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LiveLocationMapScreen());
  }
}
