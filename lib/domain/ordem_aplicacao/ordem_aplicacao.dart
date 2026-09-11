import 'anexo_aplicacao.dart';
import 'enums_ordem.dart';
import 'execucao_aplicacao.dart';
import 'produto_aplicacao.dart';

class OrdemAplicacao {
  const OrdemAplicacao({
    required this.id,
    this.clienteId,
    this.clienteNome = '',
    this.fazendaId,
    this.fazendaNome = '',
    this.talhaoId,
    this.talhaoNome = '',
    this.areaTalhaoHa = 0,
    this.areaAplicar = 0,
    this.alvo,
    this.produtos = const [],
    this.execucao = const ExecucaoAplicacao(),
    this.anexos = const [],
    this.estoqueBaixado = false,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;
  final String? clienteId;
  final String clienteNome;
  final String? fazendaId;
  final String fazendaNome;
  final String? talhaoId;
  final String talhaoNome;
  final double areaTalhaoHa;
  final double areaAplicar;
  final AlvoAplicacao? alvo;
  final List<ProdutoAplicacao> produtos;
  final ExecucaoAplicacao execucao;
  final List<AnexoAplicacao> anexos;
  final bool estoqueBaixado;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  bool get etapa1Completa =>
      clienteNome.trim().isNotEmpty &&
      talhaoNome.trim().isNotEmpty &&
      areaAplicar > 0 &&
      alvo != null;

  bool get etapa2Completa => produtos.isNotEmpty;

  factory OrdemAplicacao.fromJson(Map<String, dynamic> json) {
    return OrdemAplicacao(
      id: json['id'] as String,
      clienteId: json['clienteId'] as String?,
      clienteNome: json['clienteNome'] as String? ?? '',
      fazendaId: json['fazendaId'] as String?,
      fazendaNome: json['fazendaNome'] as String? ?? '',
      talhaoId: json['talhaoId'] as String?,
      talhaoNome: json['talhaoNome'] as String? ?? '',
      areaTalhaoHa: (json['areaTalhaoHa'] as num?)?.toDouble() ?? 0,
      areaAplicar: (json['areaAplicar'] as num?)?.toDouble() ?? 0,
      alvo: json['alvo'] == null
          ? null
          : AlvoAplicacao.values.byName(json['alvo'] as String),
      produtos: (json['produtos'] as List<dynamic>? ?? [])
          .map(
            (item) => ProdutoAplicacao.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      execucao: json['execucao'] == null
          ? const ExecucaoAplicacao()
          : ExecucaoAplicacao.fromJson(
              json['execucao'] as Map<String, dynamic>,
            ),
      anexos: (json['anexos'] as List<dynamic>? ?? [])
          .map((item) => AnexoAplicacao.fromJson(item as Map<String, dynamic>))
          .toList(),
      estoqueBaixado: json['estoqueBaixado'] as bool? ?? false,
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clienteId': clienteId,
      'clienteNome': clienteNome,
      'fazendaId': fazendaId,
      'fazendaNome': fazendaNome,
      'talhaoId': talhaoId,
      'talhaoNome': talhaoNome,
      'areaTalhaoHa': areaTalhaoHa,
      'areaAplicar': areaAplicar,
      'alvo': alvo?.name,
      'produtos': produtos.map((item) => item.toJson()).toList(),
      'execucao': execucao.toJson(),
      'anexos': anexos.map((item) => item.toJson()).toList(),
      'estoqueBaixado': estoqueBaixado,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }

  OrdemAplicacao copyWith({
    String? clienteId,
    String? clienteNome,
    String? fazendaId,
    String? fazendaNome,
    String? talhaoId,
    String? talhaoNome,
    double? areaTalhaoHa,
    double? areaAplicar,
    AlvoAplicacao? alvo,
    List<ProdutoAplicacao>? produtos,
    ExecucaoAplicacao? execucao,
    List<AnexoAplicacao>? anexos,
    bool? estoqueBaixado,
    DateTime? atualizadoEm,
    bool limparAlvo = false,
  }) {
    return OrdemAplicacao(
      id: id,
      clienteId: clienteId ?? this.clienteId,
      clienteNome: clienteNome ?? this.clienteNome,
      fazendaId: fazendaId ?? this.fazendaId,
      fazendaNome: fazendaNome ?? this.fazendaNome,
      talhaoId: talhaoId ?? this.talhaoId,
      talhaoNome: talhaoNome ?? this.talhaoNome,
      areaTalhaoHa: areaTalhaoHa ?? this.areaTalhaoHa,
      areaAplicar: areaAplicar ?? this.areaAplicar,
      alvo: limparAlvo ? null : (alvo ?? this.alvo),
      produtos: produtos ?? this.produtos,
      execucao: execucao ?? this.execucao,
      anexos: anexos ?? this.anexos,
      estoqueBaixado: estoqueBaixado ?? this.estoqueBaixado,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm ?? this.atualizadoEm,
    );
  }
}
