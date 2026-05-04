"""
send_readback.py — send simple UDP packets to the eth_readback FPGA demo.

The FPGA strips the 42-byte Ethernet+IP+UDP header (14+20+8) and forwards
every UDP payload byte out the UART at 115200 8N1.  A normal UDP socket is
enough — the OS and NIC build all the headers automatically.

Requirements: none beyond stdlib

Setup (one-time, replace interface/IP to match your setup):
    sudo ip link set <iface> up
    sudo ip addr add 192.168.1.1/24 dev <iface>

Run:
    python3 send_readback.py --iface eth0

Then watch your UART terminal (minicom -b 115200 -D /dev/ttyUSB1) for the
raw bytes coming back.  Each payload byte will appear as-is, so send ASCII
for easy visual confirmation.
"""

import argparse
import socket
import time

PAYLOADS = [
    b"HELLO FPGA\n",
    b"PACKET 2: abcdefghij\n",
    b"PACKET 3: 0123456789\n",
    b"PACKET 4: THE QUICK BROWN FOX\n",
]

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--iface",  default="enx9cebe8ed31d2", help="Network interface bound to the FPGA")
    ap.add_argument("--dst-ip", default="255.255.255.255", help="Destination IP — broadcast avoids ARP traffic confusing the FPGA")
    ap.add_argument("--port",   default=1234, type=int,  help="UDP destination port (ignored by FPGA)")
    ap.add_argument("--gap",    default=0.5,  type=float, help="Seconds between packets")
    mode = ap.add_mutually_exclusive_group()
    mode.add_argument("--once",   action="store_true", help="Send all packets once then exit")
    mode.add_argument("--single", action="store_true", help="Send only the first packet once then exit")
    mode.add_argument("--loop",   action="store_true", help="Loop forever until Ctrl-C (default)")
    args = ap.parse_args()

    sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
    # Bind to the specific interface so the frame goes out the right NIC
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_BINDTODEVICE, args.iface.encode())

    print(f"Sending to {args.dst_ip}:{args.port} via {args.iface}")
    print(f"Each payload will appear byte-for-byte on the UART (115200 8N1 /dev/ttyUSB1)\n")

    def send_once():
        for i, payload in enumerate(PAYLOADS):
            sock.sendto(payload, (args.dst_ip, args.port))
            print(f"  [{i+1}/{len(PAYLOADS)}]: {payload!r}")
            time.sleep(args.gap)

    try:
        if args.single:
            sock.sendto(PAYLOADS[0], (args.dst_ip, args.port))
            print(f"  [1/1]: {PAYLOADS[0]!r}")
            print("\nDone.")
        elif args.once:
            send_once()
            print("\nDone.")
        else:
            run = 0
            while True:
                run += 1
                print(f"--- run {run} ---")
                send_once()
    except KeyboardInterrupt:
        print("\nDone.")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
