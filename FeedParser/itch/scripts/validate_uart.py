#!/usr/bin/env python3
"""
validate_uart.py
Hardware UART validation for uart_test_top.sv

Connects to the Arty A7-100T over USB-UART and checks that all 8 canned
event lines arrive in the correct order with the correct content.

Usage:
    python3 scripts/validate_uart.py --port /dev/ttyUSB1
    python3 scripts/validate_uart.py --port COM3          # Windows
    python3 scripts/validate_uart.py --port /dev/ttyUSB1 --dump   # print only
    python3 scripts/validate_uart.py --port /dev/ttyUSB1 --timeout 30

Requirements:
    pip install pyserial

Board setup:
    1.  Program the Arty with uart_test_top.bit (see scripts/create_uart_test_project.tcl)
    2.  Connect via USB — the FTDI port is usually /dev/ttyUSB1 (Linux) or COM3-ish (Windows)
        Tip: ls /dev/ttyUSB*  or  python3 -m serial.tools.list_ports
    3.  Press BTN0 on the board to reset and replay the sequence at any time
"""

import argparse
import sys
import time

# ─────────────────────────────────────────────────────────────────────────────
# Expected output — must match uart_test_top.sv ev_rom[] entries exactly
# ─────────────────────────────────────────────────────────────────────────────
EXPECTED_LINES = [
    "ADD  REF=0000000000001001 SIDE=B SZ=000003E8 PX=0012D484",
    "ADD  REF=0000000000001002 SIDE=S SZ=000001F4 PX=0012D678",
    "BBO  BID=0012D484x000003E8 ASK=0012D678x000001F4",
    "EXE  REF=0000000000001001 SZ=000001F4",
    "CAN  REF=0000000000001002 SZ=00000064",
    "DEL  REF=0000000000001001",
    "REP  OLD=0000000000001002 NEW=0000000000001010 SZ=000000C8 PX=0012D8A8",
    "GAP  SEQ=0000000000000008",
]

BAUD     = 115_200
BYTESIZE = 8
PARITY   = "N"
STOPBITS = 1


# ─────────────────────────────────────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────────────────────────────────────

PASS = "\033[32mPASS\033[0m"
FAIL = "\033[31mFAIL\033[0m"
INFO = "\033[36mINFO\033[0m"


def read_line(ser, timeout_s: float) -> str | None:
    """Read one CRLF-terminated line from the serial port.

    Returns the line content without trailing CR/LF, or None on timeout.
    """
    buf = bytearray()
    deadline = time.monotonic() + timeout_s
    while time.monotonic() < deadline:
        b = ser.read(1)
        if not b:
            continue
        c = b[0]
        if c == 0x0A:           # LF — end of line
            return buf.decode("ascii", errors="replace").rstrip("\r")
        buf.append(c)
    return None                 # timed out


def highlight_diff(got: str, exp: str) -> str:
    """Return a character-level diff string."""
    max_len = max(len(got), len(exp))
    markers = []
    for i in range(max_len):
        g = got[i] if i < len(got) else " "
        e = exp[i] if i < len(exp) else " "
        markers.append("^" if g != e else " ")
    return "".join(markers)


# ─────────────────────────────────────────────────────────────────────────────
# Dump mode — print raw lines without validation
# ─────────────────────────────────────────────────────────────────────────────

def run_dump(ser, timeout_s: float, max_lines: int) -> None:
    print(f"[{INFO}] Dumping UART output (Ctrl-C to stop, timeout {timeout_s}s/line)\n")
    count = 0
    while count < max_lines:
        line = read_line(ser, timeout_s)
        if line is None:
            print(f"[{INFO}] Timeout — no more data")
            break
        print(repr(line))
        count += 1


# ─────────────────────────────────────────────────────────────────────────────
# Validate mode
# ─────────────────────────────────────────────────────────────────────────────

