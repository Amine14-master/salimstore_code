import 'package:flutter/material.dart';
import '../services/realtime_database_service.dart';

class DeliveryPricesDialog {
  static void show(BuildContext context) async {
    final prices = await RealtimeDatabaseService.getDeliveryPrices();
    final bejaiaController = TextEditingController(
      text: prices['bejaiaCityFee'].toString(),
    );
    final otherController = TextEditingController(
      text: prices['otherWilayaFee'].toString(),
    );

    if (!context.mounted) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'DeliveryPrices',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  const Icon(Icons.local_shipping_rounded, color: Colors.red),
                  const SizedBox(width: 10),
                  const Text('Prix de livraison'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: bejaiaController,
                    decoration: const InputDecoration(
                      labelText: 'Prix Béjaïa',
                      suffixText: 'DA',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: otherController,
                    decoration: const InputDecoration(
                      labelText: 'Prix Hors Béjaïa',
                      suffixText: 'DA',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final bejaiaFee = double.tryParse(bejaiaController.text);
                    final otherFee = double.tryParse(otherController.text);
                    if (bejaiaFee != null && otherFee != null) {
                      await RealtimeDatabaseService.updateDeliveryPrices(
                        bejaiaFee,
                        otherFee,
                      );
                      if (context.mounted) Navigator.pop(context);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Prix mis à jour avec succès !'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Enregistrer les modifications'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
