from dataclasses import dataclass
from typing import Dict, List, Optional
import time
import random

@dataclass
class BookLevel:
    px: int      # price in 1/10000 dollars, e.g. 2345678 = 234.5678
    qty: int

@dataclass
class BookEvent:
    ts_ns: int
    seq: int
    symbol: str
    event_type: str   # ADD / EXEC / CANCEL / DELETE / SNAPSHOT
    side: Optional[str] = None
    order_id: Optional[int] = None
    px: Optional[int] = None
    qty: Optional[int] = None
    notes: str = ""

class SimpleOrderBook:
    def __init__(self, symbol: str):
        self.symbol = symbol
        self.bids: Dict[int, int] = {}   # price -> total qty
        self.asks: Dict[int, int] = {}   # price -> total qty
        self.seq = 100000
        self.ts_ns = 1713451200000000000

    def _advance_time(self):
        self.ts_ns += random.randint(60, 250)

    def _next_seq(self):
        self.seq += 1
        return self.seq

    def _best_bid(self):
        if not self.bids:
            return None
        px = max(self.bids.keys())
        return BookLevel(px=px, qty=self.bids[px])

    def _best_ask(self):
        if not self.asks:
            return None
        px = min(self.asks.keys())
        return BookLevel(px=px, qty=self.asks[px])

    def add(self, side: str, px: int, qty: int, order_id: int) -> BookEvent:
        self._advance_time()
        book = self.bids if side == "B" else self.asks
        book[px] = book.get(px, 0) + qty
        return BookEvent(
            ts_ns=self.ts_ns,
            seq=self._next_seq(),
            symbol=self.symbol,
            event_type="ADD",
            side=side,
            order_id=order_id,
            px=px,
            qty=qty,
            notes="hotpath update accepted"
        )

    def execute(self, side: str, px: int, qty: int, order_id: int) -> BookEvent:
        self._advance_time()
        book = self.bids if side == "B" else self.asks
        if px in book:
            book[px] = max(0, book[px] - qty)
            if book[px] == 0:
                del book[px]
        return BookEvent(
            ts_ns=self.ts_ns,
            seq=self._next_seq(),
            symbol=self.symbol,
            event_type="EXEC",
            side=side,
            order_id=order_id,
            px=px,
            qty=qty,
            notes="executed against resting liquidity"
        )

    def cancel(self, side: str, px: int, qty: int, order_id: int) -> BookEvent:
        self._advance_time()
        book = self.bids if side == "B" else self.asks
        if px in book:
            book[px] = max(0, book[px] - qty)
            if book[px] == 0:
                del book[px]
        return BookEvent(
            ts_ns=self.ts_ns,
            seq=self._next_seq(),
            symbol=self.symbol,
            event_type="CANCEL",
            side=side,
            order_id=order_id,
            px=px,
            qty=qty,
            notes="partial cancel mirrored to coldpath"
        )

    def snapshot_event(self) -> BookEvent:
        self._advance_time()
        bid = self._best_bid()
        ask = self._best_ask()

        spread_bps = None
        if bid and ask and ask.px > bid.px:
            mid = (bid.px + ask.px) / 2.0
            spread_bps = ((ask.px - bid.px) / mid) * 10000.0

        notes = (
            f"bb={fmt_px(bid.px) if bid else 'NA'} x {bid.qty if bid else 0}, "
            f"ba={fmt_px(ask.px) if ask else 'NA'} x {ask.qty if ask else 0}, "
            f"spread_bps={spread_bps:.3f}" if spread_bps is not None else
            "book incomplete"
        )

        return BookEvent(
            ts_ns=self.ts_ns,
            seq=self._next_seq(),
            symbol=self.symbol,
            event_type="SNAPSHOT",
            notes=notes
        )

def fmt_px(px: int) -> str:
    return f"{px / 10000.0:.4f}"

def format_coldpath_print(ev: BookEvent) -> str:
    base = (
        f"[PCIe-COLDPATH] ts={ev.ts_ns} seq={ev.seq} sym={ev.symbol} "
        f"type={ev.event_type}"
    )
    if ev.event_type in {"ADD", "EXEC", "CANCEL", "DELETE"}:
        return (
            f"{base} side={ev.side} oid={ev.order_id} "
            f"px={fmt_px(ev.px)} qty={ev.qty} note='{ev.notes}'"
        )
    return f"{base} note='{ev.notes}'"


def run_demo():
    ob = SimpleOrderBook("AAPL")
    mirrored: List[BookEvent] = []

    stream = [
        ("add",     {"side": "B", "px": 1841234, "qty": 500, "order_id": 9001001}),
        ("add",     {"side": "A", "px": 1841250, "qty": 300, "order_id": 9001002}),
        ("add",     {"side": "B", "px": 1841228, "qty": 200, "order_id": 9001003}),
        ("execute", {"side": "A", "px": 1841250, "qty": 100, "order_id": 9001002}),
        ("cancel",  {"side": "B", "px": 1841234, "qty": 150, "order_id": 9001001}),
        ("add",     {"side": "A", "px": 1841248, "qty": 250, "order_id": 9001004}),
        ("execute", {"side": "B", "px": 1841234, "qty": 200, "order_id": 9001001}),
    ]

    for i, (op, kwargs) in enumerate(stream, start=1):
        ev = getattr(ob, op)(**kwargs)
        mirrored.append(ev)

        if i % 2 == 0:
            mirrored.append(ob.snapshot_event())

    for ev in mirrored:
        print(format_coldpath_print(ev))


if __name__ == "__main__":
    run_demo()
