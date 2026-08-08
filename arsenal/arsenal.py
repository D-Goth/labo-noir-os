#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# 🖤 Arsenal - Lanceur d'outils du Lab'O Noir

import sys
import json
import subprocess
import os
from PyQt5.QtWidgets import *
from PyQt5.QtCore import *
from PyQt5.QtGui import *

class ArsenalLauncher(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Arsenal - Lab'O Noir")
        self.setGeometry(100, 100, 1100, 750)
        
        base_dir = os.path.dirname(os.path.abspath(__file__))
        db_path = os.path.join(base_dir, "tools_db.json")
        with open(db_path, "r") as f:
            self.tools_data = json.load(f)
        
        self.current_tool = None
        self.inputs = {}
        self.params_widgets = []  # pour garder trace des widgets
        self.initUI()
        self.load_styles()
    
    def initUI(self):
        central = QWidget()
        self.setCentralWidget(central)
        layout = QHBoxLayout(central)
        layout.setSpacing(20)
        layout.setContentsMargins(20, 20, 20, 20)
        
        left_panel = QWidget()
        left_panel.setFixedWidth(300)
        left_layout = QVBoxLayout(left_panel)
        left_layout.setSpacing(10)
        
        logo_label = QLabel()
        base_dir = os.path.dirname(os.path.abspath(__file__))
        icon_path = os.path.join(base_dir, "assets", "icon.png")
        if os.path.exists(icon_path):
            pixmap = QPixmap(icon_path).scaled(64, 64, Qt.KeepAspectRatio, Qt.SmoothTransformation)
            logo_label.setPixmap(pixmap)
        logo_label.setAlignment(Qt.AlignCenter)
        left_layout.addWidget(logo_label)
        
        title = QLabel("ARSENAL")
        title.setAlignment(Qt.AlignCenter)
        title.setStyleSheet("font-size: 24px; font-weight: bold; color: #FF1654;")
        left_layout.addWidget(title)
        
        self.tool_list = QListWidget()
        self.tool_list.itemClicked.connect(self.on_tool_selected)
        left_layout.addWidget(self.tool_list)
        
        right_panel = QWidget()
        right_layout = QVBoxLayout(right_panel)
        right_layout.setSpacing(10)
        
        self.desc_label = QLabel("Sélectionnez un outil")
        self.desc_label.setWordWrap(True)
        self.desc_label.setStyleSheet("color: #C0C0C0; padding: 10px; background: #1A1A1A; border-radius: 5px;")
        right_layout.addWidget(self.desc_label)
        
        self.params_widget = QWidget()
        self.params_layout = QFormLayout(self.params_widget)
        self.params_layout.setSpacing(8)
        right_layout.addWidget(self.params_widget)
        
        self.run_btn = QPushButton("▶ EXÉCUTER")
        self.run_btn.setStyleSheet("""
            QPushButton {
                background-color: #FF1654;
                color: #FFFFFF;
                font-weight: bold;
                padding: 12px;
                border-radius: 5px;
                font-size: 14px;
            }
            QPushButton:hover {
                background-color: #CC1144;
            }
        """)
        self.run_btn.clicked.connect(self.execute_tool)
        right_layout.addWidget(self.run_btn)
        
        self.output_area = QTextEdit()
        self.output_area.setFont(QFont("Monospace", 10))
        self.output_area.setStyleSheet("""
            QTextEdit {
                background-color: #0A0A0A;
                color: #FFFFFF;
                border: 1px solid #FF1654;
                border-radius: 5px;
                padding: 10px;
                font-family: 'JetBrains Mono', monospace;
            }
        """)
        right_layout.addWidget(self.output_area)
        
        layout.addWidget(left_panel)
        layout.addWidget(right_panel)
        
        self.populate_tools()
    
    def populate_tools(self):
        for cat in self.tools_data["categories"]:
            item = QListWidgetItem(f"📁 {cat['name']}")
            item.setFlags(item.flags() & ~Qt.ItemIsSelectable)
            self.tool_list.addItem(item)
            for tool in cat["tools"]:
                t_item = QListWidgetItem(f"   {tool['name']}")
                t_item.setData(Qt.UserRole, tool)
                self.tool_list.addItem(t_item)
    
    def on_tool_selected(self, item):
        self.clear_layout(self.params_layout)
        tool = item.data(Qt.UserRole)
        if not tool:
            return
        self.current_tool = tool
        self.desc_label.setText(f"{tool['name']} — {tool['description']}")
        
        self.inputs = {}
        self.params_widgets = []
        for param in tool["params"]:
            if param["type"] == "text":
                field = QLineEdit()
                field.setPlaceholderText(param.get("placeholder", ""))
                if "default" in param:
                    field.setText(param["default"])
                self.params_layout.addRow(QLabel(param["label"]), field)
                self.inputs[param["id"]] = field
                self.params_widgets.append(field)
            elif param["type"] == "dropdown":
                combo = QComboBox()
                combo.addItems(param["options"])
                default = param.get("default")
                if default and default in param["options"]:
                    combo.setCurrentText(default)
                self.params_layout.addRow(QLabel(param["label"]), combo)
                self.inputs[param["id"]] = combo
                self.params_widgets.append(combo)
            elif param["type"] == "checkbox":
                check = QCheckBox(param["label"])
                check.setStyleSheet("color: #C0C0C0;")
                if param.get("default", False):
                    check.setChecked(True)
                self.params_layout.addRow("", check)
                self.inputs[param["id"]] = check
                self.params_widgets.append(check)
    
    def clear_layout(self, layout):
        while layout.count():
            child = layout.takeAt(0)
            if child.widget():
                child.widget().deleteLater()
        self.inputs = {}
        self.params_widgets = []
    
    def is_widget_valid(self, widget):
        """Vérifie si un widget Qt est encore valide."""
        try:
            # Tester si le widget existe encore
            widget.objectName()
            return True
        except RuntimeError:
            return False
    
    def execute_tool(self):
        if not self.current_tool:
            return
        
        # Vérifier que tous les widgets sont encore valides
        for widget in self.params_widgets:
            if not self.is_widget_valid(widget):
                self.output_area.append("[ERREUR] Les paramètres ont été modifiés. Veuillez resélectionner l'outil.")
                return
        
        tool = self.current_tool
        command = tool["command"]
        args = []
        
        for param in tool["params"]:
            widget = self.inputs.get(param["id"])
            if not widget or not self.is_widget_valid(widget):
                self.output_area.append(f"[ERREUR] Paramètre '{param['label']}' invalide.")
                return
            
            if param["type"] == "text":
                val = widget.text().strip()
                if val:
                    args.append(val)
            elif param["type"] == "dropdown":
                val = widget.currentText()
                if " (" in val:
                    val = val.split(" ")[0]
                args.append(val)
            elif param["type"] == "checkbox":
                if widget.isChecked():
                    args.append(param.get("option", ""))
        
        args = [a for a in args if a and a != ""]
        full_cmd = [command] + args
        
        self.output_area.append(f"\n$ {' '.join(full_cmd)}\n")
        self.output_area.append("-" * 60)
        
        try:
            result = subprocess.run(
                full_cmd,
                capture_output=True,
                text=True,
                timeout=300,
                check=False
            )
            self.output_area.append(result.stdout)
            if result.stderr:
                self.output_area.append(f"[STDERR]\n{result.stderr}")
            if result.returncode != 0:
                self.output_area.append(f"[CODE] Retour : {result.returncode}")
        except subprocess.TimeoutExpired:
            self.output_area.append("[ERREUR] Temps d'exécution dépassé (5 min)")
        except Exception as e:
            self.output_area.append(f"[ERREUR] {str(e)}")
        
        self.output_area.verticalScrollBar().setValue(
            self.output_area.verticalScrollBar().maximum()
        )
    
    def load_styles(self):
        base_dir = os.path.dirname(os.path.abspath(__file__))
        style_path = os.path.join(base_dir, "style.qss")
        if os.path.exists(style_path):
            with open(style_path, "r") as f:
                self.setStyleSheet(f.read())

if __name__ == "__main__":
    app = QApplication(sys.argv)
    app.setStyle("Fusion")
    window = ArsenalLauncher()
    window.show()
    sys.exit(app.exec_())
