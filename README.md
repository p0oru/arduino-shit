Arduino Nano Robotics Shield Utilities

Cross-platform utilities and sketches to test and control a Nano-based robotics shield with 8 bi-color LEDs (D2–D9) and optional LCD.

- Windows: PowerShell CLI (RunSketch.cmd) and GUI (RunSketchGUI.cmd).
- Linux (Kali/Raspberry Pi): Bash scripts in scripts/linux/ to install Arduino CLI, upload sketches, and interact with the binary LED display.

Sketches
- LED_Sequence/LED_Sequence.ino – All LEDs on, then off one-by-one, loop.
- Red_LED_Only/Red_LED_Only.ino – Only the red halves lit continuously.
- Flash_All_LEDs/Flash_All_LEDs.ino – Alternates green/red for all LEDs.
- Binary_4LED_Display/Binary_4LED_Display.ino – Shows 0–15 on 4 green LEDs in binary. Commands: invert, off, exit. Invalid input flashes random red/green.
- All_Off/All_Off.ino – Turns off D2–D9 and the built-in LED.

LED pins: LED1→D2/3, LED2→D4/5, LED3→D6/7, LED4→D8/9.

Board: Arduino Nano (Old Bootloader). FQBN: arduino:avr:nano:cpu=atmega328old.

Linux (Kali/Raspberry Pi) Usage
1) Clone the repo and install prerequisites
  sudo apt update && sudo apt install -y git curl unzip python3 python3-pip
  git clone <YOUR_REPO_URL>.git
  cd <REPO_NAME>
  chmod +x scripts/linux/install_cli.sh
  scripts/linux/install_cli.sh
  sudo usermod -aG dialout "$USER"
  newgrp dialout <<<'echo applied'

  By default the Nano (CH340) appears as /dev/ttyUSB0. If your device is /dev/ttyACM0, set PORT=/dev/ttyACM0 when running the script.

2) Upload a sketch (interactive menu)
  chmod +x scripts/linux/run_sketch.sh
  scripts/linux/run_sketch.sh
  # or specify explicitly
  PORT=/dev/ttyUSB0 scripts/linux/run_sketch.sh

  Choose a sketch; it compiles and uploads to Nano Old Bootloader.
  If you select Binary_4LED_Display, after upload the script can optionally launch a small serial helper to send values continuously.

3) Optional: interactive serial sender for Binary_4LED_Display
  pip3 install --user pyserial
  python3 scripts/linux/serial_send.py --port /dev/ttyUSB0 --baud 9600
  # Then type values like: 0, 7, 1010, invert, off, exit

Windows quick start
- RunSketch.cmd – CLI menu runner (COM6).
- RunSketchGUI.cmd – GUI uploader with an input box for Binary_4LED_Display.

Ensure no app holds the COM port (close Serial Monitor/Plotter) before uploading.

Repository housekeeping
- .gitignore excludes local Arduino CLI binaries, build artifacts, and Python cache.

Troubleshooting
- Linux: If uploads fail, ensure your user is in dialout and the port is correct (ls -l /dev/ttyUSB* /dev/ttyACM*).
- Windows: If you see "can't set com-state", unplug/replug the Nano, close any serial apps, then retry. The scripts also try to reset the port.

