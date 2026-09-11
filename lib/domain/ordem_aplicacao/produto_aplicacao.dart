import 'calc_quantidade_total.dart';
import 'calc_totais_unidade.dart';

class ProdutoAplicacao {
  const ProdutoAplicacao({
    required this.id,
    required this.produtoId,
    required this.nomeProduto,
    required this.dose,
    required this.unidade,
    this.reservarEstoque = false,
    this.observacao,
  });

  final String id;
  final String produtoId;
  final String nomeProduto;
  final double dose;
  final UnidadeDose unidade;
  final bool reservarEstoque;
  final String? observacao;

  double quantidadeTotal(double areaAplicar) {
    return calcularQuantidadeTotal(dose: dose, areaAplicar: areaAplicar);
  }

  factory ProdutoAplicacao.fromJson(Map<String, dynamic> json) {
    return ProdutoAplicacao(
      id: json['id'] as String,
      produtoId: json['produtoId'] as String? ?? '',
      nomeProduto: json['nomeProduto'] as String? ?? '',
      dose: (json['dose'] as num?)?.toDouble() ?? 0,
      unidade: UnidadeDose.values.byName(json['unidade'] as String? ?? 'lHa'),
      reservarEstoque: json['reservarEstoque'] as bool? ?? false,
      observacao: json['observacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produtoId': produtoId,
      'nomeProduto': nomeProduto,
      'dose': dose,
      'unidade': unidade.name,
      'reservarEstoque': reservarEstoque,
      'observacao': observacao,
    };
  }
}
