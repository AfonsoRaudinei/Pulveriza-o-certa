# Cálculo 01 — Litro por Minuto Ideal (L/min por Ponta)

> **Onde vive:** `FormularioProgressivo` → `litroMinIdealCalculado` (useMemo)  
> **Quem consome:** `PulverizadorRegulagem` via prop `litroMinIdeal`

---

## Finalidade

Determina a **vazão esperada por ponta** (em L/min) com base nos parâmetros operacionais configurados pelo técnico. É o valor de referência central de toda a regulagem: cada ponta medida no campo é comparada contra ele.

---

## Entradas

| Variável       | Unidade | Campo no formulário       | Descrição                                      |
|----------------|---------|---------------------------|------------------------------------------------|
| `vazao`        | L/ha    | Vazão (L/ha)              | Volume de calda a aplicar por hectare          |
| `velocidade`   | km/h    | Velocidade (km/h)         | Velocidade de deslocamento do pulverizador     |
| `espacamento`  | cm      | Espaçamento Bicos (cm)    | Distância entre pontas na barra                |

---

## Fórmula

```
litroMinIdeal = (vazao × velocidade × (espacamento ÷ 100)) ÷ 600
```

### Derivação dimensional

```
  [L/ha] × [km/h] × [m]
= [L/ha] × [1000 m/h] × [m]
= L · m / (ha · h / 1000)

1 ha = 10.000 m²  →  1 ha = 10.000 m × 1 m
Largura de faixa por ponta = espacamento (m)

L/min = (L/ha × km/h × m) / 600
```

O divisor **600** unifica km/h → m/min e m² → ha em uma única constante:  
`600 = 10 (ha→m² escala) × 60 (h→min)`

---

## Implementação Dart (AgroCalc)

```dart
/// Calcula a vazão ideal por ponta em L/min.
///
/// [vazaoLHa]      Vazão desejada em litros por hectare.
/// [velocidadeKmH] Velocidade de aplicação em km/h.
/// [espacamentoCm] Espaçamento entre pontas em centímetros.
///
/// Retorna 0.0 se qualquer entrada for nula, zero ou negativa.
double calcularLitroMinIdeal({
  required double vazaoLHa,
  required double velocidadeKmH,
  required double espacamentoCm,
}) {
  if (vazaoLHa <= 0 || velocidadeKmH <= 0 || espacamentoCm <= 0) {
    return 0.0;
  }

  final espacamentoM = espacamentoCm / 100.0;
  return (vazaoLHa * velocidadeKmH * espacamentoM) / 600.0;
}
```

---

## Exemplo numérico

| Parâmetro       | Valor    |
|-----------------|----------|
| Vazão           | 150 L/ha |
| Velocidade      | 18 km/h  |
| Espaçamento     | 50 cm    |

```
litroMinIdeal = (150 × 18 × 0,50) / 600
             = 1.350 / 600
             = 2,25 L/min por ponta
```

---

## Regras de negócio

- Se **qualquer** entrada for `<= 0`, o resultado é exibido como `0,00` (campo readonly azul).
- O valor é recalculado **reativamente** toda vez que `vazao`, `velocidade` ou `espacamento` mudam.
- Exibido com **2 casas decimais** (`toStringAsFixed(2)`).
- Alimenta diretamente a coluna **"Ideal (L/min)"** da tabela de pontas.

---

## Testes unitários obrigatórios

```dart
group('calcularLitroMinIdeal', () {
  test('caso nominal — 150 L/ha, 18 km/h, 50 cm → 2.25', () {
    expect(
      calcularLitroMinIdeal(vazaoLHa: 150, velocidadeKmH: 18, espacamentoCm: 50),
      closeTo(2.25, 0.001),
    );
  });

  test('vazão zero → retorna 0', () {
    expect(
      calcularLitroMinIdeal(vazaoLHa: 0, velocidadeKmH: 18, espacamentoCm: 50),
      equals(0.0),
    );
  });

  test('velocidade negativa → retorna 0', () {
    expect(
      calcularLitroMinIdeal(vazaoLHa: 150, velocidadeKmH: -5, espacamentoCm: 50),
      equals(0.0),
    );
  });

  test('espaçamento zero → retorna 0', () {
    expect(
      calcularLitroMinIdeal(vazaoLHa: 150, velocidadeKmH: 18, espacamentoCm: 0),
      equals(0.0),
    );
  });
});
```
