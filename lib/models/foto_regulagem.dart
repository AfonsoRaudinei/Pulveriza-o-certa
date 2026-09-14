class FotoRegulagem {
  const FotoRegulagem({
    required this.arquivo,
    this.titulo,
    this.observacao,
    required this.timestamp,
  });

  /// Nome do arquivo salvo em disco (sem path absoluto).
  final String arquivo;
  final String? titulo;
  final String? observacao;
  final DateTime timestamp;

  factory FotoRegulagem.fromJson(Map<String, dynamic> json) {
    return FotoRegulagem(
      arquivo: json['arquivo'] as String,
      titulo: json['titulo'] as String?,
      observacao: json['observacao'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arquivo': arquivo,
      'titulo': titulo,
      'observacao': observacao,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  FotoRegulagem copyWith({
    String? arquivo,
    String? titulo,
    String? observacao,
    DateTime? timestamp,
  }) {
    return FotoRegulagem(
      arquivo: arquivo ?? this.arquivo,
      titulo: titulo ?? this.titulo,
      observacao: observacao ?? this.observacao,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
