#!/usr/bin/env python3
"""
send_test_packets.py — blast MoldUDP64/ITCH 5.0 test packets at the Arty board.

The board has no IP stack; it strips the first 42 bytes (14 eth + 20 IP + 8 UDP)
and passes the payload straight to moldudp64_parser.  Any destination IP works —
broadcast is used here so the PHY accepts the frame unconditionally.

Packet sequence mirrors tb_itch_demo.sv:
  Pkt 1 (seq 1): Add BUY  ref=0x1001 1000sh @ $123.45
                 Add SELL ref=0x1002  500sh @ $123.50
                 Add BUY  ref=0x1003  300sh @ $123.44
  Pkt 2 (seq 4): Exe ref=0x1001 500sh
                 Can ref=0x1003 100sh
  Pkt 3 (seq 6): Rep old=0x1002 new=0x1010 200sh @ $123.55
                 Del ref=0x1001
  Pkt 4 (seq 9): Add SELL ref=0x1004 100sh @ $123.48  ← gap: expected 8

Usage:
  # bring up the interface first (one-time):
  sudo ip link set enx9cebe8ed31d2 up
  sudo ip addr add 192.168.1.1/24 dev enx9cebe8ed31d2

  python3 scripts/send_test_packets.py [--iface enx9cebe8ed31d2] [--repeat N]
"""

import argparse
import socket
import struct
import time

# ---------------------------------------------------------------------------
# ITCH 5.0 price convention: wire value = dollars * 10000
# ---------------------------------------------------------------------------
def price(dollars: float) -> int:
    return round(dollars * 10_000)


# ---------------------------------------------------------------------------
# MoldUDP64 packet builder
# ---------------------------------------------------------------------------
SESSION = b'\x00' * 10   # 10-byte session ID (ignored by hardware)

def mold_packet(seq: int, messages: list[bytes]) -> bytes:
    header = SESSION + struct.pack('>QH', seq, len(messages))
    blocks = b''.join(struct.pack('>H', len(m)) + m for m in messages)
    return header + blocks


# ---------------------------------------------------------------------------
# ITCH 5.0 message builders
# All fields big-endian; timestamp = 0 (hardware ignores it for book logic)
# ---------------------------------------------------------------------------
TIMESTAMP = b'\x00' * 6   # 6-byte nanosecond timestamp

def msg_add(ref: int, side: str, shares: int, px: float, stock: str = 'TEST    ') -> bytes:
    return (
        b'A'
        + struct.pack('>HH', 1, 0)          # locate, tracking
        + TIMESTAMP
        + struct.pack('>Q', ref)             # order ref
        + (b'B' if side == 'B' else b'S')   # side
        + struct.pack('>I', shares)          # shares
        + stock[:8].ljust(8).encode()        # stock (8 bytes)
        + struct.pack('>I', price(px))       # price
    )

def msg_del(ref: int) -> bytes:
    return b'D' + struct.pack('>HH', 1, 0) + TIMESTAMP + struct.pack('>Q', ref)

def msg_exe(ref: int, shares: int) -> bytes:
    return (
        b'E'
        + struct.pack('>HH', 1, 0)
        + TIMESTAMP
        + struct.pack('>Q', ref)
        + struct.pack('>I', shares)
        + struct.pack('>Q', 0)    # match number
    )

def msg_can(ref: int, shares: int) -> bytes:
    return (
        b'X'
        + struct.pack('>HH', 1, 0)
        + TIMESTAMP
        + struct.pack('>Q', ref)
        + struct.pack('>I', shares)
    )

def msg_rep(orig: int, new: int, shares: int, px: float) -> bytes:
    return (
        b'U'
        + struct.pack('>HH', 1, 0)
        + TIMESTAMP
        + struct.pack('>Q', orig)
        + struct.pack('>Q', new)
        + struct.pack('>I', shares)
        + struct.pack('>I', price(px))
    )


# ---------------------------------------------------------------------------
# Packet sequence
# ---------------------------------------------------------------------------
PACKETS = [
    # seq, [messages]
    (1, [
        msg_add(0x1001, 'B', 1000, 123.45),
        msg_add(0x1002, 'S',  500, 123.50),
        msg_add(0x1003, 'B',  300, 123.44),
    ]),
    (4, [
        msg_exe(0x1001, 500),
        msg_can(0x1003, 100),
    ]),
    (6, [
        msg_rep(0x1002, 0x1010, 200, 123.55),
        msg_del(0x1001),
    ]),
    # seq 9 — gap (expected 8): triggers gap_detected → led[3] latches
    (9, [
        msg_add(0x1004, 'S', 100, 123.48),
    ]),
]


def main():
    ap = argparse.ArgumentParser(description='Send ITCH test packets to Arty board')
    ap.add_argument('--iface',  default='enx9cebe8ed31d2', help='Ethernet interface name')
    ap.add_argument('--dest',   default='192.168.1.255',   help='Destination IP (broadcast)')
    ap.add_argument('--port',   default=26477, type=int,   help='UDP destination port')
    ap.add_argument('--repeat', default=1,     type=int,   help='Number of times to repeat sequence')
    ap.add_argument('--delay',  default=0.1,   type=float, help='Seconds between packets')
    args = ap.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, args.iface.encode())

    print(f'Sending to {args.dest}:{args.port} via {args.iface}')
    print('Expected LED behaviour:')
    print('  led[0]  heartbeat — already blinking if board is alive')
    print('  led[1]  strobes on each decoded ITCH message')
    print('  led[2]  strobes when BBO changes')
    print('  led[3]  latches when gap is detected (pkt 4)')
    print()

    for run in range(args.repeat):
        if args.repeat > 1:
            print(f'--- Run {run + 1}/{args.repeat} ---')
        for seq, msgs in PACKETS:
            pkt = mold_packet(seq, msgs)
            sock.sendto(pkt, (args.dest, args.port))
            desc = ', '.join(chr(m[0]) for m in msgs)
            print(f'  seq={seq:2d}  {len(msgs)} msg(s): [{desc}]  ({len(pkt)} bytes)')
            time.sleep(args.delay)
        time.sleep(args.delay * 2)

    sock.close()
    print('\nDone.')


if __name__ == '__main__':
    main()
