# Cálculo 03 — Classificação de Status da Ponta

> **Onde vive:** `PulverizadorRegulagem` → `calcularStatus()` + bloco `estatisticas` (useMemo)  
> **Alimenta:** badge de status na tabela, cor da linha, contadores, gráfico, cards orientativos

---

## Finalidade

Converte o **percentual da ponta** (Cálculo 02) em um dos três estados operacionais que o técnico enxerga na tela. É a decisão central da regulagem de barra.

---

## Entradas

| Variável         | Tipo    | Origem          |
|------------------|---------|-----------------|
| `percentual`     | double  | Cálculo 02      |
| `limiteDesgaste` | double  | prop (padrão: 105)   |
| `limiteIrregular`| double  | prop (padrão: 100)   |

---

## Lógica de classificação

```
SE percentual > limiteDesgaste  → "Desgaste"   🔴
SE percentual < limiteIrregular → "Irregular"  🟡
SENÃO                           → "Ideal"      🟢
```

### Diagrama de limiares padrão

```
  0%         88%        100%       105%       ∞
  |-----------|----------|----------|----------|
  [  Irregular (< 100%)  ][ Ideal  ][  Desgaste (> 105%)  ]
```

> **Zona cinza (100% – 105%):** tecnicamente "Ideal" pela classificação primária,  
> mas refinada pelo Cálculo 04 (Tolerância) para monitoramento avançado.

---

## Implementação Dart (AgroCalc)

```dart
enum StatusPonta { ideal, irregular, desgaste, pendente }

class ResultadoStatus {
  final double percentual;
  final StatusPonta status;

  const ResultadoStatus({required this.percentual, required this.status});
}

/// Classifica uma ponta com base no percentual medido.
///
/// [percentual]      Saída do Cálculo 02 (pode ser 0.0 se sem medição).
/// [limiteDesgaste]  Limite superior; acima → Desgaste. Padrão: 105.
/// [limiteIrregular] Limite inferior; abaixo → Irregular. Padrão: 100.
ResultadoStatus classificarPonta({
  required double percentual,
  double limiteDesgaste = 105.0,
  double limiteIrregular = 100.0,
}) {
  if (percentual <= 0) {
    return ResultadoStatus(percentual: 0, status: StatusPonta.pendente);
  }
  if (percentual > limiteDesgaste) {
    return ResultadoStatus(percentual: percentual, status: StatusPonta.desgaste);
  }
  if (percentual < limiteIrregular) {
    return ResultadoStatus(percentual: percentual, status: StatusPonta.irregular);
  }
  return ResultadoStatus(percentual: percentual, status: StatusPonta.ideal);
}
```

---

## Mapeamento visual (Flutter)

```dart
Color corDeFundo(StatusPonta status) => switch (status) {
  StatusPonta.desgaste  => const Color(0xFFFFF1F1), // red-50
  StatusPonta.irregular => const Color(0xFFFFFBEB), // yellow-50
  StatusPonta.ideal     => const Color(0xFFF0FDF4), // green-50
  StatusPonta.pendente  => const Color(0xFFF9FAFB), // gray-50
};

Color corDeTexto(StatusPonta status) => switch (status) {
  StatusPonta.desgaste  => const Color(0xFFB91C1C), // red-700
  StatusPonta.irregular => const Color(0xFFB45309), // yellow-700
  StatusPonta.ideal     => const Color(0xFF15803D), // green-700
  StatusPonta.pendente  => const Color(0xFF6B7280), // gray-500
};

String rotulo(StatusPonta status) => switch (status) {
  StatusPonta.desgaste  => 'Desgaste',
  StatusPonta.irregular => 'Irregular',
  StatusPonta.ideal     => 'Ideal',
  StatusPonta.pendente  => '—',
};
```

---

## Exemplo numérico

| Ponta | valorMedido | percentual | limDesgaste | limIrregular | Status     |
|-------|-------------|------------|-------------|--------------|------------|
| 1     | 2,25 L/min  | 100,0 %    | 105         | 100          | ✅ Ideal   |
| 2     | 2,45 L/min  | 108,9 %    | 105         | 100          | 🔴 Desgaste|
| 3     | 2,00 L/min  |  88,9 %    | 105         | 100          | 🟡 Irregular|
| 4     | —           |   0,0 %    | 105         | 100          | — Pendente |

---

## Efeitos colaterais visuais

| Status     | Cor da linha (TableRow) | Cor do badge       | Ícone         |
|------------|-------------------------|--------------------|---------------|
| Desgaste   | `red-50`                | `red-100/red-800`  | TrendingUp    |
| Irregular  | `yellow-50`             | `yellow-100/800`   | AlertTriangle |
| Ideal      | `green-50`              | `green-100/800`    | CheckCircle   |
| Pendente   | —                       | —                  | —             |

---

## Testes unitários obrigatórios

```dart
group('classificarPonta', () {
  test('100% → Ideal', () {
    final r = classificarPonta(percentual: 100.0);
    expect(r.status, StatusPonta.ideal);
  });

  test('102% → Ideal (dentro da faixa)', () {
    final r = classificarPonta(percentual: 102.0);
    expect(r.status, StatusPonta.ideal);
  });

  test('106% → Desgaste', () {
    final r = classificarPonta(percentual: 106.0);
    expect(r.status, StatusPonta.desgaste);
  });

  test('105% exato → Ideal (limite exclusivo)', () {
    // > 105 → desgaste; == 105 ainda é ideal
    final r = classificarPonta(percentual: 105.0);
    expect(r.status, StatusPonta.ideal);
  });

  test('99% → Irregular', () {
    final r = classificarPonta(percentual: 99.0);
    expect(r.status, StatusPonta.irregular);
  });

  test('sem medição (0%) → Pendente', () {
    final r = classificarPonta(percentual: 0.0);
    expect(r.status, StatusPonta.pendente);
  });

  test('limiares customizados', () {
    final r = classificarPonta(
      percentual: 108.0,
      limiteDesgaste: 110.0,
    );
    expect(r.status, StatusPonta.ideal); // 108 < 110 → ideal
  });
});
```
