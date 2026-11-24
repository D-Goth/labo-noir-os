#!/usr/bin/env python3
import json
import os
import shlex
import shutil
import subprocess
import sys
import tomllib
from pathlib import Path

from PyQt6.QtCore import QProcess, Qt, QTimer
from PyQt6.QtGui import QBrush, QColor, QFont, QFontDatabase, QIcon, QTextCursor
from PyQt6.QtWidgets import (
    QApplication, QCheckBox, QComboBox, QFormLayout, QFrame, QHBoxLayout, QLabel, QLineEdit,
    QMainWindow, QPlainTextEdit, QPushButton, QSplitter, QTabWidget, QTreeWidget, QTreeWidgetItem,
    QVBoxLayout, QWidget,
)

sys.path.insert(0, str(Path(__file__).resolve().parent))
import vues

# [ARS-02]
HERE = Path(__file__).resolve().parent
TOOLS = HERE / "tools.json"
STYLE = HERE / "style.qss"
ICON = HERE / "assets" / "icon.png"
BOX = os.environ.get("LABNOIR_KALI_BOX", "kali")
CONFIG_HOME = Path(os.environ.get("XDG_CONFIG_HOME", Path.home() / ".config"))
THEME_DIRS = [Path.home() / ".local/share/labnoir/themes", Path("/opt/labnoir/themes"), HERE.parent / "themes"]
RUNNER_LABEL = {"host": "Système", "kali": "Kali isolée"}


