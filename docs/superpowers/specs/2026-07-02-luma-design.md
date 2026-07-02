# Luma — Design

**Date** : 2026-07-02
**Statut** : validé en brainstorming, en attente de relecture finale

## Vue d'ensemble

Luma est une application iOS personnelle (jamais publiée sur l'App Store, buildée directement sur l'iPhone du propriétaire via Xcode) qui sert de posemètre pour un Nikon FM2 argentique. Elle utilise la caméra de l'iPhone pour mesurer la lumière de la scène et propose les réglages à reporter sur le boîtier : ouverture, vitesse d'obturation, avec l'ISO imposé par la pellicule chargée.

L'utilisateur est débutant en photographie argentique. L'app doit donc être simple, claire et légèrement pédagogique, avec un design « moderne léché, vintage chic » directement inspiré du boîtier FM2 chromé.

## Contexte matériel

- **Boîtier** : Nikon FM2. Vitesses mécaniques à cran entier : 1s, 1/2, 1/4, 1/8, 1/15, 1/30, 1/60, 1/125, 1/250, 1/500, 1/1000, 1/2000, 1/4000 (+ pose B, hors périmètre v1).
- **Objectif** : Nikkor 28mm f/2.8. Ouvertures à cran entier : f/2.8, f/4, f/5.6, f/8, f/11, f/16, f/22.
- **Pellicule** : variable (l'utilisateur débute). L'ISO est fixé par le film chargé, pour tout le rouleau.

## Décisions de cadrage (validées)

| Sujet | Décision |
|---|---|
| Périmètre v1 | Posemètre uniquement, aucun extra (pas de journal, pas de compteur de vues) |
| Pellicule / ISO | Liste des films courants (Portra 400, Gold 200, HP5+, Tri-X…) + saisie ISO manuelle ; choix mémorisé |
| Recommandation | Une config idéale mise en avant + molette pour parcourir les paires équivalentes |
| Mesure | Moyenne de la scène par défaut ; toucher une zone = mesure spot ; toucher ailleurs = déplacer le spot ; toucher le cercle = retour en moyenne |
| Pédagogie | Explications légères : une phrase par réglage décrivant son effet concret |
| Direction visuelle | « Chrome & cuir » : argent champagne, noir cuir grainé, rouge FM2 |
| Techno | Swift + SwiftUI + AVFoundation, iOS 17+, projet Xcode natif |

## Écran principal (unique)

De haut en bas :

1. **En-tête** — logo LUMA ; badge de la pellicule chargée (ex. « Portra 400 »), un appui ouvre le `FilmPickerSheet`.
2. **Viseur** — flux caméra en direct. Affiche discrètement le mode de mesure (« MESURE MOYENNE » / « MESURE SPOT ») et l'EV courant. Un toucher place un cercle de mesure spot à l'endroit touché ; toucher un autre endroit déplace le spot ; toucher le cercle lui-même revient en mesure moyenne.
3. **Molette** — rangée horizontale des paires équivalentes (ouverture · vitesse), la paire recommandée encadrée de rouge au centre. Glissement horizontal pour explorer, avec retour haptique « cliquet » à chaque cran, façon molette du FM2. Légende : « ◂ flou d'arrière-plan · netteté partout ▸ ». Un appui sur la paire recommandée (ou un bouton discret) recentre sur la reco.
4. **Recommandation** — les trois valeurs en grand : ouverture, vitesse (en rouge, clin d'œil à la gravure du boîtier), ISO du film.
5. **Pédagogie** — deux lignes : effet de l'ouverture affichée (profondeur de champ) et de la vitesse affichée (mouvement / risque de bougé).

## Cœur du posemètre

### Lecture (CameraService)

`AVCaptureSession` en continu. Par observation clé-valeur sur l'`AVCaptureDevice`, on lit à chaque changement :

- `ISO` et `exposureDuration` choisis par l'autoexposition de l'iPhone ;
- `lensAperture` (fixe, connue par appareil) ;
- `exposureTargetOffset` (écart en EV entre la cible d'exposition et l'obtenu — corrige les scènes extrêmes où l'autoexposition sature). Convention AVFoundation : valeur **négative** = image plus sombre que la cible (scène sous-exposée par la caméra), donc la scène est plus sombre que ce que ISO/durée seuls indiquent — d'où le `+ exposureTargetOffset` dans la formule. Un test unitaire dédié verrouille cette convention de signe.

La mesure spot déplace `exposurePointOfInterest` sur le point touché (converti en coordonnées du device) ; le retour en moyenne le replace au centre avec le mode d'exposition continu.

### Calcul (ExposureCalculator — code pur)

1. **EV de la scène normalisé ISO 100** :
   `EV100 = log2(N² / t) − log2(ISO / 100) + exposureTargetOffset`
   où N = ouverture de l'iPhone, t = temps de pose, ISO = ISO courant de l'iPhone.
2. **Lissage** : moyenne glissante sur les ~10 dernières mesures pour stabiliser l'affichage.
3. **Paires FM2** : pour l'ISO du film, `EVfilm = EV100 + log2(ISOfilm / 100)`. On énumère les combinaisons (7 ouvertures × 13 vitesses) et on retient celles dont l'exposition est à moins de ½ EV de la cible, ordonnées de la plus ouverte à la plus fermée.
4. **Choix de la recommandation** (priorités dans l'ordre) :
   - vitesse ≥ 1/125 (marge confortable contre le flou de bougé avec un 28mm à main levée) ;
   - ouverture dans la zone f/5.6–f/8 (piqué optimal de l'objectif) ;
   - si la lumière manque : ouvrir le diaphragme d'abord, ne descendre sous 1/125 qu'en dernier recours ;
   - **départage déterministe** si plusieurs paires restent candidates : la plus proche du cœur de la zone f/5.6–f/8 (f/6.7 en stops, de sorte que f/5.6 passe avant f/11), puis la vitesse la plus basse ≥ 1/125.
5. **Cas hors plage** :
   - trop sombre (même f/2.8 à 1s sous-expose de plus de ½ EV) → message « Trop sombre pour le FM2 à main levée » ;
   - trop lumineux (même f/22 à 1/4000 surexpose de plus de ½ EV) → message « Trop lumineux pour cette pellicule ».
   Dans les deux cas, aucune config n'est affichée : jamais de recommandation mensongère.

### Pédagogie

Deux tables statiques associent une phrase courte à chaque cran :

- ouverture → profondeur de champ (« f/2.8 — sujet isolé, arrière-plan très flou » … « f/22 — tout net, du premier plan à l'infini ») ;
- vitesse → mouvement (« 1/1000 — fige un sujet rapide » … « 1/30 — risque de flou, cale tes coudes »).

## Architecture

```
Luma/ (projet Xcode, SwiftUI, iOS 17+)
├── LumaApp.swift            — point d'entrée
├── Services/
│   └── CameraService.swift  — AVFoundation : session, ExposureReading, spot
├── Core/
│   ├── ExposureCalculator.swift — EV, paires FM2, recommandation (pur)
│   ├── FM2.swift            — constantes : vitesses FM2, ouvertures 28mm
│   └── FilmStock.swift      — catalogue pellicules + ISO manuel
│                              (catalogue v1 : Portra 160/400/800, Ektar 100,
│                               Gold 200, UltraMax 400, HP5+ 400, Tri-X 400,
│                               Delta 100/400, Fomapan 100/400)
├── Views/
│   ├── MeterView.swift          — écran principal, composition
│   ├── ViewfinderView.swift     — preview caméra + geste de mesure
│   ├── DialView.swift           — molette haptique des paires
│   ├── RecommendationView.swift — les trois valeurs + pédagogie
│   ├── FilmPickerSheet.swift    — choix du film / ISO
│   └── CameraDeniedView.swift   — permission refusée
├── Theme.swift              — palette Chrome & cuir, typographie
└── Tests/
    └── ExposureCalculatorTests.swift
```

**Flux de données à sens unique** : `CameraService` publie des `ExposureReading` → `ExposureCalculator` produit une `Recommendation` (paires + reco + messages) → les vues affichent. La pellicule choisie est persistée dans `UserDefaults`. Aucune autre persistance en v1.

## Gestion d'erreurs

- **Permission caméra refusée** → `CameraDeniedView` : explication + bouton vers Réglages.
- **Pas de caméra** (preview Xcode, simulateur) → mode démo avec EV fixe injecté, pour développer l'interface.
- **Scène hors plage** → messages explicites (voir Cœur du posemètre), jamais de valeurs fausses.

## Tests

- **Tests unitaires** sur `ExposureCalculator` : conversion EV, décalage ISO film, énumération des paires, règle de choix de la reco, arrondis aux crans, cas hors plage (trop sombre / trop lumineux), lissage.
- **Vérification manuelle** sur iPhone pour la caméra, les gestes et le rendu visuel — app personnelle, on ne sur-teste pas l'UI. Test de plausibilité recommandé : comparer les recommandations de Luma au posemètre intégré du FM2 sur quelques scènes.

## Identité visuelle — logo « Diaphragme »

Choisi parmi quatre pistes (iris minimal, diaphragme, profil d'objectif, réticule) : un **iris à 7 lamelles** vu de face — 7 comme les crans d'ouverture du 28mm — avec un **cœur rouge** (le point de mesure). Géométrie de référence en espace 100×100 : fût = cercle r40 (trait centré) ; lamelle = segment (50,36)→(78.4,27.8) répété par rotation de 360/7° ; cœur r5. Les épaisseurs de trait diffèrent volontairement entre les deux rendus (compensation optique) : icône 1024 px = fût 5, lamelles 3.5, cœur r5 ; vue in-app ~20 pt = fût 7, lamelles 5, cœur r5.5.

- **Dans l'app** : `LumaLogo` (vue SwiftUI vectorielle, `Luma/Views/LumaLogo.swift`), encre sur champagne, 20 pt, à gauche du mot LUMA dans l'en-tête.
- **Icône d'app** : crème sur dégradé cuir noir, 1024×1024, générée par `scripts/generate-appicon.swift` (CoreGraphics, même géométrie) dans `Luma/Assets.xcassets/AppIcon.appiconset/`. Nom affiché sous l'icône : **LUMA** (`CFBundleDisplayName`).

## Hors périmètre v1

Journal de prises de vue, compteur de vues du rouleau, pose B et temps de pose longs (réciprocité), support multi-objectifs (la plage f/2.8–f/22 du 28mm est une constante ; prévoir la constante isolée dans `FM2.swift` pour la rendre configurable plus tard).

## Distribution

Build direct sur l'iPhone via Xcode (compte Apple gratuit : re-signature nécessaire tous les 7 jours ; compte développeur payant : 1 an).
