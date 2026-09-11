# PRD — AgroCalc
## Product Requirements Document
### Versão 1.0.0 | Status: Aprovado para Desenvolvimento

---

> **Plataforma:** iOS (iPhone)  
> **Framework:** Flutter / Dart 3  
> **Armazenamento:** Local no dispositivo (SharedPreferences + backup JSON exportável)  
> **Autenticação:** Congelada — sem login ativo nesta versão  
> **Distribuição:** TestFlight → App Store  
> **Idioma:** Português do Brasil (pt_BR)

---

## 1. Visão do Produto

### 1.1 Problema

Técnicos agrícolas, consultores e RTVs (Representantes Técnicos de Vendas) que atuam em grandes culturas (soja, milho, algodão) realizam regulagens de pulverizadores e plantadeiras em campo. Hoje esse processo é feito em papel ou em planilhas de Excel desconectadas, sem cálculo automático, sem histórico estruturado e sem análise econômica integrada.

O resultado: erros de aplicação, desperdício de insumo, perda de produtividade e nenhum registro rastreável do serviço prestado.

### 1.2 Solução

O **AgroCalc** é uma calculadora técnica de regulagem de precisão para grandes culturas. Roda completamente offline, armazena todo o histórico no próprio smartphone, calcula automaticamente os parâmetros de regulagem e gera análise econômica de troca de pontas.

### 1.3 Proposta de Valor

- Cálculo instantâneo de L/min ideal sem planilha
- Diagnóstico automático por ponta (Ideal / Irregular / Desgaste)
- Análise econômica: quando vale mais trocar todas as pontas vs. troca seletiva
- Histórico completo de regulagens no smartphone
- 100% offline — funciona em campo sem sinal
- Dados nunca se perdem: backup exportável como JSON

### 1.4 Usuário-Alvo

| Perfil | Descrição |
|--------|-----------|
| Consultor agrônomo | Realiza laudos de regulagem para produtores |
| RTV | Demonstra qualidade de insumo no campo |
| Técnico de fazenda | Realiza regulagens de forma autônoma |

---

## 2. Escopo da Versão 1.0

### ✅ Incluído nesta versão

- Tela inicial (Dashboard) com resumo de atividade
- Regulagem de pulverizador com formulário progressivo de 4 etapas
- Regulagem de plantadeira com cálculos específicos
- Medição por ponta com classificação automática
- Análise econômica de troca de pontas
- Histórico de regulagens com busca e filtro
- Tela de configurações com limites ajustáveis
- Armazenamento local no smartphone
- Exportação de dados como backup JSON
- Design iOS nativo (SF Pro Display visual equivalente via Inter)

### ❄️ Congelado — não entra na v1.0

| Feature | Motivo |
|---------|--------|
| Tela de login e autenticação | Sem backend; reservada para versão SaaS futura |
| Cadastro de usuário/empresa | Idem |
| Recuperação de senha | Idem |
| Sincronização em nuvem | Infraestrutura não definida |
| Compartilhamento de relatório PDF | Fase 2 |
| Tela de cobrança por regulagem | Fase 2 (estrutura já prevista no EntitlementService) |
| Multi-usuário / perfis | Fase 2 |

---

## 3. Arquitetura e Dados

### 3.1 Armazenamento Local

Todos os dados vivem **no próprio dispositivo**, usando `SharedPreferences` como camada de persistência com serialização JSON. Não há servidor, não há conta, não há internet necessária.

**Chaves de armazenamento:**

| Chave | Conteúdo |
|-------|----------|
| `agro_regulagens` | Array JSON de todas as regulagens |
| `agro_configuracoes` | Objeto JSON das configurações do app |

### 3.2 Estratégia de Backup (Proteção contra Perda de Dados)

O maior risco no modelo local é o usuário desinstalar o app ou trocar de celular. A solução:

**Exportação JSON manual:**
- Na tela de Configurações, botão "Exportar Dados" gera um arquivo `agro_backup_YYYY-MM-DD.json`
- O arquivo é compartilhado via share sheet nativa do iOS (AirDrop, iCloud Drive, E-mail, WhatsApp)
- O JSON contém todas as regulagens e configurações num único arquivo
- Formato legível e compatível com futuras versões

