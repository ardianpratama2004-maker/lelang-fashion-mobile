import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/snackbar.dart';
import '../domain/settlement_repository.dart';

Future<void> openSettlementCheckout(
  BuildContext context,
  SettlementRepository repository,
  int settlementId,
) async {
  try {
    final paymentUrl = await repository.startPayment(settlementId);
    final uri = Uri.tryParse(paymentUrl);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Tautan pembayaran Duitku tidak valid.');
    }

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw StateError('Browser tidak dapat membuka halaman pembayaran.');
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selesaikan pembayaran di halaman Duitku.'),
        ),
      );
    }
  } catch (error) {
    if (context.mounted) showError(context, error.toString());
  }
}
