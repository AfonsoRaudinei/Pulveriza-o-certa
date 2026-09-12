# TestFlight — Ponta Verde

Passo a passo para enviar um IPA ao TestFlight. Complementa `AGENTIPA.md` e `scripts/upload_testflight.sh`.

## Pré-requisitos

1. IPA gerado e inspecionado: `build/ios/ipa/pontaverde.ipa`
2. Bloco correspondente em `AGENTIPA.md` (build N inédito no App Store Connect)
3. Smoke em iPhone físico registrado em `.agent/SMOKE_DEVICE.md`
4. App Store Connect API Key (`M3424Q9LY2`) em `~/.private_keys/AuthKey_M3424Q9LY2.p8`
5. **Issuer ID** (UUID) de App Store Connect → Users and Access → Integrations → App Store Connect API

## 1. Informar o Issuer ID (uma vez por máquina)

```bash
echo "SEU_ISSUER_ID_UUID" > ios/.asc_issuer_id
# arquivo ignorado pelo git
```

Ou: `export ASC_ISSUER_ID=...`

## 2. Enviar o IPA

```bash
./scripts/upload_testflight.sh
# ou: ./scripts/upload_testflight.sh <ISSUER_ID>
```

## 3. App Store Connect

1. Abrir **Ponta Verde** → **TestFlight** → aguardar processamento do build N
2. Anexar ao grupo de teste (ex.: Teste Externo)
3. Preencher **Export Compliance** se solicitado (`ITSAppUsesNonExemptEncryption=false` no IPA)
4. Atualizar `AGENTIPA.md`: `Upload TestFlight: enviado em <data>`

## 4. Ficha da loja (antes da revisão App Store)

Ver [`STORE.md`](STORE.md):

- URLs de privacidade e suporte (GitHub Pages)
- Screenshots iPhone 6.9"
- App Privacy: **Dados não coletados**
- Notas para o revisor (texto em STORE.md)

## Build atual recomendado

- **116** (`1.0.0+116`) — ver último bloco em `AGENTIPA.md`
- Status: disco apenas até rodar o upload acima
