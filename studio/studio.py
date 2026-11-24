#!/usr/bin/env python3
import os
import shutil
import sys
from contextlib import redirect_stdout
from dataclasses import replace
from importlib.machinery import SourceFileLoader
from importlib.util import module_from_spec, spec_from_loader
from io import StringIO
from pathlib import Path

from PyQt6.QtCore import QPointF, QProcess, QRectF, Qt, QTimer
from PyQt6.QtGui import QBrush, QColor, QFont, QIcon, QLinearGradient, QPainter, QPainterPath, QPen
from PyQt6.QtWidgets import (
    QApplication, QButtonGroup, QCheckBox, QColorDialog, QFileDialog, QFormLayout, QFrame,
    QGridLayout, QHBoxLayout, QLabel, QLineEdit, QListWidget, QListWidgetItem, QMainWindow,
    QMessageBox, QPushButton, QRadioButton, QSlider, QVBoxLayout, QWidget,
)

# [STU-01]
HERE = Path(__file__).resolve().parent
ENGINE_PATHS = [HERE.parent / "bin" / "labnoir-theme", Path("/opt/labnoir/bin/labnoir-theme")]
ICON = Path("/usr/share/icons/hicolor/256x256/apps/labonoir.png")
SWATCHES = ["#FF1654", "#FF7A1A", "#F5B33F", "#2BD67B", "#3CCFCF", "#4F8CFF", "#B57BFF", "#E8E8EC"]
BUTTON_LABELS = {
    "classique": "Classique : réduire, agrandir, fermer à droite",
    "elementary": "elementary : fermer à gauche, agrandir à droite",
    "macos": "macOS : tout à gauche",
}


def load_engine():
    for p in ENGINE_PATHS:
        if p.is_file():
            loader = SourceFileLoader("labnoir_theme", str(p))
            module = module_from_spec(spec_from_loader("labnoir_theme", loader))
            loader.exec_module(module)
            return module
    raise SystemExit("labnoir-theme introuvable : sudo ./install.sh --only base")


E = load_engine()


