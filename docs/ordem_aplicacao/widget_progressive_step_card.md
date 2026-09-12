# Widget — ProgressiveStepCard

> **Onde vive:** `lib/widgets/progressive_step_card.dart`  
> **Quem consome:** Ordem de Aplicação; `ProgressiveCard` da regulagem vira adaptador fino  
> **Referência visual:** tela Nova Regulagem / Editar Regulagem (`lib/screens/regulagem/widgets/progressive_card.dart`)

## Finalidade

Card de etapa numerada com desbloqueio progressivo.

Na **Ordem de Aplicação** não é accordion: o corpo permanece visível (opacidade
reduzida quando bloqueado). Na **regulagem**, `ProgressiveCard` liga
`expandable: true` e o corpo vai para um `ExpansionTile`.

## API

```dart
enum StepStatus { locked, active, completed }

class ProgressiveStepCard extends StatelessWidget {
  final int stepNumber;
  final String title;
  final String? description;
  final StepStatus status;
  final Widget child;
}
```

Derivação a partir do card antigo: `locked` → `locked`; senão `complete` → `completed`; senão `active`.

## Anatomia

| Elemento | Token | Nota |
|---|---|---|
| Raio | `AppRadius.lg` (16) | igual à regulagem, não 20 px solto |
| Padding interno | `AppSpacing.lg` (16) | igual à regulagem |
| Margem inferior | `AppSpacing.xl` (20) | separação entre cards |
| Fundo | `AppThemeColors.surface` | |
| Borda locked/active | `AppThemeColors.border` | |
| Borda completed | `AppColors.success` alpha 0.3 | |
| Indicador | círculo 32×32 (`AppSpacing.xxxl`) | |
| Título | `Theme.textTheme.headlineSmall` | |
| Locked | opacidade 0.4 + `IgnorePointer` | corpo **não** some |
| Active | opacidade 1, número azul `AppColors.primary` | |
| Completed | check `Icons.check` em verde | card continua expandido |

## Animações

- `AnimatedOpacity` locked ↔ ativo: 200 ms
- `AnimatedContainer` borda: 300 ms
- Indicador: `AnimatedSwitcher` entre número / cadeado (`Icons.lock_outline`) / check

## Cores

Nenhuma cor literal (`Color(0x…)`, `Colors.green`, etc.). Só `AppColors` / `AppThemeColors`.

## Adaptador

`ProgressiveCard` da regulagem delega para `ProgressiveStepCard` com `expandable: true` (círculo 1/✓/cadeado **e** chevron do `ExpansionTile`). Ordem de aplicação continua sem accordion (`expandable` omitido / `false`).
