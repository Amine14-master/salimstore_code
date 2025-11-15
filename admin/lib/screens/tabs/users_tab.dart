import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../theme/design_tokens.dart';
import '../../firebase_options.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final FirebaseDatabase _db = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
  );
  bool _loading = true;
  List<_AppUser> _users = [];
  String _query = '';
  StreamSubscription<DatabaseEvent>? _clientsSub;
  StreamSubscription<DatabaseEvent>? _usersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreSub;
  Map<String, Map<String, dynamic>> _firestoreById = {};
  Map<String, Map<String, dynamic>> _firestoreByPhone = {};
  List<_AppUser> _clientsNode = [];
  List<_AppUser> _usersNode = [];

  @override
  void initState() {
    super.initState();
    print('[USER DEBUG] Initializing UsersTab');
    _listenUsers();
  }

  @override
  void dispose() {
    _clientsSub?.cancel();
    _usersSub?.cancel();
    _firestoreSub?.cancel();
    super.dispose();
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D+'), '');
    if (digits.isEmpty) return '';
    if (digits.startsWith('213') && digits.length >= 12) {
      final local = digits.substring(3);
      return local.startsWith('0') ? local : '0$local';
    }
    if (digits.length == 9) {
      return '0$digits';
    }
    return digits;
  }

  String _formatDisplayPhone(String phone) {
    final normalized = _normalizePhone(phone);
    if (normalized.isEmpty) return 'Téléphone non renseigné';
    if (normalized.length != 10) return normalized;
    final chunks = [
      normalized.substring(0, 2),
      normalized.substring(2, 5),
      normalized.substring(5, 7),
      normalized.substring(7, 10),
    ];
    return chunks.join(' ');
  }

  int _extractCreatedAt(dynamic value) {
    if (value is int) return value;
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  _AppUser _buildUserFromFirestore(String id, Map<String, dynamic> data) {
    final createdAt = _extractCreatedAt(data['createdAt']);
    final photo = data['photoUrl']?.toString();
    return _AppUser(
      id: id,
      name: (data['name'] ?? 'Utilisateur').toString(),
      phone: (data['phone'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      photoUrl: (photo != null && photo.isNotEmpty) ? photo : null,
      wilaya: data['wilaya']?.toString() ?? '',
      commune: data['commune']?.toString() ?? '',
      role: (data['role'] ?? 'client').toString(),
      createdAtMs: createdAt,
    );
  }

  _AppUser _enrichUser(_AppUser user) {
    final trimmedPhone = user.phone.trim();
    final normalizedPhone = _normalizePhone(trimmedPhone);
    final data = _firestoreById[user.id] ??
        (normalizedPhone.isNotEmpty ? _firestoreByPhone[normalizedPhone] : null);
    if (data == null) return user;

    final photo = data['photoUrl']?.toString();
    final createdAt = user.createdAtMs != 0
        ? user.createdAtMs
        : _extractCreatedAt(data['createdAt']);

    return _AppUser(
      id: user.id,
      name: (data['name'] ?? user.name).toString(),
      phone: (data['phone'] ?? user.phone).toString(),
      email: (data['email'] ?? user.email).toString(),
      photoUrl: (photo != null && photo.isNotEmpty) ? photo : user.photoUrl,
      wilaya: data['wilaya']?.toString() ?? user.wilaya,
      commune: data['commune']?.toString() ?? user.commune,
      role: (data['role'] ?? user.role).toString(),
      createdAtMs: createdAt,
    );
  }

  void _recomputeUsers() {
    print('[USER DEBUG] Recomputing users: clientsNode=${_clientsNode.length}, usersNode=${_usersNode.length}, firestoreById=${_firestoreById.length}');
    
    final merged = [..._clientsNode, ..._usersNode];
    final Map<String, _AppUser> dedup = {};

    for (final user in merged) {
      print('[USER DEBUG] Processing user: ${user.id} - ${user.name}');
      final normalizedPhone = _normalizePhone(user.phone);
      final key =
          normalizedPhone.isNotEmpty ? 'p:$normalizedPhone' : 'i:${user.id}';
      dedup[key] = _enrichUser(user);
    }

    // Include Firestore-only records if RTDB nodes are empty
    for (final entry in _firestoreById.entries) {
      final id = entry.key;
      final data = entry.value;
      final phone = data['phone']?.toString().trim() ?? '';
      final normalizedPhone = _normalizePhone(phone);
      final key =
          normalizedPhone.isNotEmpty ? 'p:$normalizedPhone' : 'i:$id';
      dedup.putIfAbsent(key, () => _buildUserFromFirestore(id, data));
    }

    final list = dedup.values.toList()
      ..sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));

    print('[USER DEBUG] Final user count: ${list.length}');
    
    if (!mounted) return;
    setState(() {
      _users = list;
      _loading = false;
    });
  }

  void _listenFirestoreClients() {
    try {
      _firestoreSub?.cancel();
      _firestoreSub = FirebaseFirestore.instance
          .collection('clients')
          .snapshots()
          .listen(
        (snapshot) {
          final byId = <String, Map<String, dynamic>>{};
          final byPhone = <String, Map<String, dynamic>>{};

          for (final doc in snapshot.docs) {
            final data = doc.data();
            byId[doc.id] = data;
            final phone = data['phone']?.toString().trim();
            if (phone != null && phone.isNotEmpty) {
              final normalizedPhone = _normalizePhone(phone);
              if (normalizedPhone.isNotEmpty) {
                byPhone[normalizedPhone] = data;
              }
            }
          }

          _firestoreById = byId;
          _firestoreByPhone = byPhone;
          _recomputeUsers();
        },
        onError: (error) {
          print('Firestore clients stream error: $error');
          _firestoreById = {};
          _firestoreByPhone = {};
          _recomputeUsers();
        },
      );
    } catch (e) {
      print('Unable to start Firestore clients listener: $e');
    }
  }

  void _listenUsers() {
    setState(() => _loading = true);
    print('[USER DEBUG] Starting user data listeners');

    _listenFirestoreClients();

    // Listen to RTDB 'clients' (phone keyed)
    _clientsSub?.cancel();
    print('[USER DEBUG] Listening to RTDB clients node');
    _clientsSub = _db.ref('clients').onValue.listen(
      (event) {
        final list = <_AppUser>[];
        if (event.snapshot.exists && event.snapshot.value is Map) {
          final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          print('[USER DEBUG] RTDB clients node received ${map.length} entries');
          map.forEach((key, value) {
            if (value is Map) {
              final v = Map<dynamic, dynamic>.from(value);
              final createdAt =
                  v['createdAt'] is int ? v['createdAt'] as int : 0;
              final phone = (v['phone'] ?? key.toString()).toString();
              list.add(
                _AppUser(
                  id: key.toString(),
                  name: (v['name'] ?? 'Utilisateur').toString(),
                  phone: phone,
                  email: (v['email'] ?? '').toString(),
                  photoUrl: v['photoUrl']?.toString(),
                  wilaya: v['wilaya']?.toString() ?? '',
                  commune: v['commune']?.toString() ?? '',
                  role: (v['role'] ?? 'client').toString(),
                  createdAtMs: createdAt,
                ),
              );
            }
          });
        } else {
          print('[USER DEBUG] RTDB clients node has no data');
        }
        _clientsNode = list;
        print('[USER DEBUG] _clientsNode now has ${_clientsNode.length} users');
        _recomputeUsers();
      },
      onError: (error) => print('[USER ERROR] Error listening clients: $error'),
    );

    // Listen to RTDB 'users' (UID keyed)
    _usersSub?.cancel();
    print('[USER DEBUG] Listening to RTDB users node');
    _usersSub = _db.ref('users').onValue.listen(
      (event) {
        final list = <_AppUser>[];
        if (event.snapshot.exists && event.snapshot.value is Map) {
          final map = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
          print('[USER DEBUG] RTDB users node received ${map.length} entries');
          map.forEach((uid, value) {
            if (value is Map) {
              final v = Map<dynamic, dynamic>.from(value);
              final name =
                  (v['name'] ?? v['displayName'] ?? 'Utilisateur').toString();
              final phone = (v['phone'] ?? v['phoneNumber'] ?? '').toString();
              final email = (v['email'] ?? '').toString();
              final photo =
                  (v['photoUrl'] ?? v['photoURL'] ?? v['avatar'] ?? '')
                      .toString();
              final role = (v['role'] ?? 'client').toString();
              int createdAt = 0;
              if (v['createdAt'] is int) createdAt = v['createdAt'] as int;
              list.add(
                _AppUser(
                  id: uid.toString(),
                  name: name,
                  phone: phone,
                  email: email,
                  photoUrl: photo.isNotEmpty ? photo : null,
                  role: role,
                  createdAtMs: createdAt,
                ),
              );
            }
          });
        } else {
          print('[USER DEBUG] RTDB users node has no data');
        }
        _usersNode = list;
        print('[USER DEBUG] _usersNode now has ${_usersNode.length} users');
        _recomputeUsers();
      },
      onError: (error) => print('[USER ERROR] Error listening users: $error'),
    );
  }

  Future<void> _deleteUser(_AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'utilisateur'),
        content: Text('Supprimer ${user.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _db.ref('clients').child(user.id).remove();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${user.name} a été supprimé'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _users.where((u) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return u.name.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Utilisateurs'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Rechercher par nom, email ou téléphone',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Text(
                      'Aucun utilisateur',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final u = filtered[index];
                      return _UserTile(
                        user: u,
                        displayPhone: _formatDisplayPhone(u.phone),
                        onDelete: () => _deleteUser(u),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _UserTile extends StatelessWidget {
  final _AppUser user;
  final VoidCallback onDelete;
  final String displayPhone;
  const _UserTile({
    required this.user,
    required this.onDelete,
    required this.displayPhone,
  });

  Future<void> _showAddressesMapDialog(BuildContext context) async {
    final theme = Theme.of(context);
    final List<String> addressList = [];
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
      );
      final addressesRef = db.ref('users/${user.id}/addresses');
      final addressesSnap = await addressesRef.get();
      if (addressesSnap.exists && addressesSnap.value is Map) {
        final addrMap = Map<dynamic, dynamic>.from(addressesSnap.value as Map);
        addrMap.forEach((key, value) {
          if (value is Map) {
            final addr = Map<dynamic, dynamic>.from(value);
            final full = addr['fullAddress']?.toString() ??
                addr['address']?.toString() ??
                '${addr['wilaya'] ?? ''}, ${addr['commune'] ?? ''}';
            if (full.trim().isNotEmpty) addressList.add(full.trim());
          }
        });
      }
      // Fallback to coarse location if none
      if (addressList.isEmpty) {
        final coarse = [user.wilaya, user.commune]
          ..removeWhere((e) => (e).toString().trim().isEmpty);
        if (coarse.isNotEmpty) addressList.add(coarse.join(', '));
      }
      if (addressList.isEmpty) addressList.add(user.name);
    } catch (e) {
      print('Error loading addresses for map: $e');
    }

    // Build a Google Maps directions URL with waypoints
    final origin = Uri.encodeComponent(addressList.first);
    final destination = Uri.encodeComponent(addressList.length > 1
        ? addressList.last
        : addressList.first);
    final waypoints = addressList.length > 2
        ? addressList
            .sublist(1, addressList.length - 1)
            .map(Uri.encodeComponent)
            .join('|')
        : '';
    final mapsUrl = waypoints.isNotEmpty
        ? 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving&waypoints=$waypoints'
        : 'https://www.google.com/maps/search/?api=1&query=$destination';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.map, color: AppTheme.accentColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Adresses du client',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (addressList.isNotEmpty)
                ...addressList.map((a) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.place, size: 16, color: AppTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              a,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final u = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(a)}');
                              if (await canLaunchUrl(u)) {
                                await launchUrl(u, mode: LaunchMode.externalApplication);
                              }
                            },
                            child: const Text('Ouvrir'),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.textLight.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Cliquez sur 'Ouvrir la carte' pour afficher toutes les adresses en même temps dans Google Maps.",
                        style: theme.textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final u = Uri.parse(mapsUrl);
              if (await canLaunchUrl(u)) {
                await launchUrl(u, mode: LaunchMode.externalApplication);
              }
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.map),
            label: const Text('Ouvrir la carte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showClientDetails(BuildContext context) async {
    // Aggregate details
    String? defaultAddress;
    String? defaultAddressId;
    final List<Map<String, String>> addresses = [];
    final List<String> favorites = [];
    int createdAtMs = user.createdAtMs;
    int updatedAtMs = 0;
    try {
      final db = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: DefaultFirebaseOptions.currentPlatform.databaseURL,
      );

      // Try to read timestamps and defaultAddress pointer
      final userRef = db.ref('users/${user.id}');
      final userSnap = await userRef.get();
      if (userSnap.exists && userSnap.value is Map) {
        final root = Map<dynamic, dynamic>.from(userSnap.value as Map);
        if (root['createdAt'] is int) createdAtMs = root['createdAt'] as int;
        if (root['updatedAt'] is int) updatedAtMs = root['updatedAt'] as int;
        if (root['defaultAddress'] is String) {
          defaultAddressId = root['defaultAddress'] as String;
        }
      }

      // Addresses list
      final addressesRef = db.ref('users/${user.id}/addresses');
      final addressesSnap = await addressesRef.get();

      if (addressesSnap.exists) {
        final addrMap = Map<dynamic, dynamic>.from(addressesSnap.value as Map);
        addrMap.forEach((key, value) {
          if (value is Map) {
            final addr = Map<dynamic, dynamic>.from(value);
            final full =
                addr['fullAddress']?.toString() ??
                addr['address']?.toString() ??
                '${addr['wilaya'] ?? ''}, ${addr['commune'] ?? ''}';
            addresses.add({
              'id': key.toString(),
              'label': addr['label']?.toString() ?? '',
              'full': full,
              'wilaya': addr['wilaya']?.toString() ?? '',
              'commune': addr['commune']?.toString() ?? '',
            });
            if (addr['isDefault'] == true || defaultAddress == null) {
              defaultAddress = full;
            }
          }
        });
      }

      // If no address found, use wilaya and commune
      if (defaultAddress == null || defaultAddress!.isEmpty) {
        if (user.wilaya.isNotEmpty || user.commune.isNotEmpty) {
          defaultAddress =
              '${user.wilaya.isNotEmpty ? user.wilaya : ''}${user.wilaya.isNotEmpty && user.commune.isNotEmpty ? ', ' : ''}${user.commune.isNotEmpty ? user.commune : ''}';
        }
      }
      // Favorites under users/{uid}/favorites or /favorites/{uid}
      DataSnapshot favSnap = await db.ref('users/${user.id}/favorites').get();
      if (!(favSnap.exists && favSnap.value is Map)) {
        favSnap = await db.ref('favorites/${user.id}').get();
      }
      if (favSnap.exists && favSnap.value is Map) {
        final fMap = Map<dynamic, dynamic>.from(favSnap.value as Map);
        fMap.forEach((key, value) {
          final isFav =
              (value is bool && value) || (value?.toString() == 'true');
          if (isFav) favorites.add(key.toString());
        });
      }
    } catch (e) {
      print('Error getting address: $e');
    }

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.person, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Détails du client',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile photo and name
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                      backgroundImage:
                          user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null || user.photoUrl!.isEmpty
                          ? const Icon(
                              Icons.person,
                              size: 40,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow(context, Icons.phone, 'Téléphone', user.phone),
              const Divider(),
              _buildDetailRow(context, Icons.email, 'Email', user.email),
              if (createdAtMs > 0) ...[
                const Divider(),
                _buildDetailRow(
                  context,
                  Icons.event,
                  'Créé le',
                  DateTime.fromMillisecondsSinceEpoch(createdAtMs).toString(),
                ),
              ],
              if (updatedAtMs > 0) ...[
                const Divider(),
                _buildDetailRow(
                  context,
                  Icons.update,
                  'Mis à jour le',
                  DateTime.fromMillisecondsSinceEpoch(updatedAtMs).toString(),
                ),
              ],
              if (user.wilaya.isNotEmpty || user.commune.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow(
                  context,
                  Icons.location_city,
                  'Wilaya',
                  user.wilaya.isNotEmpty ? user.wilaya : 'Non spécifiée',
                ),
                const Divider(),
                _buildDetailRow(
                  context,
                  Icons.location_on,
                  'Commune',
                  user.commune.isNotEmpty ? user.commune : 'Non spécifiée',
                ),
              ],
              if (defaultAddress != null && defaultAddress!.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow(
                  context,
                  Icons.home,
                  'Adresse de livraison',
                  defaultAddress!,
                ),
              ],
              if (addresses.isNotEmpty) ...[
                const Divider(),
                Text(
                  'Adresses (${addresses.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...addresses.map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(
                          a['id'] == defaultAddressId
                              ? Icons.check_circle
                              : Icons.place,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${a['label']?.isNotEmpty == true ? '${a['label']} — ' : ''}${a['full']}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (favorites.isNotEmpty) ...[
                const Divider(),
                _buildDetailRow(
                  context,
                  Icons.favorite,
                  'Favoris',
                  '${favorites.length} produits',
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (user.phone.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                final uri = Uri.parse('tel:${user.phone}');
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.call, size: 18),
              label: const Text('Appeler'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successColor,
                foregroundColor: Colors.white,
              ),
            ),
          if (defaultAddress != null && defaultAddress!.isNotEmpty)
            ElevatedButton.icon(
              onPressed: () async {
                final encodedAddress = Uri.encodeComponent(defaultAddress!);
                final uri = Uri.parse(
                  'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
                Navigator.pop(context);
              },
              icon: const Icon(Icons.map, size: 18),
              label: const Text('Voir sur la carte'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName =
        user.name.trim().isNotEmpty ? user.name.trim() : 'Client';
    final locationParts = [user.wilaya.trim(), user.commune.trim()]
      ..removeWhere((element) => element.isEmpty);
    final location = locationParts.isNotEmpty ? locationParts.join(', ') : '';
    final hasPhone = user.phone.trim().isNotEmpty;
    final hasEmail = user.email.trim().isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.08),
            Colors.white,
          ],
        ),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
        boxShadow: AppShadows.subtle,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          onTap: () => _showClientDetails(context),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                      backgroundImage:
                          user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? NetworkImage(user.photoUrl!)
                          : null,
                      child: user.photoUrl == null || user.photoUrl!.isEmpty
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                  vertical: AppSpacing.xs,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primaryColor.withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius.circular(AppRadii.sm),
                                ),
                                child: Text(
                                  user.role,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          if (hasPhone) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    displayPhone,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Text(
                              'Téléphone non renseigné',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          if (hasEmail) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(
                                  Icons.mail_outline,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    user.email,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (location.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    location,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _ActionButton(
                      icon: Icons.call,
                      color: AppTheme.successColor,
                      tooltip: 'Appeler',
                      onTap: () async {
                        if (user.phone.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Numéro de téléphone non disponible'),
                              backgroundColor: AppTheme.warningColor,
                            ),
                          );
                          return;
                        }
                        final uri = Uri.parse('tel:${user.phone}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Impossible d\'ouvrir l\'application téléphone',
                                ),
                                backgroundColor: AppTheme.errorColor,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    _ActionButton(
                      icon: Icons.map,
                      color: AppTheme.accentColor,
                      tooltip: 'Voir sur la carte',
                      onTap: () async {
                        await _showAddressesMapDialog(context);
                      },
                    ),
                    _ActionButton(
                      icon: Icons.delete_rounded,
                      color: AppTheme.errorColor,
                      tooltip: 'Supprimer',
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppRadii.sm),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                tooltip,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppUser {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final String wilaya;
  final String commune;
  final String role;
  final int createdAtMs;
  _AppUser({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    this.wilaya = '',
    this.commune = '',
    required this.role,
    required this.createdAtMs,
  });
}
