#!/usr/bin/env python3
"""Orbit Pixel : analyseur de niveaux audio (nécessite python3-numpy).

Usage : orbit-audio.py out   (ce qui sort des haut-parleurs / de l'oreillette)
        orbit-audio.py in    (le micro)

Capture le flux via PipeWire (pw-record) ou PulseAudio (parec), calcule le niveau
d'énergie de quelques bandes de fréquences (en dBFS) et le sert au widget par un mini
serveur HTTP local : 127.0.0.1, port aléatoire, jeton secret dans l'URL.
Port et jeton sont écrits (mode 600) dans $XDG_RUNTIME_DIR/orbit-audio-<mode>.port.

Rien n'est enregistré : seuls des niveaux circulent. Le démon s'arrête seul quand plus
aucun widget ne l'interroge pendant 20 s. Une seule instance par mode (verrou).
"""
import fcntl
import http.server
import math
import os
import secrets
import select
import signal
import socketserver
import subprocess
import sys
import threading
import time

try:
    import numpy as np
except Exception:
    sys.exit("orbit-audio.py : numpy est requis (sudo apt install python3-numpy)")

MODE = sys.argv[1] if len(sys.argv) > 1 else ""
if MODE not in ("out", "in"):
    sys.exit("usage: orbit-audio.py out|in")

RATE, N = 48000, 1024
FLOOR = -120.0
LAT = ["--latency", "25ms"]

if MODE == "out":
    NB, FMIN, FMAX, IDX, ATT, DEC = 7, 20.0, 20000.0, [1, 2, 3, 4, 5, 6], 10.0, 200.0
    CMDS = [
        ["pw-record", "-P", "stream.capture.sink=true", "--rate", str(RATE), "--channels", "1", "--format", "s16"] + LAT + ["-"],
        ["pw-record", "-P", "stream.capture.sink=true", "--rate", str(RATE), "--channels", "1", "--format", "s16", "-"],
        ["parec", "-d", "@DEFAULT_MONITOR@", "--rate=%d" % RATE, "--channels=1", "--format=s16le", "--latency-msec=20"],
    ]
else:
    NB, FMIN, FMAX, IDX, ATT, DEC = 4, 80.0, 20000.0, [1, 2, 3], 15.0, 75.0
    CMDS = [
        ["pw-record", "--rate", str(RATE), "--channels", "1", "--format", "s16"] + LAT + ["-"],
        ["pw-record", "--rate", str(RATE), "--channels", "1", "--format", "s16", "-"],
        ["parec", "--rate=%d" % RATE, "--channels=1", "--format=s16le", "--latency-msec=20"],
    ]

EDGES = [FMIN * (FMAX / FMIN) ** (k / NB) for k in range(NB + 1)]
BANDS = [(EDGES[i], EDGES[i + 1]) for i in IDX]
NEED = N * 2  # octets par trame (s16 mono)

WIN = np.hanning(N).astype(np.float32)
FREQS = np.fft.rfftfreq(N, 1.0 / RATE)
BAND_BINS = []
for lo, hi in BANDS:
    ids = np.nonzero((FREQS >= lo) & (FREQS < hi))[0]
    if len(ids) == 0:
        ids = np.array([int(np.argmin(np.abs(FREQS - math.sqrt(lo * hi))))])
    BAND_BINS.append(ids)
# Énergie de la bande (somme des puissances), calée pour qu'un sinus pleine échelle donne 0 dBFS
# (fenêtre de Hann : pic A*N/4, voisins A*N/8 -> somme des carrés = 1,5 * (A*N/4)^2)
REF = 32768.0 * N / 4.0 * math.sqrt(1.5)

STATE = {"text": " ".join("%.1f" % FLOOR for _ in BANDS), "last": time.time()}
TOKEN = secrets.token_urlsafe(12)


def db(mag):
    return max(FLOOR, 20.0 * math.log10(mag / REF + 1e-9))


