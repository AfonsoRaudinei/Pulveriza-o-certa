import 'package:intl/intl.dart';

extension DoubleExtension on double {
  String toMoeda() {
    return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(this);
  }

  String toPercent({int casas = 1}) {
    return NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: casas,
    ).format(this) +
        '%';
  }

  String toLitroMin() {
    return '${NumberFormat.decimalPatternDigits(locale: 'pt_BR', decimalDigits: 3).format(this)} L/min';
  }
}
