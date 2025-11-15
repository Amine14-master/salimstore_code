import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../firebase_options.dart';

class FavoritesService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseDatabase _database = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );
  static const String _localKey = 'favorite_products';

  static DatabaseReference _favoritesRef(String userId) {
    return _database.ref('users/$userId/favorites');
  }

  // Sync local favorites to Firebase (using Map structure)
  static Future<void> _syncToFirebase(List<String> favoriteIds) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _favoritesRef(user.uid);
    // Convert list to map for better Firebase handling
    final Map<String, bool> favoritesMap = {};
    for (var id in favoriteIds) {
      favoritesMap[id] = true;
    }
    await ref.set(favoritesMap);
  }

  // Load favorites from Firebase (or fallback to local)
  static Future<List<String>> getFavorites() async {
    final user = _auth.currentUser;
    final prefs = await SharedPreferences.getInstance();

    if (user != null) {
      try {
        final snapshot = await _favoritesRef(user.uid).get();
        if (snapshot.exists) {
          final value = snapshot.value;
          List<String> favoriteIds = [];

          if (value is Map) {
            // New format: Map structure
            final mapValue = Map<dynamic, dynamic>.from(value);
            favoriteIds = mapValue.keys
                .where((key) => mapValue[key] == true)
                .map((e) => e.toString())
                .toList();
          } else if (value is List) {
            // Old format: List structure (backward compatibility)
            favoriteIds = List<dynamic>.from(
              value,
            ).map((e) => e.toString()).toList();
          }

          // Sync to local storage
          await prefs.setString(_localKey, jsonEncode(favoriteIds));
          return favoriteIds;
        }
      } catch (e) {
        print('Error loading favorites from Firebase: $e');
      }
    }

    // Fallback to local storage
    final favoritesJson = prefs.getString(_localKey);
    if (favoritesJson != null) {
      try {
        final List<dynamic> favoriteIds = jsonDecode(favoritesJson);
        return favoriteIds.map((e) => e.toString()).toList();
      } catch (e) {
        print('Error parsing local favorites: $e');
      }
    }

    return [];
  }

  static Future<void> addFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = await getFavorites();

    if (!favoriteIds.contains(productId)) {
      favoriteIds.add(productId);
      await prefs.setString(_localKey, jsonEncode(favoriteIds));
      await _syncToFirebase(favoriteIds);
    }
  }

  static Future<void> removeFavorite(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIds = await getFavorites();

    favoriteIds.remove(productId);
    await prefs.setString(_localKey, jsonEncode(favoriteIds));
    await _syncToFirebase(favoriteIds);
  }

  static Future<bool> isFavorite(String productId) async {
    final favoriteIds = await getFavorites();
    return favoriteIds.contains(productId);
  }
}
