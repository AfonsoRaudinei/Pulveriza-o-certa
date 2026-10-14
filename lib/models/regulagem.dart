import 'foto_regulagem.dart';
import '../domain/calculos/limites_regulagem.dart';

enum TipoOperacao { pulverizador, plantadeira }

enum StatusPonta { pendente, ideal, irregular, desgaste, atencao }

/// Lado por onde a conferência das pontas começou (1D = direita, 1E = esquerda).
enum LadoConferenciaPontas { direita, esquerda }

/// Cultura da operação (lista fechada — extensível no mesmo enum).
enum CulturaCultivo {
  soja,
  milho,
}

extension CulturaCultivoLabels on CulturaCultivo {
  String get label => switch (this) {
        CulturaCultivo.soja => 'Soja',
        CulturaCultivo.milho => 'Milho',
      };

  static CulturaCultivo? fromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return CulturaCultivo.values.byName(raw);
  }
}

/// Registros salvos antes do campo [cultura]: Milho ao carregar, sem sobrescrever valor salvo.
CulturaCultivo? culturaFromStorageJson(Map<String, dynamic> json) {
  if (!json.containsKey('cultura')) {
    return CulturaCultivo.milho;
  }
  return CulturaCultivoLabels.fromJson(json['cultura'] as String?) ??
      CulturaCultivo.milho;
}

/// Tipo de ponta/bico da barra (lista fechada).
enum TipoPontaBico {
  conica,
  lequeSimples,
  lequeDuplo,
  jatoDuplo,
  defletora,
}

extension TipoPontaBicoLabels on TipoPontaBico {
  String get label => switch (this) {
        TipoPontaBico.conica => 'Cônica',
        TipoPontaBico.lequeSimples => 'Leque Simples',
        TipoPontaBico.lequeDuplo => 'Leque Duplo',
        TipoPontaBico.jatoDuplo => 'Jato Duplo',
        TipoPontaBico.defletora => 'Defletora (Antideriva/AI)',
      };

  static TipoPontaBico? fromJson(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return TipoPontaBico.values.byName(raw);
  }
}

String rotuloPonta(int id, LadoConferenciaPontas lado) {
  final sufixo = lado == LadoConferenciaPontas.direita ? 'D' : 'E';
  return '$id$sufixo';
}

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
    this.fotos = const [],
    this.ladoConferenciaPontas = LadoConferenciaPontas.direita,
    this.larguraUtil,
    this.rendimento,
    this.manejoRS,
    this.precoBicoRS,
    this.areaHa,
    this.cultura,
    this.tipoPonta,
    this.numeroAplicacoes,
    this.limiteEntupido,
    this.limiteDesgaste,
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
  final List<FotoRegulagem> fotos;
  final LadoConferenciaPontas ladoConferenciaPontas;
  final double? larguraUtil;
  final double? rendimento;
  final double? manejoRS;
  final double? precoBicoRS;
  final double? areaHa;
  final CulturaCultivo? cultura;
  final TipoPontaBico? tipoPonta;
  /// Aplicações na safra com esta regulagem; registros antigos → null (= 1).
  final int? numeroAplicacoes;
  final double? limiteEntupido;
  final double? limiteDesgaste;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  LimitesRegulagem? get limitesSnapshot {
    final entupido = limiteEntupido;
    final desgaste = limiteDesgaste;
    if (entupido == null || desgaste == null) return null;
    return LimitesRegulagem(
      limiteEntupido: entupido,
      limiteDesgaste: desgaste,
    );
  }

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
      fotos: ((json['fotos'] as List<dynamic>?) ?? [])
          .map((item) => FotoRegulagem.fromJson(item as Map<String, dynamic>))
          .toList(),
      ladoConferenciaPontas: LadoConferenciaPontas.values.byName(
        json['ladoConferenciaPontas'] as String? ?? 'direita',
      ),
      larguraUtil: (json['larguraUtil'] as num?)?.toDouble(),
      rendimento: (json['rendimento'] as num?)?.toDouble(),
      manejoRS: (json['manejoRS'] as num?)?.toDouble(),
      precoBicoRS: (json['precoBicoRS'] as num?)?.toDouble(),
      areaHa: (json['areaHa'] as num?)?.toDouble(),
      cultura: culturaFromStorageJson(json),
      tipoPonta: TipoPontaBicoLabels.fromJson(json['tipoPonta'] as String?),
      numeroAplicacoes: json['numeroAplicacoes'] as int?,
      limiteEntupido: (json['limiteEntupido'] as num?)?.toDouble(),
      limiteDesgaste: (json['limiteDesgaste'] as num?)?.toDouble(),
      criadoEm: DateTime.parse(json['criadoEm'] as String),
      atualizadoEm: DateTime.parse(json['atualizadoEm'] as String),
    );
  }

  Regulagem copyWith({
    List<FotoRegulagem>? fotos,
    CulturaCultivo? cultura,
    TipoPontaBico? tipoPonta,
    int? numeroAplicacoes,
  }) {
    return Regulagem(
      id: id,
      produtor: produtor,
      fazenda: fazenda,
      talhao: talhao,
      maquina: maquina,
      tipoOperacao: tipoOperacao,
      dataRegulagem: dataRegulagem,
      consultor: consultor,
      vazaoLha: vazaoLha,
      velocidade: velocidade,
      espacamentoCm: espacamentoCm,
      numeroPontas: numeroPontas,
      pressaoBar: pressaoBar,
      nLinhas: nLinhas,
      espacamentoLinhasM: espacamentoLinhasM,
      eficiencia: eficiencia,
      populacaoDesejada: populacaoDesejada,
      litroMinIdeal: litroMinIdeal,
      medicoes: medicoes,
      fotos: fotos ?? this.fotos,
      ladoConferenciaPontas: ladoConferenciaPontas,
      larguraUtil: larguraUtil,
      rendimento: rendimento,
      manejoRS: manejoRS,
      precoBicoRS: precoBicoRS,
      areaHa: areaHa,
      cultura: cultura ?? this.cultura,
      tipoPonta: tipoPonta ?? this.tipoPonta,
      numeroAplicacoes: numeroAplicacoes ?? this.numeroAplicacoes,
      limiteEntupido: limiteEntupido,
      limiteDesgaste: limiteDesgaste,
      criadoEm: criadoEm,
      atualizadoEm: atualizadoEm,
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
      'fotos': fotos.map((item) => item.toJson()).toList(),
      'ladoConferenciaPontas': ladoConferenciaPontas.name,
      'larguraUtil': larguraUtil,
      'rendimento': rendimento,
      'manejoRS': manejoRS,
      'precoBicoRS': precoBicoRS,
      'areaHa': areaHa,
      if (cultura != null) 'cultura': cultura!.name,
      if (tipoPonta != null) 'tipoPonta': tipoPonta!.name,
      if (numeroAplicacoes != null) 'numeroAplicacoes': numeroAplicacoes,
      'limiteEntupido': limiteEntupido,
      'limiteDesgaste': limiteDesgaste,
      'criadoEm': criadoEm.toIso8601String(),
      'atualizadoEm': atualizadoEm.toIso8601String(),
    };
  }
}
