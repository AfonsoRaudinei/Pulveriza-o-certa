import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../domain/calculos/limites_regulagem.dart';
import 'marca_pdf.dart';

enum TemaApp { system, light, dark }

class Configuracoes {
  const Configuracoes({
    this.limiteDesgaste = 105.0,
    this.limiteIrregular = 97.0,
    this.nomeConsultor = '',
    this.empresaNome = '',
    this.registroProfissional = '',
    this.marcaLogoArquivo = '',
    this.corMarcaPdf = CorMarcaPdf.azul,
    this.corMarcaPersonalizadaArgb,
    this.tema = TemaApp.system,
  });

  final double limiteDesgaste;
  final double limiteIrregular;
  final String nomeConsultor;
  final String empresaNome;
  final String registroProfissional;
  final String marcaLogoArquivo;
  final CorMarcaPdf corMarcaPdf;
  final int? corMarcaPersonalizadaArgb;
  final TemaApp tema;

  LimitesRegulagem get limitesRegulagem => LimitesRegulagem(
        limiteEntupido: limiteIrregular,
        limiteDesgaste: limiteDesgaste,
      );

  ThemeMode get themeMode {
    return switch (tema) {
      TemaApp.system => ThemeMode.system,
      TemaApp.light => ThemeMode.light,
      TemaApp.dark => ThemeMode.dark,
    };
  }

  String textoMarcaCabecalho() {
    if (empresaNome.trim().isNotEmpty) return empresaNome.trim();
    if (nomeConsultor.trim().isNotEmpty) return nomeConsultor.trim();
    return AppConstants.appName;
  }

  factory Configuracoes.fromJson(Map<String, dynamic> json) {
    return Configuracoes(
      limiteDesgaste: (json['limiteDesgaste'] as num?)?.toDouble() ?? 105.0,
      limiteIrregular: (json['limiteIrregular'] as num?)?.toDouble() ?? 97.0,
      nomeConsultor: json['nomeConsultor'] as String? ?? '',
      empresaNome: json['empresaNome'] as String? ?? '',
      registroProfissional: json['registroProfissional'] as String? ?? '',
      marcaLogoArquivo: json['marcaLogoArquivo'] as String? ?? '',
      corMarcaPdf: corMarcaPdfFromJson(json['corMarcaPdf']),
      corMarcaPersonalizadaArgb: json['corMarcaPersonalizadaArgb'] as int?,
      tema: _temaFromJson(json['tema']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limiteDesgaste': limiteDesgaste,
      'limiteIrregular': limiteIrregular,
      'nomeConsultor': nomeConsultor,
      'empresaNome': empresaNome,
      'registroProfissional': registroProfissional,
      'marcaLogoArquivo': marcaLogoArquivo,
      'corMarcaPdf': corMarcaPdf.name,
      if (corMarcaPersonalizadaArgb != null)
        'corMarcaPersonalizadaArgb': corMarcaPersonalizadaArgb,
      'tema': tema.name,
    };
  }

  Configuracoes copyWith({
    double? limiteDesgaste,
    double? limiteIrregular,
    String? nomeConsultor,
    String? empresaNome,
    String? registroProfissional,
    String? marcaLogoArquivo,
    CorMarcaPdf? corMarcaPdf,
    int? corMarcaPersonalizadaArgb,
    bool limparCorPersonalizada = false,
    TemaApp? tema,
  }) {
    return Configuracoes(
      limiteDesgaste: limiteDesgaste ?? this.limiteDesgaste,
      limiteIrregular: limiteIrregular ?? this.limiteIrregular,
      nomeConsultor: nomeConsultor ?? this.nomeConsultor,
      empresaNome: empresaNome ?? this.empresaNome,
      registroProfissional: registroProfissional ?? this.registroProfissional,
      marcaLogoArquivo: marcaLogoArquivo ?? this.marcaLogoArquivo,
      corMarcaPdf: corMarcaPdf ?? this.corMarcaPdf,
      corMarcaPersonalizadaArgb: limparCorPersonalizada
          ? null
          : (corMarcaPersonalizadaArgb ?? this.corMarcaPersonalizadaArgb),
      tema: tema ?? this.tema,
    );
  }
}

TemaApp _temaFromJson(Object? value) {
  return switch (value) {
    'light' => TemaApp.light,
    'dark' => TemaApp.dark,
    _ => TemaApp.system,
  };
}
