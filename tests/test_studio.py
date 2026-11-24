import os
import sys
import tempfile
from pathlib import Path

home = tempfile.mkdtemp()
os.environ.update(HOME=home, XDG_DATA_HOME=f"{home}/.local/share", XDG_CONFIG_HOME=f"{home}/.config")
sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "studio"))
import studio as S
from PyQt6.QtWidgets import QApplication

app = QApplication(sys.argv)
w = S.Studio()
w.show()
app.processEvents()
assert w.list.count() >= 3
w.set_accent("#3CCFCF")
w.blur.setValue(14)
w.name.setText("Lagon")
w.changed()
t = w.save_theme()
saved = (S.E.USER_THEMES / "lagon.toml").read_text()
assert t.ident == "lagon" and 'accent = "#3CCFCF"' in saved and "flou = 14" in saved
assert S.E.load("lagon").accent == "#3CCFCF"
w.run_engine(w.collect(), False)
assert S.E.current_theme() == "lagon"
w.name.setText("Lab'O Noir")
w.changed()
t2 = w.save_theme()
assert t2.ident == "lab-o-noir", t2.ident
w.duplicate()
assert S.E.is_user_theme("lab-o-noir-copie")
print("studio ok")
