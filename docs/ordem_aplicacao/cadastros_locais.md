# Cadastros locais (substituto dos selectors React)

O app v1 **não tem** Cliente / Fazenda / Talhão / Produto / Estoque como entidades.
Não inventar HTTP. Tudo em SharedPreferences.

## Chave

`agro_cadastros` em `AppConstants`.

## Modelos

```
Cliente { id, nome }
Fazenda { id, clienteId, nome }
Talhao { id, fazendaId, nome, areaHa }
ProdutoCatalogo { id, nome, unidadePadrao, estoque }
MaquinaLocal { id, nome }
```

## UX dos seletores

Dropdown filtrável. Item extra **+ Novo …** abre diálogo com nome (talhão também pede área ha).
Opções de Cliente/Fazenda/Talhão/Máquina também sugerem valores já gravados em regulagens
(`produtor`, `fazenda`, `talhao`, `maquina`) para não começar vazio.

## Persistência da ordem

A ordem grava **nomes** (e ids quando existirem) para a listagem sobreviver se o cadastro for apagado.

Backup JSON: incluir `ordensAplicacao` e `cadastros` no mesmo arquivo de backup existente,
sem quebrar import antigo (campos ausentes = lista vazia).
