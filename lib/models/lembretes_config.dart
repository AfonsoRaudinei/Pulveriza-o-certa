enum CriterioLembrete { tempo, uso }

/// Opções de lembrete de revisão de bicos e backup periódico.
class LembretesConfig {
  const LembretesConfig({
    this.revisaoAtivo = false,
    this.criterio = CriterioLembrete.tempo,
    this.intervaloDias = 30,
    this.intervaloRegulagens = 5,
    this.intervaloPersonalizado = false,
    this.regulagensDesdeUltimoLembrete = 0,
    this.lembreteBackupAtivo = false,
    this.proximoLembreteRevisao,
    this.proximoLembreteBackup,
  });

  final bool revisaoAtivo;
  final CriterioLembrete criterio;
  final int intervaloDias;
  final int intervaloRegulagens;
  final bool intervaloPersonalizado;
  final int regulagensDesdeUltimoLembrete;
  final bool lembreteBackupAtivo;
  final DateTime? proximoLembreteRevisao;
  final DateTime? proximoLembreteBackup;

  static const opcoesDias = [7, 15, 30, 60, 90];
  static const opcoesRegulagens = [3, 5, 10, 20, 50];

  factory LembretesConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const LembretesConfig();
    return LembretesConfig(
      revisaoAtivo: json['revisaoAtivo'] as bool? ?? false,
      criterio: _criterioFromJson(json['criterio']),
      intervaloDias: (json['intervaloDias'] as num?)?.toInt() ?? 30,
      intervaloRegulagens: (json['intervaloRegulagens'] as num?)?.toInt() ?? 5,
      intervaloPersonalizado: json['intervaloPersonalizado'] as bool? ?? false,
      regulagensDesdeUltimoLembrete:
          (json['regulagensDesdeUltimoLembrete'] as num?)?.toInt() ?? 0,
      lembreteBackupAtivo: json['lembreteBackupAtivo'] as bool? ?? false,
      proximoLembreteRevisao: _dateFromJson(json['proximoLembreteRevisao']),
      proximoLembreteBackup: _dateFromJson(json['proximoLembreteBackup']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'revisaoAtivo': revisaoAtivo,
      'criterio': criterio.name,
      'intervaloDias': intervaloDias,
      'intervaloRegulagens': intervaloRegulagens,
      'intervaloPersonalizado': intervaloPersonalizado,
      'regulagensDesdeUltimoLembrete': regulagensDesdeUltimoLembrete,
      'lembreteBackupAtivo': lembreteBackupAtivo,
      if (proximoLembreteRevisao != null)
        'proximoLembreteRevisao': proximoLembreteRevisao!.toIso8601String(),
      if (proximoLembreteBackup != null)
        'proximoLembreteBackup': proximoLembreteBackup!.toIso8601String(),
    };
  }

  LembretesConfig copyWith({
    bool? revisaoAtivo,
    CriterioLembrete? criterio,
    int? intervaloDias,
    int? intervaloRegulagens,
    bool? intervaloPersonalizado,
    int? regulagensDesdeUltimoLembrete,
    bool? lembreteBackupAtivo,
    DateTime? proximoLembreteRevisao,
    DateTime? proximoLembreteBackup,
    bool limparProximoRevisao = false,
    bool limparProximoBackup = false,
  }) {
    return LembretesConfig(
      revisaoAtivo: revisaoAtivo ?? this.revisaoAtivo,
      criterio: criterio ?? this.criterio,
      intervaloDias: intervaloDias ?? this.intervaloDias,
      intervaloRegulagens: intervaloRegulagens ?? this.intervaloRegulagens,
      intervaloPersonalizado:
          intervaloPersonalizado ?? this.intervaloPersonalizado,
      regulagensDesdeUltimoLembrete:
          regulagensDesdeUltimoLembrete ?? this.regulagensDesdeUltimoLembrete,
      lembreteBackupAtivo: lembreteBackupAtivo ?? this.lembreteBackupAtivo,
      proximoLembreteRevisao: limparProximoRevisao
          ? null
          : (proximoLembreteRevisao ?? this.proximoLembreteRevisao),
      proximoLembreteBackup: limparProximoBackup
          ? null
          : (proximoLembreteBackup ?? this.proximoLembreteBackup),
    );
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static CriterioLembrete _criterioFromJson(Object? value) {
    return switch (value) {
      'uso' => CriterioLembrete.uso,
      _ => CriterioLembrete.tempo,
    };
  }
}