# [STU-02]
class Preview(QWidget):
    def __init__(self):
        super().__init__()
        self.theme = None
        self.setMinimumSize(420, 300)

    def set_theme(self, t):
        self.theme = t
        self.update()

    def paintEvent(self, _):
        t = self.theme
        if not t:
            return
        pal = E.PALETTES[t.mode]
        p = QPainter(self)
        p.setRenderHint(QPainter.RenderHint.Antialiasing)
        w, h = self.width(), self.height()
        g = QLinearGradient(0, 0, w, h)
        g.setColorAt(0, QColor(E.mix(t.accent, "#000000", 0.75)))
        g.setColorAt(1, QColor("#050507"))
        p.fillRect(self.rect(), g)

        bar = QRectF(0, 0, w, 22)
        glass = QColor(pal["window"])
        glass.setAlpha(150 + (15 - t.blur) * 5)
        p.fillRect(bar, glass)
        p.setPen(QColor(pal["fg"]))
        f = QFont()
        f.setPointSize(8)
        p.setFont(f)
        p.drawText(bar, Qt.AlignmentFlag.AlignCenter, "mar. 24 nov. 13:14")

        win = QRectF(w * 0.08, 40, w * 0.62, h * 0.62)
        self.window(p, win, t, pal)

        term = QRectF(w * 0.46, h * 0.38, w * 0.48, h * 0.4)
        self.terminal(p, term, t)

        dock = QRectF(w / 2 - 90, h - 34, 180, 26)
        dc = QColor(pal["window"])
        dc.setAlpha(170)
        path = QPainterPath()
        path.addRoundedRect(dock, 10, 10)
        p.fillPath(path, dc)
        for i in range(6):
            c = QColor(t.accent if i == 4 else pal["inactive"])
            p.setBrush(c)
            p.setPen(Qt.PenStyle.NoPen)
            p.drawRoundedRect(QRectF(dock.x() + 12 + i * 27, dock.y() + 5, 16, 16), 4, 4)

    def window(self, p, r, t, pal):
        path = QPainterPath()
        path.addRoundedRect(r, 9, 9)
        win = QColor(pal["window"])
        if t.glass_windows:
            win.setAlpha(int(255 * t.window_opacity))
        p.fillPath(path, win)
        title = QRectF(r.x(), r.y(), r.width(), 26)
        p.save()
        p.setClipPath(path)
        p.fillRect(title, QColor(pal["header"]))
        p.restore()
        p.setPen(QColor(pal["fg"]))
        f = QFont()
        f.setPointSize(8)
        f.setBold(True)
        p.setFont(f)
        p.drawText(title, Qt.AlignmentFlag.AlignCenter, "Dolphin")
        left, right = E.BUTTONS[t.buttons]
        colors = {"X": t.accent, "I": pal["inactive"], "A": pal["inactive"], "M": pal["inactive"]}
        for i, b in enumerate(left):
            if b == "M":
                continue
            p.setBrush(QColor(colors[b]))
            p.setPen(Qt.PenStyle.NoPen)
            p.drawEllipse(QPointF(r.x() + 14 + i * 16, r.y() + 13), 5, 5)
        for i, b in enumerate(reversed(right)):
            p.setBrush(QColor(colors[b]))
            p.setPen(Qt.PenStyle.NoPen)
            p.drawEllipse(QPointF(r.right() - 14 - i * 16, r.y() + 13), 5, 5)
        body = r.adjusted(10, 34, -10, -10)
        rows = ["Documents", "Images", "Musique", "Projets", "Téléchargements"]
        f.setBold(False)
        p.setFont(f)
        for i, name in enumerate(rows):
            rr = QRectF(body.x(), body.y() + i * 22, body.width(), 20)
            if i == 3:
                p.setBrush(QColor(t.accent))
                p.setPen(Qt.PenStyle.NoPen)
                p.drawRoundedRect(rr, 5, 5)
                sel = "#000000" if E.luminance(t.accent) > 0.55 else "#FFFFFF"
                p.setPen(QColor(sel))
            else:
                p.setPen(QColor(pal["fg"]))
            p.drawText(rr.adjusted(8, 0, 0, 0), Qt.AlignmentFlag.AlignVCenter, name)

    def terminal(self, p, r, t):
        dark = t.mode == "sombre"
        bg = QColor("#0B0B0D" if dark else "#FBFBFC")
        bg.setAlpha(int(255 * t.terminal_opacity))
        path = QPainterPath()
        path.addRoundedRect(r, 9, 9)
        p.fillPath(path, bg)
        p.setBrush(Qt.BrushStyle.NoBrush)
        p.setPen(QPen(QColor(E.mix(t.accent, "#000000", 0.3)), 1))
        p.drawPath(path)
        f = QFont("JetBrains Mono")
        f.setStyleHint(QFont.StyleHint.Monospace)
        f.setPointSize(8)
        p.setFont(f)
        lines = [("moi@labonoir", t.accent), (":~$ labnoir-theme", "#E8E8EC" if dark else "#1C1C1F"),
                 ("  ✓ couleurs", "#2BD67B"), ("  ✓ verre dépoli", "#2BD67B")]
        y = r.y() + 20
        p.setPen(QColor(lines[0][1]))
        p.drawText(QPointF(r.x() + 10, y), lines[0][0])
        p.setPen(QColor(lines[1][1]))
        p.drawText(QPointF(r.x() + 10 + p.fontMetrics().horizontalAdvance(lines[0][0]), y), lines[1][0])
        for i, (txt, col) in enumerate(lines[2:]):
            p.setPen(QColor(col))
            p.drawText(QPointF(r.x() + 10, y + 18 * (i + 1)), txt)


