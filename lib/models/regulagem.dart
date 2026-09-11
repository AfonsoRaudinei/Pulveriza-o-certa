enum TipoOperacao { pulverizador, plantadeira }

enum StatusPonta { pendente, ideal, irregular, desgaste }

class PontaMedicao {
  const PontaMedicao({
    required this.id,
    this.valorMedido,
    required this.status,
  });

  final int id;
  final double? valorMedido;
  final StatusPonta status;

  factory PontaMedicao.fromJson(Map<String, dynamic> json) {
    return PontaMedicao(
      id: json['id'] as int,
      valorMedido: (json['valorMedido'] as num?)?.toDouble(),
      status:
          StatusPonta.values.byName(json['status'] as String? ?? 'pendente'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'valorMedido': valorMedido,
      'status': status.name,
    };
  }

  PontaMedicao copyWith({double? valorMedido, StatusPonta? status}) {
    return PontaMedicao(
      id: id,
      valorMedido: valorMedido ?? this.valorMedido,
      status: status ?? this.status,
    );
  }
}

class Regulagem {
  const Regulagem({
    required this.id,
    required this.produtor,
    required this.fazenda,
    this.talhao,
    required this.maquina,
    required this.tipoOperacao,
    required this.dataRegulagem,
    this.consultor,
    required this.vazaoLha,
    required this.velocidade,
    required this.espacamentoCm,
    required this.numeroPontas,
    this.pressaoBar,
    this.nLinhas,
    this.espacamentoLinhasM,
    this.eficiencia,
    this.populacaoDesejada,
    required this.litroMinIdeal,
    required this.medicoes,
    this.larguraUtil,
    this.rendimento,
    this.manejoRS,
    this.precoBicoRS,
    this.areaHa,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  final String id;
  final String produtor;
  final String fazenda;
  final String? talhao;
  final String maquina;
  final TipoOperacao tipoOperacao;
  final DateTime dataRegulagem;
  final String? consultor;
  final double vazaoLha;
  final double velocidade;
  final double espacamentoCm;
  final int numeroPontas;
  final double? pressaoBar;
  final int? nLinhas;
  final double? espacamentoLinhasM;
  final double? eficiencia;
  final int? populacaoDesejada;
  final double litroMinIdeal;
  final List<PontaMedicao> medicoes;
  final double? larguraUtil;
  final double? rendimento;
  final double? manejoRS;
  final double? precoBicoRS;
  final double? areaHa;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  factory Regulagem.fromJson(Map<String, dynamic> json) {
    return Regulagem(
      id: json['id'] as String,
      produtor: json['produtor'] as String,
      fazenda: json['fazenda'] as String,
      talhao: json['talhao'] as String?,
      maquina: json['maquina'] as String,
      tipoOperacao: TipoOperacao.values.byName(
        json['tipoOperacao'] as String? ?? 'pulverizador',
      ),
      dataRegulagem: DateTime.parse(json['dataRegulagem'] as String),
      consultor: json['consultor'] as String?,
      vazaoLha: (json['vazaoLha'] as num?)?.toDouble() ?? 0,
      velocidade: (json['velocidade'] as num?)?.toDouble() ?? 0,
      espacamentoCm: (json['espacamentoCm'] as num?)?.toDouble() ?? 0,
      numeroPontas: json['numeroPontas'] as int? ?? 0,
      pressaoBar: (json['pressaoBar'] as num?)?.toDouble(),
      nLinhas: json['nLinhas'] as int?,
      espacamentoLinhasM: (json['espacamentoLinhasM'] as num?)?.toDouble(),
      eficiencia: (json['eficiencia'] as num?)?.toDouble(),
      populacaoDesejada: json['populacaoDesejada'] as int?,
      litroMinIdeal: (json['litroMinIdeal'] as num?)?.toDouble() ?? 0,
      medicoes: ((json['medicoes'] as List<dynamic>?) ?? [])
          .map((item) => PontaMedicao.fromJson(item as Map<String, dynamic>))
          .toList(),
      larguraUtil: (json['larguraUtil'] as num?)?.toDouble(),
      rendimento: (json['rendimento'] as num?)?.toDouble(),
      manejoRS: (json['manejoRS'] as num?)?.toDouble(),
      precoBicoRS: (json['precoBicoRS'] as num?)?.toDouble(),
      areaHa: (json['areaHa'] as num?)?.toDouble(),
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'produtor': produtor,
      'fazenda': fazenda,
      'talhao': talhao,
      'maquina': maquina,
      'tipoOperacao': tipoOperacao.name,
      'dataRegulagem': dataRegulagem.toIso8601String(),
      'consultor': consultor,
      'vazaoLha': vazaoLha,
      'velocidade': velocidade,
      'espacamentoCm': espacamentoCm,
      'numeroPontas': numeroPontas,
      'pressaoBar': pressaoBar,
      'nLinhas': nLinhas,
      'espacamentoLinhasM': espacamentoLinhasM,
      'eficiencia': eficiencia,
      'populacaoDesejada': populacaoDesejada,
      'litroMinIdeal': litroMinIdeal,
      'medicoes': medicoes.map((item) => item.toJson()).toList(),
      'larguraUtil': larguraUtil,
      'rendimento': rendimento,
      'manejoRS': manejoRS,
      'precoBicoRS': precoBicoRS,
      'areaHa': areaHa,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }
}
