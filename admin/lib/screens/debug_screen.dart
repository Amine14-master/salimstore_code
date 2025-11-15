import 'package:flutter/material.dart';
import '../services/realtime_database_service.dart';
import '../theme/app_theme.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _connectionStatus = 'Testing...';
  String _categoriesStatus = 'Loading...';
  List<String> _debugLogs = [];

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    setState(() {
      _connectionStatus = 'Testing connection...';
      _debugLogs.add('Testing Firebase Realtime Database connection...');
    });

    try {
      final result = await RealtimeDatabaseService.testConnection();
      setState(() {
        _connectionStatus = result ? 'Connected ✅' : 'Failed ❌';
        _debugLogs.add('Connection test result: $result');
      });

      if (result) {
        _loadCategories();
      }
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error: $e';
        _debugLogs.add('Connection error: $e');
      });
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _categoriesStatus = 'Loading categories...';
      _debugLogs.add('Loading categories from Firebase...');
    });

    try {
      final categories = await RealtimeDatabaseService.getCategories();
      setState(() {
        _categoriesStatus = 'Found ${categories.length} categories';
        _debugLogs.add('Found ${categories.length} categories');
        for (final category in categories) {
          _debugLogs.add('- ${category.name} (ID: ${category.id})');
        }
      });
    } catch (e) {
      setState(() {
        _categoriesStatus = 'Error: $e';
        _debugLogs.add('Categories error: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Screen'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Debug Information',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connection Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _connectionStatus,
                      style: TextStyle(
                        color: _connectionStatus.contains('✅')
                            ? Colors.green
                            : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Categories Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Categories Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_categoriesStatus),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Debug Logs
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debug Logs',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          itemCount: _debugLogs.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                _debugLogs[index],
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _testConnection,
                    child: const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _loadCategories,
                    child: const Text('Load Categories'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _debugLogs.add('Cleaning up null entries...');
                  });
                  try {
                    await RealtimeDatabaseService.cleanupNullEntries();
                    setState(() {
                      _debugLogs.add('Cleanup completed successfully');
                    });
                  } catch (e) {
                    setState(() {
                      _debugLogs.add('Cleanup error: $e');
                    });
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Clean Up Null Entries'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
