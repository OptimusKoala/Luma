#!/usr/bin/env python3
"""Vérifie que les textes de la fiche App Store respectent les limites d'Apple.

Usage : python3 scripts/check-metadata.py

Lit docs/appstore/metadata.md. Toute section dont le titre contient une limite
entre parenthèses — par exemple « ### Sous-titre (30) » — voit le bloc de code
qui la suit mesuré en caractères. Sort en erreur si une limite est dépassée,
pour pouvoir être branché sur un pré-commit ou une CI.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

RACINE = Path(__file__).resolve().parent.parent
FICHE = RACINE / "docs" / "appstore" / "metadata.md"

# « ### Sous-titre (30) », « ### Description (4000) »…
TITRE_AVEC_LIMITE = re.compile(r"^#{2,4}\s+(?P<label>[^(]+?)\s*\((?P<limite>\d+)\)")
CLOTURE = re.compile(r"^```")


def sections(texte: str) -> list[tuple[str, int, str]]:
    """Renvoie (label, limite, contenu) pour chaque section limitée."""
    trouvees: list[tuple[str, int, str]] = []
    label: str | None = None
    limite = 0
    dans_bloc = False
    tampon: list[str] = []

    for ligne in texte.splitlines():
        if dans_bloc:
            if CLOTURE.match(ligne):
                dans_bloc = False
                trouvees.append((label, limite, "\n".join(tampon)))
                label, tampon = None, []
            else:
                tampon.append(ligne)
            continue

        entete = TITRE_AVEC_LIMITE.match(ligne)
        if entete:
            label = entete.group("label").strip()
            limite = int(entete.group("limite"))
            continue

        # Premier bloc de code rencontré après un titre limité : c'est le contenu.
        if label and CLOTURE.match(ligne):
            dans_bloc = True

    return trouvees


def main() -> int:
    if not FICHE.exists():
        print(f"✗ fiche introuvable : {FICHE}", file=sys.stderr)
        return 2

    texte = FICHE.read_text(encoding="utf-8")
    trouvees = sections(texte)
    if not trouvees:
        print("✗ aucune section à limite trouvée — le format de la fiche a changé ?",
              file=sys.stderr)
        return 2

    echecs = 0
    for label, limite, contenu in trouvees:
        n = len(contenu)
        etat = "✓" if n <= limite else "✗"
        if n > limite:
            echecs += 1
        print(f"{etat} {label:<24} {n:>5} / {limite} caractères")

        # Les mots-clés App Store se séparent par des virgules sans espace :
        # chaque espace superflu est décompté du quota de 100.
        if "ots-clé" in label or "eyword" in label:
            if ", " in contenu:
                print("  ↳ ✗ espace après une virgule : il gaspille le quota",
                      file=sys.stderr)
                echecs += 1
            if "\n" in contenu:
                print("  ↳ ✗ les mots-clés doivent tenir sur une seule ligne",
                      file=sys.stderr)
                echecs += 1

    print()
    if echecs:
        print(f"✗ {echecs} problème(s) à corriger avant de coller dans App Store Connect")
        return 1
    print(f"✓ {len(trouvees)} champs dans les limites")
    return 0


if __name__ == "__main__":
    sys.exit(main())
