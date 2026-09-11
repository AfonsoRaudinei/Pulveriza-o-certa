import 'enums_ordem.dart';

class ExecucaoAplicacao {
  const ExecucaoAplicacao({
    this.responsavel,
    this.maquinaId,
    this.maquinaNome,
    this.inicio,
    this.fim,
    this.temperaturaC,
    this.umidadePct,
    this.ventoKmh,
    this.volumeCaldaLha,
    this.darSaidaEstoque = false,
    this.status = StatusOrdem.aberta,
  });

  final String? responsavel;
  final String? maquinaId;
  final String? maquinaNome;
  final DateTime? inicio;
  final DateTime? fim;
  final double? temperaturaC;
  final double? umidadePct;
  final double? ventoKmh;
  final double? volumeCaldaLha;
  final bool darSaidaEstoque;
  final StatusOrdem status;

  factory ExecucaoAplicacao.fromJson(Map<String, dynamic> json) {
    return ExecucaoAplicacao(
      responsavel: json['responsavel'] as String?,
      maquinaId: json['maquinaId'] as String?,
      maquinaNome: json['maquinaNome'] as String?,
      inicio: json['inicio'] == null
          ? null
          : DateTime.tryParse(json['inicio'] as String),
      fim:
          json['fim'] == null ? null : DateTime.tryParse(json['fim'] as String),
      temperaturaC: (json['temperaturaC'] as num?)?.toDouble(),
      umidadePct: (json['umidadePct'] as num?)?.toDouble(),
      ventoKmh: (json['ventoKmh'] as num?)?.toDouble(),
      volumeCaldaLha: (json['volumeCaldaLha'] as num?)?.toDouble(),
      darSaidaEstoque: json['darSaidaEstoque'] as bool? ?? false,
      status: StatusOrdem.values.byName(json['status'] as String? ?? 'aberta'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responsavel': responsavel,
      'maquinaId': maquinaId,
      'maquinaNome': maquinaNome,
      'inicio': inicio?.toIso8601String(),
      'fim': fim?.toIso8601String(),
      'temperaturaC': temperaturaC,
      'umidadePct': umidadePct,
      'ventoKmh': ventoKmh,
      'volumeCaldaLha': volumeCaldaLha,
      'darSaidaEstoque': darSaidaEstoque,
      'status': status.name,
    };
  }

  ExecucaoAplicacao copyWith({
    String? responsavel,
    String? maquinaId,
    String? maquinaNome,
    DateTime? inicio,
    DateTime? fim,
    double? temperaturaC,
    double? umidadePct,
    double? ventoKmh,
    double? volumeCaldaLha,
    bool? darSaidaEstoque,
    StatusOrdem? status,
  }) {
    return ExecucaoAplicacao(
      responsavel: responsavel ?? this.responsavel,
      maquinaId: maquinaId ?? this.maquinaId,
      maquinaNome: maquinaNome ?? this.maquinaNome,
      inicio: inicio ?? this.inicio,
      fim: fim ?? this.fim,
      temperaturaC: temperaturaC ?? this.temperaturaC,
      umidadePct: umidadePct ?? this.umidadePct,
      ventoKmh: ventoKmh ?? this.ventoKmh,
      volumeCaldaLha: volumeCaldaLha ?? this.volumeCaldaLha,
      darSaidaEstoque: darSaidaEstoque ?? this.darSaidaEstoque,
      status: status ?? this.status,
    );
  }
}
