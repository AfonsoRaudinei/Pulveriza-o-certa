# Tela — Nova / Editar Ordem de Aplicação

> **Rota:** `/ordem-aplicacao`  
> **Arquivo:** `lib/screens/ordem_aplicacao/nova_ordem_aplicacao_page.dart`  
> **Padrão visual:** AppBar voltar + título + “Salvar”, `ListView` de `ProgressiveStepCard`

Título: `Nova Ordem de Aplicação` ou `Editar Ordem de Aplicação`.

Salvar habilitado só com etapa 1 completa **e** ao menos 1 produto. Erros de
`validarOrdem()` aparecem como cards de orientação (ícone + texto), nunca `alert()`.

Toast ao salvar: `Ordem salva com sucesso ✓` + `Navigator.pop`.

## Etapa 1 — Contexto da Operação

Sempre desbloqueada. Completa quando: cliente + talhão + área a aplicar > 0 + alvo.

| Campo | Tipo | Obrigatório |
|---|---|---|
| Cliente | seletor local (ver `cadastros_locais.md`) | Sim |
| Fazenda | seletor, depende de Cliente | Sim |
| Talhão | seletor, depende de Fazenda | Sim |
| Área do Talhão (ha) | readonly, do talhão | — |
| Área a Aplicar (ha) | numérico decimal nativo | Sim (> 0) |
| Alvo | lista fixa abaixo | Sim |

Alvos: Sugadores, Mastigadores, Folha larga, Folha fina, Doença, Carência nutricional, Inseto, Erva daninha.

Reset em cascata: trocar Cliente limpa Fazenda / Talhão / área do talhão; trocar Fazenda limpa Talhão / área do talhão. Área a aplicar o usuário edita (não zerar automaticamente, para não perder digitação — só limpar área do talhão).

## Etapa 2 — Produtos & Dose

`locked` enquanto etapa 1 incompleta. Completa com ≥ 1 produto na lista.

Formulário de adição:

| Campo | Tipo |
|---|---|
| Produto | seletor com busca no catálogo local |
| Dose | numérico decimal |
| Unidade | `L/ha`, `kg/ha`, `ml/ha`, `g/ha`, `un/ha`, `sc/ha` |
| Qtd Total | readonly = `dose × áreaAplicar` (fundo `primaryLight`) |
| Reservar no estoque | checkbox |
| Observação | texto |

Lista: um card por produto, remover. Chip-resumo de totais por unidade (mesmo espírito de `MedicoesResumoCard`: ícone + valor + rótulo, cores só de `AppColors`).

Estoque insuficiente: card vermelho (`danger` / `dangerLight`), ícone + texto — não texto solto.

## Etapa 3 — Execução

Opcional. Desbloqueia quando etapa 2 completa. **Não** bloqueia a etapa 4.

| Campo | Tipo |
|---|---|
| Responsável | texto |
| Máquina | seletor local (nomes de máquinas já usadas + cadastro) |
| Data/Hora início | date+time picker |
| Data/Hora fim | date+time picker |
| Temperatura (°C) | numérico |
| Umidade (%) | numérico |
| Vento (km/h) | numérico |
| Volume de calda (L/ha) | numérico |
| Dar saída do estoque ao concluir | checkbox |
| Status | Aberta / Executando / Concluída / Cancelada |

## Etapa 4 — Anexos

Desbloqueia quando etapa 2 completa (etapa 3 não precisa estar preenchida).

Área tracejada (`AppColors.border`), ícone, texto “Toque para anexar um arquivo”.
Usa `FilePicker` já existente (document picker — **não** galeria/câmera).
Copia para o diretório de documentos do app. Lista com nome + remover.
Sem `*UsageDescription` nova.
