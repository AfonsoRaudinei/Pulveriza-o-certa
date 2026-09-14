#!/usr/bin/env bash
# Validação padrão do Ponta Verde (REGRA-ENTREGA-1).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> flutter analyze lib/ test/"
flutter analyze lib/ test/ --no-fatal-infos

echo "==> flutter test"
flutter test
