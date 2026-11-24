import sys
import tempfile
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "arsenal"))
import vues

HERE = Path(tempfile.mkdtemp())

NMAP = """<?xml version="1.0"?>
<nmaprun>
<host><status state="up"/><address addr="192.168.1.1" addrtype="ipv4"/>
<hostnames><hostname name="box.lan"/></hostnames>
<ports>
<port protocol="tcp" portid="53"><state state="open"/><service name="domain" product="dnsmasq" version="2.90"/></port>
<port protocol="tcp" portid="80"><state state="open"/><service name="http" product="lighttpd"/></port>
<port protocol="tcp" portid="443"><state state="open"/><service name="https"/></port>
<port protocol="tcp" portid="23"><state state="open"/><service name="telnet"/></port>
</ports><os><osmatch name="Linux 5.X" accuracy="96"/></os></host>
<host><status state="up"/><address addr="192.168.1.20" addrtype="ipv4"/>
<ports>
<port protocol="tcp" portid="22"><state state="open"/><service name="ssh" product="OpenSSH" version="9.6"/></port>
<port protocol="tcp" portid="445"><state state="open"/><service name="microsoft-ds"/></port>
<port protocol="tcp" portid="3389"><state state="filtered"/><service name="ms-wbt-server"/></port>
</ports></host>
<host><status state="down"/><address addr="192.168.1.99" addrtype="ipv4"/></host>
<host><status state="up"/><address addr="192.168.1.42" addrtype="ipv4"/>
<ports><port protocol="tcp" portid="8080"><state state="open"/><service name="http-proxy"/></port></ports></host>
</nmaprun>"""

LYNIS = """hardening_index=67
warning[]=SSH-7408|Root login allowed|-|
warning[]=FIRE-4512|No active firewall rules|-|
suggestion[]=PKGS-7370|Install debsums|-|
suggestion[]=AUTH-9262|Install PAM module for password strength|pam_passwdqc|
"""


def tshark_lines():
    rows = [
        (1700000000.1, "", "", "192.168.1.20", "192.168.1.1", "", "", "DNS", 74, "", "", "51000", "53"),
        (1700000000.4, "", "", "192.168.1.20", "10.0.0.5", "", "", "TELNET", 120, "50122", "23", "", ""),
        (1700000001.2, "", "", "10.0.0.5", "192.168.1.20", "", "", "TELNET", 300, "23", "50122", "", ""),
        (1700000003.0, "", "", "192.168.1.20", "93.184.216.34", "", "", "HTTP", 900, "50200", "80", "", ""),
        (1700000003.5, "", "", "", "", "fe80::1", "ff02::1", "ICMPv6", 86, "", "", "", ""),
        (1700000004.0, "aa:bb:cc:00:00:01", "ff:ff:ff:ff:ff:ff", "", "", "", "", "ARP", 42, "", "", "", ""),
    ]
    return "".join("|".join(str(c) for c in r) + "\n" for r in rows)


def main():
    (HERE / "scan.xml").write_text(NMAP)
    (HERE / "lynis.dat").write_text(LYNIS)
    hosts = vues.parse_nmap(HERE / "scan.xml")
    assert [h.address for h in hosts] == ["192.168.1.1", "192.168.1.20", "192.168.1.42"]
    assert hosts[0].level == "risque" and hosts[2].level == "attention"
    assert hosts[0].ports[0].product == "dnsmasq 2.90"
    idx, w, s = vues.parse_lynis(HERE / "lynis.dat")
    assert idx == 67 and len(w) == 2 and s[1][1].endswith("(pam_passwdqc)")
    clam = vues.parse_clamav("/home/x/a.exe: Win.Trojan.Agent FOUND\n/home/x/b.txt: OK\n")
    assert clam == [("/home/x/a.exe", "Win.Trojan.Agent")]
    (HERE / "cible.bin").write_text("x")
    yr = vues.parse_yara(f"Suspect_Strings {HERE / 'cible.bin'}\nwarning: blah\n")
    assert yr == [(str(HERE / "cible.bin"), "Suspect_Strings")]
    cap = vues.Capture()
    text = "Capturing on 'eth0'\n" + tshark_lines()
    assert cap.feed(text[:150]) + cap.feed(text[150:]) == 6
    assert cap.packets == 6 and cap.bytes == 74 + 120 + 300 + 900 + 86 + 42
    assert list(cap.rate) == [194, 300, 0, 986, 42], list(cap.rate)
    telnet = cap.conversations[("10.0.0.5", "192.168.1.20")]
    assert telnet.packets == 2 and telnet.level == "risque" and telnet.flags == {"telnet"}
    assert cap.conversations[("192.168.1.20", "93.184.216.34")].level == "attention"
    assert cap.top(1)[0].bytes == 900
    assert cap.protocols["TELNET"] == 2 and ("aa:bb:cc:00:00:01", "ff:ff:ff:ff:ff:ff") in cap.conversations
    print("parseurs ok")

    from PyQt6.QtWidgets import QApplication
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    app.setStyleSheet((Path(__file__).resolve().parent.parent / "arsenal" / "style.qss").read_text())
    for kind, out, rep, name in [
        ("nmap", "", HERE / "scan.xml", "nmap"),
        ("lynis", "", HERE / "lynis.dat", "lynis"),
        ("clamav", "/home/x/a.exe: Win.Trojan.Agent FOUND\n", None, "clamav"),
        ("tshark", tshark_lines(), None, "tshark"),
    ]:
        v = vues.make_view(kind)
        v.resize(860, 560)
        err = vues.render(kind, v, out, rep)
        assert not err, err
        v.show()
        app.processEvents()
        v.grab().save(str(HERE / f"{name}.png"))
    print("vues ok")


main()