**Importação JSON:**
- Botão "Importar Backup" na tela de Configurações
- Seleciona arquivo `.json` via document picker nativo do iOS
- Valida o formato antes de sobrescrever os dados
- Confirma com o usuário antes de importar ("Isso irá substituir todos os dados atuais. Continuar?")

**Proteção adicional:**
- Nenhuma operação destrói dados sem confirmação explícita (diálogo de confirmação com 2 taps)
- Deletar uma regulagem = Dismissible widget com SnackBar "Desfazer" por 4 segundos

### 3.3 Modelo de Dados

#### Regulagem

```dart
class Regulagem {
  final String id;                    // UUID v4
  final String produtor;              // Nome do produtor/cliente
  final String fazenda;               // Nome da fazenda
  final String? talhao;               // Nome do talhão (opcional)
  final String maquina;               // Marca/modelo da máquina
  final TipoOperacao tipoOperacao;    // pulverizador | plantadeira
  final DateTime dataRegulagem;       // Data/hora da regulagem
  final String? consultor;            // Nome do técnico (opcional)
  
  // Parâmetros do Pulverizador
  final double vazaoLha;              // Vazão desejada em L/ha
  final double velocidade;            // Velocidade de aplicação em km/h
  final double espacamentoCm;         // Espaçamento entre bicos em cm
  final int numeroPontas;             // Número total de pontas
  final double? pressaoBar;           // Pressão de trabalho em bar (opcional)
  
  // Parâmetros da Plantadeira
  final int? nLinhas;                 // Número de linhas
  final double? espacamentoLinhasM;   // Espaçamento entre linhas em metros
  final double? eficiencia;           // Eficiência de campo em %
  
  // Resultados Calculados (salvos junto)
  final double litroMinIdeal;         // L/min ideal por ponta
  final List<PontaMedicao> medicoes;  // Medições das pontas
  
  // Dados Econômicos
  final double? manejoRS;             // Valor do manejo em R$
  final double? precoBicoRS;          // Preço unitário do bico em R$
  final double? areaHa;              // Área de aplicação em ha
  
  final DateTime criadoEm;
  final DateTime atualizadoEm;
}
```

#### PontaMedicao

```dart
class PontaMedicao {
  final int id;                       // Número da ponta (1 a N)
  final double? valorMedido;          // L/min medido em campo (null = não medido)
  final StatusPonta status;           // pendente | ideal | irregular | desgaste
}
```

#### Configuracoes

```dart
class Configuracoes {
  final double limiteDesgaste;        // Default: 105.0 (%)
  final double limiteIrregular;       // Default: 100.0 (%)
  final double toleranciaMin;         // Default: 100.5 (%)
  final double toleranciaMax;         // Default: 104.99 (%)
  final String nomeConsultor;         // Nome exibido no dashboard
  final String empresaNome;           // Nome da empresa/firma
}
```

---

## 4. Fórmulas de Cálculo

Todas as fórmulas estão implementadas em `lib/core/utils/calculo_utils.dart` como funções puras estáticas. Nenhum cálculo ocorre dentro de métodos `build()`.

### 4.1 Pulverizador

#### Litros por Minuto Ideal (por ponta)
```
litroMinIdeal = (vazaoLha × velocidade × (espacamentoCm / 100)) / 600
```

**Exemplo:** Vazão 150 L/ha, velocidade 15 km/h, espaçamento 50 cm  
→ (150 × 15 × 0,50) / 600 = **1,875 L/min**

#### Percentual da Ponta
```
percentualPonta = (valorMedido / litroMinIdeal) × 100
```

#### Classificação da Ponta

| Condição | Status | Cor |
|----------|--------|-----|
| percentual > limiteDesgaste (default 105%) | Desgaste | Vermelho |
| percentual < limiteIrregular (default 100%) | Irregular | Amarelo |
| 100% ≤ percentual ≤ 105% | Ideal | Verde |
| Não medido | Pendente | Cinza |

#### Perda Estimada por Ponta (desgaste)
```
perdaEstimada = ((percentual - 100) / 100) × (manejoRS / numeroPontas) × areaHa
```

#### Custo de Troca Total
```
custoTrocaTotal = precoBicoRS × numeroPontas
```

#### Recomendação de Troca Completa
```
recomendarTrocaCompleta = perdaEstimadaTotal >= custoTrocaTotal
```

### 4.2 Plantadeira

