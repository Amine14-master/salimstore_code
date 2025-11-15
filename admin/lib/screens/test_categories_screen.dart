import 'package:flutter/material.dart';
import '../services/realtime_database_service.dart';
import '../models/product_models.dart';

class TestCategoriesScreen extends StatefulWidget {
  const TestCategoriesScreen({super.key});

  @override
  State<TestCategoriesScreen> createState() => _TestCategoriesScreenState();
}

class _TestCategoriesScreenState extends State<TestCategoriesScreen> {
  List<Category> _categories = [];
  bool _isLoading = false;
  String _status = 'Ready to test';

  Future<void> _testCategories() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing categories...';
    });

    try {
      // Test connection
      _status = 'Testing connection...';
      final connectionTest = await RealtimeDatabaseService.testConnection();

      if (!connectionTest) {
        setState(() {
          _status = 'Connection failed ❌';
          _isLoading = false;
        });
        return;
      }

      _status = 'Connection successful ✅';

      // Load categories
      _status = 'Loading categories...';
      final categories = await RealtimeDatabaseService.getCategories();

      setState(() {
        _categories = categories;
        _status = 'Found ${categories.length} categories ✅';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetCategories() async {
    setState(() {
      _isLoading = true;
      _status = 'Resetting categories data...';
    });

    try {
      await RealtimeDatabaseService.resetCategoriesData();

      setState(() {
        _status = 'Categories data reset successfully ✅';
        _categories = [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error resetting: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Categories'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Firebase Realtime Database Test',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testCategories,
                child: Text(_isLoading ? 'Testing...' : 'Test Categories'),
              ),
            ),
            const SizedBox(height: 16),

            // Reset Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _resetCategories,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text(
                  _isLoading ? 'Resetting...' : 'Reset Categories Data',
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Categories List
            if (_categories.isNotEmpty) ...[
              Text(
                'Categories Found (${_categories.length})',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            int.parse(category.color.replaceFirst('#', '0xff')),
                          ),
                          child: Icon(
                            _getIconData(category.iconName),
                            color: Colors.white,
                          ),
                        ),
                        title: Text(category.name),
                        subtitle: Text(category.description),
                        trailing: Text(
                          'ID: ${category.id.substring(0, 8)}...',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'apple':
        return Icons.apple;
      case 'carrot':
        return Icons.local_dining;
      case 'meat':
        return Icons.restaurant;
      case 'shopping_cart':
        return Icons.shopping_cart;
      default:
        return Icons.category;
    }
  }
}
