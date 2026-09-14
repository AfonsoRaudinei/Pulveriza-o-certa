import 'package:flutter/material.dart';

import 'lembretes_config.dart';
import 'perfil_relatorio.dart';

enum TemaApp { system, light, dark }

class Configuracoes {
  const Configuracoes({
    this.limiteDesgaste = 105.0,
    this.limiteIrregular = 100.0,
    this.toleranciaMin = 100.5,
    this.toleranciaMax = 104.99,
    this.perfilRelatorio = const PerfilRelatorio(),
    this.tema = TemaApp.system,
    this.lembretes = const LembretesConfig(),
    this.ultimoBackup,
  });

  final double limiteDesgaste;
  final double limiteIrregular;
  final double toleranciaMin;
  final double toleranciaMax;
  final PerfilRelatorio perfilRelatorio;
  final TemaApp tema;
  final LembretesConfig lembretes;
  final DateTime? ultimoBackup;

  /// Campos legados — leitura apenas para compatibilidade.
  String get nomeConsultor => perfilRelatorio.nomeConsultor;
  String get empresaNome => perfilRelatorio.empresaNome;

  ThemeMode get themeMode {
    return switch (tema) {
      TemaApp.system => ThemeMode.system,
      TemaApp.light => ThemeMode.light,
      TemaApp.dark => ThemeMode.dark,
    };
  }

  factory Configuracoes.fromJson(Map<String, dynamic> json) {
    final perfilRaw = json['perfilRelatorio'];
    final perfil = perfilRaw is Map<String, dynamic>
        ? PerfilRelatorio.fromJson(perfilRaw)
        : PerfilRelatorio.fromLegado(json);

    return Configuracoes(
      limiteDesgaste: (json['limiteDesgaste'] as num?)?.toDouble() ?? 105.0,
      limiteIrregular: (json['limiteIrregular'] as num?)?.toDouble() ?? 100.0,
      toleranciaMin: (json['toleranciaMin'] as num?)?.toDouble() ?? 100.5,
      toleranciaMax: (json['toleranciaMax'] as num?)?.toDouble() ?? 104.99,
      perfilRelatorio: perfil,
      tema: _temaFromJson(json['tema']),
      lembretes: LembretesConfig.fromJson(
        json['lembretes'] as Map<String, dynamic>?,
      ),
      ultimoBackup: _dateFromJson(json['ultimoBackup']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limiteDesgaste': limiteDesgaste,
      'limiteIrregular': limiteIrregular,
      'toleranciaMin': toleranciaMin,
      'toleranciaMax': toleranciaMax,
      'perfilRelatorio': perfilRelatorio.toJson(),
      'nomeConsultor': perfilRelatorio.nomeConsultor,
      'empresaNome': perfilRelatorio.empresaNome,
      'tema': tema.name,
      'lembretes': lembretes.toJson(),
      if (ultimoBackup != null) 'ultimoBackup': ultimoBackup!.toIso8601String(),
    };
  }

  Configuracoes copyWith({
    double? limiteDesgaste,
    double? limiteIrregular,
    double? toleranciaMin,
    double? toleranciaMax,
    PerfilRelatorio? perfilRelatorio,
    TemaApp? tema,
    LembretesConfig? lembretes,
    DateTime? ultimoBackup,
    bool limparUltimoBackup = false,
  }) {
    return Configuracoes(
      limiteDesgaste: limiteDesgaste ?? this.limiteDesgaste,
      limiteIrregular: limiteIrregular ?? this.limiteIrregular,
      toleranciaMin: toleranciaMin ?? this.toleranciaMin,
      toleranciaMax: toleranciaMax ?? this.toleranciaMax,
      perfilRelatorio: perfilRelatorio ?? this.perfilRelatorio,
      tema: tema ?? this.tema,
      lembretes: lembretes ?? this.lembretes,
      ultimoBackup:
          limparUltimoBackup ? null : (ultimoBackup ?? this.ultimoBackup),
    );
  }

  static TemaApp _temaFromJson(Object? value) {
    return switch (value) {
      'light' => TemaApp.light,
      'dark' => TemaApp.dark,
      _ => TemaApp.system,
    };
  }

  static DateTime? _dateFromJson(Object? value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
