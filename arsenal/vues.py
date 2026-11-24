import math
import os
import re
import subprocess
import xml.etree.ElementTree as ET
from collections import Counter, deque
from dataclasses import dataclass, field
from pathlib import Path

from PyQt6.QtCore import QPointF, QRectF, Qt, QTimer
from PyQt6.QtGui import QBrush, QColor, QFont, QPainter, QPainterPath, QPen
from PyQt6.QtWidgets import (
    QGraphicsEllipseItem, QGraphicsScene, QGraphicsSimpleTextItem, QGraphicsView, QHBoxLayout,
    QHeaderView, QLabel, QListWidget, QListWidgetItem, QPushButton, QSplitter, QTableWidget,
    QTableWidgetItem, QVBoxLayout, QWidget,
)

# [VUE-01]
RISKY = {
    "telnet", "ftp", "tftp", "microsoft-ds", "netbios-ssn", "smb", "ms-wbt-server", "rdp", "vnc",
    "mysql", "postgresql", "ms-sql-s", "redis", "mongodb", "memcached", "snmp", "rpcbind", "nfs",
    "rlogin", "rsh", "rexec", "x11", "elasticsearch", "docker",
}
SAFE = {"ssh", "https", "ssl/http", "imaps", "pop3s", "smtps", "domain"}
COLORS = {"risque": "#E5484D", "attention": "#F5B33F", "sain": "#2BD67B", "neutre": "#8C8C95"}
ACCENT = "#FF1654"
CACHE = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "labnoir" / "arsenal"


def scratch(name):
    CACHE.mkdir(parents=True, exist_ok=True)
    path = CACHE / name
    if path.exists():
        path.unlink()
    return path


# [VUE-02]
@dataclass
class Port:
    number: int
    protocol: str
    state: str
    service: str
    product: str

    @property
    def level(self):
        if self.state != "open":
            return "neutre"
        name = self.service.lower()
        if name in RISKY:
            return "risque"
        if name in SAFE:
            return "sain"
        return "attention"


@dataclass
class Host:
    address: str
    name: str
    status: str
    os: str
    ports: list = field(default_factory=list)

    @property
    def level(self):
        levels = [p.level for p in self.ports]
        for lv in ("risque", "attention", "sain"):
            if lv in levels:
                return lv
        return "neutre"


# [VUE-03]
def parse_nmap(path):
    root = ET.parse(path).getroot()
    hosts = []
    for h in root.findall("host"):
        status = h.find("status")
        if status is not None and status.get("state") != "up":
            continue
        addr = next((a.get("addr") for a in h.findall("address") if a.get("addrtype") in ("ipv4", "ipv6")), "?")
        name_el = h.find("hostnames/hostname")
        os_el = h.find("os/osmatch")
        host = Host(
            address=addr,
            name=name_el.get("name") if name_el is not None else "",
            status="actif",
            os=f"{os_el.get('name')} ({os_el.get('accuracy')} %)" if os_el is not None else "",
        )
        for p in h.findall("ports/port"):
            st = p.find("state")
            sv = p.find("service")
            product = ""
            if sv is not None:
                product = " ".join(x for x in (sv.get("product"), sv.get("version"), sv.get("extrainfo")) if x)
            host.ports.append(Port(
                number=int(p.get("portid", 0)),
                protocol=p.get("protocol", ""),
                state=st.get("state", "") if st is not None else "",
                service=sv.get("name", "") if sv is not None else "",
                product=product,
            ))
        hosts.append(host)
    return hosts


# [VUE-04]
def parse_lynis(path):
    index, warnings, suggestions = None, [], []
    for line in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("hardening_index="):
            try:
                index = int(line.split("=", 1)[1])
            except ValueError:
                index = None
        elif line.startswith("warning[]="):
            parts = line.split("=", 1)[1].split("|")
            warnings.append((parts[0], parts[1] if len(parts) > 1 else ""))
        elif line.startswith("suggestion[]="):
            parts = line.split("=", 1)[1].split("|")
            text = parts[1] if len(parts) > 1 else ""
            detail = parts[2] if len(parts) > 2 and parts[2] not in ("-", "") else ""
            suggestions.append((parts[0], text + (f" ({detail})" if detail else "")))
    return index, warnings, suggestions


