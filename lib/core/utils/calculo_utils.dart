import '../../models/configuracoes.dart';
import '../../models/regulagem.dart';
import '../../domain/calculos/calculos_barra.dart' as calculos;

class CalcUtils {
  static double calcularLitroMinIdeal({
    required double vazaoLha,
    required double velocidade,
    required double espacamentoCm,
  }) {
    return calculos.calcularLitroMinIdeal(
      vazaoLha: vazaoLha,
      velocidade: velocidade,
      espacamentoCm: espacamentoCm,
    );
  }

  static double calcularPercentualPonta({
    required double valorMedido,
    required double litroMinIdeal,
  }) {
    return calculos.calcularPercentualPonta(
      valorMedido: valorMedido,
      litroMinIdeal: litroMinIdeal,
    );
  }

  static StatusPonta classificarPonta({
    required double? valorMedido,
    required double litroMinIdeal,
    required Configuracoes configuracoes,
  }) {
    return calculos.classificarPonta(
      valorMedido: valorMedido,
      litroMinIdeal: litroMinIdeal,
      configuracoes: configuracoes,
    );
  }

  static ({bool entreTolerancias, bool acimaToleranciaMin})
      verificarTolerancia({
    required double percentual,
    required Configuracoes configuracoes,
  }) {
    return calculos.verificarTolerancia(
      percentual: percentual,
      configuracoes: configuracoes,
    );
  }

  static ({int entreTolerancias, int acimaToleranciaMin}) agregarTolerancia({
    required Iterable<double> percentuais,
    required Configuracoes configuracoes,
  }) {
    return calculos.agregarTolerancia(
      percentuais: percentuais,
      configuracoes: configuracoes,
    );
  }

  static double calcularPerdaEstimada({
    required double percentual,
    required double manejoRS,
    required int numeroPontas,
    required double areaHa,
  }) {
    return calculos.calcularPerdaPorPonta(
      percentual: percentual,
      manejoRS: manejoRS,
      numeroPontas: numeroPontas,
      areaHa: areaHa,
    );
  }

  static double calcularValorTotalSafra({
    required double manejoRS,
    required double areaHa,
  }) {
    return calculos.calcularValorTotalSafra(
      manejoRS: manejoRS,
      areaHa: areaHa,
    );
  }

  static double calcularPontaRS({
    required double manejoRS,
    required int numeroPontas,
  }) {
    return calculos.calcularPontaRS(
      manejoRS: manejoRS,
      numeroPontas: numeroPontas,
    );
  }

  static double calcularCustoTrocaTotal({
    required double precoBicoRS,
    required int numeroPontas,
  }) {
    return calculos.calcularCustoTrocaTotal(
      precoBicoRS: precoBicoRS,
      numeroPontas: numeroPontas,
    );
  }

  static bool recomendarTrocaCompleta({
    required double perdaEstimadaTotal,
    required double custoTrocaTotal,
  }) {
    return calculos.recomendarTrocaCompleta(
      perdaEstimadaTotal: perdaEstimadaTotal,
      custoTrocaTotal: custoTrocaTotal,
    );
  }

  static calculos.ResultadoEconomico analisarEconomia({
    required Iterable<double> percentuais,
    required double manejoRS,
    required int numeroPontas,
    required double areaHa,
    required double precoBicoRS,
    double limiteDesgaste = 105,
  }) {
    return calculos.analisarEconomia(
      percentuais: percentuais,
      manejoRS: manejoRS,
      numeroPontas: numeroPontas,
      areaHa: areaHa,
      precoBicoRS: precoBicoRS,
      limiteDesgaste: limiteDesgaste,
    );
  }

  static calculos.ResultadoZonaAtencao calcularPerdaZonaAtencao({
    required List<double> percentuais,
    required double manejoRS,
    required int numeroPontas,
    required double areaHa,
    double limiteDesgaste = 105,
  }) {
    return calculos.calcularPerdaZonaAtencao(
      percentuais: percentuais,
      manejoRS: manejoRS,
      numeroPontas: numeroPontas,
      areaHa: areaHa,
      limiteDesgaste: limiteDesgaste,
    );
  }

  static double calcularLarguraUtil({
    required int nLinhas,
    required double espacamentoLinhasM,
  }) {
    if (nLinhas <= 0 || espacamentoLinhasM <= 0) return 0;
    return nLinhas * espacamentoLinhasM;
  }

  static double calcularRendimentoOperacional({
    required double larguraUtil,
    required double velocidade,
    required double eficiencia,
  }) {
    if (larguraUtil <= 0 || velocidade <= 0 || eficiencia <= 0) return 0;
    return (larguraUtil * velocidade * (eficiencia / 100)) / 10;
  }
}
