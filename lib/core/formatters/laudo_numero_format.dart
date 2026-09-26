import 'package:intl/intl.dart';

/// Formatação numérica pt-BR para laudo PDF e telas alinhadas ao laudo.
class LaudoNumeroFormat {
  LaudoNumeroFormat._();

  static String decimal(double valor, {int casas = 1}) {
    final fmt = NumberFormat.decimalPatternDigits(
      locale: 'pt_BR',
      decimalDigits: casas,
    );
    return fmt.format(valor);
  }

  static String percentual(double valor, {int casas = 1}) =>
      '${decimal(valor, casas: casas)}%';

  static String litroMin(double valor) => '${decimal(valor, casas: 3)} L/min';

  static String vazaoLha(double valor) => '${decimal(valor, casas: 1)} L/ha';

  static String kmh(double valor) => '${decimal(valor, casas: 1)} km/h';

  static String cm(double valor) => '${decimal(valor, casas: 1)} cm';

  static String bar(double valor) => '${decimal(valor, casas: 1)} bar';

  static String hectares(double valor) {
    final s = decimal(valor, casas: 1);
    return s.endsWith(',0') ? '${decimal(valor, casas: 0)} ha' : '$s ha';
  }

  static String rotuloIdealGrafico(double litroMinIdeal) =>
      'Ideal · ${litroMin(litroMinIdeal)}';
}
