#!/bin/bash
# Archive Luma, l'exporte en .ipa signé et l'envoie sur App Store Connect.
#
# Prérequis, une fois pour toutes : copier scripts/release.env.example en
# scripts/release.env et le remplir (voir docs/appstore/publication.md).
#
#   ./scripts/release.sh                 tests + archive + validation + envoi
#   ./scripts/release.sh --bump          incrémente d'abord le numéro de build
#   ./scripts/release.sh --skip-tests    saute les tests unitaires
#   ./scripts/release.sh --dry-run       s'arrête après la validation, n'envoie rien
#   ./scripts/release.sh --oui           n'attend pas la confirmation avant l'envoi
#
# Un envoi est définitif : un numéro de build donné ne peut jamais être réutilisé,
# même après suppression. D'où la confirmation explicite avant la dernière étape.

set -euo pipefail

readonly RACINE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly BUILD="$RACINE/build"
readonly ARCHIVE="$BUILD/Luma.xcarchive"
readonly EXPORT="$BUILD/export"
readonly SIMULATEUR='platform=iOS Simulator,name=iPhone 17'
readonly TEAM_PERSONNELLE='SJVC6ZJ4VT' # ancien Personal Team, gratuit

bump=0; skip_tests=0; dry_run=0; sans_demander=0
for argument in "$@"; do
  case "$argument" in
    --bump)       bump=1 ;;
    --skip-tests) skip_tests=1 ;;
    --dry-run)    dry_run=1 ;;
    --oui|--yes)  sans_demander=1 ;;
    # L'aide, c'est l'en-tête de commentaires de ce fichier, jusqu'au premier code.
    -h|--help)    awk 'NR>1 && /^#/ {sub(/^# ?/, ""); print; next} NR>1 {exit}' \
                    "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "Option inconnue : $argument (--help pour la liste)" >&2; exit 2 ;;
  esac
done

rouge() { printf '\033[31m%s\033[0m\n' "$*"; }
vert()  { printf '\033[32m%s\033[0m\n' "$*"; }
etape() { printf '\n\033[1m▸ %s\033[0m\n' "$*"; }

echec() { rouge "✗ $1"; shift; for ligne in "$@"; do echo "  $ligne"; done; exit 1; }

cd "$RACINE"

# ── 1. Configuration ─────────────────────────────────────────────────────────

etape "Vérification de la configuration"

if [[ ! -f scripts/release.env ]]; then
  echec "scripts/release.env est absent." \
    "cp scripts/release.env.example scripts/release.env" \
    "puis remplis-le — voir docs/appstore/publication.md, étapes 1 et 4."
fi

set -a
# shellcheck source=/dev/null
source scripts/release.env
set +a

for variable in LUMA_TEAM_ID ASC_KEY_ID ASC_ISSUER_ID ASC_KEY_PATH; do
  if [[ -z "${!variable:-}" ]]; then
    echec "$variable n'est pas défini dans scripts/release.env"
  fi
done

if [[ "$LUMA_TEAM_ID" == "$TEAM_PERSONNELLE" ]]; then
  echec "LUMA_TEAM_ID vaut encore le Team ID du compte gratuit." \
    "Un Personal Team ne peut pas publier sur l'App Store." \
    "Récupère le Team ID du compte payant sur developer.apple.com → Membership."
fi

team_projet="$(awk '/DEVELOPMENT_TEAM:/ {print $2; exit}' project.yml)"
if [[ "$team_projet" != "$LUMA_TEAM_ID" ]]; then
  echec "Team ID incohérent entre les deux fichiers :" \
    "project.yml       → $team_projet" \
    "release.env       → $LUMA_TEAM_ID" \
    "Corrige DEVELOPMENT_TEAM dans project.yml, puis relance."
fi

cle="${ASC_KEY_PATH/#\~/$HOME}"
if [[ ! -f "$cle" ]]; then
  echec "Clé App Store Connect introuvable : $cle" \
    "Télécharge-la depuis App Store Connect → Utilisateurs et accès → Intégrations." \
    "Attention : Apple ne permet de la télécharger qu'une seule fois."
fi

command -v xcodegen >/dev/null || echec "xcodegen est absent (brew install xcodegen)"

vert "✓ team $LUMA_TEAM_ID · clé ${ASC_KEY_ID}"

# Simple avertissement, pas un blocage : avec la signature automatique, Xcode
# sait aussi utiliser un certificat géré dans le nuage, sans copie locale.
if ! security find-identity -v -p codesigning 2>/dev/null | grep -q 'Apple Distribution'; then
  printf '\033[33m! aucun certificat « Apple Distribution » local\033[0m\n'
  echo "  Si l'archive échoue plus bas, c'est très probablement la cause :"
  echo "  Xcode → Settings → Accounts → ton équipe → Manage Certificates"
  echo "  → + → Apple Distribution."
fi

