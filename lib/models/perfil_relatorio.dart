/// Dados do cabeçalho/rodapé do PDF de regulagem.
class PerfilRelatorio {
  const PerfilRelatorio({
    this.nomeConsultor = '',
    this.empresaNome = '',
    this.logoPath,
    this.assinaturaPath,
  });

  final String nomeConsultor;
  final String empresaNome;
  final String? logoPath;
  final String? assinaturaPath;

  factory PerfilRelatorio.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const PerfilRelatorio();
    return PerfilRelatorio(
      nomeConsultor: json['nomeConsultor'] as String? ?? '',
      empresaNome: json['empresaNome'] as String? ?? '',
      logoPath: json['logoPath'] as String?,
      assinaturaPath: json['assinaturaPath'] as String?,
    );
  }

  /// Migra campos legados soltos em [legado].
  factory PerfilRelatorio.fromLegado(Map<String, dynamic> legado) {
    return PerfilRelatorio(
      nomeConsultor: legado['nomeConsultor'] as String? ?? '',
      empresaNome: legado['empresaNome'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomeConsultor': nomeConsultor,
      'empresaNome': empresaNome,
      if (logoPath != null) 'logoPath': logoPath,
      if (assinaturaPath != null) 'assinaturaPath': assinaturaPath,
    };
  }

  PerfilRelatorio copyWith({
    String? nomeConsultor,
    String? empresaNome,
    String? logoPath,
    String? assinaturaPath,
    bool removerLogo = false,
    bool removerAssinatura = false,
  }) {
    return PerfilRelatorio(
      nomeConsultor: nomeConsultor ?? this.nomeConsultor,
      empresaNome: empresaNome ?? this.empresaNome,
      logoPath: removerLogo ? null : (logoPath ?? this.logoPath),
      assinaturaPath:
          removerAssinatura ? null : (assinaturaPath ?? this.assinaturaPath),
    );
  }
}
