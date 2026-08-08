#!/bin/bash
# Création complète du thème KDE NocturneGlass pour Lab'O Noir

# Se placer à la racine du dépôt (si tu n'y es pas déjà)
cd "$(git rev-parse --show-toplevel 2>/dev/null || echo ~/labo-noir-os)" 2>/dev/null || echo "Assure-toi d'être dans le dossier du dépôt."

# Créer les dossiers
mkdir -p kde-theme/{colors,plasma/NocturneGlass/contents/widgets,kvantum/NocturneGlass,konsole,sddm/NocturneGlass}

# --- Fichier 1 : NocturneGlass.colors ---
cat > kde-theme/colors/NocturneGlass.colors << 'EOF'
[ColorEffects:Disabled]
Color=0,0,0
Amount=0.4
IntensityAmount=0.0
ColorEffect=0
IntensityEffect=0

[ColorEffects:Inactive]
Color=0,0,0
Amount=0.3
IntensityAmount=0.0
ColorEffect=0
IntensityEffect=0

[Colors:Button]
BackgroundNormal=26,26,26
BackgroundAlternate=20,20,20
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[Colors:Complementary]
BackgroundNormal=26,26,26
BackgroundAlternate=20,20,20
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[Colors:Header]
BackgroundNormal=26,26,26
BackgroundAlternate=20,20,20
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[Colors:Selection]
BackgroundNormal=255,22,84
BackgroundAlternate=255,22,84
ForegroundNormal=255,255,255
ForegroundActive=255,255,255
ForegroundLink=255,255,255
ForegroundVisited=255,255,255
ForegroundNegative=255,255,255
ForegroundPositive=255,255,255

[Colors:Tooltip]
BackgroundNormal=10,10,10
BackgroundAlternate=10,10,10
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[Colors:View]
BackgroundNormal=10,10,10
BackgroundAlternate=20,20,20
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[Colors:Window]
BackgroundNormal=10,10,10
BackgroundAlternate=20,20,20
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[Colors:Menu]
BackgroundNormal=10,10,10
BackgroundAlternate=20,20,20
ForegroundNormal=192,192,192
ForegroundActive=255,22,84
ForegroundLink=255,22,84
ForegroundVisited=192,192,192
ForegroundNegative=255,22,84
ForegroundPositive=0,255,0

[General]
Name=NocturneGlass
X-KDE-PluginInfo-Name=NocturneGlass
EOF

# --- Fichier 2 : metadata.desktop (Plasma) ---
cat > kde-theme/plasma/NocturneGlass/metadata.desktop << 'EOF'
[Desktop Entry]
Name=NocturneGlass
Comment=Thème noir glassmorphique pour Lab'O Noir
Type=Service
ServiceTypes=Plasma/LookAndFeel,Plasma/Theme

X-KDE-PluginInfo-Name=NocturneGlass
X-KDE-PluginInfo-Category=Desktop
X-KDE-PluginInfo-Version=1.0
X-KDE-PluginInfo-License=CC BY-NC 4.0

X-Plasma-Theme-Name=NocturneGlass
EOF

# --- Fichier 3 : panel-background.svg ---
cat > kde-theme/plasma/NocturneGlass/contents/widgets/panel-background.svg << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%">
  <defs>
    <linearGradient id="grad" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:#1A1A1A;stop-opacity:0.85" />
      <stop offset="100%" style="stop-color:#0A0A0A;stop-opacity:0.95" />
    </linearGradient>
    <filter id="blur">
      <feGaussianBlur stdDeviation="2" />
    </filter>
  </defs>
  <rect width="100%" height="100%" fill="url(#grad)" filter="url(#blur)" />
</svg>
EOF

# --- Fichier 4 : Kvantum.kvconfig ---
cat > kde-theme/kvantum/NocturneGlass/Kvantum.kvconfig << 'EOF'
[General]
theme=NocturneGlass
style=kvantum
icon_theme=Papirus-Dark

[Kvantum]
opacity=0.85
contrast=0.9
saturation=0.9
EOF

# --- Fichier 5 : Kvantum.svg (placeholder) ---
cat > kde-theme/kvantum/NocturneGlass/Kvantum.svg << 'EOF'
<!-- Kvantum theme placeholder -->
EOF

# --- Fichier 6 : NocturneGlass.colorscheme (Konsole) ---
cat > kde-theme/konsole/NocturneGlass.colorscheme << 'EOF'
[General]
Description=NocturneGlass
Opacity=0.90
Wallpaper=
Blur=true

[Background]
Color=10,10,10

[BackgroundFaint]
Color=0,0,0

[BackgroundIntense]
Color=0,0,0

[Foreground]
Color=192,192,192

[ForegroundFaint]
Color=128,128,128

[ForegroundIntense]
Color=255,255,255

[Color0]
Color=10,10,10

[Color1]
Color=255,22,84

[Color2]
Color=0,255,0

[Color3]
Color=255,255,0

[Color4]
Color=0,0,255

[Color5]
Color=255,0,255

[Color6]
Color=0,255,255

[Color7]
Color=192,192,192

[Color8]
Color=64,64,64

[Color9]
Color=255,22,84

[Color10]
Color=0,255,0

[Color11]
Color=255,255,0

[Color12]
Color=0,0,255

[Color13]
Color=255,0,255

[Color14]
Color=0,255,255

[Color15]
Color=255,255,255
EOF

# --- Fichier 7 : theme.conf (SDDM) ---
cat > kde-theme/sddm/NocturneGlass/theme.conf << 'EOF'
[General]
background=background.jpg
type=image
color=0A0A0A
bgcolor=0A0A0A
font=Noto Sans,10,-1,5,50,0,0,0,0,0
EOF

# --- Fichier 8 : apply-theme.sh ---
cat > kde-theme/apply-theme.sh << 'EOF'
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
EOF

# Rendre apply-theme.sh exécutable
chmod +x kde-theme/apply-theme.sh

echo -e "\e[32m✅ Tous les fichiers du thème NocturneGlass ont été créés dans kde-theme/\e[0m"
echo -e "\e[31mN'oublie pas de placer une image background.jpg dans kde-theme/sddm/NocturneGlass/\e[0m"
echo -e "\e[32mTu peux maintenant lancer ./kde-theme/apply-theme.sh pour appliquer le thème.\e[0m"
