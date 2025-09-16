#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"

if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "Installing Arduino CLI locally..."
  cd "$ROOT_DIR"
  curl -fsSL -o arduino-cli.zip https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_ARM64.zip || \
  curl -fsSL -o arduino-cli.zip https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_ARMv7.zip || \
  curl -fsSL -o arduino-cli.zip https://downloads.arduino.cc/arduino-cli/arduino-cli_latest_Linux_64bit.zip
  rm -rf arduino-cli
  mkdir -p arduino-cli
  unzip -o arduino-cli.zip -d arduino-cli
  rm -f arduino-cli.zip
  export PATH="$ROOT_DIR/arduino-cli:$PATH"
fi

if ! command -v arduino-cli >/dev/null 2>&1; then
  echo "arduino-cli not available on PATH" >&2
  exit 1
fi

arduino-cli core update-index
arduino-cli core install arduino:avr
echo "Arduino CLI ready."

