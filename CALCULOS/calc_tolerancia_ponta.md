# Cálculo 04 — Tolerância da Ponta (Zona de Atenção)

> **Onde vive:** `PulverizadorRegulagem` → bloco `estatisticas` (useMemo), FASE 3  
> **Alimenta:** cards "Tolerância" (azul) e "Acima Min" (roxo) no painel de indicadores

---

## Finalidade

Refina a classificação "Ideal" em duas sub-categorias de atenção preventiva. Uma ponta tecnicamente ideal (100%–105%) pode estar **na zona de desgaste iminente** — este cálculo identifica isso antes que vire um problema de campo.

É o único cálculo que **não gera ação imediata**, mas dispara **recomendação de monitoramento redobrado**.

---

## Entradas

| Variável          | Tipo   | Origem                   | Padrão   |
|-------------------|--------|--------------------------|----------|
| `percentual`      | double | Cálculo 02               | —        |
| `toleranciaMin`   | double | prop `toleranciaMin`     | 100,5 %  |
| `toleranciaMax`   | double | prop `toleranciaMax`     | 104,99 % |

---

## Duas verificações independentes

### 4a — Ponta "Entre Tolerâncias" (zona de atenção plena)

```
entreTolerancias = percentual >= toleranciaMin AND percentual <= toleranciaMax
```

Conta pontas que estão **exatamente na faixa de desgaste iminente**:  
acima do mínimo operacional mas ainda abaixo do limite de desgaste.

### 4b — Ponta "Acima Tolerância Mínima" (zona de tendência)

```
acimaToleranciaMIN = percentual >= toleranciaMin
```

Conta **todas** as pontas que já ultrapassaram o limiar mínimo de tolerância —  
inclui as "entre tolerâncias" **mais** as que já atingiram desgaste.  
Útil para o técnico visualizar a tendência geral da barra.

---

## Diagrama completo dos limiares (valores padrão)

```
  0%      88%      100%   100,5%       104,99%  105%     ∞
  |--------|--------|-------|------------|--------|---------|
  [Irregular]  [ok] [  Tolerância (azul)          ][Desgaste]
                           [    Acima Min (roxo) →         ]
```

---

## Implementação Dart (AgroCalc)

```dart
class ResultadoTolerancia {
  final bool entreTolerancias;
  final bool acimaToleranciaMIN;

  const ResultadoTolerancia({
    required this.entreTolerancias,
    required this.acimaToleranciaMIN,
  });
}

/// Verifica a posição de uma ponta nas zonas de tolerância.
///
/// [percentual]     Saída do Cálculo 02.
/// [toleranciaMin]  Limite inferior da zona de atenção. Padrão: 100.5.
/// [toleranciaMax]  Limite superior da zona de atenção. Padrão: 104.99.
ResultadoTolerancia verificarTolerancia({
  required double percentual,
  double toleranciaMin = 100.5,
  double toleranciaMax = 104.99,
}) {
  final acima = percentual >= toleranciaMin;
  final entre = acima && percentual <= toleranciaMax;

  return ResultadoTolerancia(
    entreTolerancias: entre,
    acimaToleranciaMIN: acima,
  );
}

/// Agrega os resultados de tolerância para toda a barra.
({int entreTolerancias, int acimaToleranciaMIN}) agregarTolerancia({
  required List<double> percentuais,
  double toleranciaMin = 100.5,
  double toleranciaMax = 104.99,
}) {
  int entre = 0;
  int acima = 0;

  for (final p in percentuais) {
    final r = verificarTolerancia(
      percentual: p,
      toleranciaMin: toleranciaMin,
      toleranciaMax: toleranciaMax,
    );
    if (r.entreTolerancias) entre++;
    if (r.acimaToleranciaMIN) acima++;
  }

  return (entreTolerancias: entre, acimaToleranciaMIN: acima);
}
```

---

## Exemplo numérico — barra com 5 pontas

| Ponta | percentual | entreTolerancias | acimaToleranciaMIN |
|-------|------------|------------------|--------------------|
| 1     |  88,0 %    | ❌               | ❌                 |
| 2     | 100,0 %    | ❌               | ❌                 |
| 3     | 101,5 %    | ✅               | ✅                 |
| 4     | 103,0 %    | ✅               | ✅                 |
| 5     | 107,0 %    | ❌               | ✅ (acima do max)  |

**Resultado dos contadores:**  
- `entreTolerancias` = 2 (pontas 3 e 4)  
- `acimaToleranciaMIN` = 3 (pontas 3, 4 e 5)

---

## Card visual gerado (Flutter)

```
┌─────────────────────────────────────┐
│  🔵  Tolerância      [2]           │  azul — entreTolerancias
│      100.5% – 104.99%              │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│  🟣  Acima Min       [3]           │  roxo — acimaToleranciaMIN
│      ≥ 100.5%                      │
└─────────────────────────────────────┘
```

---

## Orientação exibida ao técnico

> **"X pontas em tolerância — Monitoramento redobrado recomendado.  
> Considere troca preventiva em breve."**

---

## Testes unitários obrigatórios

```dart
group('verificarTolerancia', () {
  test('88% → fora de tudo', () {
    final r = verificarTolerancia(percentual: 88.0);
    expect(r.entreTolerancias, isFalse);
    expect(r.acimaToleranciaMIN, isFalse);
  });

  test('100.0% → abaixo do min de tolerância', () {
    final r = verificarTolerancia(percentual: 100.0);
    expect(r.entreTolerancias, isFalse);
    expect(r.acimaToleranciaMIN, isFalse);
  });

  test('100.5% → no limite mínimo → entra em ambas', () {
    final r = verificarTolerancia(percentual: 100.5);
    expect(r.entreTolerancias, isTrue);
    expect(r.acimaToleranciaMIN, isTrue);
  });

  test('103.0% → entre tolerâncias', () {
    final r = verificarTolerancia(percentual: 103.0);
    expect(r.entreTolerancias, isTrue);
    expect(r.acimaToleranciaMIN, isTrue);
  });

  test('104.99% → no limite máximo → ainda entre', () {
    final r = verificarTolerancia(percentual: 104.99);
    expect(r.entreTolerancias, isTrue);
  });

  test('105.0% → acima do max → só acimaMIN', () {
    final r = verificarTolerancia(percentual: 105.0);
    expect(r.entreTolerancias, isFalse);
    expect(r.acimaToleranciaMIN, isTrue);
  });
});

group('agregarTolerancia', () {
  test('barra com 5 pontas — exemplo numérico do doc', () {
    final r = agregarTolerancia(
      percentuais: [88.0, 100.0, 101.5, 103.0, 107.0],
    );
    expect(r.entreTolerancias, equals(2));
    expect(r.acimaToleranciaMIN, equals(3));
  });
});
```
