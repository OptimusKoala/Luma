#!/usr/bin/env python3
"""Récupère les photos de scène des captures App Store depuis Wikimedia Commons.

    python3 scripts/photos-scenes.py --chercher "sunny meadow"   # explorer
    python3 scripts/photos-scenes.py                             # télécharger

Pourquoi Commons, et pourquoi seulement une partie de son catalogue : une capture
d'écran App Store est un usage **commercial** et **sans crédit visible possible**.
Ne conviennent donc que le domaine public et la CC0, qui n'exigent ni permission
ni attribution. Toute image sous CC-BY, CC-BY-SA ou licence maison est écartée
automatiquement par ce script, licence vérifiée par l'API et non à l'œil.

La provenance de chaque image retenue est écrite dans
docs/appstore/captures/scenes/CREDITS.md — même sans obligation légale, savoir
d'où vient un fichier est la moindre des choses.
"""

from __future__ import annotations

import json
import sys
import urllib.parse
import urllib.request
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
DESTINATION = RACINE / "docs" / "appstore" / "captures" / "scenes"
API = "https://commons.wikimedia.org/w/api.php"
AGENT = "Luma-screenshots/1.0 (https://github.com/OptimusKoala/Luma)"

# Licences acceptables : rien d'autre ne permet un usage commercial sans crédit.
LICENCES_OK = {"cc0", "pd"}
NOMS_OK = ("cc0", "public domain", "publicdomain", "pd-")

# Chaque scène pointe le fichier Commons retenu, avec l'EV que l'app affichera.
# Le titre est celui du fichier sur Commons, sans le préfixe « File: ».
SCENES = {
    # L'EV affiché doit rester crédible pour la lumière de la photo : une scène
    # nocturne éclairée est vers EV 4, où l'app donnerait f/2.8 · 1/8 et non un
    # refus. Seul un ciel étoilé est authentiquement sous la plage du boîtier.
    "plein-jour":  "Adventure-Clouds-Conifers-Daylight-350418.jpg",   # EV 14
    "molette":     "Boat 2 0 (215416413).jpeg",                       # EV 12
    "pellicule":   "Hügel neben Kohlbergböschung Pirna 2018.jpg",     # EV 13
    "spot":        "Sunset backlight of dates.jpg",                   # EV 13
    "trop-sombre": "Stars and Milky Way at Holma Marina 1.jpg",       # EV -3
}


def api(parametres: dict) -> dict:
    parametres = {**parametres, "format": "json", "formatversion": "2"}
    url = f"{API}?{urllib.parse.urlencode(parametres)}"
    requete = urllib.request.Request(url, headers={"User-Agent": AGENT})
    with urllib.request.urlopen(requete) as reponse:
        return json.load(reponse)


def licence_libre(meta: dict) -> tuple[bool, str]:
    """(acceptable, libellé) d'après les métadonnées Commons."""
    code = (meta.get("License", {}).get("value") or "").lower()
    nom = (meta.get("LicenseShortName", {}).get("value") or "").lower()
    libelle = meta.get("LicenseShortName", {}).get("value") or code or "?"
    if code in LICENCES_OK:
        return True, libelle
    if any(marqueur in nom for marqueur in NOMS_OK):
        return True, libelle
    return False, libelle


def chercher(requete: str, limite: int = 12) -> list[dict]:
    doc = api({
        "action": "query", "generator": "search",
        "gsrsearch": f"filetype:bitmap {requete}",
        "gsrnamespace": "6", "gsrlimit": str(limite),
        "prop": "imageinfo",
        "iiprop": "url|size|extmetadata",
        "iiurlwidth": "1400",
    })
    resultats = []
    for page in doc.get("query", {}).get("pages", []):
        info = (page.get("imageinfo") or [{}])[0]
        meta = info.get("extmetadata", {})
        libre, libelle = licence_libre(meta)
        resultats.append({
            "titre": page["title"].removeprefix("File:"),
            "libre": libre,
            "licence": libelle,
            "auteur": (meta.get("Artist", {}).get("value") or "?")[:60],
            "largeur": info.get("width"), "hauteur": info.get("height"),
            "vignette": info.get("thumburl"),
            "page": info.get("descriptionurl"),
        })
    return resultats


def details(titre: str) -> dict:
    doc = api({
        "action": "query", "titles": f"File:{titre}",
        "prop": "imageinfo", "iiprop": "url|size|extmetadata",
        "iiurlwidth": "1400",
    })
    page = doc["query"]["pages"][0]
    if "imageinfo" not in page:
        raise RuntimeError(f"fichier introuvable sur Commons : {titre}")
    return page["imageinfo"][0]


def telecharger() -> int:
    manquants = [nom for nom, titre in SCENES.items() if not titre]
    if manquants:
        print("Aucun fichier choisi pour :", ", ".join(manquants), file=sys.stderr)
        print("Renseigne SCENES dans ce script, ou explore avec --chercher.",
              file=sys.stderr)
        return 2

    DESTINATION.mkdir(parents=True, exist_ok=True)
    credits = ["# Photos des scènes de capture",
               "",
               "Images utilisées dans le viseur des captures d'écran App Store.",
               "**Domaine public ou CC0 exclusivement** : une capture App Store est",
               "un usage commercial sans crédit visible possible, ce que les licences",
               "à attribution n'autorisent pas. Licence vérifiée par l'API Commons",
               "(`scripts/photos-scenes.py`), pas à l'œil.",
               ""]

    for scene, titre in SCENES.items():
        info = details(titre)
        libre, libelle = licence_libre(info.get("extmetadata", {}))
        if not libre:
            print(f"✗ {scene} : licence « {libelle} » refusée pour {titre}",
                  file=sys.stderr)
            return 1

        url = info.get("thumburl") or info["url"]
        requete = urllib.request.Request(url, headers={"User-Agent": AGENT})
        with urllib.request.urlopen(requete) as reponse:
            octets = reponse.read()
        cible = DESTINATION / f"{scene}.jpg"
        cible.write_bytes(octets)
        print(f"✓ {scene:12} {len(octets)//1024:>5} Ko  {libelle:16} {titre[:52]}")

        meta = info.get("extmetadata", {})
        auteur = (meta.get("Artist", {}).get("value") or "auteur non précisé")
        # Les métadonnées Commons contiennent du HTML : on le réduit au texte.
        for balise in ("<", ">"):
            if balise in auteur:
                import re
                auteur = re.sub(r"<[^>]+>", "", auteur).strip()
                break
        credits += [f"## `{scene}.jpg`", "",
                    f"- Fichier Commons : [{titre}]({info['descriptionurl']})",
                    f"- Auteur : {auteur}",
                    f"- Licence : **{libelle}**", ""]

    (DESTINATION / "CREDITS.md").write_text("\n".join(credits), encoding="utf-8")
    print(f"\n✓ {len(SCENES)} photos et CREDITS.md dans {DESTINATION.relative_to(RACINE)}")
    return 0


def main() -> int:
    if "--chercher" in sys.argv:
        requete = sys.argv[sys.argv.index("--chercher") + 1]
        for element in chercher(requete):
            marque = "✓" if element["libre"] else "·"
            print(f"{marque} {element['licence'][:14]:14} "
                  f"{element['largeur']}×{element['hauteur']:<6} "
                  f"{element['titre'][:64]}")
        return 0
    return telecharger()


if __name__ == "__main__":
    try:
        sys.exit(main())
    except RuntimeError as erreur:
        print(f"✗ {erreur}", file=sys.stderr)
        sys.exit(1)
