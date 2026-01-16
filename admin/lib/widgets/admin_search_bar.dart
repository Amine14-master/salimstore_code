import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AdminSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String hintText;
  final EdgeInsetsGeometry? margin;
  final Widget? trailing;
  final bool enabled;
  final TextInputAction textInputAction;
  final VoidCallback? onTap;

  const AdminSearchBar({
    super.key,
    this.controller,
    this.onChanged,
    required this.hintText,
    this.margin,
    this.trailing,
    this.enabled = true,
    this.textInputAction = TextInputAction.search,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        onChanged: onChanged,
        textInputAction: textInputAction,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        onTap: onTap,
        decoration: InputDecoration(
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppTheme.textSecondary,
          ),
          suffixIcon: trailing,
          hintText: hintText,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
