import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../firebase_options.dart';
import '../theme/app_theme.dart';

class AnnouncementsManagementScreen extends StatefulWidget {
  const AnnouncementsManagementScreen({super.key});

  @override
  State<AnnouncementsManagementScreen> createState() =>
      _AnnouncementsManagementScreenState();
}

class _AnnouncementsManagementScreenState
    extends State<AnnouncementsManagementScreen> {
  late final FirebaseDatabase _database;
  DatabaseReference get _latestAnnouncementRef =>
      _database.ref('announcements/latest');

  late final DatabaseReference _announcementsByIdRef;
  DatabaseReference _byIdRef(String id) =>
      _announcementsByIdRef.child(id);

  @override
  void initState() {
    super.initState();
    _database = FirebaseDatabase.instanceFor(
      app: Firebase.app(),
      databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
    );
    _announcementsByIdRef = _database.ref('announcements/byId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.campaign, color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Annonces',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Test RTDB connectivity',
                    child: IconButton(
                      icon: const Icon(Icons.bug_report),
                      onPressed: _testRtdbConnection,
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _openCreate,
                    icon: const Icon(Icons.add),
                    label: const Text('Nouvelle annonce'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<DatabaseEvent>(
                  stream: _announcementsByIdRef.onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return _buildLoading();
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: AppTheme.errorColor),
                        ),
                      );
                    }
                    final raw = snapshot.data?.snapshot.value;
                    Map<String, dynamic> map = {};
                    if (raw is Map) {
                      map = Map<String, dynamic>.from(raw);
                    }
                    if (map.isEmpty) {
                      return _buildEmpty();
                    }
                    final entries = map.entries
                        .map((e) => {
                              'id': e.key,
                              ...Map<String, dynamic>.from(
                                  e.value as Map<dynamic, dynamic>),
                            })
                        .toList();
                    entries.sort((a, b) {
                      int at = (a['createdAt'] ?? a['updatedAt'] ?? 0) as int;
                      int bt = (b['createdAt'] ?? b['updatedAt'] ?? 0) as int;
                      return bt.compareTo(at);
                    });
                    return ListView.separated(
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final title = (entry['title'] ?? 'Annonce').toString();
                        final message = (entry['message'] ?? '').toString();
                        final active = (entry['active'] ?? true) == true;
                        final imageUrl = entry['imageUrl']?.toString();
                        final createdAt = _readTimestamp(entry['createdAt']);
                        final id = entry['id']?.toString() ?? '';
                        return _AnnouncementCard(
                          id: id,
                          title: title,
                          message: message,
                          active: active,
                          imageUrl: imageUrl,
                          createdAt: createdAt,
                          onEdit: () => _openEdit(id, entry),
                          onDelete: () => _delete(id),
                          onToggleActive: (value) => _toggleActive(id, value),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      itemCount: 6,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.campaign_outlined, size: 64, color: AppTheme.textLight),
          const SizedBox(height: 12),
          Text(
            'Aucune annonce',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Créez votre première annonce',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _openCreate,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle annonce'),
          ),
        ],
      ),
    );
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Future<void> _testRtdbConnection() async {
    debugPrint('=== RTDB CONNECTION TEST ===');
    try {
      final testRef = _database.ref('_test_connection');
      final testData = {
        'timestamp': ServerValue.timestamp,
        'message': 'Test write from admin app',
      };
      
      debugPrint('Writing test data to _test_connection...');
      await testRef.set(testData);
      debugPrint('✓ Test write successful');
      
      // Read back
      final snap = await testRef.get();
      if (snap.exists) {
        debugPrint('✓ Test read successful: ${snap.value}');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ RTDB Connection OK! Check console for details.'),
            backgroundColor: AppTheme.successColor,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        debugPrint('✗ Test data not found after write');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✗ RTDB write succeeded but read failed. Check rules.'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
      
      // Cleanup
      await testRef.remove();
      debugPrint('=== TEST COMPLETE ===');
    } catch (e) {
      debugPrint('✗ RTDB Connection Error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RTDB Error: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _openCreate() async {
    await _openForm();
  }

  Future<void> _openEdit(String id, Map<String, dynamic> data) async {
    await _openForm(id: id, initial: data);
  }

  Future<void> _openForm({String? id, Map<String, dynamic>? initial}) async {
    final titleCtrl = TextEditingController(
      text: initial?['title']?.toString() ?? '',
    );
    final messageCtrl = TextEditingController(
      text: initial?['message']?.toString() ?? '',
    );
    final imageCtrl = TextEditingController(
      text: initial?['imageUrl']?.toString() ?? '',
    );
    bool active = (initial?['active'] ?? true) == true;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: StatefulBuilder(
              builder: (context, setModal) {
                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.campaign,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            id == null
                                ? 'Nouvelle annonce'
                                : 'Modifier l\'annonce',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Titre',
                          prefixIcon: Icon(Icons.title_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageCtrl,
                        minLines: 3,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          prefixIcon: Icon(Icons.edit_note_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: imageCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Image (URL optionnelle)',
                          prefixIcon: Icon(Icons.image_outlined),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: active,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) => setModal(() => active = v),
                        title: const Text('Active'),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (titleCtrl.text.trim().isEmpty &&
                                messageCtrl.text.trim().isEmpty) {
                              Navigator.pop(context, false);
                              return;
                            }
                            try {
                              if (id == null) {
                                final newRef = _announcementsByIdRef.push();
                                final newId = newRef.key!;
                                final payload = <String, dynamic>{
                                  'id': newId,
                                  'title': titleCtrl.text.trim(),
                                  'message': messageCtrl.text.trim(),
                                  'imageUrl': imageCtrl.text.trim().isEmpty
                                      ? null
                                      : imageCtrl.text.trim(),
                                  'active': active,
                                  'createdAt': ServerValue.timestamp,
                                  'updatedAt': ServerValue.timestamp,
                                };
                                await newRef.set(payload);
                                await _syncLatestToRealtime(newId, payload);
                              } else {
                                final updateData = <String, dynamic>{
                                  'title': titleCtrl.text.trim(),
                                  'message': messageCtrl.text.trim(),
                                  'imageUrl': imageCtrl.text.trim().isEmpty
                                      ? null
                                      : imageCtrl.text.trim(),
                                  'active': active,
                                  'updatedAt': ServerValue.timestamp,
                                };
                                await _byIdRef(id).update(updateData);
                                await _syncLatestToRealtime(id, updateData);
                              }
                              if (context.mounted) Navigator.pop(context, true);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Erreur: $e'),
                                    backgroundColor: AppTheme.errorColor,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save_rounded),
                          label: Text(id == null ? 'Créer' : 'Enregistrer'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    titleCtrl.dispose();
    messageCtrl.dispose();
    imageCtrl.dispose();
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: const Text('Voulez-vous vraiment supprimer cette annonce ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _byIdRef(id).remove();
      final latestSnap = await _latestAnnouncementRef.get();
      if (latestSnap.exists && latestSnap.value is Map) {
        final latest = Map<String, dynamic>.from(
            latestSnap.value as Map<dynamic, dynamic>);
        if ((latest['id']?.toString() ?? '') == id) {
          await _latestAnnouncementRef.remove();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _toggleActive(String id, bool value) async {
    try {
      await _byIdRef(id).update({
        'active': value,
        'updatedAt': ServerValue.timestamp,
      });
      final snap = await _byIdRef(id).get();
      if (snap.exists && snap.value is Map) {
        await _syncLatestToRealtime(
          id,
          Map<String, dynamic>.from(snap.value as Map<dynamic, dynamic>),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  Future<void> _syncLatestToRealtime(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final payload = <String, dynamic>{
        'id': id,
        'title': (data['title'] ?? '').toString(),
        'message': (data['message'] ?? '').toString(),
        'imageUrl': data['imageUrl'],
        'active': (data['active'] ?? true) == true,
        'updatedAt': ServerValue.timestamp,
      };
      
      debugPrint('=== ANNOUNCEMENT SYNC DEBUG ===');
      debugPrint('Database URL: ${DefaultFirebaseOptions.currentPlatform.databaseURL}');
      debugPrint('Writing to: announcements/latest');
      debugPrint('Payload: $payload');
      
      await _latestAnnouncementRef.set(payload);
      debugPrint('✓ Wrote to announcements/latest');
      
      await _byIdRef(id).set(payload);
      debugPrint('✓ Wrote to announcements/byId/$id');
      
      // Verify write by reading back
      final latestSnap = await _latestAnnouncementRef.get();
      if (latestSnap.exists) {
        debugPrint('✓ Verified: announcements/latest exists');
        debugPrint('Data: ${latestSnap.value}');
      } else {
        debugPrint('✗ ERROR: announcements/latest not found after write!');
      }
      
      debugPrint('=== SYNC COMPLETE ===');
    } catch (e) {
      debugPrint('=== SYNC ERROR ===');
      debugPrint('Failed to sync announcement: $e');
      debugPrint('Stack trace: ${StackTrace.current}');
      debugPrint('=== END ERROR ===');
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('RTDB Error: $e'),
          backgroundColor: AppTheme.errorColor,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}

class _AnnouncementCard extends StatelessWidget {
  final String id;
  final String title;
  final String message;
  final bool active;
  final String? imageUrl;
  final DateTime? createdAt;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  const _AnnouncementCard({
    required this.id,
    required this.title,
    required this.message,
    required this.active,
    required this.imageUrl,
    required this.createdAt,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl!.trim().isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  imageUrl!,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_not_supported,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.campaign, color: Colors.white),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title.isNotEmpty ? title : 'Annonce',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: active
                              ? AppTheme.successColor.withOpacity(0.12)
                              : AppTheme.textLight.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: Text(
                            active ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: active
                                  ? AppTheme.successColor
                                  : AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message.isNotEmpty ? message : '—',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: const Icon(
                          Icons.edit,
                          color: AppTheme.primaryColor,
                        ),
                        tooltip: 'Modifier',
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppTheme.errorColor,
                        ),
                        tooltip: 'Supprimer',
                      ),
                      const Spacer(),
                      Switch(value: active, onChanged: onToggleActive),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
