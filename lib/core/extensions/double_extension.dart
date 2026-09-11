import 'package:intl/intl.dart';

extension DoubleExtension on double {
  String toMoeda() {
    return NumberFormat.currency(locale: 'pt_BR', symbol: r'R$').format(this);
  }

  String toPercent({int casas = 1}) {
    return '${toStringAsFixed(casas)}%';
  }

  String toLitroMin() {
    return '${toStringAsFixed(3)} L/min';
  }
}
