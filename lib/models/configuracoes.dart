import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../domain/calculos/limites_regulagem.dart';
import 'marca_pdf.dart';
import 'tipo_cabecalho_laudo.dart';

enum TemaApp { system, light, dark }

class Configuracoes {
  const Configuracoes({
    this.limiteDesgaste = 105.0,
    this.limiteIrregular = 97.0,
    this.nomeConsultor = '',
    this.empresaNome = '',
    this.contatoPerfil = '',
    this.emailPerfil = '',
    this.registroProfissional = '',
    this.marcaLogoArquivo = '',
    this.corMarcaPdf = CorMarcaPdf.azul,
    this.corMarcaPersonalizadaArgb,
    this.tipoCabecalhoLaudo = TipoCabecalhoLaudo.solida,
    this.corMarcaGradienteInicioPdf = CorMarcaPdf.azul,
    this.corMarcaGradienteFimPdf = CorMarcaPdf.verde,
    this.corMarcaGradienteInicioArgb,
    this.corMarcaGradienteFimArgb,
    this.marcaFundoCabecalhoArquivo = '',
    this.tema = TemaApp.system,
  });

  final double limiteDesgaste;
  final double limiteIrregular;
  final String nomeConsultor;
  final String empresaNome;
  final String contatoPerfil;
  final String emailPerfil;
  final String registroProfissional;
  final String marcaLogoArquivo;
  final CorMarcaPdf corMarcaPdf;
  final int? corMarcaPersonalizadaArgb;
  final TipoCabecalhoLaudo tipoCabecalhoLaudo;
  final CorMarcaPdf corMarcaGradienteInicioPdf;
  final CorMarcaPdf corMarcaGradienteFimPdf;
  final int? corMarcaGradienteInicioArgb;
  final int? corMarcaGradienteFimArgb;
  final String marcaFundoCabecalhoArquivo;
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

  /// E-mail e contato em uma linha para o cabeçalho do laudo (e-mail antes do telefone).
  String? linhaContatoPerfilLaudo() {
    final partes = <String>[];
    final email = emailPerfil.trim();
    final contato = contatoPerfil.trim();
    if (email.isNotEmpty) partes.add(email);
    if (contato.isNotEmpty) partes.add(contato);
    if (partes.isEmpty) return null;
    return partes.join(' · ');
  }

  static bool emailPerfilValido(String valor) {
    final email = valor.trim();
    if (email.isEmpty) return true;
    return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
  }