# ── 2. Numéro de build ───────────────────────────────────────────────────────

if [[ $bump -eq 1 ]]; then
  etape "Incrément du numéro de build"
  actuel="$(awk -F'"' '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' project.yml)"
  suivant=$((actuel + 1))
  # Cible la ligne de CURRENT_PROJECT_VERSION uniquement, pas MARKETING_VERSION.
  sed -i '' "s/CURRENT_PROJECT_VERSION: \"$actuel\"/CURRENT_PROJECT_VERSION: \"$suivant\"/" project.yml
  vert "✓ build $actuel → $suivant"
fi

version="$(awk -F'"' '/MARKETING_VERSION:/ {print $2; exit}' project.yml)"
build="$(awk -F'"' '/CURRENT_PROJECT_VERSION:/ {print $2; exit}' project.yml)"
echo "  version $version (build $build)"

# ── 3. Génération du projet ──────────────────────────────────────────────────

etape "Génération du projet Xcode"
xcodegen generate --quiet
vert "✓ Luma.xcodeproj régénéré"

# ── 4. Tests ─────────────────────────────────────────────────────────────────

if [[ $skip_tests -eq 1 ]]; then
  echo; echo "  (tests sautés)"
else
  etape "Tests unitaires"
  xcodebuild -project Luma.xcodeproj -scheme Luma \
    -destination "$SIMULATEUR" \
    -quiet test \
    || echec "Les tests échouent. On ne publie pas dans cet état."
  vert "✓ tests au vert"
fi

# ── 5. Archive ───────────────────────────────────────────────────────────────

etape "Archive (configuration Release)"
rm -rf "$ARCHIVE" "$EXPORT"
mkdir -p "$BUILD"
xcodebuild -project Luma.xcodeproj -scheme Luma \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  -quiet archive \
  || echec "L'archive a échoué." \
       "Cause la plus fréquente : certificat de distribution absent." \
       "Ouvre Xcode → Réglages → Comptes → ton compte → Manage Certificates," \
       "puis ajoute un « Apple Distribution »."
vert "✓ $ARCHIVE"

# ── 6. Export du .ipa ────────────────────────────────────────────────────────

etape "Export de l'archive en .ipa signé"
options="$BUILD/ExportOptions.plist"
cat > "$options" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>export</string>
	<key>teamID</key>
	<string>$LUMA_TEAM_ID</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>uploadSymbols</key>
	<true/>
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist "$options" \
  -exportPath "$EXPORT" \
  -allowProvisioningUpdates \
  -quiet \
  || echec "L'export a échoué (voir le détail ci-dessus)."

ipa="$(find "$EXPORT" -maxdepth 1 -name '*.ipa' | head -1)"
[[ -n "$ipa" ]] || echec "Aucun .ipa produit dans $EXPORT"
vert "✓ $(basename "$ipa") ($(du -h "$ipa" | cut -f1))"

# ── 7. Validation ────────────────────────────────────────────────────────────

etape "Validation par Apple (aucun envoi à ce stade)"
xcrun altool --validate-app \
  --file "$ipa" \
  --type ios \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" \
  || echec "La validation échoue : corrige les points signalés avant d'envoyer."
vert "✓ binaire validé"

if [[ $dry_run -eq 1 ]]; then
  echo; vert "--dry-run : rien n'a été envoyé."
  echo "  Le .ipa validé est prêt ici : $ipa"
  exit 0
fi

# ── 8. Envoi ─────────────────────────────────────────────────────────────────

if [[ $sans_demander -eq 0 ]]; then
  echo
  echo "Prêt à envoyer Luma $version (build $build) sur App Store Connect."
  echo "Un numéro de build envoyé est consommé définitivement, même supprimé."
  read -r -p "Envoyer ? [o/N] " reponse
  [[ "$reponse" == "o" || "$reponse" == "O" ]] || { echo "Annulé."; exit 0; }
fi

etape "Envoi sur App Store Connect"
xcrun altool --upload-app \
  --file "$ipa" \
  --type ios \
  --apiKey "$ASC_KEY_ID" \
  --apiIssuer "$ASC_ISSUER_ID" \
  || echec "L'envoi a échoué. Si le build est refusé comme déjà utilisé," \
       "relance avec --bump pour passer au numéro de build suivant."

echo
vert "✓ Luma $version (build $build) envoyée."
cat <<'SUITE'

Et maintenant :
  1. Le traitement du build par Apple prend 5 à 30 min ; un e-mail arrive à la fin.
  2. App Store Connect → ta version → section « Build » → sélectionne ce build.
  3. Vérifie que la fiche est complète (docs/appstore/metadata.md), puis
     « Ajouter à la validation » et enfin « Soumettre à la validation ».
  4. Compte 24 à 48 h de revue. En cas de refus, Apple explique quoi corriger
     dans App Store Connect ; on corrige, --bump, et on renvoie.
SUITE
