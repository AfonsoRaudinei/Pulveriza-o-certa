import '../../models/regulagem.dart';
import 'calc_percentual_ponta.dart';
import 'limites_regulagem.dart';

StatusPonta classificarPonta({
  required double? valorMedido,
  required double litroMinIdeal,
  required LimitesRegulagem limites,
}) {
  if (valorMedido == null || litroMinIdeal <= 0) {
    return StatusPonta.pendente;
  }
  if (valorMedido <= 0) return StatusPonta.irregular;

  final percentual = calcularPercentualPonta(
    valorMedido: valorMedido,
    litroMinIdeal: litroMinIdeal,
  );
  if (percentual > limites.limiteDesgaste) {
    return StatusPonta.desgaste;
  }
  if (percentual < limites.limiteEntupido) {
    return StatusPonta.irregular;
  }
  if (percentual > 100) {
    return StatusPonta.atencao;
  }
  return StatusPonta.ideal;
}

LimitesRegulagem limitesDeConfig({
  required double limiteIrregular,
  required double limiteDesgaste,
}) {
  return LimitesRegulagem(
    limiteEntupido: limiteIrregular,
    limiteDesgaste: limiteDesgaste,
  );
}
