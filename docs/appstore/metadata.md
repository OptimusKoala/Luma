# Fiche App Store — Luma · Light Meter

Tout le texte à coller dans App Store Connect, prêt à l'emploi. Les limites Apple
sont indiquées entre parenthèses ; les longueurs réelles sont vérifiables avec
`python3 scripts/check-metadata.py`.

---

## 1. Informations générales (une seule fois, pas par langue)

| Champ App Store Connect | Valeur |
|---|---|
| **Nom de l'app** (30) | `Luma · Light Meter` |
| **Bundle ID** | `com.michaelbernard69.Luma` |
| **SKU** | `LUMA-IOS-001` |
| **Langue principale** | Français (France) |
| **Catégorie principale** | Photo et vidéo |
| **Catégorie secondaire** | Utilitaires |
| **Droits d'auteur** | `2026 Michaël Bernard` |
| **Classification par âge** | 4+ (voir §5) |
| **Prix** | Gratuit |
| **Disponibilité** | Tous les pays et régions |
| **Achats intégrés** | Aucun |
| **Contact pour la validation** | `contact@elitedangereuse.fr` |
| **URL de politique de confidentialité** | `https://optimuskoala.github.io/Luma/privacy.html` |
| **URL de support** | `https://optimuskoala.github.io/Luma/support.html` |
| **URL marketing** (optionnel) | `https://optimuskoala.github.io/Luma/` |

> Le « · » du nom est un point médian (U+00B7), autorisé par Apple. Si le nom est
> refusé pour cause de similarité avec un autre éditeur, replis dans l'ordre :
> `Luma Posemètre`, `Luma — Posemètre argentique`, `Luma Film Light Meter`.

---

## 2. Fiche française (langue principale)

### Sous-titre (30)

```
Posemètre pour argentique
```

### Texte promotionnel (170) — modifiable sans nouvelle validation

```
Un écran, trois valeurs : l'ouverture, la vitesse et l'ISO à reporter sur ton boîtier. Mesure en direct, molette haptique, et un franc « hors plage » le cas échéant.
```

### Mots-clés (100)

Séparés par des virgules **sans espace** : chaque espace superflu mange le quota.
Ni « luma » (le nom est déjà indexé), ni « nikon » / « fm2 » (marques d'un tiers —
motif de refus dans les mots-clés, alors que la mention en description est admise).

```
posemètre,argentique,pellicule,exposition,cellule,photo,film,diaphragme,ouverture,vitesse,ISO,EV
```

### Description (4000)

```
Un boîtier mécanique ne pardonne pas une erreur d'exposition : sur un rouleau de 36 poses, on ne voit ses ratés qu'au développement. Luma répond à la seule question qui compte au moment de déclencher — quelle ouverture, quelle vitesse, pour cette scène et cette pellicule ?

Pas de journal de prises, pas de compteur de vues, pas de réglages cachés. Un écran, trois valeurs.

MESURE EN DIRECT
La caméra de l'iPhone sert de cellule. Luma lit en continu l'exposition choisie par l'appareil et la convertit en EV normalisé ISO 100, lissé pour un affichage stable. Aucune photo n'est enregistrée : l'image est analysée puis oubliée.

UNE RECOMMANDATION, PAS UNE LISTE
Luma affiche une seule configuration, choisie pour la photo à main levée : vitesse d'au moins 1/125 s pour éviter le flou de bougé, puis ouverture entre f/5,6 et f/8 là où l'objectif est le plus piqué. Quand la lumière manque, elle ouvre le diaphragme avant de descendre en vitesse.

LA MOLETTE
Toutes les paires ouverture/vitesse donnant la même exposition défilent sous le doigt, avec un retour haptique en cliquet — comme le barillet du boîtier. Choisis f/2,8 pour détacher un portrait, f/16 pour un paysage net de bout en bout : la vitesse suit.

MESURE SPOT
Un toucher dans le viseur place le cercle de mesure sur ton sujet — un visage en contre-jour, une ombre à préserver. Touche le cercle pour revenir en mesure moyenne.

ELLE REFUSE DE MENTIR
Si la scène sort de la plage du boîtier, Luma le dit — « trop sombre », « trop lumineux » — et n'affiche aucune valeur. Une recommandation fausse serait pire que pas de recommandation.

ELLE EXPLIQUE
Deux lignes sous les valeurs : ce que l'ouverture affichée fait à la profondeur de champ, ce que la vitesse affichée implique comme risque de bougé. De quoi progresser rouleau après rouleau.

PELLICULES
Portra 160/400/800, Ektar 100, Gold 200, UltraMax 400, HP5+ 400, Tri-X 400, Delta 100/400, Fomapan 100/400 — et la saisie d'un ISO manuel pour tout le reste, y compris un film poussé ou retenu. Le choix reste mémorisé pour tout le rouleau.

CONÇUE POUR UN BOÎTIER PRÉCIS
Luma est calibrée pour un Nikon FM2 avec un Nikkor 28 mm f/2,8 : vitesses de 1 s à 1/4000 s, ouvertures de f/2,8 à f/22. Elle rend le même service sur tout appareil manuel partageant cette plage — il suffit de reporter les valeurs sur les crans de ton matériel. Projet indépendant, non affilié à Nikon ; les marques citées le sont à seule fin de décrire la compatibilité.

SANS RIEN DEMANDER
Pas de compte, pas de publicité, aucune connexion réseau : Luma fonctionne intégralement hors ligne et ne collecte aucune donnée. Gratuite, sans achat intégré, code source public.

Luma est une aide, pas une garantie : avant de lui confier un rouleau, compare ses recommandations à celles d'un posemètre de référence sur quelques scènes.
```

