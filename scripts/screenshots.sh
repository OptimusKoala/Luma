#!/bin/bash
# Met les captures d'écran au format exigé par l'App Store (iPhone 6,9").
#
#   1. Sur l'iPhone, fais tes captures dans Luma (bouton latéral + volume haut).
#   2. Envoie-les sur le Mac (AirDrop, ou Photos → Exporter l'original).
#   3. Dépose-les dans docs/appstore/captures/brutes/ en les nommant
#      01-…, 02-… : l'ordre des fichiers sera l'ordre de la fiche App Store.
#   4. ./scripts/screenshots.sh
#
# Les images prêtes à téléverser arrivent dans docs/appstore/captures/6.9/.
#
# La conversion met à l'échelle sans déformer puis recadre au centre le
# léger excédent (quelques pixels) : aucun cadre ajouté, aucune distorsion.

set -euo pipefail

readonly LARGEUR=1290
readonly HAUTEUR=2796

readonly RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly SOURCE="${1:-$RACINE/docs/appstore/captures/brutes}"
readonly CIBLE="$RACINE/docs/appstore/captures/6.9"

rouge() { printf '\033[31m%s\033[0m\n' "$*"; }
vert()  { printf '\033[32m%s\033[0m\n' "$*"; }

if [[ ! -d "$SOURCE" ]]; then
  mkdir -p "$SOURCE"
  rouge "Dossier des captures brutes créé, mais vide :"
  echo "  $SOURCE"
  echo
  echo "Dépose-y tes captures (01-…, 02-…) puis relance ce script."
  exit 1
fi

mkdir -p "$CIBLE"

# Fichiers image du dossier source, triés par nom.
sources=()
while IFS= read -r fichier; do
  sources+=("$fichier")
done < <(find "$SOURCE" -maxdepth 1 -type f \
  \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.heic' \) \
  | LC_ALL=C sort)

if [[ ${#sources[@]} -eq 0 ]]; then
  rouge "Aucune image dans $SOURCE"
  exit 1
fi

echo "Format cible : ${LARGEUR} × ${HAUTEUR} px (iPhone 6,9\")"
echo

temporaire="$(mktemp -d)"
trap 'rm -rf "$temporaire"' EXIT

index=0
for source in "${sources[@]}"; do
  index=$((index + 1))
  nom="$(printf '%02d' "$index").png"
  travail="$temporaire/$nom"

  # Conversion en PNG (couvre aussi le HEIC des captures partagées via Photos).
  sips -s format png "$source" --out "$travail" >/dev/null

  largeur_src="$(sips -g pixelWidth "$travail" | awk '/pixelWidth/ {print $2}')"
  hauteur_src="$(sips -g pixelHeight "$travail" | awk '/pixelHeight/ {print $2}')"

  if [[ "$largeur_src" -gt "$hauteur_src" ]]; then
    rouge "✗ $(basename "$source") : capture en paysage (${largeur_src}×${hauteur_src})."
    echo "  Luma est en portrait uniquement — refais la capture."
    exit 1
  fi

  if [[ "$largeur_src" -eq "$LARGEUR" && "$hauteur_src" -eq "$HAUTEUR" ]]; then
    action="déjà au format"
  else
    # Mise à l'échelle « couvrante » : on agrandit selon la dimension la plus
    # contraignante, l'excédent partira au recadrage.
    if (( largeur_src * HAUTEUR > hauteur_src * LARGEUR )); then
      sips --resampleHeight "$HAUTEUR" "$travail" >/dev/null
    else
      sips --resampleWidth "$LARGEUR" "$travail" >/dev/null
    fi
    sips --cropToHeightWidth "$HAUTEUR" "$LARGEUR" "$travail" >/dev/null
    action="${largeur_src}×${hauteur_src} → ${LARGEUR}×${HAUTEUR}"
  fi

  # Vérification : Apple refuse toute image hors dimensions ou avec canal alpha.
  largeur_out="$(sips -g pixelWidth "$travail" | awk '/pixelWidth/ {print $2}')"
  hauteur_out="$(sips -g pixelHeight "$travail" | awk '/pixelHeight/ {print $2}')"
  alpha="$(sips -g hasAlpha "$travail" | awk '/hasAlpha/ {print $2}')"

  if [[ "$largeur_out" != "$LARGEUR" || "$hauteur_out" != "$HAUTEUR" ]]; then
    rouge "✗ $(basename "$source") : dimensions obtenues ${largeur_out}×${hauteur_out}"
    exit 1
  fi

  if [[ "$alpha" == "yes" ]]; then
    rouge "✗ $nom possède un canal alpha, refusé par l'App Store."
    echo "  Ouvre l'image dans Aperçu et réexporte-la en PNG sans transparence."
    exit 1
  fi

  mv "$travail" "$CIBLE/$nom"
  vert "✓ $nom  ($action)  ← $(basename "$source")"
done

echo
vert "$index capture(s) prêtes dans docs/appstore/captures/6.9/"
echo
echo "Dans App Store Connect : fiche de l'app → Aperçus et captures d'écran →"
echo "onglet « iPhone 6,9\" » → glisser les fichiers dans l'ordre 01, 02, 03…"
echo "Apple réutilise cette série pour toutes les autres tailles d'iPhone."
