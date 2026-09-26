import 'package:flutter/services.dart';

/// Impede mais de [max] dígitos (vírgula e ponto não contam).
class DigitosMaximoFormatter extends TextInputFormatter {
  const DigitosMaximoFormatter([this.max = 7]);

  final int max;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length <= max) return newValue;
    return oldValue;
  }
}
