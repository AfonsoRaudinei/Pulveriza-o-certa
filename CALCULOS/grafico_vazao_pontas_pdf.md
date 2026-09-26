# Gráfico “Vazão por ponta” — eixo e laudo PDF

> **Onde vive:** `lib/core/charts/vazao_chart_data.dart` (eixo, tela + PDF)  
> **Planejamento PDF:** `lib/core/charts/vazao_chart_pdf_plan.dart`  
> **Desenho PDF:** `_paintChart` em `lib/services/regulagem_pdf_service.dart`  
> **Domínio:** não muda. Percentual e status continuam em `lib/domain/calculos/`.

---

## 1. Cálculos de domínio reutilizados (sem alteração)

### Percentual da ponta

```
percentual = (valorMedido ÷ litroMinIdeal) × 100
```

`null` (sem medição) não entra no eixo. `0` medido entra como 0% e é classificado como Entupida.

### Status (limites configurados)

| Condição | Zona |
|---|---|
| `percentual < limiteEntupido` | Entupida |
| `limiteEntupido ≤ percentual ≤ 100` | Ideal |
| `100 < percentual ≤ limiteDesgaste` | Atenção |
| `percentual > limiteDesgaste` | Desgaste |
| `valorMedido == null` | Pendente |

Padrão de config: `limiteEntupido = 97`, `limiteDesgaste = 105`.

---

## 2. Janela vertical (eixo Y em %)

Constantes:

| Nome | Valor | Função |
|---|---|---|
| `folgaExtremos` | 25 pp | teto/piso dos **dados** em torno dos limites |
| `margemMinima` | 3 pp | folga mínima acima/abaixo da janela |
| `margemFator` | 0,12 | 12% da amplitude já limitada |
| `alcanceMaximo` | 60 pp | não deixa uma ponta em 0% achatar o gráfico |

### Passo a passo

```
1. Começa contendo os referenciais:
   inferior = min(limiteEntupido, 100)
   superior = max(limiteDesgaste, 100)

2. Abre para os dados (só pontas medidas):
   inferior = min(inferior, menores %)
   superior = max(superior, maiores %)

3. ANTES da margem, limita os extremos dos dados:
   inferior = máx(inferior, limiteEntupido − 25)
   superior = mín(superior, limiteDesgaste + 25)

4. Margem:
   margem = máx(3, (superior − inferior) × 0,12)

5. Janela:
   maxY = superior + margem
   minY = inferior − margem

6. A janela final sempre contém limiteEntupido, 100 e limiteDesgaste
   (se o alcance de 60 pp empurrar o piso, o referencial ganha).

7. Barra fora de [minY, maxY] é cortada (`percentualNoEixo`).
   O rótulo mostra o % real. No PDF, indicador de “continua”.
```

Todos os gráficos do mesmo laudo usam esta janela (`fatiaComEscala`), para o eixo em % ser comparável.

### Exemplo de conferência — 95% e 200%, limites 97 / 105

Ideal = 1,000 L/min → pontas 0,950 e 2,000 L/min.

```
inferior inicial = min(97, 100) = 97
superior inicial = max(105, 100) = 105

com dados:     inferior = 95    superior = 200
após teto ±25: inferior = máx(95, 97−25) = 95
               superior = mín(200, 105+25) = 130

margem = máx(3, (130 − 95) × 0,12) = máx(3, 4,2) = 4,2

maxY = 130 + 4,2 = 134,2
minY = 95 − 4,2  = 90,8
```

| Checagem | Resultado |
|---|---|
| 97, 100 e 105 dentro de 90,8–134,2 | sim |
| linha de 100% visível | sim |
| barra de 95% | inteira (95 > 90,8) |
| barra de 200% | cortada no topo (200 > 134,2) |
| rótulo da barra 200% | valor real `200.0` (não 134,2) |

---

## 3. Planejamento dos gráficos no PDF

`maxPontasPorGraficoPdf = 20` (única constante para mudar o máximo).

```
se n ≤ 20:  1 gráfico, lado da conferência
se n > 20:  1ª metade = lado direito (D), resto = esquerdo (E)
se um lado > 20:
  k = ceil(nLado / 20)
  tamanho = ceil(nLado / k)     → blocos iguais
```

| Pontas | Gráficos | Títulos |
|---|---|---|
| 10 | 1 | `Vazão por ponta: lado direito (1D a 10D)` |
| 30 | 2 | `1D a 15D` e `1E a 15E` |
| 60 | 4 | `1D–15D`, `16D–30D`, `1E–15E`, `16E–30E` |
| 45 num lado | 3 | três blocos de 15 |

- Legenda de marcadores só no **primeiro** gráfico.
- Subtítulo lê os limites: faixa verde `entupido–100%`, faixa laranja `100–desgaste%`.
- Cada gráfico é `pw.Inseparable` (não quebra no meio da página), altura 200 pt.

### Geometria da barra

```
slot     = larguraÚtil / nPontasDoBloco
barWidth = mín(16, slot × 0,40)
```

Rótulo do eixo X = nome da ponta. Com 20 pontas no bloco, rótulos a 90°. Sobre a barra: 1 casa decimal; sem `%` se o bloco tiver mais de 10 pontas; fonte 8,5 pt.

A **tabela** das pontas continua completa e o cabeçalho de colunas se repete a cada página.

---

## 4. O que isto não calcula

Perda em R$, troca de bicos, CV% e classificação de zona **não** passam por este arquivo. Só a janela do gráfico e o fatiamento visual do laudo.