#### Largura Útil
```
larguraUtil = nLinhas × espacamentoLinhasM
```

#### Rendimento Operacional
```
rendimento = (larguraUtil × velocidade × (eficiencia / 100)) / 10
```
Resultado em ha/h.

---

## 5. Telas e Fluxo de Navegação

### 5.1 Mapa de Navegação

```
App Inicia
    │
    ▼
Dashboard (Home) ────────────────────────────────────┐
    │                                                 │
    ├── [+ Nova Regulagem] ──► Regulagem Screen       │
    │                              │                  │
    │                              ▼                  │
    │                         [Salvar] ──► volta para Home
    │
    ├── [Tab: Regulagens] ──► Histórico Screen
    │                              │
    │                              ▼
    │                         [Card] ──► Regulagem Screen (visualização)
    │
    └── [Tab: Config] ──► Configurações Screen
```

### 5.2 BottomNavigationBar

3 abas com ícones iOS-style:

| # | Ícone | Label | Tela |
|---|-------|-------|------|
| 1 | home / home_outlined | Início | DashboardTab |
| 2 | list_alt / list_alt_outlined | Regulagens | HistoricoScreen |
| 3 | settings / settings_outlined | Config | ConfiguracoesScreen |

IndexedStack mantém estado de cada aba ao alternar.

---

## 6. Especificação Detalhada das Telas

### TELA 1 — Dashboard (Aba Início)

**Objetivo:** Ponto de entrada. Visão rápida do trabalho e acesso à nova regulagem.

**Elementos:**
- AppBar com "AgroCalc" + data de hoje (formato: "quarta, 12 ago 2026")
- Card de boas-vindas: "Olá, [nomeConsultor]" — carregado das configurações
- Botão primário centralizado: "+ Nova Regulagem" (grande, azul, borderRadius lg)
- Card de resumo: "X regulagens realizadas"
- Card de última regulagem: mostra produtor + fazenda + data da última entrada

**Comportamento:**
- Se `nomeConsultor` estiver vazio nas configurações, exibe "Bem-vindo ao AgroCalc"
- FutureBuilder carrega contagem do StorageService no initState
- Pull to refresh recarrega os dados

**Regras técnicas:**
- Máximo 250 linhas
- Nenhuma lógica de cálculo
- StatefulWidget (precisa de FutureBuilder)

---

### TELA 2 — Regulagem Screen (Formulário Progressivo)

**Objetivo:** Tela principal — coleta dados e calcula a regulagem em campo.

**Estrutura:** 4 etapas progressivas (ProgressiveCard por etapa). Uma etapa só é desbloqueada quando a anterior está completa.

---

#### ETAPA 1 — Contexto da Operação
**Sempre desbloqueada**

| Campo | Tipo | Obrigatório |
|-------|------|-------------|
| Produtor | TextField | ✅ |
| Fazenda | TextField | ✅ |
| Talhão | TextField | Não |
| Máquina (marca/modelo) | TextField | ✅ |
| Tipo de Operação | DropdownButton (Pulverizador / Plantadeira) | ✅ |
| Consultor | TextField | Não (pre-preenche com nomeConsultor das configs) |
| Data da Regulagem | DatePicker | ✅ (default: hoje) |

**isCompleto:** `produtor.isNotEmpty && fazenda.isNotEmpty && maquina.isNotEmpty`

---

#### ETAPA 2 — Parâmetros da Máquina
**Desbloqueada quando Etapa 1 está completa**

**Se Pulverizador:**

| Campo | Unidade | Tipo | Obrigatório |
|-------|---------|------|-------------|
| Vazão | L/ha | TextField número | ✅ |
| Velocidade | km/h | TextField número | ✅ |
| Espaçamento entre bicos | cm | TextField número | ✅ |
| Número de pontas | un | TextField inteiro | ✅ |
| Pressão de trabalho | bar | TextField número | Não |

**Se Plantadeira:**

| Campo | Unidade | Tipo | Obrigatório |
|-------|---------|------|-------------|
| Número de linhas | un | TextField inteiro | ✅ |
| Espaçamento entre linhas | m | TextField número | ✅ |
| Velocidade | km/h | TextField número | ✅ |
| Eficiência de campo | % | TextField número | ✅ |
| População desejada | plantas/ha | TextField inteiro | Não |