# [STU-03]
class Studio(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Studio Lab'O Noir")
        self.resize(1120, 720)
        if ICON.exists():
            self.setWindowIcon(QIcon(str(ICON)))
        self.theme = None
        self.loading = False
        self.live = QTimer(self, singleShot=True, interval=700)
        self.live.timeout.connect(self.apply_live)
        self.build()
        self.refresh_list(E.current_theme() or "labonoir")

    def build(self):
        root = QWidget()
        self.setCentralWidget(root)
        outer = QHBoxLayout(root)
        outer.setContentsMargins(0, 0, 0, 0)
        outer.setSpacing(0)

        side = QFrame(objectName="side")
        side.setFixedWidth(250)
        sl = QVBoxLayout(side)
        sl.setContentsMargins(18, 20, 18, 18)
        sl.addWidget(QLabel("Studio", objectName="brand"))
        self.list = QListWidget()
        self.list.currentItemChanged.connect(self.select)
        sl.addWidget(self.list, 1)
        grid = QGridLayout()
        self.btn_new = QPushButton("Dupliquer")
        self.btn_new.clicked.connect(self.duplicate)
        self.btn_del = QPushButton("Supprimer")
        self.btn_del.clicked.connect(self.delete)
        self.btn_imp = QPushButton("Importer…")
        self.btn_imp.clicked.connect(self.import_theme)
        self.btn_exp = QPushButton("Exporter…")
        self.btn_exp.clicked.connect(self.export_theme)
        grid.addWidget(self.btn_new, 0, 0)
        grid.addWidget(self.btn_del, 0, 1)
        grid.addWidget(self.btn_imp, 1, 0)
        grid.addWidget(self.btn_exp, 1, 1)
        sl.addLayout(grid)
        outer.addWidget(side)

        main = QFrame(objectName="main")
        ml = QHBoxLayout(main)
        ml.setContentsMargins(28, 24, 28, 24)
        ml.setSpacing(28)
        form_box = QVBoxLayout()
        form = QFormLayout()
        form.setVerticalSpacing(14)
        form.setHorizontalSpacing(18)

        self.name = QLineEdit()
        self.name.textEdited.connect(self.changed)
        form.addRow("Nom", self.name)

        mode = QHBoxLayout()
        self.mode_group = QButtonGroup(self)
        for i, (val, label) in enumerate((("sombre", "Sombre"), ("clair", "Clair"))):
            rb = QRadioButton(label)
            rb.setProperty("value", val)
            rb.setMinimumWidth(rb.sizeHint().width() + 12)
            self.mode_group.addButton(rb, i)
            mode.addWidget(rb)
        mode.addStretch(1)
        self.mode_group.buttonToggled.connect(lambda *_: self.changed())
        form.addRow("Mode", mode)

        acc = QVBoxLayout()
        sw = QHBoxLayout()
        sw.setSpacing(8)
        self.swatches = []
        for c in SWATCHES:
            b = QPushButton(objectName="swatch")
            b.setFixedSize(26, 26)
            b.setStyleSheet(f"background:{c}; border-radius:13px; border:2px solid transparent;")
            b.setToolTip(c)
            b.clicked.connect(lambda _, col=c: self.set_accent(col))
            sw.addWidget(b)
            self.swatches.append((c, b))
        pick = QPushButton("Pipette…")
        pick.clicked.connect(self.pick_color)
        sw.addWidget(pick)
        sw.addStretch(1)
        acc.addLayout(sw)
        self.hex = QLineEdit(maxLength=7)
        self.hex.setFixedWidth(110)
        self.hex.textEdited.connect(self.hex_edited)
        acc.addWidget(self.hex)
        form.addRow("Accent", acc)

        self.blur = self.slider(1, 15)
        form.addRow("Flou du verre", self.labeled(self.blur, "blur"))
        self.noise = self.slider(0, 14)
        form.addRow("Grain", self.labeled(self.noise, "noise"))
        self.opacity = self.slider(50, 100)
        form.addRow("Opacité du terminal", self.labeled(self.opacity, "opacity", "%"))
        self.orbit = self.slider(0, 255)
        form.addRow("Fond d'Orbit Pixel", self.labeled(self.orbit, "orbit"))
        self.glass_win = QCheckBox("Fenêtres en verre dépoli (Kvantum)")
        self.glass_win.toggled.connect(self.changed)
        form.addRow("", self.glass_win)
        self.win_opacity = self.slider(60, 100)
        form.addRow("Opacité des fenêtres", self.labeled(self.win_opacity, "win_opacity", "%"))

        btns = QVBoxLayout()
        self.btn_group = QButtonGroup(self)
        for i, (val, label) in enumerate(BUTTON_LABELS.items()):
            rb = QRadioButton(label)
            rb.setProperty("value", val)
            self.btn_group.addButton(rb, i)
            btns.addWidget(rb)
        self.btn_group.buttonToggled.connect(lambda *_: self.changed())
        form.addRow("Boutons des fenêtres", btns)

        wall = QHBoxLayout()
        self.wall = QLineEdit(placeholderText="aucun : le fond actuel est gardé")
        self.wall.textEdited.connect(self.changed)
        wb = QPushButton("Choisir…")
        wb.clicked.connect(self.pick_wallpaper)
        wall.addWidget(self.wall, 1)
        wall.addWidget(wb)
        form.addRow("Fond d'écran", wall)
        self.with_wall = QCheckBox("Appliquer aussi ce fond d'écran")
        form.addRow("", self.with_wall)

        form_box.addLayout(form)
        form_box.addStretch(1)
        self.live_box = QCheckBox("Aperçu en direct sur le bureau")
        form_box.addWidget(self.live_box)
        actions = QHBoxLayout()
        self.btn_apply = QPushButton("Appliquer", objectName="accent")
        self.btn_apply.clicked.connect(lambda: self.apply_theme(save_first=False))
        self.btn_save = QPushButton("Enregistrer")
        self.btn_save.clicked.connect(self.save_theme)
        self.btn_both = QPushButton("Enregistrer et appliquer")
        self.btn_both.clicked.connect(lambda: self.apply_theme(save_first=True))
        for b in (self.btn_apply, self.btn_save, self.btn_both):
            actions.addWidget(b)
        actions.addStretch(1)
        about = QPushButton("À propos")
        about.clicked.connect(lambda: QProcess.startDetached("labnoir-about", []))
        actions.addWidget(about)
        form_box.addLayout(actions)
        self.status = QLabel(objectName="muted")
        self.status.setWordWrap(True)
        form_box.addWidget(self.status)
        ml.addLayout(form_box, 3)

        right = QVBoxLayout()
        right.addWidget(QLabel("Aperçu", objectName="section"))
        self.preview = Preview()
        right.addWidget(self.preview, 1)
        ml.addLayout(right, 2)
        outer.addWidget(main, 1)

    def slider(self, lo, hi):
        s = QSlider(Qt.Orientation.Horizontal)
        s.setRange(lo, hi)
        s.valueChanged.connect(self.changed)
        return s

    def labeled(self, slider, key, unit=""):
        box = QHBoxLayout()
        lab = QLabel(objectName="value")
        lab.setFixedWidth(46)
        slider.valueChanged.connect(lambda v: lab.setText(f"{v}{unit}"))
        box.addWidget(slider, 1)
        box.addWidget(lab)
        setattr(self, f"{key}_label", lab)
        return box

    # [STU-04]
    def refresh_list(self, select=None):
        self.list.blockSignals(True)
        self.list.clear()
        cur = E.current_theme()
        for ident in E.all_themes():
            t = E.load(ident)
            it = QListWidgetItem(("● " if ident == cur else "   ") + t.name)
            it.setData(Qt.ItemDataRole.UserRole, ident)
            it.setForeground(QBrush(QColor(t.accent)) if ident == cur else QBrush(QColor("#E8E8EC")))
            it.setToolTip(f"{ident} · {t.mode} · {t.accent}" + (" · personnel" if E.is_user_theme(ident) else ""))
            self.list.addItem(it)
            if ident == select:
                self.list.setCurrentItem(it)
        self.list.blockSignals(False)
        if self.list.currentItem() is None and self.list.count():
            self.list.setCurrentRow(0)
        self.select(self.list.currentItem())

    def select(self, item, _prev=None):
        if not item:
            return
        self.theme = E.load(item.data(Qt.ItemDataRole.UserRole))
        self.fill()
        self.btn_del.setEnabled(E.is_user_theme(self.theme.ident))

    def fill(self):
        t = self.theme
        self.loading = True
        self.name.setText(t.name)
        for b in self.mode_group.buttons():
            b.setChecked(b.property("value") == t.mode)
        self.hex.setText(t.accent)
        self.blur.setValue(t.blur)
        self.noise.setValue(t.noise)
        self.opacity.setValue(round(t.terminal_opacity * 100))
        self.orbit.setValue(t.orbit_alpha)
        self.glass_win.setChecked(t.glass_windows)
        self.win_opacity.setValue(round(t.window_opacity * 100))
        self.win_opacity.setEnabled(t.glass_windows)
        for b in self.btn_group.buttons():
            b.setChecked(b.property("value") == t.buttons)
        self.wall.setText(str(t.wallpaper) if t.wallpaper else "")
        for lab, s, unit in ((self.blur_label, self.blur, ""), (self.noise_label, self.noise, ""),
                             (self.opacity_label, self.opacity, "%"), (self.orbit_label, self.orbit, ""),
                             (self.win_opacity_label, self.win_opacity, "%")):
            lab.setText(f"{s.value()}{unit}")
        self.loading = False
        self.mark_swatch()
        self.preview.set_theme(t)

    # [STU-05]
    def collect(self):
        t = self.theme
        mode = next((b.property("value") for b in self.mode_group.buttons() if b.isChecked()), t.mode)
        buttons = next((b.property("value") for b in self.btn_group.buttons() if b.isChecked()), t.buttons)
        accent = self.hex.text().strip().upper()
        if not E.HEX.match(accent):
            accent = t.accent
        wall = self.wall.text().strip()
        return replace(
            t, name=self.name.text().strip() or t.name, mode=mode, accent=accent, blur=self.blur.value(),
            noise=self.noise.value(), terminal_opacity=self.opacity.value() / 100, buttons=buttons,
            wallpaper=Path(wall) if wall and Path(os.path.expanduser(wall)).is_file() else None,
            orbit_alpha=self.orbit.value(), glass_windows=self.glass_win.isChecked(),
            window_opacity=self.win_opacity.value() / 100,
        )

    def changed(self, *_):
        if self.loading or not self.theme:
            return
        self.theme = self.collect()
        self.win_opacity.setEnabled(self.theme.glass_windows)
        self.mark_swatch()
        self.preview.set_theme(self.theme)
        if self.live_box.isChecked():
            self.live.start()

    def set_accent(self, col):
        self.hex.setText(col)
        self.changed()

    def hex_edited(self, text):
        if E.HEX.match(text.strip()):
            self.changed()

    def pick_color(self):
        c = QColorDialog.getColor(QColor(self.hex.text()), self, "Couleur d'accent")
        if c.isValid():
            self.set_accent(c.name().upper())

    def mark_swatch(self):
        for col, b in self.swatches:
            border = "#FFFFFF" if self.theme and col.upper() == self.theme.accent.upper() else "transparent"
            b.setStyleSheet(f"background:{col}; border-radius:13px; border:2px solid {border};")

    def pick_wallpaper(self):
        path, _ = QFileDialog.getOpenFileName(self, "Fond d'écran", str(Path.home()),
                                              "Images (*.jpg *.jpeg *.png *.webp)")
        if path:
            self.wall.setText(path)
            self.with_wall.setChecked(True)
            self.changed()

    # [STU-06]
    def save_theme(self):
        t = self.collect()
        if not E.is_user_theme(t.ident) or t.ident != E.slug(t.name):
            ident = E.slug(t.name)
            if not E.is_user_theme(ident) and E.find_theme(ident):
                ident = ident + "-perso"
            t = replace(t, ident=ident)
        path = E.save(t)
        self.theme = t
        self.status.setText(f"Enregistré : {path}")
        self.refresh_list(t.ident)
        return t

    def apply_theme(self, save_first):
        t = self.save_theme() if save_first else self.collect()
        out = self.run_engine(t, self.with_wall.isChecked())
        self.status.setText(out)
        if save_first:
            self.refresh_list(t.ident)

    def apply_live(self):
        self.run_engine(self.collect(), False)

    def run_engine(self, t, with_wall):
        buf = StringIO()
        try:
            with redirect_stdout(buf):
                E.apply(t, with_wall)
        except Exception as e:
            return f"Échec : {e}"
        lines = [l.strip() for l in buf.getvalue().splitlines()[1:] if l.strip()]
        return "Appliqué. " + " · ".join(lines)

    def duplicate(self):
        t = self.collect()
        name = t.name + " (copie)"
        self.theme = replace(t, name=name, ident=E.slug(name))
        E.save(self.theme)
        self.refresh_list(self.theme.ident)
        self.name.setFocus()
        self.name.selectAll()

    def delete(self):
        t = self.theme
        if not t or not E.is_user_theme(t.ident):
            return
        if QMessageBox.question(self, "Supprimer", f"Supprimer le thème « {t.name} » ?") != \
                QMessageBox.StandardButton.Yes:
            return
        (E.USER_THEMES / f"{t.ident}.toml").unlink(missing_ok=True)
        self.refresh_list(E.current_theme() or "labonoir")

    def import_theme(self):
        path, _ = QFileDialog.getOpenFileName(self, "Importer un thème", str(Path.home()), "Thème (*.toml)")
        if not path:
            return
        dest = E.USER_THEMES / Path(path).name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy(path, dest)
        try:
            E.load(dest.stem)
        except SystemExit as e:
            dest.unlink(missing_ok=True)
            self.status.setText(f"Thème refusé : {e}")
            return
        self.refresh_list(dest.stem)
        self.status.setText(f"Importé : {dest.stem}")

    def export_theme(self):
        t = self.collect()
        path, _ = QFileDialog.getSaveFileName(self, "Exporter le thème", str(Path.home() / f"{t.ident}.toml"),
                                              "Thème (*.toml)")
        if path:
            Path(path).write_text(E.dump(replace(t, wallpaper=None)), encoding="utf-8")
            self.status.setText(f"Exporté : {path}")


# [STU-07]
def main():
    app = QApplication(sys.argv)
    app.setApplicationName("Studio Lab'O Noir")
    app.setDesktopFileName("labnoir-studio")
    app.setStyle("Fusion")
    qss = HERE / "style.qss"
    if qss.exists():
        try:
            accent = E.load(E.current_theme() or "labonoir").accent
        except SystemExit:
            accent = "#FF1654"
        app.setStyleSheet(qss.read_text(encoding="utf-8").replace("#FF1654", accent))
    app.setFont(QFont("Inter", 10))
    w = Studio()
    w.show()
    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
