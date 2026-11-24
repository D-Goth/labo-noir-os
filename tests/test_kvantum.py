import importlib.machinery
import importlib.util
import os
import tempfile
from dataclasses import replace
from pathlib import Path

home = tempfile.mkdtemp()
os.environ.update(HOME=home, XDG_DATA_HOME=f"{home}/.local/share", XDG_CONFIG_HOME=f"{home}/.config")
root = Path(__file__).resolve().parent.parent
loader = importlib.machinery.SourceFileLoader("labnoir_theme", str(root / "bin" / "labnoir-theme"))
E = importlib.util.module_from_spec(importlib.util.spec_from_loader("labnoir_theme", loader))
loader.exec_module(E)

base = Path(home) / "Kvantum" / "KvArcDark"
base.mkdir(parents=True)
(base / "KvArcDark.kvconfig").write_text(
    "[%General]\ncomposite=true\ntranslucent_windows=false\n\n[GeneralColors]\nwindow.color=#383C4A\nhighlight.color=#5294E2\n"
)
(base / "KvArcDark.svg").write_text('<svg><rect fill="#5294E2"/><rect fill="#383C4A"/><rect fill="#E23D2D"/></svg>')
E.KVANTUM_SYSTEM = Path(home) / "Kvantum"

t = replace(E.load("labonoir"), glass_windows=True, window_opacity=0.8)
assert E.load("labonoir").glass_windows
cfg, svg = E.render_kvantum(t)
assert "translucent_windows=true" in cfg and "blurring=true" in cfg
assert "reduce_window_opacity=20" in cfg
assert f"highlight.color={t.accent}" in cfg
assert "#5294E2" not in svg and t.accent in svg and "#E23D2D" in svg
assert "#383C4A" not in svg

assert E.render_kvantum(replace(t, mode="clair")) is None
text = E.dump(t)
assert "fenetres = true" in text and "opacite_fenetres = 0.80" in text
print("kvantum ok")
