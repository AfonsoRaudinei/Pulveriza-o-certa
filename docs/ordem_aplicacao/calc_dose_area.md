# Cálculo — Quantidade total do produto

> **Onde vive:** `lib/domain/ordem_aplicacao/calc_quantidade_total.dart`  
> **Quem consome:** etapa Produtos & Dose (campo readonly Qtd Total)  
> **Origem:** `quantidadeTotal = dose × areaAplicar` do formulário React

## Finalidade

Converte a dose por hectare na quantidade física a separar para a área a aplicar.

## Entradas

| Variável | Unidade | Descrição |
|---|---|---|
| `dose` | unidade/ha | Dose informada |
| `areaAplicar` | ha | Área a aplicar da etapa 1 |

## Fórmula

```
quantidadeTotal = dose × areaAplicar
```

Retorna `0.0` se `dose <= 0` ou `areaAplicar <= 0`.

Recalcular a cada mudança de dose ou de área (equivalente ao `useEffect` da referência).

## Exemplo numérico

| Parâmetro | Valor |
|---|---|
| Dose | 1,5 L/ha |
| Área a aplicar | 80 ha |
| Quantidade total | **120 L** |

A unidade da quantidade total é a parte à esquerda de `/ha` (L, kg, ml, g, un, sc).