  factory Configuracoes.fromJson(Map<String, dynamic> json) {
    return Configuracoes(
      limiteDesgaste: (json['limiteDesgaste'] as num?)?.toDouble() ?? 105.0,
      limiteIrregular: (json['limiteIrregular'] as num?)?.toDouble() ?? 97.0,
      nomeConsultor: json['nomeConsultor'] as String? ?? '',
      empresaNome: json['empresaNome'] as String? ?? '',
      contatoPerfil: json['contatoPerfil'] as String? ?? '',
      emailPerfil: json['emailPerfil'] as String? ?? '',
      registroProfissional: json['registroProfissional'] as String? ?? '',
      marcaLogoArquivo: json['marcaLogoArquivo'] as String? ?? '',
      corMarcaPdf: corMarcaPdfFromJson(json['corMarcaPdf']),
      corMarcaPersonalizadaArgb: json['corMarcaPersonalizadaArgb'] as int?,
      tipoCabecalhoLaudo:
          tipoCabecalhoLaudoFromJson(json['tipoCabecalhoLaudo']),
      corMarcaGradienteInicioPdf: corMarcaPdfFromJson(
        json['corMarcaGradienteInicioPdf'] ?? 'azul',
      ),
      corMarcaGradienteFimPdf: corMarcaPdfFromJson(
        json['corMarcaGradienteFimPdf'] ?? 'verde',
      ),
      corMarcaGradienteInicioArgb:
          json['corMarcaGradienteInicioArgb'] as int?,
      corMarcaGradienteFimArgb: json['corMarcaGradienteFimArgb'] as int?,
      marcaFundoCabecalhoArquivo:
          json['marcaFundoCabecalhoArquivo'] as String? ?? '',
      tema: _temaFromJson(json['tema']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'limiteDesgaste': limiteDesgaste,
      'limiteIrregular': limiteIrregular,
      'nomeConsultor': nomeConsultor,
      'empresaNome': empresaNome,
      'contatoPerfil': contatoPerfil,
      'emailPerfil': emailPerfil,
      'registroProfissional': registroProfissional,
      'marcaLogoArquivo': marcaLogoArquivo,
      'corMarcaPdf': corMarcaPdf.name,
      if (corMarcaPersonalizadaArgb != null)
        'corMarcaPersonalizadaArgb': corMarcaPersonalizadaArgb,
      'tipoCabecalhoLaudo': tipoCabecalhoLaudo.name,
      'corMarcaGradienteInicioPdf': corMarcaGradienteInicioPdf.name,
      'corMarcaGradienteFimPdf': corMarcaGradienteFimPdf.name,
      if (corMarcaGradienteInicioArgb != null)
        'corMarcaGradienteInicioArgb': corMarcaGradienteInicioArgb,
      if (corMarcaGradienteFimArgb != null)
        'corMarcaGradienteFimArgb': corMarcaGradienteFimArgb,
      'marcaFundoCabecalhoArquivo': marcaFundoCabecalhoArquivo,
      'tema': tema.name,
    };
  }

  Configuracoes copyWith({
    double? limiteDesgaste,
    double? limiteIrregular,
    String? nomeConsultor,
    String? empresaNome,
    String? contatoPerfil,
    String? emailPerfil,
    String? registroProfissional,
    String? marcaLogoArquivo,
    CorMarcaPdf? corMarcaPdf,
    int? corMarcaPersonalizadaArgb,
    bool limparCorPersonalizada = false,
    TipoCabecalhoLaudo? tipoCabecalhoLaudo,
    CorMarcaPdf? corMarcaGradienteInicioPdf,
    CorMarcaPdf? corMarcaGradienteFimPdf,
    int? corMarcaGradienteInicioArgb,
    int? corMarcaGradienteFimArgb,
    bool limparGradienteInicioArgb = false,
    bool limparGradienteFimArgb = false,
    String? marcaFundoCabecalhoArquivo,
    TemaApp? tema,
  }) {
    return Configuracoes(
      limiteDesgaste: limiteDesgaste ?? this.limiteDesgaste,
      limiteIrregular: limiteIrregular ?? this.limiteIrregular,
      nomeConsultor: nomeConsultor ?? this.nomeConsultor,
      empresaNome: empresaNome ?? this.empresaNome,
      contatoPerfil: contatoPerfil ?? this.contatoPerfil,
      emailPerfil: emailPerfil ?? this.emailPerfil,
      registroProfissional: registroProfissional ?? this.registroProfissional,
      marcaLogoArquivo: marcaLogoArquivo ?? this.marcaLogoArquivo,
      corMarcaPdf: corMarcaPdf ?? this.corMarcaPdf,
      corMarcaPersonalizadaArgb: limparCorPersonalizada
          ? null
          : (corMarcaPersonalizadaArgb ?? this.corMarcaPersonalizadaArgb),
      tipoCabecalhoLaudo: tipoCabecalhoLaudo ?? this.tipoCabecalhoLaudo,
      corMarcaGradienteInicioPdf:
          corMarcaGradienteInicioPdf ?? this.corMarcaGradienteInicioPdf,
      corMarcaGradienteFimPdf:
          corMarcaGradienteFimPdf ?? this.corMarcaGradienteFimPdf,
      corMarcaGradienteInicioArgb: limparGradienteInicioArgb
          ? null
          : (corMarcaGradienteInicioArgb ?? this.corMarcaGradienteInicioArgb),
      corMarcaGradienteFimArgb: limparGradienteFimArgb
          ? null
          : (corMarcaGradienteFimArgb ?? this.corMarcaGradienteFimArgb),
      marcaFundoCabecalhoArquivo:
          marcaFundoCabecalhoArquivo ?? this.marcaFundoCabecalhoArquivo,
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
