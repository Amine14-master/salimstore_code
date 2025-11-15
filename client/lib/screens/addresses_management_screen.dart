import 'package:flutter/material.dart';
import '../services/address_service.dart';
import '../theme/app_theme.dart';
import 'address_picker_screen.dart';

class AddressesManagementScreen extends StatefulWidget {
  const AddressesManagementScreen({super.key});

  @override
  State<AddressesManagementScreen> createState() =>
      _AddressesManagementScreenState();
}

class _AddressesManagementScreenState extends State<AddressesManagementScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;
  String? _defaultAddressId;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _loading = true);
    try {
      final addresses = await AddressService.getAddresses();
      final defaultAddr = await AddressService.getDefaultAddress();

      setState(() {
        _addresses = addresses;
        _defaultAddressId = defaultAddr?['id'];
        _loading = false;
      });
    } catch (e) {
      print('Error loading addresses: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _setAsDefault(String addressId, String fullAddress) async {
    try {
      await AddressService.setDefaultAddress(addressId);
      await _loadAddresses();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adresse par défaut mise à jour'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _editAddress(Map<String, dynamic> address) async {
    final labelController = TextEditingController(text: address['label'] ?? '');
    final fullAddressController = TextEditingController(
      text: address['fullAddress'] ?? '',
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.edit_location_alt, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            const Expanded(child: Text('Modifier l\'adresse')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'adresse',
                  prefixIcon: const Icon(Icons.label_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fullAddressController,
                decoration: InputDecoration(
                  labelText: 'Adresse complète',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (labelController.text.trim().isEmpty ||
                  fullAddressController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez remplir tous les champs'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await AddressService.updateAddress(address['id'], {
          'label': labelController.text.trim(),
          'fullAddress': fullAddressController.text.trim(),
        });
        await _loadAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse mise à jour'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAddress(String addressId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'adresse'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette adresse ?',
        ),
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
      try {
        await AddressService.removeAddress(addressId);
        await _loadAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adresse supprimée'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: ${e.toString()}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => Navigator.pop(context),
                      color: AppTheme.primaryColor,
                    ),
                    Expanded(
                      child: Text(
                        'Mes Adresses',
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddressPickerScreen(),
                          ),
                        );
                        if (result == true) {
                          await _loadAddresses();
                        }
                      },
                      color: AppTheme.primaryColor,
                      tooltip: 'Ajouter une adresse',
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _addresses.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune adresse enregistrée',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Ajoutez une adresse pour commencer',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AddressPickerScreen(),
                                    ),
                                  );
                                  if (result == true) {
                                    await _loadAddresses();
                                  }
                                },
                                icon: const Icon(Icons.add),
                                label: const Text('Ajouter une adresse'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _addresses.length,
                        itemBuilder: (context, index) {
                          final address = _addresses[index];
                          final isDefault = address['id'] == _defaultAddressId;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDefault
                                    ? AppTheme.primaryColor
                                    : Colors.grey[300]!,
                                width: isDefault ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.location_on,
                                color: isDefault
                                    ? AppTheme.primaryColor
                                    : AppTheme.textSecondary,
                              ),
                              title: Text(
                                address['label'] ?? 'Adresse',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDefault
                                      ? AppTheme.primaryColor
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              subtitle: Text(
                                address['fullAddress'] ?? '',
                                style: TextStyle(color: AppTheme.textSecondary),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isDefault)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Par défaut',
                                        style: TextStyle(
                                          color: AppTheme.primaryColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editAddress(address),
                                    tooltip: 'Modifier',
                                    color: AppTheme.primaryColor,
                                  ),
                                  if (!isDefault)
                                    IconButton(
                                      icon: const Icon(
                                        Icons.check_circle_outline,
                                      ),
                                      onPressed: () => _setAsDefault(
                                        address['id'],
                                        address['fullAddress'] ?? '',
                                      ),
                                      tooltip: 'Définir par défaut',
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () =>
                                        _deleteAddress(address['id']),
                                    tooltip: 'Supprimer',
                                    color: AppTheme.errorColor,
                                  ),
                                ],
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
    );
  }
}
