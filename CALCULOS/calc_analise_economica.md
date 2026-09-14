# Cálculo 05 — Análise Econômica (Perda Estimada vs Custo de Troca)

> **Onde vive:** `PulverizadorRegulagem` → bloco `estatisticas` (useMemo), FASE 4  
> **Alimenta:** card "Análise Econômica" (laranja/cinza) + recomendação final de troca

---

## Finalidade

Traduz o **desperdício técnico em R$**, comparando o prejuízo acumulado por excesso de vazão das pontas com desgaste contra o custo de troca completa da barra. Responde à pergunta objetiva do produtor:

> *"Compensa trocar agora ou só as pontas problemáticas?"*

---

## Sub-cálculo A — Perda por Ponta com Excesso

### Entradas

| Variável       | Unidade | Origem                         |
|----------------|---------|--------------------------------|
| `percentual`   | %       | Cálculo 02 (por ponta)         |
| `manejoRS`     | R$      | Campo "Manejo R$" do formulário |
| `numeroPontas` | unid    | Campo "Número de Pontas"       |
| `areaHa`       | ha      | Campo "Área (ha)"              |

### Condição de ativação

```
APLICA APENAS SE: percentual > 100%  AND  numeroPontas > 0  AND  areaHa > 0
```

### Fórmula

```
excesso       = (percentual - 100) / 100
custoManejoP  = manejoRS / numeroPontas        ← custo por ponta da aplicação
perdaBico     = excesso × custoManejoP × areaHa
```

### Acumulação segmentada

Para cada ponta com `percentual > 100%`, a mesma `perdaBico` vai para **um** dos acumuladores:

```
100% < percentual ≤ limiteDesgaste  →  perdaTolerancia += perdaBico
percentual > limiteDesgaste         →  perdaDesgaste   += perdaBico
percentual == 100%                  →  nenhuma faixa (perdaBico = 0)
percentual == limiteDesgaste (105%) →  tolerância (não desgaste)
```

```
perdaTotal = perdaTolerancia + perdaDesgaste
           = Σ perdaBico  (para todas as pontas com percentual > 100%)
```

| Output             | Unidade | Descrição                                              |
|--------------------|---------|--------------------------------------------------------|
| `perdaTolerancia`  | R$      | Soma das perdas na faixa 100% < % ≤ `limiteDesgaste`   |
| `perdaDesgaste`    | R$      | Soma das perdas com % > `limiteDesgaste`               |
| `perdaTotal`       | R$      | Soma das duas parcelas (compara com `custoTrocaTotal`) |
| `recomendarTroca`  | bool    | Inalterado: `perdaTotal >= custoTrocaTotal`            |

---

## Sub-cálculo B — Custo de Troca Completa

```
custoTrocaTotal = precoBico × numeroPontas
```

| Variável      | Unidade | Origem                         |
|---------------|---------|--------------------------------|
| `precoBico`   | R$/un   | Campo "Preço do Bico (R$)"     |
| `numeroPontas`| unid    | Campo "Número de Pontas"       |

---

## Sub-cálculo C — Recomendação de Troca

```
recomendarTroca = (perdaTotal >= custoTrocaTotal) AND (custoTrocaTotal > 0)
```

| Condição                      | Recomendação                                |
|-------------------------------|---------------------------------------------|
| `perdaTotal >= custoTrocaTotal`| 🚨 **TROCA COMPLETA dos bicos**             |
| `perdaTotal < custoTrocaTotal` | ✅ **Troca seletiva das pontas problemáticas** |

---

## Implementação Dart (AgroCalc)

```dart
class ResultadoEconomico {
  final double perdaTotal;
  final double custoTrocaTotal;
  final bool recomendarTroca;

  const ResultadoEconomico({
    required this.perdaTotal,
    required this.custoTrocaTotal,
    required this.recomendarTroca,
  });
}

/// Calcula a perda estimada por excesso de vazão em uma única ponta.
///
/// [percentual]    Saída do Cálculo 02.
/// [manejoRS]      Custo total do manejo em R$.
/// [numeroPontas]  Número total de pontas da barra.
/// [areaHa]        Área a ser aplicada em ha.
///
/// Retorna 0.0 se o percentual não for superior a 100% ou entradas inválidas.
double calcularPerdaPorPonta({
  required double percentual,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
}) {
  if (percentual <= 100.0 || numeroPontas <= 0 || areaHa <= 0 || manejoRS <= 0) {
    return 0.0;
  }
  final excesso = (percentual - 100.0) / 100.0;
  final custoManejoP = manejoRS / numeroPontas;
  return excesso * custoManejoP * areaHa;
}

/// Executa a análise econômica completa para toda a barra.
///
/// [percentuais]   Lista com o percentual de cada ponta (Cálculo 02).
/// [manejoRS]      Custo total do manejo em R$.
/// [numeroPontas]  Total de pontas da barra.
/// [areaHa]        Área da aplicação em ha.
/// [precoBico]     Preço unitário de um bico em R$.
ResultadoEconomico analisarEconomia({
  required List<double> percentuais,
  required double manejoRS,
  required int numeroPontas,
  required double areaHa,
  required double precoBico,
}) {
  final perdaTotal = percentuais.fold(0.0, (acc, p) {
    return acc + calcularPerdaPorPonta(
      percentual: p,
      manejoRS: manejoRS,
      numeroPontas: numeroPontas,
      areaHa: areaHa,
    );
  });

  final custoTrocaTotal = precoBico * numeroPontas;
  final recomendarTroca = custoTrocaTotal > 0 && perdaTotal >= custoTrocaTotal;

  return ResultadoEconomico(
    perdaTotal: perdaTotal,
    custoTrocaTotal: custoTrocaTotal,
    recomendarTroca: recomendarTroca,
  );
}
```