def levels_of(raw):
    x = np.frombuffer(raw, dtype="<i2").astype(np.float32)
    if float(np.abs(x).max()) < 3:
        return [FLOOR] * len(BANDS)
    p = np.abs(np.fft.rfft(x * WIN)) ** 2
    return [db(math.sqrt(float(p[ids].sum()))) for ids in BAND_BINS]


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.0"

    def do_GET(self):
        if self.path != "/" + TOKEN:
            self.send_response(404)
            self.end_headers()
            return
        STATE["last"] = time.time()
        body = STATE["text"].encode()
        self.send_response(200)
        self.send_header("Content-Type", "text/plain")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()  # volontairement aucun en-tête CORS : une page web ne peut pas lire la réponse
        self.wfile.write(body)

    def log_message(self, *args):
        pass


class Server(socketserver.ThreadingMixIn, http.server.HTTPServer):
    daemon_threads = True


def frames(proc):
    """Génère des trames brutes ; None si rien n'arrive pendant 1 s (sortie en veille)."""
    fd = proc.stdout.fileno()
    buf = b""
    probed = False
    while True:
        ready, _, _ = select.select([fd], [], [], 1.0)
        if not ready:
            yield None
            continue
        chunk = os.read(fd, 65536)
        if not chunk:
            return
        buf += chunk
        if not probed:
            if len(buf) < 64:
                continue
            probed = True
            if buf[:4] == b"RIFF":  # pw-record peut préfixer un en-tête WAV
                pos = buf.find(b"data", 0, 256)
                if pos < 0:
                    return
                buf = buf[pos + 8:]
        if len(buf) > NEED * 4:  # on reste en temps réel : on jette le retard
            buf = buf[-NEED * 2:]
        while len(buf) >= NEED:
            yield buf[:NEED]
            buf = buf[NEED:]


def main():
    run = os.environ.get("XDG_RUNTIME_DIR") or "/tmp"
    base = os.path.join(run, "orbit-audio-" + MODE)
    port_file = base + ".port"

    lock = open(base + ".lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return  # déjà lancé

    server = Server(("127.0.0.1", 0), Handler)
    port = server.server_address[1]
    fd = os.open(port_file, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w") as f:
        f.write("%d %s" % (port, TOKEN))
    threading.Thread(target=server.serve_forever, daemon=True).start()

    def alive():
        return time.time() - STATE["last"] < 20

    def publish(vals):
        STATE["text"] = " ".join("%.1f" % v for v in vals)

    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))

    cur = [FLOOR] * len(BANDS)
    proc = None
    attempt = 0
    last_check = 0.0

    try:
        while True:
            started = time.monotonic()
            proc = None
            try:
                proc = subprocess.Popen(CMDS[attempt % len(CMDS)], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
            except OSError:
                proc = None

            if proc is not None:
                for raw in frames(proc):
                    now = time.monotonic()
                    if now - last_check > 2.0:
                        last_check = now
                        if not alive():
                            return
                    target = levels_of(raw) if raw is not None else [FLOOR] * len(BANDS)
                    dt_ms = N / RATE * 1000.0
                    for i, t in enumerate(target):
                        tau = ATT if t > cur[i] else DEC
                        cur[i] += (t - cur[i]) * (1.0 - math.exp(-dt_ms / tau))
                    publish(cur)
                try:
                    proc.kill()
                    proc.wait(timeout=2)
                except Exception:
                    pass

            attempt += 1
            publish([FLOOR] * len(BANDS))
            # commande qui plante tout de suite (option inconnue) : on passe vite à la suivante
            pause = 1.0 if time.monotonic() - started < 3.0 else 5.0
            end = time.monotonic() + pause
            while time.monotonic() < end:
                time.sleep(0.25)
                if not alive():
                    return
    finally:
        if proc is not None:
            try:
                proc.kill()
            except Exception:
                pass
        try:
            os.unlink(port_file)
        except OSError:
            pass
        server.shutdown()


if __name__ == "__main__":
    main()
