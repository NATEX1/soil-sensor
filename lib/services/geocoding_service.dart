import 'package:geocoding/geocoding.dart';

class GeocodingService {
  static final Map<String, String> _cache = {};

  static Future<String> getAddress(double lat, double lng) async {
    final key = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Collect available components
        final components = <String>[];
        if (p.subLocality != null && p.subLocality!.isNotEmpty) components.add(p.subLocality!);
        if (p.locality != null && p.locality!.isNotEmpty) components.add(p.locality!);
        if (p.administrativeArea != null && p.administrativeArea!.isNotEmpty) components.add(p.administrativeArea!);
        
        if (components.isNotEmpty) {
          final address = components.join(', ');
          _cache[key] = address;
          return address;
        }
      }
    } catch (e) {
      // Intentionally ignoring errors (e.g. no internet)
    }

    // Fallback if formatting or query fails
    return 'พิกัด: $key';
  }
}
