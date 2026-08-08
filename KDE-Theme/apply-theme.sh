#!/bin/bash
# Applique le thème NocturneGlass à KDE Plasma

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo -e "\e[32m>> Application du thème NocturneGlass...\e[0m"

# 1. Copier les fichiers de couleur
mkdir -p ~/.local/share/color-schemes/
cp "$REPO_DIR/kde-theme/colors/NocturneGlass.colors" ~/.local/share/color-schemes/

# 2. Copier le thème Plasma
mkdir -p ~/.local/share/plasma/desktoptheme/
cp -r "$REPO_DIR/kde-theme/plasma/NocturneGlass" ~/.local/share/plasma/desktoptheme/

# 3. Copier le thème Kvantum
mkdir -p ~/.config/Kvantum/
cp -r "$REPO_DIR/kde-theme/kvantum/NocturneGlass" ~/.config/Kvantum/

# 4. Copier le thème Konsole
mkdir -p ~/.local/share/konsole/
cp "$REPO_DIR/kde-theme/konsole/NocturneGlass.colorscheme" ~/.local/share/konsole/

# 5. Appliquer les paramètres via kwriteconfig5
kwriteconfig5 --file ~/.config/kdeglobals --group General --key ColorScheme "NocturneGlass"
kwriteconfig5 --file ~/.config/kdeglobals --group KDE --key widgetStyle "kvantum"
kwriteconfig5 --file ~/.config/kdeglobals --group Icons --key Theme "Papirus-Dark"

# 6. Appliquer le thème Plasma
kwriteconfig5 --file ~/.config/plasmarc --group Theme --key name "NocturneGlass"

# 7. Appliquer Kvantum comme style d'application
kwriteconfig5 --file ~/.config/Kvantum/kvantum.kvconfig --group General --key theme "NocturneGlass"

# 8. Configurer Konsole
kwriteconfig5 --file ~/.config/konsolerc --group Desktop Entry --key DefaultProfile "NocturneGlass.profile"
kwriteconfig5 --file ~/.config/konsolerc --group General --key TerminalApplication "konsole"

# 9. Redémarrer Plasma pour appliquer les changements
kquitapp5 plasmashell 2>/dev/null
kstart5 plasmashell 2>/dev/null &

echo -e "\e[32m>> Thème NocturneGlass appliqué.\e[0m"
