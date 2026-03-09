// lib/src/services/geolocation_service.dart
import 'package:geolocator/geolocator.dart';

class GeolocationService {
  /// Requests permission (if needed) and returns the current position.
  /// Throws an exception with a friendly message if permission is denied or service disabled.
  Future<Position> getCurrentPosition() async {
    // Is location service enabled on device?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable location services.');
    }

    // Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permission denied. Please grant permission to continue.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      throw Exception('Location permission permanently denied. Please enable it from settings.');
    }

    // All good: get position using the new LocationSettings API
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }
}
