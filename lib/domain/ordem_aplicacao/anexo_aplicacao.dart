class AnexoAplicacao {
  const AnexoAplicacao({
    required this.id,
    required this.nome,
    required this.path,
  });

  final String id;
  final String nome;
  final String path;

  factory AnexoAplicacao.fromJson(Map<String, dynamic> json) {
    return AnexoAplicacao(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      path: json['path'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nome': nome, 'path': path};
  }
}
