# Cálculo 07 — Valor Total da Safra (R$)

> **Onde vive:** `RegulagemScreen` → card **Contexto da Operação**  
> **Alimenta:** campo readonly "Valor Total da Safra (R$)" abaixo de Manejo (R$)

---

## Finalidade

Estima o **custo total de manejo da safra** multiplicando o custo por hectare pela área da operação. Dá ao consultor uma referência econômica imediata do volume financeiro envolvido na área regulada, antes da análise por ponta.

---

## Entradas

| Variável     | Unidade | Campo no formulário | Descrição                              |
|--------------|---------|---------------------|----------------------------------------|
| `manejoRS`   | R$/ha   | Manejo (R$)         | Custo de manejo por hectare            |
| `areaHa`     | ha      | Área (ha)           | Área total da operação                 |

---

## Fórmula

```
valorTotalSafra = manejoRS × areaHa
```

### Derivação dimensional

```
  [R$/ha] × [ha] = R$
```

O manejo informado é **por hectare**; multiplicado pela área total, resulta no valor financeiro da safra naquela extensão.

---

## Implementação Dart (AgroCalc)

```dart
/// Calcula o valor total da safra em reais.
///
/// [manejoRS] Custo de manejo por hectare (R$/ha).
/// [areaHa]   Área da operação em hectares.
///
/// Retorna 0.0 se qualquer entrada for nula, zero ou negativa.
double calcularValorTotalSafra({
  required double manejoRS,
  required double areaHa,
}) {
  if (manejoRS <= 0 || areaHa <= 0) return 0;
  return manejoRS * areaHa;
}
```

Arquivo: `lib/domain/calculos/calc_valor_total_safra.dart`  
Fachada UI: `CalcUtils.calcularValorTotalSafra()` em `lib/core/utils/calculo_utils.dart`.

---

## Exemplo numérico

| Parâmetro | Valor     |
|-----------|-----------|
| Manejo    | R$ 600,00 |
| Área      | 700 ha    |

```
valorTotalSafra = 600 × 700
                = R$ 420.000,00
```

---

## Regras de negócio

- Se **qualquer** entrada for `<= 0` ou vazia (parseada como 0), o resultado é exibido como **R$ 0,00** — sem exceção.
- O valor recalcula **reativamente** sempre que Área ou Manejo mudam (`_updateEconomiaFromControllers`).
- Exibição monetária pt-BR com 2 casas decimais (`toMoeda()`).
- Campo **somente leitura**, fundo `AppColors.primaryLight` (padrão `_ReadonlyResult`).
- **Valores negativos:** os inputs decimais do card não permitem sinal `-` (formatador `[0-9.,]`). Se chegarem negativos por outro caminho (ex.: JSON legado), a função trata como 0.

---

## Testes unitários obrigatórios

| Cenário                         | manejoRS | areaHa | Esperado    |
|---------------------------------|----------|--------|-------------|
| Exemplo do documento            | 600      | 700    | 420000.00   |
| Manejo zero                     | 0        | 700    | 0.00        |
| Área zero                       | 600      | 0      | 0.00        |
| Manejo negativo                 | -600     | 700    | 0.00        |
| Área negativa                   | 600      | -700   | 0.00        |

Arquivo: `test/domain/calculos/calc_valor_total_safra_test.dart`