**isCompleto (Pulverizador):** `vazao > 0 && velocidade > 0 && espacamento > 0 && numeroPontas > 0`  
**isCompleto (Plantadeira):** `nLinhas > 0 && espacamentoLinhas > 0 && velocidade > 0 && eficiencia > 0`

---

#### ETAPA 3 — Cálculos Automáticos
**Desbloqueada quando Etapa 2 está completa**

Campos readonly com fundo azul suave (`AppColors.primaryLight`):

**Pulverizador:**
| Campo | Fórmula |
|-------|---------|
| Lt/min Ideal | `(vazao × velocidade × (espacamento / 100)) / 600` |

**Plantadeira:**
| Campo | Fórmula |
|-------|---------|
| Largura Útil (m) | `nLinhas × espacamentoLinhas` |
| Rendimento (ha/h) | `(larguraUtil × velocidade × (eficiencia / 100)) / 10` |

Atualiza em tempo real sempre que Etapa 2 muda (via `onChanged`).

---

#### ETAPA 4 — Medições das Pontas
**Desbloqueada quando Etapa 3 tem valor > 0**

Dividida em sub-componentes (widgets separados):

**Cards de Resumo (grid 2×2):**
| Card | Cor | Ícone | Conteúdo |
|------|-----|-------|----------|
| Desgaste | Vermelho | TrendingUp | Contagem de pontas com desgaste |
| Irregular | Amarelo | TrendingDown | Contagem de pontas irregulares |
| Tolerância | Azul | CheckCircle | Pontas entre toleranciaMin e toleranciaMax |
| Ideal | Verde | CheckCircle | Pontas em condição ideal |

**Tabela de Pontas (ListView.builder — obrigatório):**

| Coluna | Conteúdo |
|--------|----------|
| Nº | Número da ponta |
| Medida (L/min) | TextField editável por ponta |
| Ideal (L/min) | Valor calculado na Etapa 3 (readonly) |
| % | `(medida / ideal) × 100` |
| Status | Badge com cor semântica |

**Seção Econômica (aparece quando há medições):**
- Campos: Manejo R$, Preço do Bico R$, Área (ha)
- Perda estimada total (R$)
- Custo de troca total (R$)
- Recomendação: "🚨 TROCA COMPLETA recomendada" ou "✅ Troca seletiva das pontas problemáticas"

**Orientações textuais (após dados preenchidos):**
- X ponta(s) em condição ideal → "Sem ação imediata. Continue o monitoramento."
- X ponta(s) irregular → "Limpar bicos e repetir teste. Verifique filtro e calda."
- X ponta(s) com desgaste → "Substituir urgentemente. Excesso de vazão compromete a aplicação."

---

**Botão Salvar (AppBar actions):**
- Ativo somente se Etapa 1 está completa
- Cria objeto `Regulagem` com UUID
- Salva via `StorageService.saveRegulagem()`
- SnackBar: "Regulagem salva com sucesso ✓"
- Retorna à tela anterior via `Navigator.pop()`

---

### TELA 3 — Histórico de Regulagens

**Objetivo:** Listar, buscar e deletar regulagens salvas.

**Elementos:**
- AppBar "Regulagens" + botão lupa (busca inline)
- Campo de busca (aparece ao tap na lupa) — filtra por produtor ou fazenda
- ListView.builder com cards de regulagem
- Empty state se lista vazia: ícone + "Nenhuma regulagem ainda. Crie a primeira!"

**Card de Regulagem:**
- Linha 1: Nome do produtor (fonte headline, bold)
- Linha 2: Fazenda • Talhão (se houver) — cinza, menor
- Linha 3: Badge tipo (Pulverizador / Plantadeira) + Data ("15 jan 2026 às 14:30")
- Linha 4: "24 pontas — 3 com desgaste, 2 irregulares" (resumo automático)
- Swipe para esquerda: ação Deletar (vermelho, ícone lixeira)
  - Confirmação: SnackBar "Regulagem excluída" com botão "Desfazer" por 4 segundos
- Tap no card: abre em modo visualização (RegulagemScreen readonly)

**Regras técnicas:**
- FutureBuilder carregando do StorageService
- ListView.builder obrigatório
- `DateFormat('dd MMM yyyy', 'pt_BR')` via intl
- Máximo 300 linhas

---

