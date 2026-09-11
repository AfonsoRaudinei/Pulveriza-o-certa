import '../../models/configuracoes.dart';
import '../../models/regulagem.dart';
import 'calc_percentual_ponta.dart';

StatusPonta classificarPonta({
  required double? valorMedido,
  required double litroMinIdeal,
  required Configuracoes configuracoes,
}) {
  if (valorMedido == null || litroMinIdeal <= 0) {
    return StatusPonta.pendente;
  }
  if (valorMedido <= 0) return StatusPonta.irregular;

  final percentual = calcularPercentualPonta(
    valorMedido: valorMedido,
    litroMinIdeal: litroMinIdeal,
  );
  if (percentual > configuracoes.limiteDesgaste) {
    return StatusPonta.desgaste;
  }
  if (percentual < configuracoes.limiteIrregular) {
    return StatusPonta.irregular;
  }
  return StatusPonta.ideal;
}