---

## 3. Fiche anglaise (English U.S.)

### Subtitle (30)

```
Light meter for film cameras
```

### Promotional text (170)

```
One screen, three values: the aperture, shutter speed and ISO to dial in on your camera. Live metering, a haptic dial, and an honest "out of range" when it is.
```

### Keywords (100)

```
light meter,film,analog,analogue,exposure,photography,aperture,shutter,vintage,35mm,ISO,EV
```

### Description (4000)

```
A mechanical camera does not forgive an exposure mistake: on a roll of 36, you only see your misses at the lab. Luma answers the one question that matters as you raise the camera — which aperture, which shutter speed, for this scene and this film?

No shot log, no frame counter, no hidden settings. One screen, three values.

LIVE METERING
Your iPhone's camera becomes the meter. Luma continuously reads the exposure the phone settles on and converts it into an ISO 100 normalised EV, smoothed for a stable reading. No photo is ever saved: the image is analysed, then forgotten.

ONE RECOMMENDATION, NOT A LIST
Luma shows a single aperture and shutter pair, chosen for handheld shooting: at least 1/125 s to stay clear of camera shake, then f/5.6 to f/8 where the lens is sharpest. When light runs short, it opens the aperture before slowing the shutter.

THE DIAL
Every equivalent aperture / shutter pair scrolls under your thumb with clicking haptic feedback, like the shutter dial on the body. Pick f/2.8 to lift a portrait off its background, f/16 for a landscape sharp front to back — the shutter speed follows.

SPOT METERING
Tap the viewfinder to place the metering circle on your subject: a backlit face, a shadow worth keeping. Tap the circle to return to average metering.

IT REFUSES TO LIE
When the scene falls outside the camera's range, Luma says so — too dark, too bright — and shows no values at all. A wrong recommendation would be worse than none.

IT EXPLAINS
Two lines under the values: what the shown aperture does to depth of field, what the shown shutter speed means for shake. Enough to learn, roll after roll.

FILM STOCKS
Portra 160/400/800, Ektar 100, Gold 200, UltraMax 400, HP5+ 400, Tri-X 400, Delta 100/400, Fomapan 100/400 — plus manual ISO entry for everything else, including pushed or pulled film. Your choice stays loaded for the whole roll.

BUILT FOR A SPECIFIC CAMERA
Luma is calibrated for a Nikon FM2 with a 28 mm f/2.8 lens: 1 s to 1/4000 s, f/2.8 to f/22. It serves any manual camera sharing that range just as well — simply transfer the values to the stops your gear actually has. Independent project, not affiliated with Nikon; trademarks are named only to describe compatibility.

IT ASKS FOR NOTHING
No account, no ads, no network access: Luma works fully offline and collects no data whatsoever. Free, no in-app purchases, open source.

Please note: the app's interface is in French.

Luma is an aid, not a guarantee — cross-check it against a reference meter on a few scenes before trusting it with a roll.
```

---

## 4. Réponses au questionnaire « Confidentialité de l'app »

Section **Confidentialité de l'app** d'App Store Connect :

1. « Collectez-vous des données de cette app ? » → **Non, nous ne collectons aucune donnée de cette app.**

