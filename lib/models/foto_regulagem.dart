class FotoRegulagem {
  const FotoRegulagem({
    required this.arquivo,
    this.titulo,
    this.observacao,
    this.pontaId,
    required this.timestamp,
  });

  /// Nome do arquivo salvo em disco (sem path absoluto).
  final String arquivo;
  final String? titulo;
  final String? observacao;
  final int? pontaId;
  final DateTime timestamp;

  factory FotoRegulagem.fromJson(Map<String, dynamic> json) {
    return FotoRegulagem(
      arquivo: json['arquivo'] as String,
      titulo: json['titulo'] as String?,
      observacao: json['observacao'] as String?,
      pontaId: json['pontaId'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'arquivo': arquivo,
      'titulo': titulo,
      'observacao': observacao,
      if (pontaId != null) 'pontaId': pontaId,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  FotoRegulagem copyWith({
    String? arquivo,
    String? titulo,
    String? observacao,
    int? pontaId,
    DateTime? timestamp,
  }) {
    return FotoRegulagem(
      arquivo: arquivo ?? this.arquivo,
      titulo: titulo ?? this.titulo,
      observacao: observacao ?? this.observacao,
      pontaId: pontaId ?? this.pontaId,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
