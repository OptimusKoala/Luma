#!/usr/bin/env python3
"""Remplit la fiche App Store de Luma par l'API App Store Connect.

    ASC_KEY_ID=… ASC_ISSUER_ID=… ASC_KEY_PATH=… python3 scripts/fiche-appstore.py
    …                                                                   --dry-run

La source de vérité des textes est docs/appstore/metadata.md : ce script en lit
les blocs de code, donc corriger la fiche se fait dans le Markdown, jamais ici.

Ce qu'il écrit
  · nom et sous-titre, par langue (fr-FR, en-US)
  · description, mots-clés, texte promotionnel, URL de support et marketing
  · URL de politique de confidentialité
  · catégories (Photo et vidéo / Utilitaires) et droits d'auteur
  · les captures d'écran du créneau 6,9"

Ce qu'il ne peut PAS écrire, et qui reste à faire à la main dans App Store
Connect (l'API ne les expose pas, ou pas sans risque) : le questionnaire de
confidentialité, la classification par âge, le tarif et la disponibilité, le
statut de professionnel, et la soumission elle-même. Le script les rappelle
en terminant.

L'Issuer ID n'est jamais écrit sur le disque : il passe par l'environnement.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
FICHE = RACINE / "docs" / "appstore" / "metadata.md"
CAPTURES = RACINE / "docs" / "appstore" / "captures" / "6.9"
API = "https://api.appstoreconnect.apple.com/v1"

BUNDLE_ID = "com.michaelbernard69.Luma"
NOM_APP = "Luma · Light Meter"
COPYRIGHT = "2026 L'ELITE DANGEREUSE"
CATEGORIE_PRINCIPALE = "PHOTO_AND_VIDEO"
CATEGORIE_SECONDAIRE = "UTILITIES"
BASE_WEB = "https://optimuskoala.github.io/Luma"
URL_SUPPORT = f"{BASE_WEB}/support.html"
URL_MARKETING = f"{BASE_WEB}/"
URL_CONFIDENTIALITE = f"{BASE_WEB}/privacy.html"
TYPE_CAPTURES = "APP_IPHONE_6_9"

SEC = "\033[32m"; ERR = "\033[31m"; GRAS = "\033[1m"; NEUTRE = "\033[0m"

SEC_ARRET = False  # basculé par --dry-run


def ok(m): print(f"{SEC}✓{NEUTRE} {m}")
def ko(m): print(f"{ERR}✗{NEUTRE} {m}", file=sys.stderr)
def etape(m): print(f"\n{GRAS}▸ {m}{NEUTRE}")


# ── Authentification ────────────────────────────────────────────────────────

def jeton() -> str:
    """Délègue la signature du JWT à altool : pas de dépendance crypto ici.

    Attention, altool écrit le jeton sur stderr, pas sur stdout.
    """
    for variable in ("ASC_KEY_ID", "ASC_ISSUER_ID", "ASC_KEY_PATH"):
        if not os.environ.get(variable):
            ko(f"{variable} manque dans l'environnement")
            sys.exit(2)
    cle = Path(os.path.expanduser(os.environ["ASC_KEY_PATH"]))
    if not cle.is_file():
        ko(f"clé introuvable : {cle}")
        sys.exit(2)

    resultat = subprocess.run(
        ["xcrun", "altool", "--generate-jwt",
         "--apiKey", os.environ["ASC_KEY_ID"],
         "--apiIssuer", os.environ["ASC_ISSUER_ID"]],
        capture_output=True, text=True,
        env={**os.environ, "API_PRIVATE_KEYS_DIR": str(cle.parent)})
    trouve = re.search(r"eyJ[A-Za-z0-9_.\-]+", resultat.stdout + resultat.stderr)
    if not trouve:
        ko("altool n'a pas produit de JWT")
        print(resultat.stderr[:400], file=sys.stderr)
        sys.exit(2)
    return trouve.group(0)


JWT = ""


def appel(methode: str, chemin: str, corps: dict | None = None,
          brut: bytes | None = None, entetes: dict | None = None):
    """Appel JSON:API. Renvoie le document décodé, ou None sur 204."""
    url = chemin if chemin.startswith("http") else f"{API}/{chemin}"
    donnees = brut if brut is not None else (
        json.dumps(corps).encode() if corps is not None else None)
    requete = urllib.request.Request(url, data=donnees, method=methode)
    requete.add_header("Authorization", f"Bearer {JWT}")
    if brut is None and corps is not None:
        requete.add_header("Content-Type", "application/json")
    for nom, valeur in (entetes or {}).items():
        requete.add_header(nom, valeur)
    try:
        with urllib.request.urlopen(requete) as reponse:
            charge = reponse.read()
            return json.loads(charge) if charge else None
    except urllib.error.HTTPError as erreur:
        detail = erreur.read().decode(errors="replace")
        try:
            premiere = json.loads(detail)["errors"][0]
            message = f"{premiere.get('title')} — {premiere.get('detail')}"
        except Exception:
            message = detail[:300]
        raise RuntimeError(f"{methode} {chemin} → {erreur.code} : {message}") from None


# ── Lecture des textes ──────────────────────────────────────────────────────

CHAMPS = {
    "Sous-titre": "subtitle", "Subtitle": "subtitle",
    "Texte promotionnel": "promotionalText", "Promotional text": "promotionalText",
    "Mots-clés": "keywords", "Keywords": "keywords",
    "Description": "description",
}


def textes() -> dict[str, dict[str, str]]:
    """{locale: {champ: texte}} extrait de metadata.md."""
    resultat: dict[str, dict[str, str]] = {"fr-FR": {}, "en-US": {}}
    locale = None
    champ = None
    dans_bloc = False
    tampon: list[str] = []

    for ligne in FICHE.read_text(encoding="utf-8").splitlines():
        if ligne.startswith("## "):
            if "française" in ligne:
                locale = "fr-FR"
            elif "anglaise" in ligne:
                locale = "en-US"
            else:
                locale = None
            continue

        if dans_bloc:
            if ligne.startswith("```"):
                dans_bloc = False
                if locale and champ:
                    resultat[locale][champ] = "\n".join(tampon)
                champ, tampon = None, []
            else:
                tampon.append(ligne)
            continue

        entete = re.match(r"^#{3,4}\s+([^(]+?)\s*\(\d+\)", ligne)
        if entete:
            champ = CHAMPS.get(entete.group(1).strip())
            continue

        if champ and ligne.startswith("```"):
            dans_bloc = True

    for locale, valeurs in resultat.items():
        manquants = {"subtitle", "promotionalText", "keywords", "description"} - valeurs.keys()
        if manquants:
            ko(f"{locale} : champs introuvables dans metadata.md → {sorted(manquants)}")
            sys.exit(2)
    return resultat


# ── Écriture de la fiche ────────────────────────────────────────────────────

def trouver_app() -> str:
    doc = appel("GET", "apps?limit=200")
    for app in doc["data"]:
        if app["attributes"]["bundleId"] == BUNDLE_ID:
            return app["id"]
    ko(f"aucune app pour {BUNDLE_ID}")
    sys.exit(1)


def version_en_cours(app: str) -> str:
    doc = appel("GET", f"apps/{app}/appStoreVersions?limit=10")
    modifiables = {"PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED",
                   "REJECTED", "METADATA_REJECTED", "INVALID_BINARY"}
    for version in doc["data"]:
        etat = (version["attributes"].get("appStoreState")
                or version["attributes"].get("appVersionState"))
        if etat in modifiables:
            return version["id"]
    # Faute d'état reconnu, la plus récente reste le meilleur choix.
    if doc["data"]:
        return doc["data"][0]["id"]
    ko("aucune version à remplir — crée-la dans App Store Connect")
    sys.exit(1)


def maj_ou_creer(collection: str, parent_type: str, parent: str,
                 locale: str, attributs: dict, relation: str) -> None:
    """Crée la localisation si elle manque, la met à jour sinon."""
    existantes = appel("GET", f"{parent_type}/{parent}/{collection}?limit=50")
    for element in existantes["data"]:
        if element["attributes"]["locale"] == locale:
            if SEC_ARRET:
                ok(f"(dry-run) {collection} {locale} : mise à jour de "
                   f"{sorted(attributs)}")
                return
            appel("PATCH", f"{collection}/{element['id']}",
                  {"data": {"type": collection, "id": element["id"],
                            "attributes": attributs}})
            ok(f"{collection} {locale} mise à jour")
            return

    if SEC_ARRET:
        ok(f"(dry-run) {collection} {locale} : création")
        return
    appel("POST", collection, {"data": {
        "type": collection,
        "attributes": {**attributs, "locale": locale},
        "relationships": {relation: {"data": {"type": parent_type, "id": parent}}},
    }})
    ok(f"{collection} {locale} créée")


def categories_et_copyright(app: str, version: str) -> None:
    infos = appel("GET", f"apps/{app}/appInfos?limit=10")
    info = infos["data"][0]["id"]
    if SEC_ARRET:
        ok(f"(dry-run) catégories {CATEGORIE_PRINCIPALE} / {CATEGORIE_SECONDAIRE}")
        ok(f"(dry-run) droits d'auteur « {COPYRIGHT} »")
        return info
    appel("PATCH", f"appInfos/{info}", {"data": {
        "type": "appInfos", "id": info,
        "relationships": {
            "primaryCategory": {"data": {"type": "appCategories",
                                         "id": CATEGORIE_PRINCIPALE}},
            "secondaryCategory": {"data": {"type": "appCategories",
                                           "id": CATEGORIE_SECONDAIRE}},
        }}})
    ok(f"catégories : {CATEGORIE_PRINCIPALE} / {CATEGORIE_SECONDAIRE}")
    appel("PATCH", f"appStoreVersions/{version}", {"data": {
        "type": "appStoreVersions", "id": version,
        "attributes": {"copyright": COPYRIGHT}}})
    ok(f"droits d'auteur : {COPYRIGHT}")
    return info


def captures(version: str) -> None:
    fichiers = sorted(CAPTURES.glob("*.png"))
    if not fichiers:
        ko(f"aucune capture dans {CAPTURES} — lance scripts/screenshots-simulateur.sh")
        sys.exit(1)

    # Les captures se rattachent à la localisation, pas à la version.
    locales = appel("GET", f"appStoreVersions/{version}/appStoreVersionLocalizations?limit=50")
    for localisation in locales["data"]:
        locale = localisation["attributes"]["locale"]
        ensembles = appel(
            "GET", f"appStoreVersionLocalizations/{localisation['id']}"
                   f"/appScreenshotSets?limit=50")
        ensemble = next((e["id"] for e in ensembles["data"]
                         if e["attributes"]["screenshotDisplayType"] == TYPE_CAPTURES),
                        None)

        if SEC_ARRET:
            ok(f"(dry-run) {locale} : {len(fichiers)} captures dans "
               f"{TYPE_CAPTURES} (ensemble {'existant' if ensemble else 'à créer'})")
            continue

        if ensemble is None:
            cree = appel("POST", "appScreenshotSets", {"data": {
                "type": "appScreenshotSets",
                "attributes": {"screenshotDisplayType": TYPE_CAPTURES},
                "relationships": {"appStoreVersionLocalization": {"data": {
                    "type": "appStoreVersionLocalizations",
                    "id": localisation["id"]}}}}})
            ensemble = cree["data"]["id"]

        # On remplace : sinon les captures s'empilent à chaque exécution.
        anciennes = appel("GET", f"appScreenshotSets/{ensemble}/appScreenshots?limit=50")
        for ancienne in anciennes["data"]:
            appel("DELETE", f"appScreenshots/{ancienne['id']}")

        for fichier in fichiers:
            octets = fichier.read_bytes()
            reserve = appel("POST", "appScreenshots", {"data": {
                "type": "appScreenshots",
                "attributes": {"fileSize": len(octets), "fileName": fichier.name},
                "relationships": {"appScreenshotSet": {"data": {
                    "type": "appScreenshotSets", "id": ensemble}}}}})
            identifiant = reserve["data"]["id"]

            for operation in reserve["data"]["attributes"]["uploadOperations"]:
                morceau = octets[operation["offset"]:
                                 operation["offset"] + operation["length"]]
                entetes = {e["name"]: e["value"] for e in operation["requestHeaders"]}
                appel(operation["method"], operation["url"],
                      brut=morceau, entetes=entetes)

            appel("PATCH", f"appScreenshots/{identifiant}", {"data": {
                "type": "appScreenshots", "id": identifiant,
                "attributes": {"uploaded": True,
                               "sourceFileChecksum": hashlib.md5(octets).hexdigest()}}})
        ok(f"{locale} : {len(fichiers)} captures téléversées ({TYPE_CAPTURES})")


def main() -> int:
    global JWT, SEC_ARRET
    SEC_ARRET = "--dry-run" in sys.argv

    contenu = textes()
    JWT = jeton()

    etape("Fiche")
    app = trouver_app()
    version = version_en_cours(app)
    ok(f"app {app} · version {version}")

    etape("Informations générales")
    info = categories_et_copyright(app, version)

    etape("Nom, sous-titre, confidentialité")
    for locale, valeurs in contenu.items():
        maj_ou_creer("appInfoLocalizations", "appInfos", info, locale,
                     {"name": NOM_APP, "subtitle": valeurs["subtitle"],
                      "privacyPolicyUrl": URL_CONFIDENTIALITE},
                     relation="appInfo")

    etape("Description, mots-clés, URL")
    for locale, valeurs in contenu.items():
        maj_ou_creer("appStoreVersionLocalizations", "appStoreVersions", version,
                     locale,
                     {"description": valeurs["description"],
                      "keywords": valeurs["keywords"],
                      "promotionalText": valeurs["promotionalText"],
                      "supportUrl": URL_SUPPORT,
                      "marketingUrl": URL_MARKETING},
                     relation="appStoreVersion")

    etape("Captures d'écran")
    captures(version)

    print()
    if SEC_ARRET:
        print("--dry-run : rien n'a été écrit.")
        return 0
    ok("fiche remplie")
    print(f"""
Reste à faire à la main dans App Store Connect — l'API ne les couvre pas :
  1. Confidentialité de l'app → « Nous ne collectons aucune donnée »
  2. Classification par âge → questionnaire tout à « Aucun » → 4+
  3. Tarifs et disponibilité → Gratuit, tous les pays
  4. Statut de professionnel (DSA) → coordonnées de la structure
  5. Sélectionner le build, puis soumettre à la validation
Détail de chaque point : docs/appstore/publication.md, étapes 7 et 10.
https://appstoreconnect.apple.com/apps/{app}""")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as erreur:
        ko(str(erreur))
        sys.exit(1)
