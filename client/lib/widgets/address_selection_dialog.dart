import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/city_service.dart';
import '../theme/app_theme.dart';

class AddressSelectionDialog extends StatefulWidget {
  final String? currentAddress;

  const AddressSelectionDialog({super.key, this.currentAddress});

  @override
  State<AddressSelectionDialog> createState() => _AddressSelectionDialogState();
}

class _AddressSelectionDialogState extends State<AddressSelectionDialog> {
  String? _selectedWilaya;
  String? _selectedCommune;
  List<String> _wilayas = [];
  List<String> _communes = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadCities();
  }

  Future<void> _loadCities() async {
    setState(() => _loading = true);
    try {
      if (!CityService.isLoaded()) {
        final String jsonString = await rootBundle.loadString(
          'lib/data/algeria_cities.json',
        );
        await CityService.loadCities(jsonString);
      }
      setState(() {
        _wilayas = CityService.getWilayas();
        _loading = false;
      });
    } catch (e) {
      print('Error loading cities: $e');
      setState(() => _loading = false);
    }
  }

  void _onWilayaChanged(String? wilaya) {
    setState(() {
      _selectedWilaya = wilaya;
      _selectedCommune = null;
      _communes = wilaya != null
          ? CityService.getCommunesForWilaya(wilaya)
          : [];
    });
  }

  void _saveAddress() {
    if (_selectedWilaya != null && _selectedCommune != null) {
      final address = '$_selectedWilaya, $_selectedCommune';
      Navigator.pop(context, address);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une wilaya et une commune'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sélectionner l\'adresse',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Wilaya dropdown
                  Text(
                    'Wilaya',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedWilaya,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      hint: const Text('Sélectionner une wilaya'),
                      items: _wilayas.map((wilaya) {
                        return DropdownMenuItem(
                          value: wilaya,
                          child: Text(wilaya),
                        );
                      }).toList(),
                      onChanged: _onWilayaChanged,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Commune dropdown
                  Text(
                    'Commune',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedCommune,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      hint: Text(
                        _selectedWilaya == null
                            ? 'Sélectionner d\'abord une wilaya'
                            : 'Sélectionner une commune',
                      ),
                      items: _communes.map((commune) {
                        return DropdownMenuItem(
                          value: commune,
                          child: Text(commune),
                        );
                      }).toList(),
                      onChanged: _selectedWilaya != null
                          ? (value) {
                              setState(() => _selectedCommune = value);
                            }
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saveAddress,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Enregistrer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}