# [ARS-03]
def load_tools():
    with open(TOOLS, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("categories", [])


# [ARS-04]
def theme_accent():
    try:
        ident = (CONFIG_HOME / "labnoir" / "theme").read_text(encoding="utf-8").strip()
    except OSError:
        ident = "labonoir"
    for d in THEME_DIRS:
        p = d / f"{ident}.toml"
        if p.is_file():
            try:
                with open(p, "rb") as f:
                    return tomllib.load(f).get("accent", "#FF1654")
            except (OSError, tomllib.TOMLDecodeError):
                break
    return "#FF1654"


# [ARS-05]
class Runners:
    def __init__(self):
        self.refresh()

    def refresh(self):
        self.distrobox = shutil.which("distrobox") is not None
        self.kali = False
        if self.distrobox:
            try:
                out = subprocess.run(["distrobox", "list", "--no-color"], capture_output=True, text=True,
                                     timeout=10).stdout
                self.kali = any(line.split("|")[1].strip() == BOX for line in out.splitlines()[1:]
                                if line.count("|") >= 2)
            except (OSError, subprocess.SubprocessError, IndexError):
                self.kali = False

    def resolve(self, tool):
        wanted = tool.get("runner", "host")
        on_host = shutil.which(tool["program"]) is not None
        if wanted == "auto":
            if on_host:
                return "host", True, ""
            wanted = "kali"
        if wanted == "host":
            return "host", on_host, "" if on_host else f"« {tool['program']} » n'est pas installé sur le système"
        if not self.distrobox:
            return "kali", False, "Distrobox absent : sudo ./install.sh --only redteam"
        if not self.kali:
            return "kali", False, "Kali isolée absente : lance « labnoir-redteam init »"
        return "kali", True, ""


# [ARS-06]
def build_args(tool, values):
    args = []
    for p in tool.get("params", []):
        v = values.get(p["id"])
        if p["type"] == "flag":
            if v:
                args += p["args"]
        elif p["type"] == "choice":
            opts = p["options"]
            idx = v if isinstance(v, int) and 0 <= v < len(opts) else p.get("default", 0)
            args += opts[idx]["args"]
        else:
            text = (v or "").strip()
            if not text:
                if p.get("required"):
                    raise ValueError(f"« {p['label']} » est obligatoire")
                continue
            if text.startswith("~"):
                text = os.path.expanduser(text)
            if "prefix" in p:
                args.append(p["prefix"] + text)
            elif "flag" in p:
                args += [p["flag"], text]
            else:
                args.append(text)
    return args


def view_args(tool, report):
    vue = tool.get("vue") or {}
    if not vue.get("args"):
        return []
    folder = str(Path(report).parent) if report else str(vues.CACHE)
    path = str(report) if report else str(vues.CACHE / vue.get("fichier", "rapport"))
    return [a.replace("{fichier}", path).replace("{dossier}", folder) for a in vue["args"]]


def needs_admin(tool, values):
    if tool.get("sudo"):
        return True
    for p in tool.get("params", []):
        v = values.get(p["id"])
        if p["type"] == "flag" and v and p.get("root"):
            return True
        if p["type"] == "choice":
            opts = p["options"]
            idx = v if isinstance(v, int) and 0 <= v < len(opts) else p.get("default", 0)
            if opts[idx].get("root"):
                return True
    return False


def full_command(tool, runner, args, report=None, admin=False):
    cmd = [tool["program"], *view_args(tool, report), *args]
    if admin:
        if runner == "kali" or tool.get("terminal"):
            cmd = ["sudo", *cmd]
        else:
            cmd = ["pkexec", *cmd]
    if runner == "kali":
        cmd = ["distrobox", "enter", BOX, "--", *cmd]
    return cmd


# [ARS-07]
def terminal_command(cmd):
    if shutil.which("konsole"):
        return ["konsole", "--hold", "-e", *cmd]
    if shutil.which("x-terminal-emulator"):
        return ["x-terminal-emulator", "-e", *cmd]
    return None


# [ARS-08]
class ParamForm(QWidget):
    def __init__(self, on_change):
        super().__init__()
        self.on_change = on_change
        self.layout_ = QFormLayout(self)
        self.layout_.setContentsMargins(0, 0, 0, 0)
        self.layout_.setHorizontalSpacing(16)
        self.layout_.setVerticalSpacing(10)
        self.fields = {}

    def build(self, tool):
        while self.layout_.rowCount():
            self.layout_.removeRow(0)
        self.fields = {}
        for p in tool.get("params", []):
            if p["type"] == "flag":
                w = QCheckBox(p["label"])
                w.setChecked(bool(p.get("defaut_coche")))
                w.toggled.connect(self.on_change)
                self.layout_.addRow("", w)
            elif p["type"] == "choice":
                w = QComboBox()
                w.addItems([o["label"] for o in p["options"]])
                w.setCurrentIndex(p.get("default", 0))
                w.currentIndexChanged.connect(self.on_change)
                self.layout_.addRow(p["label"], w)
            else:
                w = QLineEdit()
                w.setPlaceholderText(p.get("placeholder", ""))
                w.setText(p.get("default", ""))
                w.textChanged.connect(self.on_change)
                label = p["label"] + (" *" if p.get("required") else "")
                self.layout_.addRow(label, w)
            self.fields[p["id"]] = (p, w)

    def values(self):
        out = {}
        for pid, (p, w) in self.fields.items():
            if p["type"] == "flag":
                out[pid] = w.isChecked()
            elif p["type"] == "choice":
                out[pid] = w.currentIndex()
            else:
                out[pid] = w.text()
        return out


# [ARS-09]
class Arsenal(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Arsenal")
        self.resize(1180, 760)
        if ICON.exists():
            self.setWindowIcon(QIcon(str(ICON)))
        self.categories = load_tools()
        self.runners = Runners()
        self.tool = None
        self.running_tool = None
        self.running_admin = False
        self.proc = None
        self.build_ui()
        self.populate()

    def build_ui(self):
        root = QWidget()
        self.setCentralWidget(root)
        outer = QHBoxLayout(root)
        outer.setContentsMargins(0, 0, 0, 0)
        split = QSplitter(Qt.Orientation.Horizontal)
        outer.addWidget(split)

        side = QFrame(objectName="side")
        sl = QVBoxLayout(side)
        sl.setContentsMargins(18, 20, 18, 18)
        sl.setSpacing(12)
        title = QLabel("Arsenal", objectName="brand")
        sl.addWidget(title)
        self.search = QLineEdit(placeholderText="Rechercher un outil…")
        self.search.textChanged.connect(self.filter)
        sl.addWidget(self.search)
        self.tree = QTreeWidget()
        self.tree.setHeaderHidden(True)
        self.tree.setIndentation(12)
        self.tree.currentItemChanged.connect(self.select)
        sl.addWidget(self.tree, 1)
        self.kali_state = QLabel(objectName="muted")
        self.kali_state.setWordWrap(True)
        sl.addWidget(self.kali_state)
        refresh = QPushButton("Actualiser")
        refresh.clicked.connect(self.refresh_runners)
        about = QPushButton("À propos")
        about.clicked.connect(lambda: QProcess.startDetached("labnoir-about", []))
        foot = QHBoxLayout()
        foot.addWidget(refresh, 1)
        foot.addWidget(about)
        sl.addLayout(foot)
        split.addWidget(side)

        main = QFrame(objectName="main")
        ml = QVBoxLayout(main)
        ml.setContentsMargins(28, 24, 28, 24)
        ml.setSpacing(14)
        head = QHBoxLayout()
        self.name = QLabel("Choisis un outil", objectName="title")
        head.addWidget(self.name)
        head.addStretch(1)
        self.badge = QLabel(objectName="badge")
        self.badge.hide()
        head.addWidget(self.badge)
        ml.addLayout(head)
        self.desc = QLabel(objectName="muted")
        self.desc.setWordWrap(True)
        ml.addWidget(self.desc)
        self.warning = QLabel(objectName="warning")
        self.warning.setWordWrap(True)
        self.warning.hide()
        ml.addWidget(self.warning)

        self.form = ParamForm(self.update_preview)
        ml.addWidget(self.form)

        self.preview = QLineEdit(objectName="preview")
        self.preview.setReadOnly(True)
        mono = QFontDatabase.systemFont(QFontDatabase.SystemFont.FixedFont)
        self.preview.setFont(mono)
        ml.addWidget(self.preview)

        actions = QHBoxLayout()
        self.run_btn = QPushButton("Exécuter", objectName="accent")
        self.run_btn.clicked.connect(self.run)
        self.stop_btn = QPushButton("Arrêter")
        self.stop_btn.clicked.connect(self.stop)
        self.stop_btn.setEnabled(False)
        self.admin = QCheckBox("Administrateur")
        self.admin.setToolTip("Lance seulement cette commande en root : Plasma demande ton mot de passe")
        self.admin.toggled.connect(self.update_preview)
        self.admin_forced = False
        copy = QPushButton("Copier la commande")
        copy.clicked.connect(lambda: QApplication.clipboard().setText(self.preview.text()))
        clear = QPushButton("Effacer")
        clear.clicked.connect(lambda: self.output.clear())
        for b in (self.run_btn, self.stop_btn, self.admin, copy):
            actions.addWidget(b)
        actions.addStretch(1)
        actions.addWidget(clear)
        ml.addLayout(actions)

        self.output = QPlainTextEdit(objectName="output")
        self.output.setReadOnly(True)
        self.output.setFont(mono)
        self.output.setMaximumBlockCount(20000)
        self.tabs = QTabWidget()
        self.tabs.addTab(self.output, "Sortie")
        self.view = None
        self.buffer = []
        self.report = None
        self.live = False
        ml.addWidget(self.tabs, 1)
        self.status = QLabel(objectName="muted")
        ml.addWidget(self.status)
        split.addWidget(main)
        split.setSizes([300, 880])
        self.set_enabled(False)

    def populate(self):
        self.tree.clear()
        for cat in self.categories:
            ci = QTreeWidgetItem([cat["name"]])
            ci.setFlags(Qt.ItemFlag.ItemIsEnabled)
            f = ci.font(0)
            f.setBold(True)
            ci.setFont(0, f)
            self.tree.addTopLevelItem(ci)
            for tool in cat["tools"]:
                runner, ok, why = self.runners.resolve(tool)
                ti = QTreeWidgetItem([tool["name"]])
                ti.setData(0, Qt.ItemDataRole.UserRole, tool)
                ti.setToolTip(0, why or f"{tool['description']} ({RUNNER_LABEL[runner]})")
                if not ok:
                    ti.setForeground(0, QBrush(QColor("#6B6B74")))
                ci.addChild(ti)
            ci.setExpanded(True)
        self.kali_state.setText(
            "Kali isolée : prête" if self.runners.kali else "Kali isolée : absente (labnoir-redteam init)"
        )

    def filter(self, text):
        text = text.strip().lower()
        for i in range(self.tree.topLevelItemCount()):
            cat = self.tree.topLevelItem(i)
            visible = 0
            for j in range(cat.childCount()):
                child = cat.child(j)
                tool = child.data(0, Qt.ItemDataRole.UserRole)
                hit = not text or text in tool["name"].lower() or text in tool["description"].lower()
                child.setHidden(not hit)
                visible += hit
            cat.setHidden(visible == 0)

    def refresh_runners(self):
        current = self.tool["id"] if self.tool else None
        self.runners.refresh()
        self.populate()
        self.filter(self.search.text())
        if current:
            for i in range(self.tree.topLevelItemCount()):
                cat = self.tree.topLevelItem(i)
                for j in range(cat.childCount()):
                    if cat.child(j).data(0, Qt.ItemDataRole.UserRole)["id"] == current:
                        self.tree.setCurrentItem(cat.child(j))

    def set_enabled(self, on):
        self.run_btn.setEnabled(on and self.proc is None)

    # [ARS-10]
    def select(self, item, _prev=None):
        tool = item.data(0, Qt.ItemDataRole.UserRole) if item else None
        if not tool:
            return
        self.tool = tool
        runner, ok, why = self.runners.resolve(tool)
        self.name.setText(tool["name"])
        self.desc.setText(tool["description"])
        self.badge.setText(RUNNER_LABEL[runner] + (" · terminal" if tool.get("terminal") else ""))
        self.badge.show()
        self.warning.setText(why)
        self.warning.setVisible(bool(why))
        self.admin.blockSignals(True)
        self.admin.setChecked(False)
        self.admin.blockSignals(False)
        self.admin_forced = False
        self.form.build(tool)
        self.set_view(tool)
        self.set_enabled(ok)
        self.update_preview()

    # [ARS-13]
    def set_view(self, tool):
        if self.view is not None:
            self.tabs.removeTab(1)
            self.view.deleteLater()
            self.view = None
        vue = tool.get("vue")
        if vue:
            self.view = vues.make_view(vue["type"])
            self.tabs.addTab(self.view, "Vue")
        self.tabs.setCurrentIndex(0)

    # [ARS-15]
    def sync_admin(self):
        needed = needs_admin(self.tool, self.form.values())
        if needed and not self.admin.isChecked():
            self.admin.blockSignals(True)
            self.admin.setChecked(True)
            self.admin.blockSignals(False)
            self.admin_forced = True
        elif not needed and self.admin_forced:
            self.admin.blockSignals(True)
            self.admin.setChecked(False)
            self.admin.blockSignals(False)
            self.admin_forced = False
        self.admin.setEnabled(not needed)

    def update_preview(self, *_):
        if not self.tool:
            return
        self.sync_admin()
        runner, _, _ = self.runners.resolve(self.tool)
        try:
            cmd = full_command(self.tool, runner, build_args(self.tool, self.form.values()),
                               admin=self.admin.isChecked())
            self.preview.setText(shlex.join(cmd))
            self.preview.setProperty("invalid", False)
        except ValueError as e:
            self.preview.setText(str(e))
            self.preview.setProperty("invalid", True)
        self.preview.style().unpolish(self.preview)
        self.preview.style().polish(self.preview)

    # [ARS-11]
    def run(self):
        if not self.tool or self.proc:
            return
        runner, ok, why = self.runners.resolve(self.tool)
        if not ok:
            self.status.setText(why)
            return
        vue = self.tool.get("vue") or {}
        self.report = vues.scratch(vue["fichier"]) if vue.get("fichier") else None
        try:
            admin = self.admin.isChecked()
            if admin and runner == "host" and not self.tool.get("terminal") and not shutil.which("pkexec"):
                raise ValueError("pkexec absent : sudo apt install pkexec")
            cmd = full_command(self.tool, runner, build_args(self.tool, self.form.values()), self.report, admin)
        except ValueError as e:
            self.status.setText(str(e))
            return
        self.buffer = []
        self.running_tool = self.tool
        self.running_admin = admin and runner == "host" and not self.tool.get("terminal")
        self.output.appendPlainText(f"$ {shlex.join(cmd)}")
        if self.tool.get("terminal"):
            term = terminal_command(cmd)
            if not term:
                self.status.setText("Aucun terminal trouvé (konsole)")
                return
            QProcess.startDetached(term[0], term[1:])
            self.status.setText("Lancé dans un terminal.")
            return
        self.output.appendPlainText("")
        self.proc = QProcess(self)
        self.proc.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        self.proc.readyReadStandardOutput.connect(self.read_output)
        self.proc.finished.connect(self.finished)
        self.proc.errorOccurred.connect(self.failed)
        self.proc.start(cmd[0], cmd[1:])
        self.live = bool(vue.get("direct")) and self.view is not None
        if self.live:
            self.view.reset()
            self.tabs.setCurrentIndex(1)
        self.run_btn.setEnabled(False)
        self.stop_btn.setEnabled(True)
        self.status.setText("En cours… (mot de passe demandé par Plasma)" if self.running_admin else "En cours…")

    def read_output(self):
        data = bytes(self.proc.readAllStandardOutput()).decode("utf-8", "replace")
        self.buffer.append(data)
        if self.live and self.view is not None and self.running_tool is self.tool:
            self.view.feed(data)
        self.output.moveCursor(QTextCursor.MoveOperation.End)
        self.output.insertPlainText(data)
        self.output.moveCursor(QTextCursor.MoveOperation.End)

    def finished(self, code, status):
        crashed = status == QProcess.ExitStatus.CrashExit
        self.output.appendPlainText(f"[terminé : {'interrompu' if crashed else f'code {code}'}]\n")
        self.status.setText("Interrompu." if crashed else f"Terminé (code {code}).")
        self.proc = None
        self.show_view()
        self.stop_btn.setEnabled(False)
        self.set_enabled(self.tool is not None and self.runners.resolve(self.tool)[1])

    # [ARS-14]
    def show_view(self):
        vue = (self.running_tool or {}).get("vue")
        if not vue or self.view is None or self.running_tool is not self.tool:
            return
        try:
            err = vues.render(vue["type"], self.view, "".join(self.buffer), self.report)
        except (OSError, ValueError, vues.ET.ParseError) as e:
            err = f"rapport illisible : {e}"
        if err:
            self.status.setText(self.status.text() + " " + err)
        else:
            self.tabs.setCurrentIndex(1)

    def failed(self, err):
        if err == QProcess.ProcessError.FailedToStart:
            self.output.appendPlainText("[impossible de lancer la commande]\n")
            self.proc = None
            self.stop_btn.setEnabled(False)
            self.set_enabled(True)

    def stop(self):
        if not self.proc:
            return
        if self.running_admin:
            pid = self.proc.processId()
            if pid:
                QProcess.startDetached("pkexec", ["kill", "-TERM", str(pid)])
                self.status.setText("Arrêt demandé (mot de passe administrateur).")
            return
        self.proc.terminate()
        QTimer.singleShot(3000, lambda: self.proc and self.proc.kill())

    def closeEvent(self, e):
        if self.proc:
            self.proc.kill()
            self.proc.waitForFinished(2000)
        super().closeEvent(e)


# [ARS-12]
def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Arsenal")
    app.setDesktopFileName("labnoir-arsenal")
    app.setStyle("Fusion")
    if STYLE.exists():
        vues.ACCENT = theme_accent()
        app.setStyleSheet(STYLE.read_text(encoding="utf-8").replace("#FF1654", vues.ACCENT))
    app.setFont(QFont("Inter", 10))
    w = Arsenal()
    w.show()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
