#!/usr/bin/env bash
#
# Envio do IPA do Ponta Verde para o App Store Connect / TestFlight.
#
# Tudo já vem pré-preenchido. A ÚNICA coisa que falta é o Issuer ID da
# App Store Connect API. Pegue em:
#   App Store Connect -> Users and Access -> Integrations ->
#   App Store Connect API -> campo "Issuer ID" (formato UUID)
#
# Forneça o Issuer ID de UMA destas formas (a primeira que existir vence):
#   1) argumento:      ./scripts/upload_testflight.sh 69a6de70-xxxx-xxxx-xxxx-xxxxxxxxxxxx
#   2) variável de ambiente:  export ASC_ISSUER_ID=...   e rode sem argumento
#   3) arquivo:        echo "SEU_ISSUER_ID" > ios/.asc_issuer_id   (fica fora do git)
#
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IPA_PATH="${PROJECT_DIR}/build/ios/ipa/pontaverde.ipa"

# --- Credenciais da API (chave já existente na máquina) ----------------------
API_KEY_ID="M3424Q9LY2"                       # ~/.private_keys/AuthKey_M3424Q9LY2.p8
ISSUER_ID="${1:-${ASC_ISSUER_ID:-}}"
if [[ -z "${ISSUER_ID}" && -f "${PROJECT_DIR}/ios/.asc_issuer_id" ]]; then
  ISSUER_ID="$(tr -d '[:space:]' < "${PROJECT_DIR}/ios/.asc_issuer_id")"
fi

if [[ -z "${ISSUER_ID}" ]]; then
  echo "ERRO: Issuer ID não informado."
  echo "  ./scripts/upload_testflight.sh <ISSUER_ID>"
  echo "  ou: export ASC_ISSUER_ID=<ISSUER_ID>"
  echo "  ou: echo <ISSUER_ID> > ios/.asc_issuer_id"
  exit 1
fi

if [[ ! -f "${IPA_PATH}" ]]; then
  echo "ERRO: IPA não encontrado em ${IPA_PATH}"
  echo "Gere antes com:"
  echo "  flutter build ipa --release --build-name 1.0.0 --build-number 8 \\"
  echo "    --export-options-plist=ios/ExportOptions.plist"
  exit 1
fi

echo "==> IPA .......: ${IPA_PATH}"
echo "==> API Key ...: ${API_KEY_ID}"
echo "==> Issuer ....: ${ISSUER_ID}"
echo

echo "==> 1/2  Validando o pacote (xcrun altool --validate-app)"
xcrun altool --validate-app \
  --type ios \
  --file "${IPA_PATH}" \
  --apiKey "${API_KEY_ID}" \
  --apiIssuer "${ISSUER_ID}"

echo
echo "==> 2/2  Enviando para o App Store Connect (xcrun altool --upload-app)"
xcrun altool --upload-app \
  --type ios \
  --file "${IPA_PATH}" \
  --apiKey "${API_KEY_ID}" \
  --apiIssuer "${ISSUER_ID}"

echo
echo "OK. Acompanhe o processamento em:"
echo "  App Store Connect -> Ponta Verde Agro -> TestFlight -> Compilações do iOS"
echo "Quando sair de 'Processando', o build 1.0.0 (8) fica disponível para teste."
echo "A conformidade de criptografia já está respondida no Info.plist"
echo "(ITSAppUsesNonExemptEncryption = false), então não vai aparecer a pergunta."