### TELA 4 — Configurações

**Objetivo:** Personalização dos parâmetros técnicos e do perfil do consultor.

**Seções:**

**Perfil:**
| Campo | Default |
|-------|---------|
| Nome do Consultor | "" |
| Nome da Empresa | "" |

**Limites de Regulagem:**
| Campo | Default | Descrição |
|-------|---------|-----------|
| Limite Desgaste (%) | 105.0 | Acima disso → bico desgastado |
| Limite Irregular (%) | 100.0 | Abaixo disso → bico entupido/irregular |
| Tolerância Mínima (%) | 100.5 | Início da zona de tolerância |
| Tolerância Máxima (%) | 104.99 | Fim da zona de tolerância |

Texto explicativo abaixo de cada campo com linguagem simples.

**Dados e Backup:**
| Ação | Comportamento |
|------|---------------|
| Exportar Dados | Gera `agro_backup_YYYY-MM-DD.json` + share sheet iOS |
| Importar Backup | Document picker → valida → confirma → importa |
| Apagar Todos os Dados | Diálogo duplo de confirmação → limpa SharedPreferences |

**Sobre:**
- "AgroCalc v1.0.0"
- "Calculadora de regulagem para grandes culturas"
- "Dados armazenados localmente neste dispositivo"

**Botão Salvar:**
- Full width, azul primário
- Salva via `StorageService.saveConfiguracoes()`
- SnackBar: "Configurações salvas"

**Regras técnicas:**
- Máximo 300 linhas
- `initState` carrega valores atuais
- `dispose()` em todos os TextEditingControllers

---

### TELA CONGELADA — Login (Não ativa na v1.0)

A tela de login existe no código mas **não é acessada no fluxo atual**. O app inicia diretamente no Dashboard.

**Estado:** O arquivo `lib/screens/login/login_screen.dart` existe com a UI implementada, mas a rota inicial em `lib/routes.dart` aponta para `/home` (não `/login`).

**Quando ativar (futuro):** Quando houver autenticação real com backend. Bastará mudar `initialRoute` de `Routes.home` para `Routes.login` e implementar o serviço de autenticação.

**O que já está implementado na tela congelada:**
- Layout visual completo (logo, campos, botão)
- Validação básica de campos
- Navegação simulada após 1.5 segundos (mock)
- Toggle de visibilidade da senha

---

## 7. Design System

### 7.1 Princípios

1. **Menos é mais** — Cada elemento na tela existe por uma razão
2. **Clareza antes de estética** — Dados técnicos precisam ser legíveis em campo (sol, luva, tela molhada)
3. **Feedback imediato** — Toda ação do usuário tem resposta visual em ≤ 300ms
4. **iOS-native** — Transições, gestos e hierarquia visual seguem HIG (Human Interface Guidelines)

### 7.2 Paleta de Cores

| Token | Hex | Uso |
|-------|-----|-----|
| `primary` | #0057FF | Botões, links, foco, ícones ativos |
| `primaryDark` | #0041CC | Estados pressed |
| `primaryLight` | #EBF2FF | Fundo de campos calculados |
| `background` | #F5F7FA | Fundo de telas |
| `surface` | #FFFFFF | Cards, modais, inputs |
| `surfaceAlt` | #F9FAFB | Cabeçalhos de tabela, linhas alternadas |
| `textPrimary` | #1A1A2E | Títulos, textos principais |
| `textSecondary` | #6B7280 | Labels, subítulos |
| `textTertiary` | #9CA3AF | Placeholders, hints |
| `border` | #E5E7EB | Bordas de cards e inputs |
| `borderFocus` | #0057FF | Borda ao focar input |
| `success` | #10B981 | Ponta ideal, confirmações |
| `successLight` | #D1FAE5 | Fundo badge ideal |
| `warning` | #F59E0B | Ponta irregular, avisos |
| `warningLight` | #FEF3C7 | Fundo badge irregular |
| `danger` | #EF4444 | Ponta desgastada, erros |
| `dangerLight` | #FEE2E2 | Fundo badge desgaste |
| `info` | #3B82F6 | Tolerância, informação |
| `infoLight` | #DBEAFE | Fundo badge tolerância |
| `purple` | #8B5CF6 | Acima do mínimo de tolerância |
| `purpleLight` | #EDE9FE | Fundo badge acima-min |