# [VUE-05]
FOUND = re.compile(r"^(?P<path>.+): (?P<sig>.+) FOUND$")


def parse_clamav(text):
    return [(m.group("path"), m.group("sig")) for m in map(FOUND.match, text.splitlines()) if m]


def parse_yara(text):
    out = []
    for line in text.splitlines():
        parts = line.strip().split(" ", 1)
        if len(parts) == 2 and re.match(r"^[A-Za-z_][\w]*$", parts[0]) and os.path.exists(parts[1]):
            out.append((parts[1], parts[0]))
    return out


# [VUE-06]
class NmapView(QWidget):
    def __init__(self):
        super().__init__()
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        self.summary = QLabel(objectName="muted")
        lay.addWidget(self.summary)
        split = QSplitter(Qt.Orientation.Vertical)
        self.scene = QGraphicsScene()
        self.view = QGraphicsView(self.scene)
        self.view.setRenderHint(QPainter.RenderHint.Antialiasing)
        self.view.setObjectName("map")
        split.addWidget(self.view)
        self.table = QTableWidget(0, 6)
        self.table.setHorizontalHeaderLabels(["Machine", "Port", "État", "Service", "Version", "Niveau"])
        self.table.horizontalHeader().setSectionResizeMode(4, QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().hide()
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        split.addWidget(self.table)
        split.setSizes([380, 220])
        lay.addWidget(split, 1)

    def show_hosts(self, hosts):
        self.scene.clear()
        opened = sum(1 for h in hosts for p in h.ports if p.state == "open")
        risky = sum(1 for h in hosts for p in h.ports if p.level == "risque")
        self.summary.setText(f"{len(hosts)} machine(s) active(s) · {opened} port(s) ouvert(s) · "
                             f"{risky} service(s) sensible(s) exposé(s)")
        n = max(1, len(hosts))
        cols = max(1, math.ceil(math.sqrt(n)))
        cell = 230
        for i, h in enumerate(hosts):
            cx, cy = (i % cols) * cell, (i // cols) * cell
            self.draw_host(h, QPointF(cx, cy))
        self.view.setSceneRect(self.scene.itemsBoundingRect().adjusted(-30, -30, 30, 30))
        self.fill_table(hosts)
        self.fit()

    def fit(self):
        rect = self.view.sceneRect()
        if rect.isEmpty():
            return
        self.view.resetTransform()
        self.view.fitInView(rect, Qt.AspectRatioMode.KeepAspectRatio)
        if self.view.transform().m11() > 1.0:
            self.view.resetTransform()

    def resizeEvent(self, e):
        super().resizeEvent(e)
        self.fit()

    def showEvent(self, e):
        super().showEvent(e)
        self.fit()

    def draw_host(self, h, c):
        color = QColor(COLORS[h.level])
        r = 34
        body = QGraphicsEllipseItem(QRectF(c.x() - r, c.y() - r, 2 * r, 2 * r))
        body.setBrush(QBrush(QColor(color.red(), color.green(), color.blue(), 45)))
        body.setPen(QPen(color, 2))
        body.setToolTip("\n".join(x for x in (h.address, h.name, h.os) if x))
        self.scene.addItem(body)
        label = QGraphicsSimpleTextItem(h.address)
        label.setBrush(QBrush(QColor("#E8E8EC")))
        f = QFont()
        f.setBold(True)
        label.setFont(f)
        label.setPos(c.x() - label.boundingRect().width() / 2, c.y() - 8)
        self.scene.addItem(label)
        if h.name or h.os:
            sub = QGraphicsSimpleTextItem((h.name or h.os)[:28])
            sub.setBrush(QBrush(QColor("#8C8C95")))
            sub.setPos(c.x() - sub.boundingRect().width() / 2, c.y() + r + 6)
            self.scene.addItem(sub)
        ports = [p for p in h.ports if p.state == "open"][:16]
        for k, p in enumerate(ports):
            a = -math.pi / 2 + 2 * math.pi * k / max(1, len(ports))
            px, py = c.x() + math.cos(a) * 78, c.y() + math.sin(a) * 78
            pc = QColor(COLORS[p.level])
            dot = QGraphicsEllipseItem(QRectF(px - 15, py - 11, 30, 22))
            dot.setBrush(QBrush(QColor(pc.red(), pc.green(), pc.blue(), 60)))
            dot.setPen(QPen(pc, 1.5))
            dot.setToolTip(f"{p.number}/{p.protocol} {p.service}\n{p.product}".strip())
            self.scene.addItem(dot)
            self.scene.addLine(c.x() + math.cos(a) * r, c.y() + math.sin(a) * r,
                               px - math.cos(a) * 15, py - math.sin(a) * 11, QPen(QColor("#2A2A30"), 1))
            t = QGraphicsSimpleTextItem(str(p.number))
            t.setBrush(QBrush(QColor("#E8E8EC")))
            sf = QFont()
            sf.setPointSize(8)
            t.setFont(sf)
            t.setPos(px - t.boundingRect().width() / 2, py - t.boundingRect().height() / 2)
            self.scene.addItem(t)

    def fill_table(self, hosts):
        rows = [(h, p) for h in hosts for p in h.ports]
        self.table.setRowCount(len(rows))
        names = {"risque": "Sensible", "attention": "À vérifier", "sain": "Attendu", "neutre": "Fermé/filtré"}
        for r, (h, p) in enumerate(rows):
            vals = [h.address, f"{p.number}/{p.protocol}", p.state, p.service, p.product, names[p.level]]
            for col, v in enumerate(vals):
                item = QTableWidgetItem(v)
                if col == 5:
                    item.setForeground(QBrush(QColor(COLORS[p.level])))
                self.table.setItem(r, col, item)
        self.table.resizeColumnsToContents()


# [VUE-07]
class Gauge(QWidget):
    def __init__(self):
        super().__init__()
        self.value = None
        self.setMinimumSize(200, 200)

    def set_value(self, v):
        self.value = v
        self.update()

    def paintEvent(self, _):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        side = min(self.width(), self.height()) - 20
        rect = QRectF((self.width() - side) / 2, (self.height() - side) / 2, side, side)
        p.setPen(QPen(QColor("#222227"), 14, cap=Qt.PenCapStyle.RoundCap))
        p.drawArc(rect, 225 * 16, -270 * 16)
        if self.value is not None:
            v = max(0, min(100, self.value))
            color = COLORS["risque"] if v < 60 else COLORS["attention"] if v < 80 else COLORS["sain"]
            p.setPen(QPen(QColor(color), 14, cap=Qt.PenCapStyle.RoundCap))
            p.drawArc(rect, 225 * 16, int(-270 * 16 * v / 100))
        p.setPen(QColor("#E8E8EC"))
        f = QFont()
        f.setPointSize(28)
        f.setBold(True)
        p.setFont(f)
        p.drawText(rect, Qt.AlignmentFlag.AlignCenter, "—" if self.value is None else str(self.value))
        f.setPointSize(9)
        f.setBold(False)
        p.setFont(f)
        p.setPen(QColor("#8C8C95"))
        p.drawText(rect.adjusted(0, side * 0.32, 0, 0), Qt.AlignmentFlag.AlignCenter, "indice de durcissement")


class LynisView(QWidget):
    def __init__(self):
        super().__init__()
        lay = QHBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        self.gauge = Gauge()
        lay.addWidget(self.gauge)
        right = QVBoxLayout()
        self.wtitle = QLabel(objectName="section")
        self.warnings = QListWidget()
        self.stitle = QLabel(objectName="section")
        self.suggestions = QListWidget()
        for w in (self.wtitle, self.warnings, self.stitle, self.suggestions):
            right.addWidget(w)
        lay.addLayout(right, 1)

    def show_report(self, index, warnings, suggestions):
        self.gauge.set_value(index)
        self.wtitle.setText(f"Avertissements ({len(warnings)})")
        self.stitle.setText(f"Suggestions ({len(suggestions)})")
        self.warnings.clear()
        self.suggestions.clear()
        for ident, text in warnings:
            it = QListWidgetItem(f"{ident}  {text}")
            it.setForeground(QBrush(QColor(COLORS["risque"])))
            self.warnings.addItem(it)
        for ident, text in suggestions:
            self.suggestions.addItem(QListWidgetItem(f"{ident}  {text}"))


# [VUE-08]
class FindingsView(QWidget):
    def __init__(self):
        super().__init__()
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        self.summary = QLabel(objectName="muted")
        lay.addWidget(self.summary)
        self.table = QTableWidget(0, 2)
        self.table.setHorizontalHeaderLabels(["Fichier", "Détection"])
        self.table.horizontalHeader().setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().hide()
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        lay.addWidget(self.table, 1)
        open_btn = QPushButton("Ouvrir le dossier du fichier")
        open_btn.clicked.connect(self.open_folder)
        lay.addWidget(open_btn, 0, Qt.AlignmentFlag.AlignLeft)

    def show_findings(self, items):
        self.summary.setText("Aucune détection." if not items else f"{len(items)} détection(s)")
        self.table.setRowCount(len(items))
        for r, (path, sig) in enumerate(items):
            self.table.setItem(r, 0, QTableWidgetItem(path))
            s = QTableWidgetItem(sig)
            s.setForeground(QBrush(QColor(COLORS["risque"])))
            self.table.setItem(r, 1, s)

    def open_folder(self):
        row = self.table.currentRow()
        if row < 0:
            return
        folder = os.path.dirname(self.table.item(row, 0).text())
        if folder:
            subprocess.Popen(["xdg-open", folder], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


# [VUE-10]
TSHARK_FIELDS = [
    "frame.time_epoch", "eth.src", "eth.dst", "ip.src", "ip.dst", "ipv6.src", "ipv6.dst",
    "_ws.col.protocol", "frame.len", "tcp.srcport", "tcp.dstport", "udp.srcport", "udp.dstport",
]
RISKY_PORTS = {
    21: "ftp", 23: "telnet", 69: "tftp", 111: "rpcbind", 135: "msrpc", 139: "netbios", 161: "snmp",
    445: "smb", 512: "rexec", 513: "rlogin", 514: "rsh", 1433: "mssql", 2049: "nfs", 2375: "docker",
    3306: "mysql", 3389: "rdp", 5432: "postgresql", 5900: "vnc", 6000: "x11", 6379: "redis",
    9200: "elasticsearch", 11211: "memcached", 27017: "mongodb",
}
CLEAR_PORTS = {80: "http", 110: "pop3", 143: "imap", 25: "smtp", 8080: "http"}


@dataclass
class Conversation:
    a: str
    b: str
    packets: int = 0
    bytes: int = 0
    flags: set = field(default_factory=set)

    @property
    def level(self):
        if any(f in RISKY_PORTS.values() for f in self.flags):
            return "risque"
        if self.flags:
            return "attention"
        return "neutre"


class Capture:
    def __init__(self, window=60):
        self.window = window
        self.reset()

    def reset(self):
        self.packets = 0
        self.bytes = 0
        self.first = None
        self.last = None
        self.rate = deque(maxlen=self.window)
        self.second = None
        self.protocols = Counter()
        self.conversations = {}
        self.rest = ""

    def feed(self, text):
        data = self.rest + text
        lines = data.split("\n")
        self.rest = lines.pop()
        n = 0
        for line in lines:
            n += self.add(line)
        return n

    def flush(self):
        if self.rest:
            line, self.rest = self.rest, ""
            return self.add(line)
        return 0

    def add(self, line):
        cols = line.rstrip("\r").split("|")
        if len(cols) != len(TSHARK_FIELDS):
            return 0
        f = dict(zip(TSHARK_FIELDS, (c.split(",")[0].strip() for c in cols)))
        try:
            ts = float(f["frame.time_epoch"])
            size = int(f["frame.len"] or 0)
        except ValueError:
            return 0
        src = f["ip.src"] or f["ipv6.src"] or f["eth.src"] or "?"
        dst = f["ip.dst"] or f["ipv6.dst"] or f["eth.dst"] or "?"
        self.packets += 1
        self.bytes += size
        self.first = ts if self.first is None else self.first
        self.last = ts
        sec = int(ts)
        if self.second is None or sec != self.second:
            if self.second is not None:
                for _ in range(min(self.window, max(0, sec - self.second - 1))):
                    self.rate.append(0)
            self.second = sec
            self.rate.append(0)
        self.rate[-1] += size
        self.protocols[f["_ws.col.protocol"] or "?"] += 1
        a, b = sorted((src, dst))
        conv = self.conversations.get((a, b))
        if conv is None:
            conv = self.conversations[(a, b)] = Conversation(a, b)
        conv.packets += 1
        conv.bytes += size
        for key in ("tcp.srcport", "tcp.dstport", "udp.srcport", "udp.dstport"):
            if f[key].isdigit():
                port = int(f[key])
                name = RISKY_PORTS.get(port) or CLEAR_PORTS.get(port)
                if name:
                    conv.flags.add(name)
        return 1

    def duration(self):
        return 0 if self.first is None else max(0.0, self.last - self.first)

    def top(self, n=20):
        return sorted(self.conversations.values(), key=lambda c: c.bytes, reverse=True)[:n]


def human(n):
    for unit in ("o", "Ko", "Mo", "Go"):
        if n < 1024 or unit == "Go":
            return f"{n:.0f} {unit}" if unit == "o" else f"{n:.1f} {unit}"
        n /= 1024
    return str(n)


class Sparkline(QWidget):
    def __init__(self):
        super().__init__()
        self.values = []
        self.setMinimumHeight(110)

    def set_values(self, values):
        self.values = list(values)
        self.update()

    def paintEvent(self, _):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        r = QRectF(self.rect()).adjusted(8, 22, -8, -8)
        p.setPen(QColor("#8C8C95"))
        top = max(self.values) if self.values else 0
        p.drawText(QRectF(8, 0, self.width() - 16, 20), Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter,
                   f"Débit (60 s) · pic {human(top)}/s")
        p.setPen(QPen(QColor("#222227"), 1))
        p.drawLine(r.bottomLeft(), r.bottomRight())
        if len(self.values) < 2 or top <= 0:
            return
        accent = QColor(ACCENT)
        step = r.width() / (len(self.values) - 1)
        pts = [QPointF(r.x() + i * step, r.bottom() - r.height() * v / top) for i, v in enumerate(self.values)]
        area = QPainterPath(QPointF(pts[0].x(), r.bottom()))
        for pt in pts:
            area.lineTo(pt)
        area.lineTo(pts[-1].x(), r.bottom())
        fill = QColor(accent)
        fill.setAlpha(50)
        p.fillPath(area, fill)
        line = QPainterPath(pts[0])
        for pt in pts[1:]:
            line.lineTo(pt)
        p.setPen(QPen(accent, 2))
        p.drawPath(line)


class ProtocolBars(QWidget):
    def __init__(self):
        super().__init__()
        self.items = []
        self.setMinimumWidth(220)

    def set_items(self, items):
        self.items = items
        self.update()

    def paintEvent(self, _):
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        p.setPen(QColor("#8C8C95"))
        p.drawText(QRectF(8, 0, self.width() - 16, 20), Qt.AlignmentFlag.AlignVCenter, "Protocoles")
        if not self.items:
            return
        accent = QColor(ACCENT)
        total = sum(c for _, c in self.items) or 1
        top = self.items[0][1]
        row = max(16, min(24, (self.height() - 26) / len(self.items)))
        for i, (name, count) in enumerate(self.items):
            y = 26 + i * row
            if y + row > self.height():
                break
            bar = QRectF(90, y + 4, (self.width() - 150) * count / top, row - 10)
            c = QColor(accent)
            c.setAlpha(170)
            p.setPen(Qt.PenStyle.NoPen)
            p.setBrush(c)
            p.drawRoundedRect(bar, 4, 4)
            p.setPen(QColor("#E8E8EC"))
            p.drawText(QRectF(8, y, 80, row), Qt.AlignmentFlag.AlignVCenter, name[:11])
            p.setPen(QColor("#8C8C95"))
            p.drawText(QRectF(bar.right() + 6, y, 60, row), Qt.AlignmentFlag.AlignVCenter,
                       f"{100 * count / total:.0f} %")


class TsharkView(QWidget):
    def __init__(self):
        super().__init__()
        self.capture = Capture()
        lay = QVBoxLayout(self)
        lay.setContentsMargins(0, 0, 0, 0)
        self.summary = QLabel(objectName="muted")
        lay.addWidget(self.summary)
        top = QHBoxLayout()
        self.spark = Sparkline()
        self.bars = ProtocolBars()
        top.addWidget(self.spark, 3)
        top.addWidget(self.bars, 2)
        lay.addLayout(top, 2)
        self.table = QTableWidget(0, 5)
        self.table.setHorizontalHeaderLabels(["Machine A", "Machine B", "Paquets", "Volume", "Services en clair / sensibles"])
        self.table.horizontalHeader().setSectionResizeMode(4, QHeaderView.ResizeMode.Stretch)
        self.table.verticalHeader().hide()
        self.table.setEditTriggers(QTableWidget.EditTrigger.NoEditTriggers)
        self.table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        lay.addWidget(self.table, 3)
        self.timer = QTimer(self)
        self.timer.setInterval(500)
        self.timer.timeout.connect(self.refresh)
        self.dirty = False
        self.refresh()

    def reset(self):
        self.capture.reset()
        self.dirty = True
        self.refresh()
        self.timer.start()

    def feed(self, text):
        if self.capture.feed(text):
            self.dirty = True

    def finish(self):
        self.capture.flush()
        self.timer.stop()
        self.dirty = True
        self.refresh()

    def refresh(self):
        if not self.dirty and self.capture.packets:
            return
        self.dirty = False
        c = self.capture
        risky = sum(1 for x in c.conversations.values() if x.level == "risque")
        self.summary.setText(f"{c.packets} paquet(s) · {human(c.bytes)} · {c.duration():.0f} s · "
                             f"{len(c.conversations)} conversation(s) · {risky} sensible(s)")
        self.spark.set_values(c.rate)
        self.bars.set_items(c.protocols.most_common(8))
        rows = c.top()
        self.table.setRowCount(len(rows))
        for r, conv in enumerate(rows):
            vals = [conv.a, conv.b, str(conv.packets), human(conv.bytes), ", ".join(sorted(conv.flags))]
            for col, v in enumerate(vals):
                item = QTableWidgetItem(v)
                if col == 4 and conv.flags:
                    item.setForeground(QBrush(QColor(COLORS[conv.level])))
                self.table.setItem(r, col, item)


# [VUE-09]
def make_view(kind):
    return {"nmap": NmapView, "lynis": LynisView, "clamav": FindingsView, "yara": FindingsView,
            "tshark": TsharkView}[kind]()


def render(kind, widget, output_text, report_path):
    if kind == "nmap":
        if not report_path or not Path(report_path).is_file():
            return "aucun rapport Nmap produit"
        widget.show_hosts(parse_nmap(report_path))
    elif kind == "lynis":
        if not report_path or not Path(report_path).is_file():
            return "aucun rapport Lynis produit"
        widget.show_report(*parse_lynis(report_path))
    elif kind == "clamav":
        widget.show_findings(parse_clamav(output_text))
    elif kind == "yara":
        widget.show_findings(parse_yara(output_text))
    elif kind == "tshark":
        if not widget.capture.packets:
            widget.feed(output_text)
        widget.finish()
        if not widget.capture.packets:
            return "aucun paquet capturé"
    return ""
