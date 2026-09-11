import 'package:agrocalc/domain/ordem_aplicacao/ordens.dart';
import 'package:flutter_test/flutter_test.dart';

OrdemAplicacao _ordem({
  String cliente = 'Cliente A',
  String talhao = 'T1',
  double area = 80,
  AlvoAplicacao? alvo = AlvoAplicacao.sugadores,
  List<ProdutoAplicacao> produtos = const [],
}) {
  final agora = DateTime(2026, 9, 11);
  return OrdemAplicacao(
    id: 'o1',
    clienteNome: cliente,
    talhaoNome: talhao,
    areaAplicar: area,
    alvo: alvo,
    produtos: produtos,
    criadoEm: agora,
    atualizadoEm: agora,
  );
}

ProdutoAplicacao _produto({
  String id = 'p1',
  String nome = 'Inseticida',
  double dose = 1.5,
  bool reservar = true,
}) {
  return ProdutoAplicacao(
    id: 'item-$id',
    produtoId: id,
    nomeProduto: nome,
    dose: dose,
    unidade: UnidadeDose.lHa,
    reservarEstoque: reservar,
  );
}

void main() {
  group('validarOrdem', () {
    test('ordem completa e estoque suficiente não gera erro', () {
      final erros = validarOrdem(
        _ordem(produtos: [_produto()]),
        estoquePorProdutoId: {'p1': 200},
      );
      expect(erros, isEmpty);
    });

    test('lista as mensagens na ordem da spec', () {
      final erros = validarOrdem(
        _ordem(cliente: '', talhao: '', area: 0, alvo: null),
        estoquePorProdutoId: const {},
      );
      expect(erros, [
        'Informe o cliente.',
        'Informe o talhão.',
        'Informe uma área a aplicar válida.',
        'Informe o alvo.',
        'Adicione pelo menos um produto.',
      ]);
    });

    test('estoque insuficiente só se reservar estiver marcado', () {
      final comReserva = validarOrdem(
        _ordem(produtos: [_produto(reservar: true)]),
        estoquePorProdutoId: {'p1': 10},
      );
      expect(comReserva, ['Estoque insuficiente para Inseticida.']);

      final semReserva = validarOrdem(
        _ordem(produtos: [_produto(reservar: false)]),
        estoquePorProdutoId: {'p1': 10},
      );
      expect(semReserva, isEmpty);
    });
  });
}