C'est la seule réponse à donner, et elle est exacte : la caméra est lue en mémoire
sans enregistrement, la pellicule choisie reste dans `UserDefaults` sur l'appareil,
et l'app n'a aucune fonction réseau. Le fichier `Luma/PrivacyInfo.xcprivacy` déclare
en parallèle l'usage de `UserDefaults` avec la raison `CA92.1` (accès aux
informations de cette app uniquement).

---

## 5. Réponses au questionnaire de classification par âge

Tout à **Aucun / Non**, ce qui donne **4+** :

- Violence (dessinée, réaliste, prolongée) : Aucune
- Contenu sexuel, nudité, thèmes suggestifs : Aucun
- Blasphème, humour grossier : Aucun
- Alcool, tabac, drogues : Aucun
- Jeux d'argent (réels ou simulés) : Non
- Concours : Non
- Horreur, thèmes effrayants : Aucun
- Contenu web illimité : Non
- Fonctionnalités sociales, partage de position, messagerie : Non
- Publicité ciblée : Non
- Achats intégrés : Non

---

## 6. Notes pour l'équipe de validation (« App Review Information »)

Pas d'identifiants de test à fournir : l'app n'a ni compte ni connexion.
Coller ce texte dans **Notes** :

```
Luma est un posemètre pour appareils photo argentiques à réglage manuel.

TEST DE L'APP
1. Autoriser l'accès à la caméra à l'ouverture : la caméra est le capteur de lumière de l'app, il n'y a pas de mesure possible sans elle.
2. Pointer l'iPhone vers n'importe quelle scène. Les trois valeurs (ouverture, vitesse, ISO) s'affichent en bas et se mettent à jour en direct.
3. Faire glisser la molette horizontale pour parcourir les paires ouverture/vitesse équivalentes.
4. Toucher le viseur pour passer en mesure spot ; toucher le cercle pour revenir en mesure moyenne.
5. Appuyer sur le badge en haut de l'écran pour changer de pellicule.
Note : sous une lumière très faible ou très forte, l'app affiche volontairement « Trop sombre » / « Trop lumineux » sans aucune valeur. C'est le comportement attendu, pas un bug : la scène sort de la plage de l'appareil argentique visé.

CAMÉRA ET DONNÉES
L'app lit l'exposition automatique de la caméra en mémoire pour en déduire la luminosité de la scène. Aucune image n'est enregistrée ni transmise, et l'app n'a aucune fonctionnalité réseau : elle fonctionne intégralement hors ligne. Aucun compte, aucune donnée collectée. La seule donnée persistée est la pellicule sélectionnée, dans UserDefaults.

MARQUES CITÉES
L'app est calibrée pour un Nikon FM2 avec un objectif 28 mm f/2,8. Il s'agit d'un projet indépendant, non affilié à Nikon Corporation. Les noms « Nikon », « FM2 » et « Nikkor » n'apparaissent ni dans le nom de l'app ni dans les mots-clés ; ils sont uniquement mentionnés dans la description et dans l'app pour décrire la compatibilité matérielle.

LANGUE
L'interface de l'app est en français. La fiche anglaise le signale explicitement.

Le code source est public : https://github.com/OptimusKoala/Luma
```

---

## 7. Captures d'écran

Apple exige au minimum une série pour l'iPhone **6,9"** (1290 × 2796 px, portrait).
Elle est réutilisée automatiquement pour toutes les autres tailles d'iPhone.
Voir `scripts/screenshots.sh` : il capture l'écran de l'iPhone connecté et
redimensionne au format exigé.

Trois à cinq captures suffisent. Ordre conseillé (la première est celle qu'on voit
dans les résultats de recherche) :

| # | Scène à photographier | Ce qu'elle montre |
|---|---|---|
| 1 | Extérieur en plein jour, sujet net | L'écran complet : viseur, molette, les trois valeurs |
| 2 | La molette en cours de glissement | Les paires équivalentes |
| 3 | Le sélecteur de pellicule ouvert | Le catalogue de films |
| 4 | Mesure spot sur un sujet en contre-jour | Le cercle de mesure et `MESURE SPOT` |
| 5 | Scène très sombre | Le message « Trop sombre », l'honnêteté de l'app |

Les captures peuvent rester en français, même pour la fiche anglaise (Apple
l'accepte ; on peut aussi ne fournir qu'un seul jeu partagé entre les deux langues).

Aucune obligation de vidéo de prévisualisation (« app preview »).
