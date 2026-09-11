import 'package:agrocalc/models/configuracoes.dart';
import 'package:agrocalc/models/regulagem.dart';
import 'package:agrocalc/services/regulagem_pdf_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

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

    expect(filename, 'regulagem_fazenda_boa_vista_2026-03-15.pdf');
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
    expect(filename, 'regulagem_maria_santos_2026-01-02.pdf');
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
}