---

## Exemplo numérico

**Cenário:** 24 pontas, manejo = R$ 2.400, área = 500 ha, preço bico = R$ 35

Pontas com excesso:

| Ponta | percentual | faixa      | perdaBico    |
|-------|------------|------------|--------------|
| 3     | 108,0 %    | Desgaste   | R$ 4.000     |
| 7     | 106,5 %    | Desgaste   | R$ 3.250     |
| 19    | 110,2 %    | Desgaste   | R$ 5.100     |

```
perdaTolerancia = R$ 0,00        (nenhuma ponta ≤ 105% neste cenário)
perdaDesgaste   = R$ 12.350,00
perdaTotal      = R$ 12.350,00
custoTrocaTotal = 35 × 24              = R$ 840,00
recomendarTroca = 12.350 >= 840        = TRUE  🚨 TROCA COMPLETA
```

---

## Card visual gerado (Flutter)

```
┌─────────────────────────────────────────────────────┐
│  💰  Análise Econômica                              │
│                                                     │
│  Perda por Desgaste:            R$ 12.350,00        │
│  Perda Total Estimada:          R$ 12.350,00        │
│  Custo troca completa:          R$    840,00         │
│                                                     │
│  🚨 Recomendação: TROCA COMPLETA dos bicos          │
└─────────────────────────────────────────────────────┘
```

---

## Regras de negócio

- O card **só aparece** quando `perdaTotal > 0 AND custoTrocaTotal > 0`.
- Cor **laranja** quando `recomendarTroca = true`; **cinza** caso contrário.
- Valores exibidos com **2 casas decimais** (`toStringAsFixed(2)`).
- **Não substitui** laudo técnico: é orientação quantitativa de suporte à decisão.

---

## Cálculo derivado — Ponta R$ (custo unitário de regulagem)

Exibido no formulário superior, fora do card econômico:

```
pontaRS = manejoRS / numeroPontas
```

```dart
double calcularPontaRS({
  required double manejoRS,
  required int numeroPontas,
}) {
  if (numeroPontas <= 0) return 0.0;
  return manejoRS / numeroPontas;
}
```

---

## Testes unitários obrigatórios

```dart
group('calcularPerdaPorPonta', () {
  test('108% → perda correta', () {
    expect(
      calcularPerdaPorPonta(
        percentual: 108.0,
        manejoRS: 2400,
        numeroPontas: 24,
        areaHa: 500,
      ),
      closeTo(4000.0, 0.01),
    );
  });

  test('100% exato → sem perda', () {
    expect(
      calcularPerdaPorPonta(
        percentual: 100.0,
        manejoRS: 2400,
        numeroPontas: 24,
        areaHa: 500,
      ),
      equals(0.0),
    );
  });

  test('99% → sem perda (abaixo de 100%)', () {
    expect(
      calcularPerdaPorPonta(
        percentual: 99.0,
        manejoRS: 2400,
        numeroPontas: 24,
        areaHa: 500,
      ),
      equals(0.0),
    );
  });

  test('área zero → sem perda', () {
    expect(
      calcularPerdaPorPonta(
        percentual: 110.0,
        manejoRS: 2400,
        numeroPontas: 24,
        areaHa: 0,
      ),
      equals(0.0),
    );
  });
});

group('analisarEconomia', () {
  test('cenário exemplo doc → recomendarTroca true', () {
    final r = analisarEconomia(
      percentuais: [108.0, 106.5, 110.2, 100.0, 88.0], // 3 com excesso
      manejoRS: 2400,
      numeroPontas: 24,
      areaHa: 500,
      precoBico: 35,
    );
    expect(r.perdaTotal, closeTo(12350.0, 1.0));
    expect(r.custoTrocaTotal, closeTo(840.0, 0.01));
    expect(r.recomendarTroca, isTrue);
  });

  test('perda menor que troca → seletiva', () {
    final r = analisarEconomia(
      percentuais: [101.0], // excesso mínimo
      manejoRS: 100,
      numeroPontas: 10,
      areaHa: 5,
      precoBico: 50,
    );
    expect(r.recomendarTroca, isFalse);
  });

  test('custo troca zero → nunca recomenda', () {
    final r = analisarEconomia(
      percentuais: [150.0],
      manejoRS: 2400,
      numeroPontas: 24,
      areaHa: 500,
      precoBico: 0, // bico grátis
    );
    expect(r.recomendarTroca, isFalse);
  });
});

group('calcularPontaRS', () {
  test('2400 / 24 = 100.0', () {
    expect(calcularPontaRS(manejoRS: 2400, numeroPontas: 24), equals(100.0));
  });

  test('numeroPontas zero → 0.0', () {
    expect(calcularPontaRS(manejoRS: 2400, numeroPontas: 0), equals(0.0));
  });
});
```
