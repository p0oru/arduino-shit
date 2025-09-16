#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
export PATH="$ROOT_DIR/arduino-cli:$PATH"

FQBN="arduino:avr:nano:cpu=atmega328old"

detect_port() {
  if [[ -n "${PORT:-}" ]]; then
    echo "$PORT"; return
  fi
  # Prefer CH340 on USB (often /dev/ttyUSB0)
  if ls /dev/ttyUSB* >/dev/null 2>&1; then
    echo "/dev/ttyUSB0"; return
  fi
  if ls /dev/ttyACM* >/dev/null 2>&1; then
    echo "/dev/ttyACM0"; return
  fi
  echo "/dev/ttyUSB0"
}

menu() {
  local n
  echo "Choose a sketch:" >&2
  echo "  1) LED_Sequence" >&2
  echo "  2) Binary_4LED_Display" >&2
  echo "  3) Flash_All_LEDs" >&2
  echo "  4) Red_LED_Only" >&2
  echo "  0) Exit" >&2
  read -rp "Enter number: " n
  case "$n" in
    1) printf "%s" "LED_Sequence" ;;
    2) printf "%s" "Binary_4LED_Display" ;;
    3) printf "%s" "Flash_All_LEDs" ;;
    4) printf "%s" "Red_LED_Only" ;;
    0) printf "%s" "" ;;
    *) printf "%s" "invalid" ;;
  esac
}

upload() {
  local name="$1"; local port="$2"
  echo "Uploading $name to $port as $FQBN..."
  arduino-cli compile --fqbn "$FQBN" "$ROOT_DIR/$name"
  arduino-cli upload -p "$port" --fqbn "$FQBN" "$ROOT_DIR/$name"
}

main() {
  local port
  port=$(detect_port)
  echo "Using port: $port"

  while true; do
    choice=$(menu)
    [[ -z "$choice" ]] && echo "Bye" && exit 0
    [[ "$choice" == "invalid" ]] && echo "Invalid" && continue
    upload "$choice" "$port" || { echo "Upload failed"; continue; }

    if [[ "$choice" == "Binary_4LED_Display" ]]; then
      read -rp "Open interactive sender now? [y/N] " ans
      if [[ "$ans" =~ ^[Yy]$ ]]; then
        python3 "$SCRIPT_DIR/serial_send.py" --port "$port" --baud 9600 || true
      fi
    fi
  done
}

main "$@"

