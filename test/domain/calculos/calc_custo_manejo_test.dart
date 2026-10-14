import 'package:agrocalc/domain/calculos/calc_custo_manejo.dart';
import 'package:agrocalc/models/custo_manejo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('totais por produto, aplicação e manejo', () {
    final custo = CustoManejo(
      id: '1',
      nome: 'Soja — herbicida + fungicida',
      aplicacoes: [
        AplicacaoManejo(
          id: 'a1',
          rotulo: 'Aplicação 1',
          produtos: [
            const ProdutoManejo(
              id: 'p1',
              nome: 'Produto A',
              dose: 2,
              valorUnitario: 50,
            ),
            const ProdutoManejo(
              id: 'p2',
              nome: 'Produto B',
              dose: 1,
              valorUnitario: 30,
            ),
          ],
        ),
        AplicacaoManejo(
          id: 'a2',
          rotulo: 'Aplicação 2',
          produtos: [
            const ProdutoManejo(
              id: 'p3',
              nome: 'Produto C',
              dose: 3,
              valorUnitario: 20,
            ),
          ],
        ),
      ],
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );

    expect(
      calcularTotalProdutoManejo(dose: 2, valorUnitario: 50),
      100,
    );
    expect(calcularTotalAplicacaoManejo(custo.aplicacoes.first), 130);
    expect(calcularTotalAplicacaoManejo(custo.aplicacoes[1]), 60);
    expect(calcularTotalManejo(custo), 190);
  });

  test('validação bloqueia manejo vazio', () {
    final vazio = novoCustoManejoRascunho();
    expect(validarCustoManejoParaSalvar(vazio), isNotNull);
  });

  test('validação aceita manejo completo', () {
    final custo = CustoManejo(
      id: '1',
      nome: 'Teste',
      aplicacoes: [
        AplicacaoManejo(
          id: 'a1',
          rotulo: 'Aplicação 1',
          produtos: [
            const ProdutoManejo(
              id: 'p1',
              nome: 'Glifosato',
              dose: 1,
              valorUnitario: 100,
            ),
          ],
        ),
      ],
      criadoEm: DateTime(2026, 1, 1),
      atualizadoEm: DateTime(2026, 1, 1),
    );
    expect(validarCustoManejoParaSalvar(custo), isNull);
    expect(calcularTotalManejo(custo), 100);
  });
}