### 7.3 Tipografia

**Fonte:** Inter (Google Fonts) — equivalente visual ao SF Pro Display do iOS

| Token | Tamanho | Peso | Uso |
|-------|---------|------|-----|
| `displayLarge` | 28px | 700 | Títulos principais de tela |
| `headlineLarge` | 22px | 600 | AppBar, títulos de seção |
| `headlineMedium` | 18px | 600 | Títulos de card |
| `headlineSmall` | 16px | 600 | Subtítulos de card |
| `bodyLarge` | 16px | 400 | Texto principal, inputs |
| `bodyMedium` | 14px | 400 | Texto secundário, descrições |
| `bodySmall` | 12px | 400 | Notas, hints |
| `labelLarge` | 15px | 600 | Botões |
| `labelMedium` | 13px | 500 | Badges, tags |
| `labelSmall` | 11px | 500 | Micro-labels |

### 7.4 Espaçamento

| Token | Valor | Uso |
|-------|-------|-----|
| `xs` | 4px | Espaço mínimo entre ícone e texto |
| `sm` | 8px | Espaço entre elementos próximos |
| `md` | 12px | Espaço interno de chips/badges |
| `lg` | 16px | Padding lateral padrão de tela |
| `xl` | 20px | Espaço entre cards |
| `xxl` | 24px | Padding de card |
| `xxxl` | 32px | Espaço entre seções |
| `huge` | 48px | Espaço generoso (empty states) |

### 7.5 Bordas e Sombras

| Token | Valor | Uso |
|-------|-------|-----|
| `radius.sm` | 8px | Badges, chips |
| `radius.md` | 12px | Inputs, botões menores |
| `radius.lg` | 16px | Botão primário, cards normais |
| `radius.xl` | 20px | Cards maiores |
| `radius.xxl` | 28px | Bottom sheets |
| `radius.full` | 999px | Pills, badges status |

### 7.6 Animações

| Token | Duração | Curva | Uso |
|-------|---------|-------|-----|
| `micro` | 100ms | easeOut | Feedback de tap |
| `short` | 200ms | easeOut | Toggle, checkbox, badge |
| `medium` | 300ms | easeOutCubic | Transição de tela, unlock de etapa |
| `long` | 450ms | easeInCubic | Bottom sheet, modal |

**Transição de tela:** SlideTransition com offset (1.0, 0.0) → (0.0, 0.0), curva `easeOutCubic`, duração `medium`. Imita o comportamento nativo do iOS push navigation.

### 7.7 Widget ProgressiveCard

O coração visual da tela de regulagem. Cada etapa do formulário vive dentro de um `ProgressiveCard`.

**Estados visuais:**

| Estado | Opacidade | Borda | Header | Interação |
|--------|-----------|-------|--------|-----------|
| Bloqueado | 0.4 | border | 🔒 Cadeado cinza | IgnorePointer |
| Desbloqueado | 1.0 | border | Número azul | Ativa |
| Completo | 1.0 | success (30%) | ✓ Verde | Ativa (editável) |

**Animações:**
- `AnimatedOpacity` na mudança bloqueado → desbloqueado (200ms)
- `AnimatedContainer` na mudança desbloqueado → completo para cor da borda (300ms)

### 7.8 Widget StatusBadge

Badge pill para status de pontas.

| Status | Fundo | Texto | Label |
|--------|-------|-------|-------|
| `ideal` | successLight | success | ● Ideal |
| `desgaste` | dangerLight | danger | ▲ Desgaste |
| `irregular` | warningLight | warning | ▼ Irregular |
| `pendente` | surfaceAlt | textTertiary | ○ Pendente |

---

## 8. Arquitetura do Código

### 8.1 Estrutura de Pastas

