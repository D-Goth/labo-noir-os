import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "arsenal"))
import arsenal as A

TOOLS = {t["id"]: t for c in A.load_tools() for t in c["tools"]}


def cmd(tid, values, runner="host", admin=None):
    t = TOOLS[tid]
    if admin is None:
        admin = A.needs_admin(t, values)
    return A.full_command(t, runner, A.build_args(t, values), None, admin)


nmap_syn = cmd("nmap", {"scan": 1, "target": "192.168.1.0/24"})
assert nmap_syn[0] == "pkexec" and "-sS" in nmap_syn, nmap_syn
nmap_tcp = cmd("nmap", {"scan": 0, "target": "192.168.1.1"})
assert nmap_tcp[0] == "nmap", nmap_tcp
nmap_os = cmd("nmap", {"scan": 0, "os": True, "target": "192.168.1.1"})
assert nmap_os[0] == "pkexec", nmap_os
assert A.needs_admin(TOOLS["rkhunter"], {})
assert cmd("rkhunter", {})[0] == "pkexec"
lynis_user = cmd("lynis", {"quick": True}, admin=False)
assert lynis_user[0] == "lynis", lynis_user
lynis_root = cmd("lynis", {"quick": True}, admin=True)
assert lynis_root[:2] == ["pkexec", "lynis"], lynis_root
tcpdump = cmd("tcpdump", {"iface": "any"})
assert tcpdump[:2] == ["sudo", "tcpdump"], tcpdump
hydra = cmd("hydra", {"users": "u", "pass": "p", "target": "10.0.0.5"}, runner="kali", admin=True)
assert hydra[:6] == ["distrobox", "enter", "kali", "--", "sudo", "hydra"], hydra
inj = cmd("nmap", {"scan": 0, "target": "10.0.0.1; reboot"})
assert inj[-1] == "10.0.0.1; reboot", inj
shark = cmd("tshark", {"iface": "eth0", "count": "500"})
assert shark[0] == "tshark" and "-l" in shark and "_ws.col.protocol" in shark, shark
assert shark[shark.index("-c") + 1] == "500" and shark[shark.index("-i") + 1] == "eth0"
import vues
fields = [shark[i + 1] for i, a in enumerate(shark) if a == "-e"]
assert fields == vues.TSHARK_FIELDS, fields
print("commandes ok")
