import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      'active' => (AppColors.success50, AppColors.success700),
      'scheduled' => (AppColors.info50, AppColors.info700),
      'closed' => (AppColors.zinc100, AppColors.zinc700),
      _ => (AppColors.accent50, AppColors.accent700),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.$2.withValues(alpha: 0.22)),
      ),
      child: Text(
        statusLabel(status),
        style: TextStyle(
          color: colors.$2,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }
}
