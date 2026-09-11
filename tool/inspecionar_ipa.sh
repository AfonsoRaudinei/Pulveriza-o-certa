#!/usr/bin/env bash
# Inspeciona o IPA do Ponta Verde. Falha se o contrato REGRA-IPA-1 não bater.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
IPA="${1:-$ROOT/build/ios/ipa/pontaverde.ipa}"

if [[ ! -f "$IPA" ]]; then
  echo "ERRO: IPA não encontrado: $IPA"
  exit 1
fi

BYTES="$(wc -c < "$IPA" | tr -d ' ')"
echo "==> arquivo: $IPA"
echo "==> bytes:   $BYTES"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
unzip -q -o "$IPA" -d "$TMP"
APP="$TMP/Payload/Runner.app"
PLIST="$APP/Info.plist"

if [[ ! -f "$PLIST" ]]; then
  echo "ERRO: Payload/Runner.app/Info.plist ausente"
  exit 1
fi

read_key() {
  /usr/libexec/PlistBuddy -c "Print :$1" "$PLIST" 2>/dev/null || true
}

ID="$(read_key CFBundleIdentifier)"
NAME="$(read_key CFBundleDisplayName)"
SHORT="$(read_key CFBundleShortVersionString)"
BUILD="$(read_key CFBundleVersion)"
MIN="$(read_key MinimumOSVersion)"
ENC="$(read_key ITSAppUsesNonExemptEncryption)"

echo "==> CFBundleIdentifier:            $ID"
echo "==> CFBundleDisplayName:           $NAME"
echo "==> CFBundleShortVersionString:    $SHORT"
echo "==> CFBundleVersion:               $BUILD"
echo "==> MinimumOSVersion:              $MIN"
echo "==> ITSAppUsesNonExemptEncryption: $ENC"

FAIL=0
[[ "$ID" == "com.pontaverde.app" ]] || { echo "FALHA: bundle id"; FAIL=1; }
[[ "$NAME" == "Ponta Verde" ]] || { echo "FALHA: display name"; FAIL=1; }
[[ "$MIN" == "15.0" ]] || { echo "FALHA: MinimumOSVersion (precisa 15.0)"; FAIL=1; }
[[ "$ENC" == "false" ]] || { echo "FALHA: ITSAppUsesNonExemptEncryption"; FAIL=1; }

if /usr/libexec/PlistBuddy -c Print "$PLIST" | grep -E 'UsageDescription'; then
  echo "FALHA: *UsageDescription presente"
  FAIL=1
else
  echo "==> UsageDescription:              nenhuma"
fi

if [[ -f "$APP/PrivacyInfo.xcprivacy" ]]; then
  echo "==> PrivacyInfo.xcprivacy:         presente"
else
  echo "FALHA: PrivacyInfo.xcprivacy ausente"
  FAIL=1
fi

echo "==> Frameworks:"
ls -1 "$APP/Frameworks" 2>/dev/null || echo "(sem pasta Frameworks)"
if ls -1 "$APP/Frameworks" 2>/dev/null | grep -Ei 'DKImagePickerController|SDWebImage|SwiftyGif'; then
  echo "FALHA: framework de fototeca/mídia presente"
  FAIL=1
fi

exit "$FAIL"
