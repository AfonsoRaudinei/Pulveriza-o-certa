import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/cadastro_local.dart';
import '../models/regulagem.dart';
import '../services/storage_service.dart';

class CadastrosProvider extends ChangeNotifier {
  CadastrosProvider({StorageService? storage})
      : _storage = storage ?? StorageService();

  final StorageService _storage;
  static const _uuid = Uuid();

  CadastrosLocais _cadastros = const CadastrosLocais();
  bool _loading = false;

  CadastrosLocais get cadastros => _cadastros;
  bool get loading => _loading;

  Map<String, double> get estoquePorProdutoId {
    return {
      for (final produto in _cadastros.produtos) produto.id: produto.estoque,
    };
  }

  Future<void> load() async {
    try {
      _loading = true;
      notifyListeners();
      _cadastros = await _storage.getCadastros();
    } catch (error) {
      debugPrint('Erro no provider de cadastros: $error');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _persist(CadastrosLocais next) async {
    await _storage.saveCadastros(next);
    _cadastros = next;
    notifyListeners();
  }

  Future<ClienteLocal> addCliente(String nome) async {
    final cliente = ClienteLocal(id: _uuid.v4(), nome: nome.trim());
    await _persist(
      _cadastros.copyWith(clientes: [..._cadastros.clientes, cliente]),
    );
    return cliente;
  }

  Future<FazendaLocal> addFazenda({
    required String clienteId,
    required String nome,
  }) async {
    final fazenda = FazendaLocal(
      id: _uuid.v4(),
      clienteId: clienteId,
      nome: nome.trim(),
    );
    await _persist(
      _cadastros.copyWith(fazendas: [..._cadastros.fazendas, fazenda]),
    );
    return fazenda;
  }

  Future<TalhaoLocal> addTalhao({
    required String fazendaId,
    required String nome,
    required double areaHa,
  }) async {
    final talhao = TalhaoLocal(
      id: _uuid.v4(),
      fazendaId: fazendaId,
      nome: nome.trim(),
      areaHa: areaHa,
    );
    await _persist(
      _cadastros.copyWith(talhoes: [..._cadastros.talhoes, talhao]),
    );
    return talhao;
  }

  Future<ProdutoCatalogo> addProduto({
    required String nome,
    required String unidadePadrao,
    double estoque = 0,
  }) async {
    final produto = ProdutoCatalogo(
      id: _uuid.v4(),
      nome: nome.trim(),
      unidadePadrao: unidadePadrao,
      estoque: estoque,
    );
    await _persist(
      _cadastros.copyWith(produtos: [..._cadastros.produtos, produto]),
    );
    return produto;
  }

  Future<MaquinaLocal> addMaquina(String nome) async {
    final maquina = MaquinaLocal(id: _uuid.v4(), nome: nome.trim());
    await _persist(
      _cadastros.copyWith(maquinas: [..._cadastros.maquinas, maquina]),
    );
    return maquina;
  }

  Future<void> baixarEstoque(Map<String, double> quantidadePorProdutoId) async {
    final produtos = _cadastros.produtos.map((produto) {
      final baixa = quantidadePorProdutoId[produto.id];
      if (baixa == null || baixa <= 0) return produto;
      final resto = produto.estoque - baixa;
      return produto.copyWith(estoque: resto < 0 ? 0 : resto);
    }).toList();
    await _persist(_cadastros.copyWith(produtos: produtos));
  }

  /// Completa cadastros vazios com nomes já usados em regulagens.
  Future<void> sugerirDeRegulagens(List<Regulagem> regulagens) async {
    if (regulagens.isEmpty) return;
    var next = _cadastros;
    var changed = false;

    for (final regulagem in regulagens) {
      final produtor = regulagem.produtor.trim();
      if (produtor.isEmpty) continue;
      ClienteLocal? cliente;
      for (final item in next.clientes) {
        if (item.nome.toLowerCase() == produtor.toLowerCase()) {
          cliente = item;
          break;
        }
      }
      if (cliente == null) {
        cliente = ClienteLocal(id: _uuid.v4(), nome: produtor);
        next = next.copyWith(clientes: [...next.clientes, cliente]);
        changed = true;
      }
      final fazendaNome = regulagem.fazenda.trim();
      if (fazendaNome.isEmpty) continue;
      FazendaLocal? fazenda;
      for (final item in next.fazendas) {
        if (item.clienteId == cliente.id &&
            item.nome.toLowerCase() == fazendaNome.toLowerCase()) {
          fazenda = item;
          break;
        }
      }
      if (fazenda == null) {
        fazenda = FazendaLocal(
          id: _uuid.v4(),
          clienteId: cliente.id,
          nome: fazendaNome,
        );
        next = next.copyWith(fazendas: [...next.fazendas, fazenda]);
        changed = true;
      }
      final talhaoNome = regulagem.talhao?.trim() ?? '';
      if (talhaoNome.isNotEmpty) {
        final exists = next.talhoes.any(
          (item) =>
              item.fazendaId == fazenda!.id &&
              item.nome.toLowerCase() == talhaoNome.toLowerCase(),
        );
        if (!exists) {
          next = next.copyWith(
            talhoes: [
              ...next.talhoes,
              TalhaoLocal(
                id: _uuid.v4(),
                fazendaId: fazenda.id,
                nome: talhaoNome,
                areaHa: regulagem.areaHa ?? 0,
              ),
            ],
          );
          changed = true;
        }
      }
      final maquinaNome = regulagem.maquina.trim();
      if (maquinaNome.isNotEmpty &&
          !next.maquinas.any(
            (item) => item.nome.toLowerCase() == maquinaNome.toLowerCase(),
          )) {
        next = next.copyWith(
          maquinas: [
            ...next.maquinas,
            MaquinaLocal(id: _uuid.v4(), nome: maquinaNome),
          ],
        );
        changed = true;
      }
    }

    if (changed) await _persist(next);
  }
}
