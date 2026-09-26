import 'dart:io';

import 'package:agrocalc/domain/calculos/calc_litro_min_ideal.dart';
import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/marca_pdf.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/services/regulagem_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

const _medidasCanonicas = [
  0.550,
  0.530,
  0.490,
  0.530,
  0.570,
  0.570,
  0.559,
  0.550,
  0.500,
  0.510,
];

RegulagemPdfData _sampleData({
  String? talhao,
  String? consultor,
  List<PontaMedicao>? medicoes,
}) {
  const config = Configuracoes();
  final pontas = medicoes ??
      [
        const PontaMedicao(id: 1, valorMedido: 1.05, status: StatusPonta.ideal),
        const PontaMedicao(
            id: 2, valorMedido: 0.92, status: StatusPonta.irregular),
        const PontaMedicao(
            id: 3, valorMedido: 1.12, status: StatusPonta.desgaste),
        const PontaMedicao(
            id: 4, valorMedido: null, status: StatusPonta.pendente),
      ];

  return RegulagemPdfData(
    produtor: 'João Silva',
    fazenda: 'Fazenda Boa Vista',
    talhao: talhao,
    maquina: 'Jacto Uniport 3030',
    consultor: consultor,
    dataRegulagem: DateTime(2026, 3, 15),
    vazaoLha: 150,
    velocidade: 12,
    espacamentoCm: 50,
    numeroPontas: pontas.length,
    pressaoBar: 3.5,
    litroMinIdeal: 1.0,
    medicoes: pontas,
    configuracoes: config,
    manejo: 450,
    precoBico: 35,
    area: 120,
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('pt_BR');
  });

  test('generate PDF with sample data', () async {
    final bytes = await RegulagemPdfService.generate(_sampleData());

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('suggestedFilename sanitizes fazenda and includes date', () {
    final filename = RegulagemPdfService.suggestedFilename(_sampleData());

    expect(filename, 'Laudo_Regulagem_fazenda_boa_vista_2026-03-15.pdf');
  });

  test('suggestedFilename falls back to produtor when fazenda empty', () {
    final data = RegulagemPdfData(
      produtor: 'Maria@ Santos!',
      fazenda: '',
      maquina: 'Pulv',
      dataRegulagem: DateTime(2026, 1, 2),
      vazaoLha: 100,
      velocidade: 10,
      espacamentoCm: 50,
      numeroPontas: 2,
      litroMinIdeal: 1,
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 1, status: StatusPonta.ideal),
      ],
      configuracoes: const Configuracoes(),
      manejo: 0,
      precoBico: 0,
      area: 0,
    );

    final filename = RegulagemPdfService.suggestedFilename(data);
    expect(filename, 'Laudo_Regulagem_maria_santos_2026-01-02.pdf');
  });

  test('empty talhao and consultor does not throw', () async {
    final bytes = await RegulagemPdfService.generate(
      _sampleData(talhao: null, consultor: null),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('generate with only ideal pontas does not throw', () async {
    final bytes = await RegulagemPdfService.generate(
      _sampleData(
        medicoes: const [
          PontaMedicao(id: 1, valorMedido: 1.0, status: StatusPonta.ideal),
          PontaMedicao(id: 2, valorMedido: 1.0, status: StatusPonta.ideal),
          PontaMedicao(id: 3, valorMedido: 1.0, status: StatusPonta.ideal),
        ],
      ),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('gráfico com limites colados e ponta quase seca não quebra', () async {
    final data = _sampleData(
      medicoes: const [
        PontaMedicao(id: 1, valorMedido: 0.05, status: StatusPonta.irregular),
        PontaMedicao(id: 2, valorMedido: 1.01, status: StatusPonta.ideal),
        PontaMedicao(id: 3, valorMedido: null, status: StatusPonta.pendente),
      ],
    );
    final bytes = await RegulagemPdfService.generate(
      RegulagemPdfData(
        produtor: data.produtor,
        fazenda: data.fazenda,
        maquina: data.maquina,
        dataRegulagem: data.dataRegulagem,
        vazaoLha: data.vazaoLha,
        velocidade: data.velocidade,
        espacamentoCm: data.espacamentoCm,
        numeroPontas: data.numeroPontas,
        litroMinIdeal: data.litroMinIdeal,
        medicoes: data.medicoes,
        // Limites colados: só o rótulo de 100% deve ser escrito no eixo.
        configuracoes: const Configuracoes(
          limiteIrregular: 100,
          limiteDesgaste: 100.5,
        ),
        manejo: data.manejo,
        precoBico: data.precoBico,
        area: data.area,
      ),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });

  test('generate with marca personalizada does not throw', () async {
    final bytes = await RegulagemPdfService.generate(
      RegulagemPdfData(
        produtor: 'João',
        fazenda: 'Fazenda',
        maquina: 'Pulv',
        consultor: 'João Consultor',
        dataRegulagem: DateTime(2026, 3, 15),
        vazaoLha: 150,
        velocidade: 12,
        espacamentoCm: 50,
        numeroPontas: 2,
        litroMinIdeal: 1.0,
        medicoes: const [
          PontaMedicao(id: 1, valorMedido: 1.0, status: StatusPonta.ideal),
        ],
        configuracoes: const Configuracoes(
          empresaNome: 'Consultoria Agro',
          corMarcaPdf: CorMarcaPdf.grafite,
        ),
        manejo: 0,
        precoBico: 0,
        area: 0,
      ),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('exporta PDF canônico 10 pontas 30 ha para revisão visual', () async {
    final ideal = calcularLitroMinIdeal(
      vazaoLha: 80,
      velocidade: 8,
      espacamentoCm: 50,
    );
    final medicoes = [
      for (var i = 0; i < _medidasCanonicas.length; i++)
        PontaMedicao(
          id: i + 1,
          valorMedido: _medidasCanonicas[i],
          status: StatusPonta.pendente,
        ),
    ];
    final bytes = await RegulagemPdfService.generate(
      RegulagemPdfData(
        produtor: 'Produtor Teste',
        fazenda: 'Morro Vermelho',
        maquina: 'Pulverizador',
        dataRegulagem: DateTime(2026, 9, 23),
        vazaoLha: 80,
        velocidade: 8,
        espacamentoCm: 50,
        numeroPontas: 10,
        litroMinIdeal: ideal,
        medicoes: medicoes,
        configuracoes: const Configuracoes(),
        manejo: 600,
        precoBico: 30,
        area: 30,
      ),
    );
    final out = File('regulagem_morro_vermelho_2026-09-23.pdf');
    await out.writeAsBytes(bytes, flush: true);
    expect(out.lengthSync(), greaterThan(1000));
  });

  test('exporta PDF 30 e 60 pontas para revisão visual', () async {
    Future<void> exportar(int n, String nome) async {
      final medicoes = [
        for (var i = 0; i < n; i++)
          PontaMedicao(
            id: i + 1,
            valorMedido: 0.5 + (i % 10) * 0.05,
            status: StatusPonta.ideal,
          ),
      ];
      final bytes = await RegulagemPdfService.generate(
        RegulagemPdfData(
          produtor: 'Produtor Teste',
          fazenda: 'Fazenda Pontas',
          maquina: 'Pulverizador',
          dataRegulagem: DateTime(2026, 9, 23),
          vazaoLha: 80,
          velocidade: 8,
          espacamentoCm: 50,
          numeroPontas: n,
          litroMinIdeal: 1.0,
          medicoes: medicoes,
          configuracoes: const Configuracoes(),
          manejo: 600,
          precoBico: 30,
          area: 30,
        ),
      );
      final out = File(nome);
      await out.writeAsBytes(bytes, flush: true);
      expect(out.lengthSync(), greaterThan(1000));
    }

    await exportar(30, 'regulagem_30_pontas_2026-09-23.pdf');
    await exportar(60, 'regulagem_60_pontas_2026-09-23.pdf');
  });

  test('PDF com logo no rodapé e sem logo quando desativado', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final comLogo = await RegulagemPdfService.generate(_sampleData());
    expect(String.fromCharCodes(comLogo.take(4)), '%PDF');
    expect(comLogo.length, greaterThan(1000));

    final semLogo = await RegulagemPdfService.generate(
      _sampleData(),
      carregarLogoRodape: false,
    );
    expect(String.fromCharCodes(semLogo.take(4)), '%PDF');
    expect(semLogo.length, greaterThan(1000));
  });

  test('exporta laudos Nova6 (bico 30 e 50) na raiz do projeto', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ideal = calcularLitroMinIdeal(
      vazaoLha: 80,
      velocidade: 8,
      espacamentoCm: 50,
    );
    expect(ideal, closeTo(0.5333, 0.0001));
    final medicoes = [
      for (var i = 0; i < _medidasCanonicas.length; i++)
        PontaMedicao(
          id: i + 1,
          valorMedido: _medidasCanonicas[i],
          status: StatusPonta.pendente,
        ),
    ];
    Future<void> write(double precoBico, String filename) async {
      final bytes = await RegulagemPdfService.generate(
        RegulagemPdfData(
          produtor: 'Produtor Teste',
          fazenda: 'Nova6',
          maquina: 'Pulverizador',
          dataRegulagem: DateTime(2026, 9, 24),
          vazaoLha: 80,
          velocidade: 8,
          espacamentoCm: 50,
          numeroPontas: 10,
          litroMinIdeal: ideal,
          medicoes: medicoes,
          configuracoes: const Configuracoes(),
          manejo: 600,
          precoBico: precoBico,
          area: 30,
        ),
      );
      final out = File(filename);
      await out.writeAsBytes(bytes, flush: true);
      expect(out.lengthSync(), greaterThan(1000));
    }

    await write(30, 'Nova6.pdf');
    await write(50, 'Nova6_bico50.pdf');
  });

  test('exporta laudo Nova4 para conferir rodapé SoloForte', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final ideal = calcularLitroMinIdeal(
      vazaoLha: 80,
      velocidade: 8,
      espacamentoCm: 50,
    );
    final medicoes = [
      for (var i = 0; i < _medidasCanonicas.length; i++)
        PontaMedicao(
          id: i + 1,
          valorMedido: _medidasCanonicas[i],
          status: StatusPonta.pendente,
        ),
    ];
    final bytes = await RegulagemPdfService.generate(
      RegulagemPdfData(
        produtor: 'Produtor Teste',
        fazenda: 'Nova4',
        maquina: 'Pulverizador',
        dataRegulagem: DateTime(2026, 9, 23),
        vazaoLha: 80,
        velocidade: 8,
        espacamentoCm: 50,
        numeroPontas: 10,
        litroMinIdeal: ideal,
        medicoes: medicoes,
        configuracoes: const Configuracoes(),
        manejo: 600,
        precoBico: 30,
        area: 30,
      ),
    );
    final out = File('regulagem_nova4_2026-09-23.pdf');
    await out.writeAsBytes(bytes, flush: true);
    expect(out.lengthSync(), greaterThan(1000));
  });

  test('generate with zona de atenção pontas does not throw', () async {
    final bytes = await RegulagemPdfService.generate(
      _sampleData(
        medicoes: const [
          PontaMedicao(id: 1, valorMedido: 1.03, status: StatusPonta.ideal),
          PontaMedicao(id: 2, valorMedido: 1.12, status: StatusPonta.desgaste),
        ],
      ),
    );

    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    expect(bytes.length, greaterThan(1000));
  });
}
