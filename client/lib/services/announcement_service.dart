import 'package:firebase_database/firebase_database.dart';

class AnnouncementService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;

  static DatabaseReference get _latestRef =>
      _database.ref('announcements/latest');

  static Future<({String id, Map<String, dynamic> data})?>
  getLatestActive() async {
    try {
      final snapshot = await _latestRef.get();
      if (!snapshot.exists || snapshot.value == null) return null;
      final raw = snapshot.value;
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw as Map);
        final id = data['id']?.toString() ?? '';
        if (id.isEmpty) return null;
        final active = data['active'] != false;
        if (!active) return null;
        return (id: id, data: data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Stream<({String id, Map<String, dynamic> data})?>
  latestActiveStream() {
    return _latestRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return null;
      }
      final raw = event.snapshot.value;
      if (raw is Map) {
        final data = Map<String, dynamic>.from(raw as Map);
        final id = data['id']?.toString() ?? '';
        if (id.isEmpty) return null;
        final active = data['active'] != false;
        if (!active) return null;
        return (id: id, data: data);
      }
      return null;
    });
  }

  static Future<void> markSeenLocally(String id) async {
    // done via SharedPreferences in UI
  }
}
