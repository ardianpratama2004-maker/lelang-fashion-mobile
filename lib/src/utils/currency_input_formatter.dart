import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (newValue.text.compareTo(oldValue.text) != 0) {
      final int selectionIndexFromTheRight =
          newValue.text.length - newValue.selection.end;

      final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
      if (digitsOnly.isEmpty) {
        return newValue.copyWith(text: '');
      }

      final num = int.tryParse(digitsOnly);
      if (num == null) return oldValue;

      final newString = NumberFormat.decimalPattern('id').format(num);

      return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(
          offset: newString.length - selectionIndexFromTheRight,
        ),
      );
    } else {
      return newValue;
    }
  }
}
