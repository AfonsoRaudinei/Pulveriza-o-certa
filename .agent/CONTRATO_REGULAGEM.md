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
| Percentual | cabeçalho e ficha: 1 casa **com** `%`; `null` → Sem medição; `0` medido → `0.0%` |
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
- Etapa fechada (não bloqueada): ficha `EtapaResumo` só com campos preenchidos (rótulo + valor). Campo vazio não entra. Aberta: some a ficha e mostra o formulário. Data da regulagem sempre entra no Contexto.
- Medições: `ExpansionPanelList.radio`, um painel por ponta. Cabeçalho com nº, L/min, % e status; `null` = “Sem medição”, `0` medido é `0.000 L/min` (não some). Corpo com o campo medido e o ideal. Card “Medições das Pontas” fechado lista só pontas já medidas. Ao abrir a ponta de baixo, auto-grava (sem fechar a tela) se a etapa 1 estiver completa.
- Inputs econômicos no card **Contexto da Operação**: Área (ha), Manejo (R$), Preço do bico (R$/un).
- `precoBico` = **R$ por um bico** (unitário). `custoTrocaTotal = precoBico × numeroPontas`.
- Resultados (Ponta R$, perda, custo de troca, recomendação) continuam depois das medições.
- Campo L/min medido: teclado decimal (`numberWithOptions(decimal: true)`), aceita vírgula e ponto, dígitos visíveis (sem label flutuante "Medida").

## Gráfico "Vazão por ponta"

Mesma geometria na tela (`lib/screens/regulagem/widgets/grafico_vazao_pontas.dart`) e no laudo (`_paintChart` em `lib/services/regulagem_pdf_service.dart`), a partir de `VazaoChartData` (`lib/core/charts/vazao_chart_data.dart`).

| Regra | Detalhe |
|---|---|
| Escala | percentual do ideal; barra sai da linha de 100% para cima (excesso) ou para baixo (falta) |
| Janela do eixo | sempre contém a faixa `limiteIrregular…limiteDesgaste`; margem mínima de 3 pp; amplitude máxima 60 pp (barra fora disso é cortada, rótulo mantém o valor real) |
| Largura | `VazaoChartLayout`: com poucas pontas o gráfico fica compacto (slot máx. 44 px) — a linha do ideal **não** atravessa espaço vazio até a borda |
| Rótulos do eixo | só `100%` à esquerda da linha do ideal — **nunca** dois números sobrepostos |
| Rótulo da barra | percentual sem casas, na cor do status; some se o vão da ponta for < 28 px |
| Ponta pendente | círculo vazado sobre a linha do ideal + item "Sem medição" na legenda; nunca barra zero |
| Legenda | só os status presentes, texto de `rotuloStatusPonta`; pílulas com fundo do status |
| PDF | eixo Y cresce de baixo para cima e `setFillColor` ignora alfa (usar `.flatten()`); seção envolvida em `pw.Inseparable` |

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