```
lib/
├── main.dart                          # Entry point (≤ 20 linhas)
├── app.dart                           # MaterialApp + locale (≤ 60 linhas)
├── theme.dart                         # AppColors, AppSpacing, AppTheme (≤ 300 linhas)
├── routes.dart                        # Constantes de rota + mapa (≤ 40 linhas)
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Strings, valores fixos
│   ├── extensions/
│   │   └── double_extension.dart      # .toMoeda(), .toPercent()
│   └── utils/
│       └── calculo_utils.dart         # Fórmulas puras estáticas (≤ 150 linhas)
├── models/
│   ├── regulagem.dart                 # Regulagem, PontaMedicao, enums (≤ 200 linhas)
│   └── configuracoes.dart             # Configuracoes model (≤ 100 linhas)
├── services/
│   ├── storage_service.dart           # CRUD via SharedPreferences (≤ 400 linhas)
│   └── entitlement_service.dart       # Controle de acesso (stub v1.0)
├── screens/
│   ├── login/
│   │   └── login_screen.dart          # ❄️ CONGELADA — não usada (≤ 200 linhas)
│   ├── home/
│   │   └── home_screen.dart           # Dashboard + BottomNav (≤ 250 linhas)
│   ├── regulagem/
│   │   ├── regulagem_screen.dart      # Formulário progressivo (≤ 700 linhas)
│   │   └── widgets/
│   │       ├── progressive_card.dart  # Card de etapa (≤ 150 linhas)
│   │       └── pontas_table.dart      # Tabela + análise econômica (≤ 350 linhas)
│   ├── historico/
│   │   └── historico_screen.dart      # Lista de regulagens (≤ 300 linhas)
│   └── configuracoes/
│       └── configuracoes_screen.dart  # Configurações + backup (≤ 350 linhas)
└── widgets/
    ├── app_button.dart                # Botão reutilizável (≤ 80 linhas)
    └── status_badge.dart              # Badge de status de ponta (≤ 60 linhas)
```

### 8.2 Regras Mandatórias de Código

**Limites de tamanho:**
- Arquivos de tela (`*_screen.dart`): máximo 900 linhas (meta: ≤ 700)
- Arquivos de widget (`*_card.dart`, `*_table.dart`): máximo 400 linhas
- Arquivos de service: máximo 400 linhas
- Arquivos de model: máximo 200 linhas
- Arquivos utilitários (`theme.dart`, `calculo_utils.dart`): máximo 300 linhas
- `main.dart`: máximo 30 linhas
- `app.dart`: máximo 60 linhas
- `routes.dart`: máximo 40 linhas

**Regras de qualidade:**
- `flutter analyze` retorna zero issues antes de qualquer commit
- `dart format` sem alterações (auto-formatação sempre aplicada)
- `const` obrigatório em todo widget estático (sem estado dinâmico)
- Nenhuma cor, padding ou radius literal fora das classes `AppColors` / `AppSpacing` / `AppRadius`
- `ListView.builder` obrigatório para listas (nunca `Column` + `.map()`)
- Nenhum cálculo numérico dentro de métodos `build()`
- Todos os `TextEditingController` e `FocusNode` têm `dispose()` correspondente
- Todos os métodos `async` têm `try/catch` com `debugPrint` no catch

**Regras de arquitetura:**
- Nenhuma tela acessa `SharedPreferences` diretamente — somente via `StorageService`
- Nenhuma tela contém lógica de cálculo — somente via `CalcUtils`
- Models não contêm lógica de negócio — apenas dados + `toJson/fromJson/copyWith`
- Widgets são classes, não funções (nenhum `Widget _buildCard()` — extrair como classe)

**Regras de imports:**
```dart
// 1. dart:
import 'dart:convert';

// 2. package:
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// 3. relativos (do projeto)
import '../../models/regulagem.dart';
import '../../services/storage_service.dart';
```

### 8.3 Gerência de Estado

Estratégia: `setState` + `Provider` mínimo.

| Quando usar setState | Quando usar Provider |
|---------------------|---------------------|
| Estado local da tela (form, loading, index de tab) | Configurações globais compartilhadas entre telas |
| Estado de animação local | Lista de regulagens (reatividade cross-screen) |
| Toggle de visibilidade local | — |

Providers registrados no `MultiProvider` do `main.dart`:
- `ConfiguracoesProvider extends ChangeNotifier` — carrega/salva configurações
- `RegulagensProvider extends ChangeNotifier` — lista e CRUD de regulagens

### 8.4 Dependências (pubspec.yaml)

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  provider: ^6.1.1
  shared_preferences: ^2.2.2
  uuid: ^4.2.1
  intl: ^0.19.0
  google_fonts: ^6.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

---

## 9. Testes

### 9.1 Cobertura Obrigatória (v1.0)

Arquivo: `test/calculo_utils_test.dart`

19 testes unitários em 4 grupos:

