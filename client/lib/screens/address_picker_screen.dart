import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/address_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/app_theme.dart';

class AddressPickerScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;

  const AddressPickerScreen({super.key, this.existingAddress});
  @override
  State<AddressPickerScreen> createState() => _AddressPickerScreenState();
}

class _AddressPickerScreenState extends State<AddressPickerScreen> {
  /// 0 = Manuelle, 1 = Auto
  int _mode = 0;
  bool _loadingLocation = false;
  LatLng? _selectedLocation;
  LatLng _currentLocation = LatLng(36.1538, 3.1588);
  String? _mapSelectedAddress;
  final MapController _mapController = MapController();
  final Completer<void> _mapReadyCompleter = Completer<void>();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _mapController.mapEventStream.listen((event) {
      if (!_mapReadyCompleter.isCompleted) {
        _mapReadyCompleter.complete();
      }
    });
    _initializeLocation();
  }

  void _setMode(int mode) {
    setState(() {
      _mode = mode;
      if (_mode == 1) {
        // Clear any previously selected manual position
        _selectedLocation = null;
        _mapSelectedAddress = null;
      }
    });
  }

  Future<void> _initializeLocation() async {
    if (widget.existingAddress != null) {
      final lat = widget.existingAddress!['latitude'];
      final lng = widget.existingAddress!['longitude'];
      if (lat != null && lng != null) {
        _selectedLocation = LatLng(lat, lng);
        _mapSelectedAddress = widget.existingAddress!['fullAddress'];
        _currentLocation = _selectedLocation!;
        // Wait for map to be ready then move
        _moveMap(_selectedLocation!, 15.0);
        return;
      }
    }

    if (_mode == 1) return;
    // Removed auto-fetch to speed up loading
    // We just start at default location
    setState(() {
      _currentLocation = LatLng(36.7515, 5.0550); // Bejaia
    });
  }

  Future<void> _moveMap(LatLng target, [double zoom = 15.0]) async {
    try {
      await _mapReadyCompleter.future;
      if (!mounted) return;
      _mapController.move(target, zoom);
    } catch (e) {
      print('Error moving map: $e');
    }
  }

  Future<void> _getCurrentLocation({bool onlyCenter = false}) async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled;
      LocationPermission permission;

      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Les services de localisation sont désactivés.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation sont refusées');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Les permissions de localisation sont définitivement refusées.',
        );
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      if (!mounted) return;

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        if (!onlyCenter) {
          _selectedLocation = _currentLocation;
        }
        _loadingLocation = false;
      });
      await _moveMap(_currentLocation, 15.0);
      if (!onlyCenter) {
        await _detectAddressFromLocation(_currentLocation);
      }
    } catch (e) {
      setState(() => _loadingLocation = false);
      if (mounted) {
        final errorMsg = e.toString();
        if (errorMsg.contains('définitivement refusées') ||
            errorMsg.contains('permanently denied')) {
          _showPermissionDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur localisation: $errorMsg'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Permission requise'),
        content: const Text(
          'L\'accès à la localisation est nécessaire pour détecter votre position. Veuillez activer la localisation dans les paramètres de l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            child: const Text('Ouvrir les paramètres'),
          ),
        ],
      ),
    );
  }

  Future<void> _detectAddressFromLocation(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );
      if (placemarks.isNotEmpty) {
        final first = placemarks.first;
        // Build address string more carefully to handle nulls
        final parts = <String>[];
        if (first.street != null && first.street!.trim().isNotEmpty) {
          parts.add(first.street!.trim());
        }
        if (first.locality != null && first.locality!.trim().isNotEmpty) {
          parts.add(first.locality!.trim());
        }
        if (first.administrativeArea != null &&
            first.administrativeArea!.trim().isNotEmpty) {
          parts.add(first.administrativeArea!.trim());
        }
        if (first.country != null && first.country!.trim().isNotEmpty) {
          parts.add(first.country!.trim());
        }

        final address = parts.isNotEmpty
            ? parts.join(', ')
            : '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';

        setState(() {
          _mapSelectedAddress = address;
        });
      } else {
        // Fallback to coordinates if no placemarks
        setState(() {
          _mapSelectedAddress =
              '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
        });
      }
    } catch (e) {
      setState(() {
        // Use coordinates as fallback
        _mapSelectedAddress =
            '${location.latitude.toStringAsFixed(6)}, ${location.longitude.toStringAsFixed(6)}';
      });
      print('Reverse geocoding error: $e');
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5&countrycodes=dz',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.salimstore.client'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = List<Map<String, dynamic>>.from(data);
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
        });
      }
    } catch (e) {
      print('Error searching address: $e');
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  Future<void> _selectSearchedLocation(Map<String, dynamic> location) async {
    final lat = double.tryParse(location['lat'].toString()) ?? 0.0;
    final lon = double.tryParse(location['lon'].toString()) ?? 0.0;
    final latlng = LatLng(lat, lon);

    setState(() {
      _selectedLocation = latlng;
      _currentLocation = latlng;
      _mapSelectedAddress = location['display_name'];
      _searchResults = [];
      _searchController.clear();
      FocusScope.of(context).unfocus();
    });
    await _moveMap(latlng);
    // We already have the address from Nominatim, but we can refine it or just use it.
    // _detectAddressFromLocation(latlng); // Optional: if we want to stick to geocoding format
  }

  Future<void> _saveMapAddress() async {
    if (_mapSelectedAddress != null && _selectedLocation != null) {
      // Show dialog to name the address
      final result = await _showSaveAddressDialog();
      if (result == null) return; // User cancelled

      final addressLabel = result['label'] as String;
      final setAsDefault = result['setAsDefault'] as bool;

      try {
        final fullAddress = _mapSelectedAddress!;
        final parts = fullAddress.split(', ');

        final addressData = {
          'wilaya': parts.isNotEmpty ? parts[0] : '',
          'commune': parts.length > 1 ? parts[1] : '',
          'fullAddress': fullAddress,
          'label': addressLabel,
          'latitude': _selectedLocation!.latitude,
          'longitude': _selectedLocation!.longitude,
        };

        if (widget.existingAddress != null) {
          // Update existing
          await AddressService.updateAddress(
            widget.existingAddress!['id'],
            addressData,
          );
          if (setAsDefault) {
            await AddressService.setDefaultAddress(
              widget.existingAddress!['id'],
            );
          }
        } else {
          // Add new
          final newId = await AddressService.addAddress(addressData);
          if (setAsDefault && newId != null) {
            await AddressService.setDefaultAddress(newId);
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Adresse "$addressLabel" enregistrée avec succès'),
              backgroundColor: AppTheme.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Erreur lors de l\'enregistrement: ${e.toString()}',
              ),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une position sur la carte'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<Map<String, dynamic>?> _showSaveAddressDialog() async {
    final labelController = TextEditingController(
      text: widget.existingAddress != null
          ? widget.existingAddress!['label']
          : '',
    );
    bool setAsDefault = false; // Default to false

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.existingAddress != null
                      ? 'Modifier l\'adresse'
                      : 'Enregistrer l\'adresse',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.map,
                        size: 18,
                        color: AppTheme.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _mapSelectedAddress ?? '',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: labelController,
                  decoration: InputDecoration(
                    labelText: 'Nom de l\'adresse',
                    hintText: 'Ex: Maison, Bureau, Livraison...',
                    prefixIcon: const Icon(Icons.label_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: setAsDefault,
                  onChanged: (value) {
                    setDialogState(() => setAsDefault = value ?? false);
                  },
                  title: const Text('Définir comme adresse par défaut'),
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (labelController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Veuillez entrer un nom pour l\'adresse',
                            ),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                        return;
                      }
                      Navigator.pop(context, {
                        'label': labelController.text.trim(),
                        'setAsDefault': setAsDefault,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isManual = _mode == 0;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          widget.existingAddress != null
              ? 'Modifier l\'adresse'
              : 'Sélectionner une adresse',
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: _loadingLocation
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 12),
                // Choice bar: Mode selection
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _setMode(0),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isManual
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : null,
                          ),
                          child: Text(
                            'Manuelle',
                            style: TextStyle(
                              color: isManual
                                  ? AppTheme.primaryColor
                                  : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _setMode(1),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: !isManual
                                ? AppTheme.primaryColor.withOpacity(0.1)
                                : null,
                          ),
                          child: Text(
                            'Auto',
                            style: TextStyle(
                              color: !isManual
                                  ? AppTheme.primaryColor
                                  : Colors.black54,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Mode explanation
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isManual ? Icons.touch_app : Icons.my_location,
                        color: AppTheme.primaryColor,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isManual
                              ? 'Tapez sur la carte pour choisir manuellement une adresse'
                              : 'Détectez automatiquement votre position actuelle',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_mode == 0) // Manual mode: show search
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Rechercher une adresse...',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: _searchAddress,
                          onChanged: (value) {
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 500),
                              () {
                                if (value.trim().isNotEmpty) {
                                  _searchAddress(value);
                                } else {
                                  setState(() {
                                    _searchResults = [];
                                    _isSearching = false;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        if (_searchResults.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final location = _searchResults[index];
                                return ListTile(
                                  leading: const Icon(
                                    Icons.location_on_outlined,
                                    size: 20,
                                  ),
                                  title: Text(
                                    location['display_name'] ??
                                        'Adresse inconnue',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                    ),
                                  ),
                                  onTap: () =>
                                      _selectSearchedLocation(location),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                if (_mode == 1) // Auto mode: show detection button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text('Détecter ma position actuelle'),
                        onPressed: _getCurrentLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _selectedLocation ?? _currentLocation,
                      zoom: 15,
                      onTap: (tapPos, latlng) {
                        if (_mode == 0) {
                          setState(() => _selectedLocation = latlng);
                          _detectAddressFromLocation(latlng);
                        }
                      },
                      interactiveFlags: isManual
                          ? InteractiveFlag.all
                          : (InteractiveFlag.pinchZoom | InteractiveFlag.drag),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: 'com.salimsotre.client',
                        maxZoom: 19,
                      ),
                      if (_selectedLocation != null)
                        MarkerLayer(
                          markers: [
                            Marker(
                              point: _selectedLocation!,
                              width: 40,
                              height: 40,
                              child: const Icon(
                                Icons.location_on,
                                size: 40,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                if (_mapSelectedAddress != null)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _mode == 0 ? Icons.place : Icons.my_location,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _mode == 0
                                    ? 'Adresse sélectionnée'
                                    : 'Adresse détectée',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppTheme.primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _mapSelectedAddress!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _saveMapAddress,
                            icon: const Icon(Icons.save_rounded),
                            label: Text(
                              widget.existingAddress != null
                                  ? 'Mettre à jour l\'adresse'
                                  : 'Enregistrer cette adresse',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