def run_validate(ser, timeout_s: float) -> int:
    """Validate the 8-line sequence.  Returns number of failures."""

    pass_count = 0
    fail_count = 0
    extra_lines: list[str] = []

    print(f"[{INFO}] Waiting for {len(EXPECTED_LINES)} lines "
          f"({timeout_s:.0f}s per line)…\n")

    for idx, expected in enumerate(EXPECTED_LINES):
        line = read_line(ser, timeout_s)

        if line is None:
            print(f"  [{FAIL}] Line {idx+1}/{len(EXPECTED_LINES)}: TIMEOUT")
            fail_count += 1
            # Stop — if one line timed out the rest will too
            remaining = len(EXPECTED_LINES) - idx - 1
            if remaining:
                print(f"         Skipping remaining {remaining} line(s)")
                fail_count += remaining
            break

        if line == expected:
            print(f"  [{PASS}] Line {idx+1}: {line}")
            pass_count += 1
        else:
            diff = highlight_diff(line, expected)
            print(f"  [{FAIL}] Line {idx+1}:")
            print(f"           got: {repr(line)}")
            print(f"           exp: {repr(expected)}")
            print(f"          diff:  {diff}")
            fail_count += 1

    # Drain any extra lines (e.g. a second reset fired)
    print()
    extra_timeout = 2.0   # short wait for extras
    deadline = time.monotonic() + extra_timeout
    while time.monotonic() < deadline:
        line = read_line(ser, 0.3)
        if line is None:
            break
        extra_lines.append(line)

    if extra_lines:
        print(f"[{INFO}] {len(extra_lines)} extra line(s) received after expected sequence:")
        for l in extra_lines:
            print(f"         {repr(l)}")
        print()

    # Summary
    total = pass_count + fail_count
    print("─" * 60)
    print(f"Results: {pass_count}/{total} PASS,  {fail_count}/{total} FAIL")
    if fail_count == 0:
        print(f"[{PASS}] All {total} lines matched — UART reporter validated ✓")
    else:
        print(f"[{FAIL}] {fail_count} line(s) did not match")
    print("─" * 60)

    return fail_count


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Arty UART output against uart_test_top.sv expected sequence"
    )
    parser.add_argument(
        "--port", "-p", required=True,
        help="Serial port, e.g. /dev/ttyUSB1 or COM3"
    )
    parser.add_argument(
        "--timeout", "-t", type=float, default=20.0,
        help="Seconds to wait for each line (default 20). "
             "The board fires one event every 20 ms so 8 lines arrive "
             "in ~160 ms; extra headroom covers board boot time."
    )
    parser.add_argument(
        "--dump", action="store_true",
        help="Dump raw lines without validation (useful for initial bring-up)"
    )
    parser.add_argument(
        "--dump-lines", type=int, default=32,
        help="Max lines to dump in --dump mode (default 32)"
    )
    parser.add_argument(
        "--reset-wait", type=float, default=3.0,
        help="Seconds to wait after opening port before reading "
             "(gives the board time to reset and start transmitting, default 3)"
    )
    args = parser.parse_args()

    try:
        import serial
    except ImportError:
        print("ERROR: pyserial not found.  Install with:  pip install pyserial",
              file=sys.stderr)
        return 2

    print(f"Opening {args.port} at {BAUD} baud…")
    try:
        ser = serial.Serial(
            port     = args.port,
            baudrate = BAUD,
            bytesize = BYTESIZE,
            parity   = PARITY,
            stopbits = STOPBITS,
            timeout  = 0.1,      # read() returns after 100 ms if no data
        )
    except serial.SerialException as e:
        print(f"ERROR: cannot open port: {e}", file=sys.stderr)
        return 2

    print(f"Port open.  Waiting {args.reset_wait:.0f}s for board to initialise…")
    print("(Press BTN0 on the Arty now if the board was already running)\n")
    time.sleep(args.reset_wait)

    # Flush stale bytes that arrived during boot
    ser.reset_input_buffer()

    try:
        if args.dump:
            run_dump(ser, args.timeout, args.dump_lines)
            return 0
        else:
            failures = run_validate(ser, args.timeout)
            return 0 if failures == 0 else 1
    except KeyboardInterrupt:
        print("\nInterrupted")
        return 130
    finally:
        ser.close()


if __name__ == "__main__":
    sys.exit(main())
