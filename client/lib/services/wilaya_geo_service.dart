import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

class WilayaGeoMatch {
  final String code;
  final String name;

  const WilayaGeoMatch({required this.code, required this.name});
}

class WilayaGeoService {
  static final List<_WilayaFeature> _features = [];
  static bool _isLoading = false;

  static bool isLoaded() => _features.isNotEmpty;

  static Future<void> ensureLoaded() async {
    if (isLoaded() || _isLoading) return;
    _isLoading = true;
    try {
      final jsonString = await rootBundle.loadString(
        'lib/assets/all-wilayas.geojson',
      );
      _loadFromJson(jsonString);
    } catch (e, stack) {
      debugPrint('Failed to load wilaya geo data: $e');
      debugPrint('$stack');
    } finally {
      _isLoading = false;
    }
  }

  static void _loadFromJson(String jsonString) {
    final dynamic decoded = json.decode(jsonString);
    if (decoded is! Map<String, dynamic>) {
      return;
    }

    final features = decoded['features'];
    if (features is! List) {
      return;
    }

    _features.clear();
    for (final feature in features) {
      if (feature is! Map<String, dynamic>) continue;
      final parsed = _WilayaFeature.tryParse(feature);
      if (parsed != null) {
        _features.add(parsed);
      }
    }
  }

  static WilayaGeoMatch? findByCoordinates(double latitude, double longitude) {
    if (!isLoaded()) return null;

    for (final feature in _features) {
      if (!feature.boundsContains(latitude, longitude)) {
        continue;
      }

      if (feature.contains(latitude, longitude)) {
        return WilayaGeoMatch(code: feature.code, name: feature.name);
      }
    }

    return null;
  }
}

class _WilayaFeature {
  final String code;
  final String name;
  final List<_GeoPolygon> polygons;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const _WilayaFeature({
    required this.code,
    required this.name,
    required this.polygons,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  static _WilayaFeature? tryParse(Map<String, dynamic> feature) {
    final properties = feature['properties'];
    final geometry = feature['geometry'];
    if (properties is! Map<String, dynamic> ||
        geometry is! Map<String, dynamic>) {
      return null;
    }

    final cityCode = properties['city_code']?.toString();
    final name = properties['name']?.toString() ?? '';
    if (cityCode == null) {
      return null;
    }

    final type = geometry['type'];
    final coordinates = geometry['coordinates'];
    final polygons = <_GeoPolygon>[];

    void addPolygon(List<dynamic> polygonData) {
      final polygon = _GeoPolygon.tryParse(polygonData);
      if (polygon != null) {
        polygons.add(polygon);
      }
    }

    if (type == 'Polygon' && coordinates is List) {
      addPolygon(coordinates);
    } else if (type == 'MultiPolygon' && coordinates is List) {
      for (final polygonData in coordinates) {
        if (polygonData is List) {
          addPolygon(polygonData);
        }
      }
    }

    if (polygons.isEmpty) {
      return null;
    }

    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final polygon in polygons) {
      minLat = minLat < polygon.minLat ? minLat : polygon.minLat;
      maxLat = maxLat > polygon.maxLat ? maxLat : polygon.maxLat;
      minLon = minLon < polygon.minLon ? minLon : polygon.minLon;
      maxLon = maxLon > polygon.maxLon ? maxLon : polygon.maxLon;
    }

    return _WilayaFeature(
      code: cityCode.padLeft(2, '0'),
      name: name,
      polygons: polygons,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }

  bool boundsContains(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  bool contains(double lat, double lon) {
    for (final polygon in polygons) {
      if (polygon.contains(lat, lon)) {
        return true;
      }
    }
    return false;
  }
}

class _GeoPolygon {
  final List<List<List<double>>> rings;
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;

  const _GeoPolygon({
    required this.rings,
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  static _GeoPolygon? tryParse(List<dynamic> polygonData) {
    final rings = <List<List<double>>>[];
    double minLat = double.infinity;
    double maxLat = -double.infinity;
    double minLon = double.infinity;
    double maxLon = -double.infinity;

    for (final ringData in polygonData) {
      if (ringData is! List) continue;
      final ring = <List<double>>[];
      for (final coordinate in ringData) {
        if (coordinate is! List || coordinate.length < 2) continue;
        final lon = (coordinate[0] as num).toDouble();
        final lat = (coordinate[1] as num).toDouble();
        ring.add([lon, lat]);
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
      }
      if (ring.isNotEmpty) {
        rings.add(ring);
      }
    }

    if (rings.isEmpty) {
      return null;
    }

    return _GeoPolygon(
      rings: rings,
      minLat: minLat,
      maxLat: maxLat,
      minLon: minLon,
      maxLon: maxLon,
    );
  }

  bool boundsContains(double lat, double lon) {
    return lat >= minLat && lat <= maxLat && lon >= minLon && lon <= maxLon;
  }

  bool contains(double lat, double lon) {
    if (!boundsContains(lat, lon)) {
      return false;
    }

    if (!_pointInRing(rings.first, lat, lon)) {
      return false;
    }

    for (var i = 1; i < rings.length; i++) {
      if (_pointInRing(rings[i], lat, lon)) {
        return false;
      }
    }

    return true;
  }

  bool _pointInRing(List<List<double>> ring, double lat, double lon) {
    var inside = false;
    for (int i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];

      final intersects =
          ((yi > lat) != (yj > lat)) &&
          (lon <
              (xj - xi) *
                      (lat - yi) /
                      (((yj - yi).abs() < 1e-12) ? 1e-12 : (yj - yi)) +
                  xi);
      if (intersects) inside = !inside;
    }
    return inside;
  }
}
