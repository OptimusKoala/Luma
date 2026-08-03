#!/bin/bash
# Produit les captures d'écran App Store depuis le simulateur iPhone 17 Pro Max,
# dont la résolution native (1320 × 2868) est une taille acceptée pour le
# créneau 6,9" — aucun redimensionnement, donc aucune perte.
#
#   ./scripts/screenshots-simulateur.sh
#
# Le simulateur n'a pas de caméra. L'app est donc lancée en mode captures
# (LUMA_SCREENSHOT, compilé en DEBUG uniquement — voir Luma/Views/
# ScreenshotMode.swift) : le viseur reçoit une photo de scène en domaine public
# ou CC0 (docs/appstore/captures/scenes/, récupérées par
# scripts/photos-scenes.py), et l'EV de cette scène traverse le vrai
# ExposureCalculator. Les valeurs visibles sont celles que l'app calcule ; seule
# la lumière d'entrée est fournie, et elle correspond à la photo affichée.
#
# Pour des captures sur de vraies scènes photographiées, utiliser plutôt
# scripts/screenshots.sh, qui reformate des captures prises sur l'iPhone.

set -euo pipefail

readonly SIMULATEUR='iPhone 17 Pro Max'
readonly LARGEUR=1320
readonly HAUTEUR=2868
readonly BUNDLE=com.michaelbernard69.Luma

readonly RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly DD="$RACINE/build/dd-simulateur"
readonly CIBLE="$RACINE/docs/appstore/captures/6.9"
readonly PHOTOS="$RACINE/docs/appstore/captures/scenes"

# Ordre des captures = ordre de la fiche App Store. La première est celle qui
# apparaît dans les résultats de recherche.
readonly SCENES=(
  "plein-jour:2.5"
  "molette:2.5"
  "pellicule:5.0"
  "spot:2.5"
  "trop-sombre:2.5"
)

rouge() { printf '\033[31m%s\033[0m\n' "$*"; }
vert()  { printf '\033[32m%s\033[0m\n' "$*"; }
etape() { printf '\n\033[1m▸ %s\033[0m\n' "$*"; }

cd "$RACINE"

etape "Simulateur"
udid="$(xcrun simctl list devices available -j \
  | python3 -c "
import json,sys
d=json.load(sys.stdin)['devices']
for liste in d.values():
    for appareil in liste:
        if appareil['name'] == '$SIMULATEUR':
            print(appareil['udid']); raise SystemExit
")"
if [[ -z "${udid:-}" ]]; then
  rouge "✗ simulateur « $SIMULATEUR » introuvable"
  echo "  Installe-le via Xcode → Settings → Components."
  exit 1
fi
xcrun simctl boot "$udid" 2>/dev/null || true
xcrun simctl bootstatus "$udid" -b >/dev/null 2>&1 || true
vert "✓ $SIMULATEUR ($udid) démarré"

etape "Build (Debug, simulateur)"
xcodegen generate --quiet
xcodebuild -project Luma.xcodeproj -scheme Luma \
  -configuration Debug \
  -destination "id=$udid" \
  -derivedDataPath "$DD" \
  -quiet build
app="$DD/Build/Products/Debug-iphonesimulator/Luma.app"
[[ -d "$app" ]] || { rouge "✗ app introuvable : $app"; exit 1; }
vert "✓ $(basename "$app")"

etape "Installation"
xcrun simctl install "$udid" "$app"
# Barre d'état figée : l'heure d'Apple, réseau et batterie pleins. Évite
# d'exposer l'heure réelle de la machine sur la fiche App Store.
xcrun simctl status_bar "$udid" override \
  --time "9:41" --batteryState charged --batteryLevel 100 \
  --cellularMode active --cellularBars 4 --wifiMode active --wifiBars 3
vert "✓ installée, barre d'état figée à 9:41"

mkdir -p "$CIBLE"
etape "Captures"
index=0
for entree in "${SCENES[@]}"; do
  scene="${entree%%:*}"
  attente="${entree##*:}"
  index=$((index + 1))
  nom="$(printf '%02d' "$index")-$scene.png"

  xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
  # Le simulateur lit le disque de l'hôte : les photos de scène restent hors
  # du bundle. Dossier absent → l'app retombe sur la scène dessinée par code.
  SIMCTL_CHILD_LUMA_SCREENSHOT="$scene" \
  SIMCTL_CHILD_LUMA_SCREENSHOT_DIR="$PHOTOS" \
    xcrun simctl launch "$udid" "$BUNDLE" >/dev/null
  sleep "$attente"
  xcrun simctl io "$udid" screenshot --type=png "$CIBLE/$nom" >/dev/null 2>&1

  # Les captures du simulateur portent un canal alpha, que l'App Store refuse.
  swift "$RACINE/scripts/aplatir-png.swift" "$CIBLE/$nom"

  largeur="$(sips -g pixelWidth "$CIBLE/$nom" | awk '/pixelWidth/ {print $2}')"
  hauteur="$(sips -g pixelHeight "$CIBLE/$nom" | awk '/pixelHeight/ {print $2}')"
  alpha="$(sips -g hasAlpha "$CIBLE/$nom" | awk '/hasAlpha/ {print $2}')"

  if [[ "$largeur" != "$LARGEUR" || "$hauteur" != "$HAUTEUR" ]]; then
    rouge "✗ $nom : ${largeur}×${hauteur}, attendu ${LARGEUR}×${HAUTEUR}"
    exit 1
  fi
  if [[ "$alpha" == "yes" ]]; then
    rouge "✗ $nom possède un canal alpha, refusé par l'App Store."
    exit 1
  fi
  vert "✓ $nom  (${largeur}×${hauteur})"
done

xcrun simctl terminate "$udid" "$BUNDLE" 2>/dev/null || true
xcrun simctl status_bar "$udid" clear 2>/dev/null || true

echo
vert "$index captures dans docs/appstore/captures/6.9/"
echo "Format 6,9\" natif : aucun redimensionnement, aucune perte."
