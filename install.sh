#!/bin/bash
# ⚙️ Lab'O Noir OS - Installateur principal
# Debian 12 + KDE Plasma + Arsenal

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARSENAL_DIR="/opt/labnoir/arsenal"

echo -e "\e[31m██████╗  ██████╗ ██╗  ██╗\e[0m"
echo -e "\e[31m██╔══██╗██╔═══██╗██║ ██╔╝\e[0m"
echo -e "\e[31m██████╔╝██║   ██║█████╔╝\e[0m"
echo -e "\e[31m██╔══██╗██║   ██║██╔═██╗\e[0m"
echo -e "\e[31m██████╔╝╚██████╔╝██║  ██╗\e[0m"
echo -e "\e[31m╚═════╝  ╚═════╝ ╚═╝  ╚═╝\e[0m"
echo -e "\e[31m    LAB'O NOIR OS — INSTALLATION    \e[0m"

if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31mCe script doit être exécuté en root (sudo).\e[0m"
   exit 1
fi

echo -e "\e[32m>> Mise à jour du système...\e[0m"
apt update && apt upgrade -y

if ! dpkg -l | grep -q plasma-desktop; then
    echo -e "\e[32m>> Installation de KDE Plasma...\e[0m"
    apt install -y plasma-desktop sddm konsole dolphin \
                   plasma-workspace plasma-themes breeze-gtk-theme \
                   kvantum papirus-icon-theme
fi

echo -e "\e[32m>> Installation des outils de dev...\e[0m"
apt install -y git curl wget htop neofetch build-essential \
               python3 python3-pip python3-pyqt5 python3-pyqt5.qtsvg \
               flatpak snapd network-manager

echo -e "\e[32m>> Installation des outils Kali (top 10)...\e[0m"
apt install -y kali-tools-top10 || echo -e "\e[33mKali tools non disponibles, passe.\e[0m"

echo -e "\e[32m>> Déploiement de l'Arsenal dans /opt/labnoir/...\e[0m"
mkdir -p "$ARSENAL_DIR"
cp -r "$REPO_DIR/arsenal/"* "$ARSENAL_DIR/"
cp -r "$REPO_DIR/assets/"* "$ARSENAL_DIR/assets/" 2>/dev/null || true
chmod +x "$ARSENAL_DIR/arsenal.py"

echo -e "\e[32m>> Installation des dépendances Python...\e[0m"
pip3 install -r "$ARSENAL_DIR/requirements.txt" --break-system-packages || pip3 install -r "$ARSENAL_DIR/requirements.txt"

echo -e "\e[32m>> Création du raccourci dans le menu KDE...\e[0m"
cat > /usr/share/applications/arsenal.desktop << EOF
[Desktop Entry]
Name=Arsenal - Lab'O Noir
Comment=Lanceur d'outils cyber
Exec=python3 /opt/labnoir/arsenal/arsenal.py
Icon=/opt/labnoir/arsenal/assets/icon.png
Terminal=false
Type=Application
Categories=System;Utility;
EOF

echo "alias arsenal='python3 /opt/labnoir/arsenal/arsenal.py'" >> /etc/bash.bashrc

if [ -n "$SUDO_USER" ]; then
    HOME_USER=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    cp "$REPO_DIR/dotfiles/.bashrc" "$HOME_USER/.bashrc" 2>/dev/null || true
    cp "$REPO_DIR/dotfiles/.zshrc" "$HOME_USER/.zshrc" 2>/dev/null || true
fi

echo -e "\e[32m>> Installation terminée !\e[0m"
echo -e "\e[31mRedémarre la session pour profiter du thème.\e[0m"
echo -e "\e[32mLance l'Arsenal avec la commande : arsenal\e[0m"
