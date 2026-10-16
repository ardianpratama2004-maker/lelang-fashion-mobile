import 'package:flutter/material.dart';

void showError(BuildContext context, String message) {
  final clean = message.replaceFirst('Exception: ', '');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(clean)));
}
