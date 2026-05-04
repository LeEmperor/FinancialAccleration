import socket
import struct
import sys
import time

def get_mac(sock: socket.socket, iface: str) -> bytes:
    import fcntl
    info = fcntl.ioctl(sock.fileno(), 0x8927, struct.pack("256s", iface.encode()[:15]))
    return info[18:24]

def build_frame(src_mac: bytes, payload: bytes) -> bytes:
    dst_mac=b"\xff\xff\xff\xff\xff\xff"
    ethertype = struct.pack("!H", 0x8885)
    if (len(payload) < 46):
        payload = payload + b"\x00" * (46 - len(payload))
        return dst_mac + src_mac + ethertype + payload

def main() -> None:
    iface = sys.argv[1] if len(sys.argv) > 1 else "enx9cebe8ed31d2"
    sock = socket.socket(socket.AF_PACKET, socket.SOCK_RAW, socket.htons(3))
    sock.bind((iface, 0))

    src_mac = get_mac(sock, iface)
    payload = bytes(range(1, 11))
    frame = build_frame(src_mac, payload)

    count = 0
    try:
        while True:
            sock.send(frame)
            count += 1
            print(f"sent packet #{count}")
            time.sleep(1)
    except KeyboardInterrupt:
            print(f"Done")
    finally:
        sock.close()

if __name__ == "__main__":
    main()
