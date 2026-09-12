# Cálculo 06 — Perda na Zona de Atenção

> **Onde vive:** `lib/domain/calculos/calc_perda_zona_atencao.dart`  
> **Alimenta:** `CardZonaAtencao` (abaixo do card Desgaste) e linha “Zona de Atenção” no laudo PDF  
> **Não substitui:** Cálculo 05 (perda total `percentual > 100` e recomendação de troca)

---

## Finalidade

Isolar o desperdício das pontas na **faixa intermediária**: acima de 100% e
até o limite de desgaste (padrão 105%). Essas pontas **ainda não justificam
troca** (não são Desgaste), mas já geram prejuízo de insumo mensurável.

O Cálculo 05 continua somando **todas** as pontas com `percentual > 100`.
Este módulo soma **só** a faixa `100 < p <= limiteDesgaste`. O prejuízo de
Desgaste (`p > limiteDesgaste`) fica de fora daqui — os dois números não se
sobreõem.

---

## Entradas

| Variável          | Tipo         | Unidade | Origem                                      |
|-------------------|--------------|---------|---------------------------------------------|
| `percentuais`     | `List<double>` | %     | Cálculo 02 (uma entrada por ponta medida)   |
| `manejoRS`        | double       | R$      | Campo Manejo (R$)                           |
| `numeroPontas`    | int          | unid    | Campo Número de pontas                      |
| `areaHa`          | double       | ha      | Campo Área (ha)                             |
| `limiteDesgaste`  | double       | %       | Config / inline (padrão **105**)            |

---

## Condição de ativação (por ponta)

```
100 < percentual  AND  percentual <= limiteDesgaste
```

| percentual | Entra na zona? | Motivo                          |
|------------|----------------|---------------------------------|
| 100        | não            | sem excesso                     |
| 100,5      | sim            | Ideal técnico, já desperdiça    |
| 105        | sim            | limite incluso; ainda não é Desgaste |
| 105,01     | não            | Desgaste (`>` limite)           |
| 88         | não            | Entupido / abaixo de 100        |

---

## Fórmula

Por ponta na faixa:

```
excessoFracao = (percentual - 100) / 100     // adimensional
custoPorPonta = manejoRS / numeroPontas      // R$/ponta
perdaPonta    = excessoFracao × custoPorPonta × areaHa  // R$
```

Acumulação:

```
perdaEstimada    = Σ perdaPonta
qtdPontasNaZona  = contagem das pontas na faixa
```

### Derivação dimensional

- `(p − 100) / 100` transforma o excesso percentual em fração de calda a mais.
- `manejoRS / n` aloca o custo de manejo a uma ponta.
- Multiplicar pela área (ha) dá o prejuízo daquela ponta na aplicação.

---

## Implementação Dart

```dart
class ResultadoZonaAtencao {
  final double perdaEstimada;
  final int qtdPontasNaZona;
}

ResultadoZonaAtencao calcularPerdaZonaAtencao({
  required List<double> percentuais,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
  double limiteDesgaste = 105,
})
```

A UI chama `CalcUtils.calcularPerdaZonaAtencao` — não copia a fórmula no widget.

---

## Exemplo numérico

**Cenário:** 24 pontas, manejo = R$ 2.400, área = 500 ha, limite = 105

`custoPorPonta = 2400 / 24 = R$ 100`

| Ponta | %     | Na zona? | perdaPonta                      |
|-------|-------|----------|---------------------------------|
| A     | 103,0 | sim      | 0,03 × 100 × 500 = **R$ 1.500** |
| B     | 105,0 | sim      | 0,05 × 100 × 500 = **R$ 2.500** |
| C     | 108,0 | não      | Desgaste (Cálculo 05 / status)  |
| D     | 100,0 | não      | sem excesso                     |

```
qtdPontasNaZona = 2
perdaEstimada   = 1.500 + 2.500 = R$ 4.000,00
```

A ponta C (108%) entra na perda de **Desgaste** do Cálculo 05, não aqui.

---

## Regras de negócio

- `numeroPontas <= 0`, `manejoRS <= 0` ou `areaHa <= 0` → `(0, 0)` sem exceção.
- Card e seção do PDF **só aparecem** se `qtdPontasNaZona > 0`.
- R$ com 2 casas (`toMoeda()`). Não substitui laudo técnico.
- `null` (ponta não medida) não entra na lista de percentuais; `0` é Irregular e fica fora da faixa.
