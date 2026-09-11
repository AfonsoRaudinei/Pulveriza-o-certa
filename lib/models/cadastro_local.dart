class ClienteLocal {
  const ClienteLocal({required this.id, required this.nome});

  final String id;
  final String nome;

  factory ClienteLocal.fromJson(Map<String, dynamic> json) {
    return ClienteLocal(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};
}

class FazendaLocal {
  const FazendaLocal({
    required this.id,
    required this.clienteId,
    required this.nome,
  });

  final String id;
  final String clienteId;
  final String nome;

  factory FazendaLocal.fromJson(Map<String, dynamic> json) {
    return FazendaLocal(
      id: json['id'] as String,
      clienteId: json['clienteId'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'clienteId': clienteId,
        'nome': nome,
      };
}

class TalhaoLocal {
  const TalhaoLocal({
    required this.id,
    required this.fazendaId,
    required this.nome,
    this.areaHa = 0,
  });

  final String id;
  final String fazendaId;
  final String nome;
  final double areaHa;

  factory TalhaoLocal.fromJson(Map<String, dynamic> json) {
    return TalhaoLocal(
      id: json['id'] as String,
      fazendaId: json['fazendaId'] as String? ?? '',
      nome: json['nome'] as String? ?? '',
      areaHa: (json['areaHa'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fazendaId': fazendaId,
        'nome': nome,
        'areaHa': areaHa,
      };
}

class ProdutoCatalogo {
  const ProdutoCatalogo({
    required this.id,
    required this.nome,
    required this.unidadePadrao,
    this.estoque = 0,
  });

  final String id;
  final String nome;
  final String unidadePadrao;
  final double estoque;

  factory ProdutoCatalogo.fromJson(Map<String, dynamic> json) {
    return ProdutoCatalogo(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
      unidadePadrao: json['unidadePadrao'] as String? ?? 'L/ha',
      estoque: (json['estoque'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'unidadePadrao': unidadePadrao,
        'estoque': estoque,
      };

  ProdutoCatalogo copyWith({double? estoque}) {
    return ProdutoCatalogo(
      id: id,
      nome: nome,
      unidadePadrao: unidadePadrao,
      estoque: estoque ?? this.estoque,
    );
  }
}

class MaquinaLocal {
  const MaquinaLocal({required this.id, required this.nome});

  final String id;
  final String nome;

  factory MaquinaLocal.fromJson(Map<String, dynamic> json) {
    return MaquinaLocal(
      id: json['id'] as String,
      nome: json['nome'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'nome': nome};
}

class CadastrosLocais {
  const CadastrosLocais({
    this.clientes = const [],
    this.fazendas = const [],
    this.talhoes = const [],
    this.produtos = const [],
    this.maquinas = const [],
  });

  final List<ClienteLocal> clientes;
  final List<FazendaLocal> fazendas;
  final List<TalhaoLocal> talhoes;
  final List<ProdutoCatalogo> produtos;
  final List<MaquinaLocal> maquinas;

  factory CadastrosLocais.fromJson(Map<String, dynamic> json) {
    return CadastrosLocais(
      clientes: _list(json['clientes'], ClienteLocal.fromJson),
      fazendas: _list(json['fazendas'], FazendaLocal.fromJson),
      talhoes: _list(json['talhoes'], TalhaoLocal.fromJson),
      produtos: _list(json['produtos'], ProdutoCatalogo.fromJson),
      maquinas: _list(json['maquinas'], MaquinaLocal.fromJson),
    );
  }

  Map<String, dynamic> toJson() => {
        'clientes': clientes.map((item) => item.toJson()).toList(),
        'fazendas': fazendas.map((item) => item.toJson()).toList(),
        'talhoes': talhoes.map((item) => item.toJson()).toList(),
        'produtos': produtos.map((item) => item.toJson()).toList(),
        'maquinas': maquinas.map((item) => item.toJson()).toList(),
      };

  static List<T> _list<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw.map((item) => fromJson(item as Map<String, dynamic>)).toList();
  }

  CadastrosLocais copyWith({
    List<ClienteLocal>? clientes,
    List<FazendaLocal>? fazendas,
    List<TalhaoLocal>? talhoes,
    List<ProdutoCatalogo>? produtos,
    List<MaquinaLocal>? maquinas,
  }) {
    return CadastrosLocais(
      clientes: clientes ?? this.clientes,
      fazendas: fazendas ?? this.fazendas,
      talhoes: talhoes ?? this.talhoes,
      produtos: produtos ?? this.produtos,
      maquinas: maquinas ?? this.maquinas,
    );
  }
}
