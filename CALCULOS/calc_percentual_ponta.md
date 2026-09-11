# Cálculo 02 — Percentual da Ponta (% Pontas)

> **Onde vive:** `PulverizadorRegulagem` → `calcularStatus()` + loop `estatisticas` (useMemo)  
> **Alimenta:** classificação de status, gráfico, contadores de Desgaste / Irregular / Ideal

---

## Finalidade

Expressa **quanto, em percentual, cada ponta medida no campo difere da vazão ideal**. É o número que o técnico lê na coluna **"% Pontas"** da tabela e que dispara toda a lógica de classificação (Ideal / Irregular / Desgaste).

---

## Entradas

| Variável        | Unidade | Origem                             |
|-----------------|---------|------------------------------------|
| `valorMedido`   | L/min   | Input do técnico, ponta a ponta    |
| `litroMinIdeal` | L/min   | Saída do Cálculo 01                |

---

## Fórmula

```
percentual = (valorMedido ÷ litroMinIdeal) × 100
```

---

## Implementação Dart (AgroCalc)

```dart
/// Calcula o percentual de uma ponta em relação ao ideal.
///
/// [valorMedido]   Medição coletada no campo em L/min.
/// [litroMinIdeal] Referência calculada pelo Cálculo 01 em L/min.
///
/// Retorna 0.0 se [valorMedido] for nulo ou [litroMinIdeal] <= 0.
double calcularPercentualPonta({
  required double? valorMedido,
  required double litroMinIdeal,
}) {
  if (valorMedido == null || valorMedido <= 0 || litroMinIdeal <= 0) {
    return 0.0;
  }
  return (valorMedido / litroMinIdeal) * 100.0;
}
```

---

## Exemplo numérico

| Cenário           | valorMedido | litroMinIdeal | percentual |
|-------------------|-------------|---------------|------------|
| Ponta ideal       | 2,25 L/min  | 2,25 L/min    | 100,0 %    |
| Ponta com desgaste| 2,45 L/min  | 2,25 L/min    | 108,9 %    |
| Ponta entupida    | 2,00 L/min  | 2,25 L/min    |  88,9 %    |

---

## Regras de negócio

- Exibido com **1 casa decimal** (`toStringAsFixed(1)`) seguida do símbolo `%`.
- Se `valorMedido` for `null` (campo não preenchido), exibe `—` na célula, sem calcular.
- Guarda-chuva de todo o sistema de classificação: **os limiares abaixo usam este valor**.

---

## Limiares padrão (configuráveis via props)

| Limiar            | Valor padrão | Prop                |
|-------------------|--------------|---------------------|
| Desgaste acima de | 105 %        | `limiteDesgaste`    |
| Irregular abaixo  | 100 %        | `limiteIrregular`   |
| Tolerância mín    | 100,5 %      | `toleranciaMin`     |
| Tolerância máx    | 104,99 %     | `toleranciaMax`     |

---

## Testes unitários obrigatórios

```dart
group('calcularPercentualPonta', () {
  test('ponta perfeita → 100.0%', () {
    expect(
      calcularPercentualPonta(valorMedido: 2.25, litroMinIdeal: 2.25),
      closeTo(100.0, 0.01),
    );
  });

  test('ponta com desgaste → > 105%', () {
    final p = calcularPercentualPonta(valorMedido: 2.45, litroMinIdeal: 2.25);
    expect(p, greaterThan(105.0));
  });

  test('ponta entupida → < 100%', () {
    final p = calcularPercentualPonta(valorMedido: 2.00, litroMinIdeal: 2.25);
    expect(p, lessThan(100.0));
  });

  test('valorMedido nulo → retorna 0.0', () {
    expect(
      calcularPercentualPonta(valorMedido: null, litroMinIdeal: 2.25),
      equals(0.0),
    );
  });

  test('litroMinIdeal zero → retorna 0.0 (sem divisão por zero)', () {
    expect(
      calcularPercentualPonta(valorMedido: 2.25, litroMinIdeal: 0),
      equals(0.0),
    );
  });
});
```
