#!/usr/bin/env python3
import argparse, sys, time
try:
    import serial  # pyserial
except ImportError:
    print('Install pyserial: pip3 install --user pyserial', file=sys.stderr)
    sys.exit(1)

def open_serial(port, baud, tries=12):
    for i in range(tries):
        try:
            ser = serial.Serial(port=port, baudrate=baud, timeout=0.2)
            time.sleep(0.3)
            return ser
        except Exception as e:
            if i == 0:
                print(f'Serial open failed (will retry): {e}', file=sys.stderr)
            time.sleep(0.5)
    print(f'Could not open serial on {port}', file=sys.stderr)
    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--port', required=True)
    ap.add_argument('--baud', type=int, default=9600)
    args = ap.parse_args()

    ser = open_serial(args.port, args.baud)
    if not ser:
        sys.exit(1)
    print("Interactive: enter 0-15 or bits, or 'invert'/'off'/'exit'. Ctrl+C to quit.")
    try:
        while True:
            try:
                line = input('> ').strip()
            except EOFError:
                break
            if not line:
                continue
            ser.write((line + '\n').encode('utf-8'))
            if line == 'exit':
                break
    except KeyboardInterrupt:
        pass
    finally:
        ser.close()

if __name__ == '__main__':
    main()


