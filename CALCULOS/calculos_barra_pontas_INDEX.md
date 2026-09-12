# Cálculos da Barra de Pontas — Índice Geral

> Módulo: **Regulagem de Pulverizador**  
> App: **AgroCalc** (Flutter/Dart)  
> Versão do documento: 1.0

---

## Pipeline de cálculo

Os 5 cálculos fluem em cadeia. A saída de cada um alimenta o próximo:

```
ENTRADAS DO FORMULÁRIO
  │
  │  vazao (L/ha) + velocidade (km/h) + espacamento (cm)
  ▼
┌──────────────────────────────────────────┐
│  Cálculo 01 — Litro por Minuto Ideal     │  → litroMinIdeal (L/min)
└──────────────────────────────────────────┘
  │
  │  litroMinIdeal + valorMedido (por ponta)
  ▼
┌──────────────────────────────────────────┐
│  Cálculo 02 — Percentual da Ponta        │  → percentual (%)
└──────────────────────────────────────────┘
  │
  ├──────────────────────────────────────────────────────────────────┐
  │  percentual + limiteDesgaste + limiteIrregular                   │
  ▼                                                                  ▼
┌──────────────────────────────────────┐  ┌──────────────────────────────────────────┐
│  Cálculo 03 — Classificação Status   │  │  Cálculo 04 — Tolerância da Ponta        │
│  Ideal / Irregular / Desgaste        │  │  Entre Tolerâncias / Acima Mín           │
└──────────────────────────────────────┘  └──────────────────────────────────────────┘
  │                                          │
  └──────────────────┬───────────────────────┘
                     │  percentuais agregados + manejoRS + precoBico + areaHa
                     ▼
          ┌──────────────────────────────────────────┐
          │  Cálculo 05 — Análise Econômica          │
          │  Perda estimada vs Custo de troca        │
          │  → Recomendação: troca seletiva / total  │
          └──────────────────────────────────────────┘
                     │
                     │  percentuais + manejoRS + n + areaHa + limiteDesgaste
                     ▼
          ┌──────────────────────────────────────────┐
          │  Cálculo 06 — Zona de Atenção            │
          │  100 < % ≤ limiteDesgaste                │
          │  → perda R$ da faixa (sem Desgaste)      │
          └──────────────────────────────────────────┘
```

---

## Tabela de cálculos

| #  | Arquivo                          | Entrada principal       | Saída principal              | Onde é exibido                        |
|----|----------------------------------|-------------------------|------------------------------|---------------------------------------|
| 01 | `calc_litro_min_ideal.md`        | vazao, velocidade, esp  | L/min por ponta (referência) | Coluna "Ideal (L/min)" da tabela      |
| 02 | `calc_percentual_ponta.md`       | valorMedido, ideal      | % por ponta                  | Coluna "% Pontas" da tabela           |
| 03 | `calc_classificacao_status.md`   | percentual, limiares    | Ideal / Irregular / Desgaste | Badge, cor da linha, contadores       |
| 04 | `calc_tolerancia_ponta.md`       | percentual, tolMin/Max  | entreTolerancias, acimaMIN   | Cards azul e roxo do painel           |
| 05 | `calc_analise_economica.md`      | percentuais, R$, ha     | perdaTotal, recomendarTroca  | Card laranja/cinza + recomendação     |
| 06 | `calc_perda_zona_atencao.md`     | percentuais, R$, ha, 105| perda zona, qtd na faixa     | Card Zona de Atenção + linha do PDF   |

---

## Variáveis globais (props de entrada)

| Variável         | Tipo   | Padrão   | Descrição                                    |
|------------------|--------|----------|----------------------------------------------|
| `numeroPontas`   | int    | 1        | Total de bicos na barra                      |
| `litroMinIdeal`  | double | 0        | Saída do Cálculo 01 (recebida via prop)      |
| `manejoRS`       | double | 0        | Custo total do manejo (R$)                   |
| `limiteDesgaste` | double | 105      | % acima do qual a ponta é "Desgaste"         |
| `limiteIrregular`| double | 100      | % abaixo do qual a ponta é "Irregular"       |
| `toleranciaMin`  | double | 100,5    | Limite inferior da zona de atenção           |
| `toleranciaMax`  | double | 104,99   | Limite superior da zona de atenção           |
| `areaHa`         | double | 0        | Área da aplicação (ha)                       |
| `precoBico`      | double | 0        | Preço unitário do bico (R$)                  |

---

## Regras transversais (válidas para todos os cálculos)

1. **Nunca dividir por zero** — toda divisão verifica o denominador antes de calcular.
2. **Entradas negativas tratadas como zero** — não existe vazão ou área negativa no domínio.
3. **`null` é diferente de `0`** — ponta não medida (`null`) é "pendente"; ponta com `0` é "Irregular".
4. **Reatividade** — todos os cálculos são `useMemo`/`computed` e recalculam automaticamente ao mudar qualquer entrada.
5. **Exibição** — 2 casas decimais para L/min e R$; 1 casa decimal para percentual.

---

## Arquivo de funções puras (Dart)

Todos os cálculos devem residir em um único arquivo de domínio puro:

```
lib/
└── domain/
    └── calculos/
        ├── calc_litro_min_ideal.dart        ← Cálculo 01
        ├── calc_percentual_ponta.dart       ← Cálculo 02
        ├── calc_classificacao_status.dart   ← Cálculo 03
        ├── calc_tolerancia_ponta.dart       ← Cálculo 04
        ├── calc_analise_economica.dart      ← Cálculo 05
        ├── calc_perda_zona_atencao.dart     ← Cálculo 06
        └── calculos_barra.dart             ← barrel export
```

### `calculos_barra.dart` (barrel)

```dart
export 'calc_litro_min_ideal.dart';
export 'calc_percentual_ponta.dart';
export 'calc_classificacao_status.dart';
export 'calc_tolerancia_ponta.dart';
export 'calc_analise_economica.dart';
export 'calc_perda_zona_atencao.dart';
```

---

## Arquivo de testes

```
test/
└── domain/
    └── calculos/
        ├── calc_litro_min_ideal_test.dart
        ├── calc_percentual_ponta_test.dart
        ├── calc_classificacao_status_test.dart
        ├── calc_tolerancia_ponta_test.dart
        ├── calc_analise_economica_test.dart
        └── calc_perda_zona_atencao_test.dart
```

Rodar com:

```bash
flutter test test/domain/calculos/
```
