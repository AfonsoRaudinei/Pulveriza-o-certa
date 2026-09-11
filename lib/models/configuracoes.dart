import 'package:flutter/material.dart';

enum TemaApp { system, light, dark }

class Configuracoes {
  const Configuracoes({
    this.limiteDesgaste = 105.0,
    this.limiteIrregular = 100.0,
    this.toleranciaMin = 100.5,
    this.toleranciaMax = 104.99,
    this.nomeConsultor = '',
    this.empresaNome = '',
    this.tema = TemaApp.system,
  });

  final double limiteDesgaste;
  final double limiteIrregular;
  final double toleranciaMin;
  final double toleranciaMax;
  final String nomeConsultor;
  final String empresaNome;
  final TemaApp tema;

  ThemeMode get themeMode {
    return switch (tema) {
      TemaApp.system => ThemeMode.system,
      TemaApp.light => ThemeMode.light,
      TemaApp.dark => ThemeMode.dark,
    };
  }

  factory Configuracoes.fromJson(Map<String, dynamic> json) {
    return Configuracoes(
      limiteDesgaste: (json['limiteDesgaste'] as num?)?.toDouble() ?? 105.0,
      limiteIrregular: (json['limiteIrregular'] as num?)?.toDouble() ?? 100.0,
      toleranciaMin: (json['toleranciaMin'] as num?)?.toDouble() ?? 100.5,
      toleranciaMax: (json['toleranciaMax'] as num?)?.toDouble() ?? 104.99,
      nomeConsultor: json['nomeConsultor'] as String? ?? '',
      empresaNome: json['empresaNome'] as String? ?? '',
      tema: _temaFromJson(json['tema']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limiteDesgaste': limiteDesgaste,
      'limiteIrregular': limiteIrregular,
      'toleranciaMin': toleranciaMin,
      'toleranciaMax': toleranciaMax,
      'nomeConsultor': nomeConsultor,
      'empresaNome': empresaNome,
      'tema': tema.name,
    };
  }

  Configuracoes copyWith({
    double? limiteDesgaste,
    double? limiteIrregular,
    double? toleranciaMin,
    double? toleranciaMax,
    String? nomeConsultor,
    String? empresaNome,
    TemaApp? tema,
  }) {
    return Configuracoes(
      limiteDesgaste: limiteDesgaste ?? this.limiteDesgaste,
      limiteIrregular: limiteIrregular ?? this.limiteIrregular,
      toleranciaMin: toleranciaMin ?? this.toleranciaMin,
      toleranciaMax: toleranciaMax ?? this.toleranciaMax,
      nomeConsultor: nomeConsultor ?? this.nomeConsultor,
      empresaNome: empresaNome ?? this.empresaNome,
      tema: tema ?? this.tema,
    );
  }

  static TemaApp _temaFromJson(Object? value) {
    return switch (value) {
      'light' => TemaApp.light,
      'dark' => TemaApp.dark,
      _ => TemaApp.system,
    };
  }
}
