# Cálculo — Totais consolidados por unidade

> **Onde vive:** `lib/domain/ordem_aplicacao/calc_totais_unidade.dart`  
> **Quem consome:** chips da etapa Produtos & Dose

## Finalidade

Somar `quantidadeTotal` dos produtos agrupados pela unidade de dose.

## Fórmula

Para cada unidade distinta na lista:

```
total(unidade) = Σ quantidadeTotal dos itens com essa unidade
```

Itens com `quantidadeTotal == 0` entram no grupo mas somam zero.

## Exemplo numérico

- Produto A: 1,5 L/ha × 80 ha = 120 L
- Produto B: 0,4 L/ha × 80 ha = 32 L
- Produto C: 200 g/ha × 80 ha = 16 000 g

Totais: **152 L** e **16000 g**.
