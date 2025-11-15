import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable export button with shimmer overlay for PDF actions.
class ExportPdfButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  final String label;

  const ExportPdfButton({
    super.key,
    required this.busy,
    required this.onPressed,
    this.label = 'Exporter en PDF',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: busy ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      icon: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            )
          : const Icon(Icons.picture_as_pdf_rounded),
      label: Text(
        busy ? 'Export en cours...' : label,
        style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.4),
      ),
    );
  }
}