| Grupo | Testes |
|-------|--------|
| `calcularLitroMinIdeal` | Normal, vazão zero, velocidade negativa |
| `calcularPercentualPonta` | Normal, ideal zero (div/zero), negativo |
| `calcularPerdaEstimada` | Com desgaste, sem desgaste (≤100%), área zero |
| `recomendarTrocaCompleta` | Troca completa, troca seletiva, custo zero |

Todos os 19 testes passam antes do deploy para TestFlight.

### 9.2 Testes Manuais (Checklist de QA)

- [ ] Formulário progressivo: etapas se desbloqueiam na ordem correta
- [ ] Cálculo de L/min ideal atualiza em tempo real ao digitar
- [ ] Badges de status mudam de cor ao inserir medições
- [ ] Salvar regulagem: aparece no histórico imediatamente
- [ ] Busca no histórico filtra por produtor e fazenda
- [ ] Swipe para deletar tem SnackBar com "Desfazer"
- [ ] Configurações salvas persistem após fechar e reabrir o app
- [ ] Exportar backup gera arquivo JSON válido
- [ ] Importar backup restaura todos os dados
- [ ] "Apagar todos os dados" exige 2 confirmações e limpa tudo
- [ ] App funciona 100% offline (modo avião)
- [ ] Tela de login existe mas não é acessada no fluxo normal

---

## 10. EntitlementService (Estrutura para Fase 2)

O `lib/services/entitlement_service.dart` existe na v1.0 como stub, sempre retornando `true` para todas as permissões. Isso garante que, quando chegar a fase de monetização, **nenhuma tela precise ser refatorada** — apenas o service muda.

```dart
class EntitlementService {
  // v1.0: sempre retorna true (acesso livre)
  // v2.0: consultará receipt validation ou API de assinatura
  
  bool get canCreateRegulagem => true;
  bool get canExportData => true;
  bool get canViewHistorico => true;
  int get maxRegulagensGratuitas => 999; // sem limite na v1.0
}
```

**Planejado para v2.0:**
- Limite de regulagens no plano gratuito
- Exportação de relatório PDF (plano Pro)
- Cobrança por regulagem ou assinatura mensal

---

## 11. Roadmap

### v1.0 (atual)
✅ Calculadora completa de regulagem  
✅ Histórico no dispositivo  
✅ Backup/restauração JSON  
✅ Configurações ajustáveis  
✅ 100% offline  

### v1.1 (próxima)
- Exportação de laudo em PDF compartilhável
- Gráfico de análise de pontas (fl_chart integrado)
- Modo escuro

### v2.0 (Fase SaaS)
- Login com autenticação real (descongelar tela de login)
- Sincronização em nuvem
- Multi-dispositivo
- Planos e cobrança via App Store In-App Purchase
- Relatórios avançados

---

## 12. Critérios de Aceite (Definition of Done)

Um item está **feito** quando:

1. `flutter analyze` retorna `No issues found!`
2. `dart format` não altera nenhum arquivo
3. Os 19 testes unitários passam (`flutter test`)
4. O fluxo completo funciona: Dashboard → Nova Regulagem → Salvar → Histórico → Configurações
5. Exportar e importar backup funciona corretamente
6. O app roda em iPhone (simulador ou dispositivo real) sem crashes
7. Nenhuma cor, padding ou radius literal fora do design system

---

## Apêndice A — Glossário Técnico

| Termo | Significado |
|-------|-------------|
| L/min ideal | Litros por minuto que cada ponta deveria vazar para atingir a dose desejada |
| Desgaste | Ponta vazando mais de 105% do ideal — bico gasto, substitua |
| Irregular | Ponta vazando menos de 100% do ideal — bico entupido, limpe |
| L/ha | Litros por hectare — dose de calda por área |
| RTV | Representante Técnico de Vendas |
| Regulagem | Processo técnico de ajuste e verificação de pulverizadores/plantadeiras |
| Calda | Mistura de água + produto para aplicação |
| Talhão | Subdivisão de uma fazenda (uma "quadra" de terra) |
| Ponta / Bico | Peça que pulveriza a calda — sujeita a desgaste e entupimento |

---

*AgroCalc PRD v1.0.0 — Gerado em agosto de 2026*  
*Próxima revisão: após validação em TestFlight com usuários reais*
