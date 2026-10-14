import 'package:uuid/uuid.dart';

class ProdutoManejo {
  const ProdutoManejo({
    required this.id,
    required this.nome,
    required this.dose,
    required this.valorUnitario,
  });

  final String id;
  final String nome;
  final double dose;
  final double valorUnitario;

  factory ProdutoManejo.fromJson(Map<String, dynamic> json) {
    return ProdutoManejo(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      dose: (json['dose'] as num?)?.toDouble() ?? 0,
      valorUnitario: (json['valorUnitario'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'dose': dose,
        'valorUnitario': valorUnitario,
      };

  ProdutoManejo copyWith({
    String? nome,
    double? dose,
    double? valorUnitario,
  }) {
    return ProdutoManejo(
      id: id,
      nome: nome ?? this.nome,
      dose: dose ?? this.dose,
      valorUnitario: valorUnitario ?? this.valorUnitario,
    );
  }
}

class AplicacaoManejo {
  const AplicacaoManejo({
    required this.id,
    required this.rotulo,
    required this.produtos,
  });

  final String id;
  final String rotulo;
  final List<ProdutoManejo> produtos;

  factory AplicacaoManejo.fromJson(Map<String, dynamic> json) {
    return AplicacaoManejo(
      id: json['id'] as String,
      rotulo: json['rotulo'] as String? ?? '',
      produtos: ((json['produtos'] as List<dynamic>?) ?? [])
          .map((e) => ProdutoManejo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'rotulo': rotulo,
        'produtos': produtos.map((p) => p.toJson()).toList(),
      };

  AplicacaoManejo copyWith({
    String? rotulo,
    List<ProdutoManejo>? produtos,
  }) {
    return AplicacaoManejo(
      id: id,
      rotulo: rotulo ?? this.rotulo,
      produtos: produtos ?? this.produtos,
    );
  }
}

class CustoManejo {
  const CustoManejo({
    required this.id,
    required this.nome,
    required this.aplicacoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;
  final String nome;
  final List<AplicacaoManejo> aplicacoes;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  factory CustoManejo.fromJson(Map<String, dynamic> json) {
    return CustoManejo(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      aplicacoes: ((json['aplicacoes'] as List<dynamic>?) ?? [])
          .map((e) => AplicacaoManejo.fromJson(e as Map<String, dynamic>))
          .toList(),
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'aplicacoes': aplicacoes.map((a) => a.toJson()).toList(),
        'criadoEm': criadoEm.toIso8601String(),
        'atualizadoEm': atualizadoEm.toIso8601String(),
      };

  CustoManejo copyWith({
    String? nome,
    List<AplicacaoManejo>? aplicacoes,
    DateTime? atualizadoEm,
  }) {
    return CustoManejo(
      id: id,
      nome: nome ?? this.nome,
      aplicacoes: aplicacoes ?? this.aplicacoes,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}

CustoManejo novoCustoManejoRascunho({String? nome}) {
  const uuid = Uuid();
  final now = DateTime.now();
  return CustoManejo(
    id: uuid.v4(),
    nome: nome ?? '',
    aplicacoes: [novaAplicacaoManejo(1)],
    criadoEm: now,
    atualizadoEm: now,
  );
}

AplicacaoManejo novaAplicacaoManejo(int indice) {
  const uuid = Uuid();
  return AplicacaoManejo(
    id: uuid.v4(),
    rotulo: 'Aplicação $indice',
    produtos: [
      ProdutoManejo(id: uuid.v4(), nome: '', dose: 0, valorUnitario: 0),
    ],
  );
}

ProdutoManejo novoProdutoManejo() {
  return ProdutoManejo(
    id: const Uuid().v4(),
    nome: '',
    dose: 0,
    valorUnitario: 0,
  );
}
