# Contrato da tela de regulagem (pulverizador)

Complemento visual de REGRA-CALC-BARRA-1. Abrir junto com `lib/screens/regulagem/`.

## Pipeline na UI

`RegulagemScreen._recalculate()`:

1. `CalcUtils.calcularLitroMinIdeal(vazao, velocidade, espacamentoCm)`
2. `_syncPontas` → `CalcUtils.classificarPonta` por linha
3. `PontasTable` recalcula % , tolerância e economia a partir das medições

`numeroPontas` da economia = `medicoes.length` (sincronizado com o campo do formulário).

## Limites de classificação (editáveis, autosalvamento)

Não estão travados. O técnico informa o % na regulagem (etapa Cálculos Automáticos) e em Configurações.

| Campo na UI | Config | Regra |
|---|---|---|
| Limite entupido (%) | `limiteIrregular` (padrão 100) | `percentual < limite` → Entupido |
| Limite desgaste (%) | `limiteDesgaste` (padrão 105) | `percentual > limite` → Desgaste |
| (faixa do meio) | — | Ideal (inclui os limites exatos) |

- Edição **inline**; grava sozinho (~400 ms) via `ConfiguracoesProvider.saveLimites`.
- Recalcula o status de cada ponta na hora (com o % digitado, sem esperar o I/O). Enum interno continua `StatusPonta.irregular`; o rótulo visível é **Entupido**.
- Configurações fica no `IndexedStack`: os campos de limite **ressincronizam** com o provider se não tiverem foco, para o botão Salvar não reverter o que a regulagem já gravou.

## Exibição atual (código, não a spec visual antiga)

| Dado | Como o app mostra hoje |
|---|---|
| L/min ideal | 3 casas (`toStringAsFixed(3)`) no resultado e na coluna |
| Percentual | 1 casa, **sem** `%`; vazio → `-` |
| R$ | `toMoeda()` (pt_BR, 2 casas) |
| Status | `StatusBadge` (não pinta o fundo da linha) |
| Card econômico | só se `perdaTotal > 0 && custo > 0` |
| Zona de Atenção | `CardZonaAtencao` abaixo do resumo Desgaste; some se `qtd == 0` |
| Perda por desgaste | só `percentual > limiteDesgaste` (não inclui a zona) |
| Troca completa | texto danger; seletiva → success |

Não “corrigir” casas decimais, símbolo `%` ou cores do card no mesmo PR de fórmula, a menos que o usuário peça o alinhamento visual.

## UI de nova regulagem (pulverizador)

- Sem dropdown de tipo de operação. Esta tela é só pulverização.
- Save (novo ou edição nesta UI) grava `tipoOperacao: TipoOperacao.pulverizador`.
- Enum `TipoOperacao.plantadeira` e `CalcUtils` de plantadeira ficam no model/JSON antigo; não aparecem nesta tela.
- Formulário em duas colunas, label visível **acima** do campo (não só `labelText` flutuante). Pares com rótulo longo empilham um abaixo do outro: Espaçamento + Nº de pontas; Limite entupido + desgaste.
- Etapas da regulagem (nova e salva): `ExpansionTile` no `ProgressiveCard` — círculo 1 / ✓ / cadeado **e** chevron. Etapa bloqueada começa recolhida; ao desbloquear, abre sozinha. Ordem de aplicação permanece `ProgressiveStepCard` sem accordion.
- Medições: `ExpansionPanelList.radio`, um painel por ponta. Cabeçalho com nº, L/min, % e status; corpo com o campo medido e o ideal. Ao abrir a ponta de baixo, auto-grava (sem fechar a tela) se a etapa 1 estiver completa.
- Inputs econômicos no card **Contexto da Operação**: Área (ha), Manejo (R$), Preço do bico (R$/un).
- `precoBico` = **R$ por um bico** (unitário). `custoTrocaTotal = precoBico × numeroPontas`.
- Resultados (Ponta R$, perda, custo de troca, recomendação) continuam depois das medições.
- Campo L/min medido: teclado decimal (`numberWithOptions(decimal: true)`), aceita vírgula e ponto, dígitos visíveis (sem label flutuante "Medida").

## Análise econômica

```
excesso     = (percentual - 100) / 100     // só se percentual > 100
perdaBico   = excesso × (manejoRS / n) × areaHa
custoTroca  = precoBico × n
troca total = perdaTotal >= custoTroca && custoTroca > 0
```

Exemplo canônico: 24 pontas, manejo 2400, área 500, bico 35, pontas 108 / 106,5 / 110,2 → perda **12350**, custo **840**, troca completa.

Zona de Atenção (`100 < % ≤ limiteDesgaste`): soma à parte, sem incluir Desgaste. Ex.: 103% + 105% no mesmo cenário → R$ 4.000 (2 pontas). UI via `CalcUtils.calcularPerdaZonaAtencao`. Spec: `CALCULOS/calc_perda_zona_atencao.md`.

## Plantadeira

Fora desta UI. Não usa tabela de pontas. `CalcUtils` ainda calcula largura útil (2 casas, m) e rendimento (2 casas, ha/h) para JSON antigo / testes.
