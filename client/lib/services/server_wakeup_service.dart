import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

/// Service to keep Render server awake
/// Render free tier sleeps after inactivity - this wakes it up proactively
class ServerWakeupService {
  static const String _serverUrl = 'https://salimstore.onrender.com';
  static const String _healthEndpoint =
      '/api/health'; // or any lightweight endpoint

  static DateTime? _lastWakeup;
  static const Duration _wakeupInterval = Duration(minutes: 5);

  /// Wake up the server with a lightweight ping
  /// This is fire-and-forget - won't block UI or show errors
  static Future<void> wakeupServer() async {
    // Don't spam the server - only wake up if last wakeup was > 5 minutes ago
    if (_lastWakeup != null &&
        DateTime.now().difference(_lastWakeup!) < _wakeupInterval) {
      debugPrint(
        '⏰ Server wakeup skipped (last wakeup was ${DateTime.now().difference(_lastWakeup!).inSeconds}s ago)',
      );
      return;
    }

    try {
      debugPrint('🔔 Waking up Render server...');
      _lastWakeup = DateTime.now();

      // Fire and forget - don't await, don't block UI
      http
          .get(
            Uri.parse('$_serverUrl$_healthEndpoint'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              debugPrint(
                '⏱️ Server wakeup timeout (this is OK - server is waking up)',
              );
              return http.Response('', 408);
            },
          )
          .then((response) {
            if (response.statusCode == 200 || response.statusCode == 404) {
              debugPrint('✅ Server is awake! (Status: ${response.statusCode})');
            } else {
              debugPrint('⚠️ Server response: ${response.statusCode}');
            }
          })
          .catchError((error) {
            // Silently ignore errors - server might be waking up
            debugPrint(
              '🔄 Server waking up... (Error: ${error.toString().substring(0, 50)})',
            );
          });
    } catch (e) {
      // Silently catch any errors - this is background task
      debugPrint('🔄 Background server wakeup initiated');
    }
  }

  /// Aggressive wakeup before PayPal checkout
  /// Makes multiple attempts to ensure server is ready
  static Future<void> aggressiveWakeup() async {
    debugPrint('🚀 Starting aggressive server wakeup for PayPal...');

    // Make 3 quick pings to wake up the server
    for (int i = 0; i < 3; i++) {
      try {
        final response = await http
            .get(
              Uri.parse('$_serverUrl$_healthEndpoint'),
              headers: {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 3));

        if (response.statusCode == 200 || response.statusCode == 404) {
          debugPrint('✅ Server confirmed awake on attempt ${i + 1}');
          return; // Server is awake, no need to continue
        }
      } catch (e) {
        debugPrint('⏳ Wakeup attempt ${i + 1}/3...');
        if (i < 2) {
          await Future.delayed(const Duration(milliseconds: 500));
        }
      }
    }

    debugPrint('🔔 Aggressive wakeup completed');
  }

  /// Check if server is likely asleep
  static bool isServerLikelyAsleep() {
    if (_lastWakeup == null) return true;
    return DateTime.now().difference(_lastWakeup!) >
        const Duration(minutes: 10);
  }
}
