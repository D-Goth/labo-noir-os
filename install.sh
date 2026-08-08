#!/bin/bash
# ⚙️ Lab'O Noir OS - Installateur pour Debian 13.6 (Trixie)

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARSENAL_DIR="/opt/labnoir/arsenal"

# --- BANNER LAB'O'NOIR ---
echo -e "\e[31m"
echo " ██╗      █████╗ ██████╗  ██████╗ ███╗   ██╗ ██████╗ ██╗██████╗ "
echo " ██║     ██╔══██╗██╔══██╗██╔═══██╗████╗  ██║██╔═══██╗██║██╔══██╗"
echo " ██║     ███████║██████╔╝██║   ██║██╔██╗ ██║██║   ██║██║██████╔╝"
echo " ██║     ██╔══██║██╔══██╗██║   ██║██║╚██╗██║██║   ██║██║██╔══██╗"
echo " ███████╗██║  ██║██████╔╝╚██████╔╝██║ ╚████║╚██████╔╝██║██║  ██║"
echo " ╚══════╝╚═╝  ╚═╝╚═════╝  ╚═════╝ ╚═╝  ╚═══╝ ╚═════╝ ╚═╝╚═╝  ╚═╝"
echo -e "\e[0m"
echo -e "\e[31m          LAB'O'NOIR OS — FORGE YOUR OWN SHADOW          \e[0m"
echo -e "\e[31m                 Installation (Debian 13.6)              \e[0m"

# Vérification des privilèges
if [[ $EUID -ne 0 ]]; then
   echo -e "\e[31mCe script doit être exécuté en root (sudo).\e[0m"
   exit 1
fi

# 1. Mise à jour du système
echo -e "\e[32m>> Mise à jour du système...\e[0m"
apt update && apt upgrade -y

# 2. Vérification de KDE Plasma
echo -e "\e[32m>> Vérification des paquets KDE...\e[0m"
apt install -y --no-install-recommends plasma-desktop sddm konsole dolphin \
               plasma-workspace plasma-themes breeze-gtk-theme \
               kvantum papirus-icon-theme 2>/dev/null || echo -e "\e[33mCertains paquets KDE sont déjà présents.\e[0m"

# 3. Outils de développement
echo -e "\e[32m>> Installation des outils de développement...\e[0m"
DEV_TOOLS=(
    git
    curl
    wget
    htop
    build-essential
    python3
    python3-pip
    python3-pyqt5
    python3-pyqt5.qtsvg
    flatpak
    snapd
    network-manager
)
for tool in "${DEV_TOOLS[@]}"; do
    if apt-cache show "$tool" &>/dev/null; then
        echo -e "\e[32m   - Installation de $tool...\e[0m"
        apt install -y "$tool" 2>/dev/null || echo -e "\e[33m   - $tool non installé (erreur).\e[0m"
    else
        echo -e "\e[33m   - $tool non trouvé dans les dépôts.\e[0m"
    fi
done

# 4. Outils de sécurité
echo -e "\e[32m>> Installation des outils de sécurité...\e[0m"
SEC_TOOLS=(
    nmap
    hydra
    sqlmap
    wpscan
    nikto
    metasploit-framework
    aircrack-ng
    john
    hashcat
    netcat-traditional
    tcpdump
    wireshark
    ettercap-graphical
)
for tool in "${SEC_TOOLS[@]}"; do
    if apt-cache show "$tool" &>/dev/null; then
        echo -e "\e[32m   - Installation de $tool...\e[0m"
        apt install -y "$tool" 2>/dev/null || echo -e "\e[33m   - $tool non installé (erreur).\e[0m"
    else
        echo -e "\e[33m   - $tool non trouvé dans les dépôts.\e[0m"
    fi
done

# 5. Déploiement de l'Arsenal
echo -e "\e[32m>> Déploiement de l'Arsenal dans /opt/labnoir/...\e[0m"
mkdir -p "$ARSENAL_DIR"
cp -r "$REPO_DIR/arsenal/"* "$ARSENAL_DIR/"
cp -r "$REPO_DIR/assets/"* "$ARSENAL_DIR/assets/" 2>/dev/null || true
chmod +x "$ARSENAL_DIR/arsenal.py"

# 6. Dépendances Python
echo -e "\e[32m>> Installation des dépendances Python...\e[0m"
pip3 install -r "$ARSENAL_DIR/requirements.txt" --break-system-packages || pip3 install -r "$ARSENAL_DIR/requirements.txt"

# 7. Raccourci .desktop
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

# 8. Alias
echo "alias arsenal='python3 /opt/labnoir/arsenal/arsenal.py'" >> /etc/bash.bashrc

# 9. Dotfiles
if [ -n "$SUDO_USER" ]; then
    HOME_USER=$(getent passwd "$SUDO_USER" | cut -d: -f6)
    cp "$REPO_DIR/dotfiles/.bashrc" "$HOME_USER/.bashrc" 2>/dev/null || true
    cp "$REPO_DIR/dotfiles/.zshrc" "$HOME_USER/.zshrc" 2>/dev/null || true
fi

# 10. Fin
echo -e "\e[32m>> Installation terminée !\e[0m"
echo -e "\e[31mRedémarre la session pour profiter du thème.\e[0m"
echo -e "\e[32mLance l'Arsenal avec la commande : arsenal\e[0m"
