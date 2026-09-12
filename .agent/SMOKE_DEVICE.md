# Smoke test — iPhone físico (Ponta Verde v1.0)

Roteiro obrigatório antes de TestFlight. **Simulador não substitui** itens 4–6 (persistência real, share sheet, backup).

## Pré-requisitos

```bash
flutter devices --device-timeout 30
# iPhone físico: cabo USB ou mesma rede Wi‑Fi + Developer Mode
flutter run --release -d <device_id>
```

## Checklist (marcar data + build)

| # | Fluxo | Passa se | Device físico | Simulador (referência) |
|---|--------|----------|---------------|------------------------|
| 1 | Boot / launch | Sem flash branco longo; marca Ponta Verde | ☐ | ☐ |
| 2 | Nova regulagem | 4 etapas; sem ✓ indevido nas 1–4; limites empilhados | ☐ | ☐ |
| 3 | Medições | Troca de ponta sem chevron/área cinza; status só no badge | ☐ | ☐ |
| 4 | Persistência | Criar → matar app → reabrir → dado permanece | ☐ | n/a |
| 5 | PDF | Share sheet abre; arquivo gera | ☐ | n/a |
| 6 | Backup JSON | Export + import round-trip | ☐ | n/a |
| 7 | Locale pt-BR | Datas/números coerentes com idioma PT do aparelho | ☐ | ☐ |
| 8 | Editar / readonly | Editar do histórico; readonly só navega pontas | ☐ | ☐ |

## Registro — Build 116 (2026-09-12)

- **Ambiente:** Mac; `flutter devices` listou simulador iPhone 17; tentativa wireless em "iPhone de Raudinei" falhou (code -27 — device não pareado/desbloqueado).
- **Device físico:** **não executado** nesta sessão (sem device_id USB disponível).
- **Simulador:** app compila (`flutter build ios --release`); smoke manual dos 8 fluxos **pendente** de sessão com operador + device.
- **Próximo passo:** conectar iPhone via cabo → `flutter run --release` → marcar tabela acima → copiar resumo para `AGENTIPA.md`.
