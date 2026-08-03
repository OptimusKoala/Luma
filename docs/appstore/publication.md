# Publier Luma sur l'App Store — marche à suivre

Ce que le dépôt fait déjà pour toi, et ce que toi seul peux faire (tout ce qui
passe par un site Apple ou par ton iPhone). Les étapes sont dans l'ordre :
chacune suppose la précédente faite.

Compte à prévoir : **1 à 2 h de manipulations**, puis 24 à 48 h de validation
par Apple.

| Étape | Où | Fait par |
|---|---|---|
| 1. Team ID ✅ · certificat de distribution | Xcode | toi |
| 2. Identifiant d'app (App ID) | developer.apple.com | toi |
| 3. ~~Publier les pages web~~ | github.com | ✅ fait |
| 4. Clé d'API App Store Connect | App Store Connect | toi |
| 5. Créer la fiche de l'app | App Store Connect | toi |
| 6. Captures d'écran | ton iPhone + `scripts/screenshots.sh` | toi + script |
| 7. Remplir la fiche | App Store Connect | toi (textes prêts) |
| 8. Envoyer le build | `scripts/release.sh` | script |
| 9. Vérifier via TestFlight | ton iPhone | toi |
| 10. Soumettre à la validation | App Store Connect | toi |

---

## 1. Team ID ✅ et certificat de distribution

Le Team ID du compte payant, **`AXVF69V3LL`**, est déjà en place dans
[`project.yml`](../../project.yml) — c'est le seul endroit du projet qui le porte,
et `scripts/release.sh` refuse de démarrer si `release.env` ne dit pas la même
chose.

**Il reste le certificat de distribution.** Cette équipe est pour l'instant
inconnue de ce Mac : ni certificat, ni profil de provisionnement. Dans Xcode :

1. **Xcode → Settings → Accounts** : ajoute l'Apple ID du compte payant s'il n'y
   figure pas (mot de passe + double authentification, donc à faire toi-même).
2. Sélectionne l'équipe `AXVF69V3LL`, puis **Manage Certificates → + → Apple
   Distribution**.

C'est le certificat qui signe les builds destinés à l'App Store ; sans lui,
l'étape d'archive échoue. `release.sh` prévient dès le départ s'il ne le trouve
pas — en simple avertissement, parce que la signature automatique sait aussi
utiliser un certificat géré par Apple dans le nuage.

> Le compte payant supprime au passage la limite des 7 jours : une app installée
> depuis Xcode reste valide un an au lieu d'expirer chaque semaine.

## 2. Identifiant d'app (App ID)

<https://developer.apple.com/account/resources/identifiers/list>

**+** → **App IDs** → **App** → puis :

| Champ | Valeur |
|---|---|
| Description | `Luma` |
| Bundle ID | **Explicit** → `com.michaelbernard69.Luma` |
| Capabilities | aucune à cocher |

L'accès à la caméra n'est pas une « capability » : il se déclare par la clé
`NSCameraUsageDescription` de l'`Info.plist`, déjà en place.

> Ce bundle ID est celui que tu utilises déjà sur ton iPhone : garde-le à
> l'identique, sinon l'app publiée sera considérée comme une app différente.

## 3. Pages web — ✅ en ligne

Apple exige une **URL de politique de confidentialité** publique et une **URL de
support** joignable. Les deux sont déjà en ligne, servies par GitHub Pages depuis
la branche `main`, dossier `/docs` :

- <https://optimuskoala.github.io/Luma/>
- <https://optimuskoala.github.io/Luma/privacy.html>
- <https://optimuskoala.github.io/Luma/support.html>

Toute modification de ces fichiers est publiée par un simple `git push` ; compter
une à deux minutes de reconstruction. Le fichier `docs/.nojekyll` sert les pages
telles quelles, sans traitement Jekyll.

> Pages n'est gratuit que sur un dépôt **public** : c'est la raison du passage du
> dépôt en public le 2026-08-03. Si tu le repasses en privé, les trois URL
> tombent — et la fiche App Store devient invalide.

Ces pages affichent `contact@elitedangereuse.fr` comme adresse de support :
vérifie qu'elle reçoit bien, c'est par là qu'Apple et les utilisateurs te
joindront. Pour la changer, elle apparaît deux fois dans chacune des deux pages.

## 4. Clé d'API App Store Connect

Elle permet à `scripts/release.sh` d'envoyer le build sans passer par l'interface
de Xcode.

1. <https://appstoreconnect.apple.com> → **Utilisateurs et accès** →
   **Intégrations** → **App Store Connect API** → onglet **Clés d'équipe**.
2. **+**, nomme la clé (`Luma release`), rôle **App Manager**, puis **Générer**.
3. **Télécharge le fichier `.p8` immédiatement** : Apple ne le propose qu'une
   seule fois. Range-le là où les outils Apple le cherchent :

   ```bash
   mkdir -p ~/.appstoreconnect/private_keys
   mv ~/Downloads/AuthKey_XXXXXXXXXX.p8 ~/.appstoreconnect/private_keys/
   ```

4. Relève le **Key ID** (sur la ligne de la clé) et l'**Issuer ID** (au-dessus
   du tableau, commun à toutes les clés).
5. Renseigne le tout :

   ```bash
   cp scripts/release.env.example scripts/release.env
   ```

   Puis ouvre `scripts/release.env` et remplis les quatre valeurs. Ce fichier est
   gitignoré : il ne partira jamais sur GitHub.

## 5. Créer la fiche de l'app

App Store Connect → **Apps** → **+** → **Nouvelle app** :

| Champ | Valeur |
|---|---|
| Plateformes | iOS |
| Nom | `Luma · Light Meter` |
| Langue principale | Français (France) |
| Bundle ID | `com.michaelbernard69.Luma` |
| SKU | `LUMA-IOS-001` |
| Accès utilisateur | Accès complet |

Si le nom est refusé comme déjà pris, [`metadata.md`](metadata.md) propose des
replis dans l'ordre. Le nom n'est réservé qu'au moment de cette création.

Ensuite, ajoute l'anglais : en haut de la page de la version, menu **Français
(France)** → **Ajouter une langue** → **Anglais (É.-U.)**.

## 6. Captures d'écran

Le simulateur n'a pas de caméra : Luma y afficherait un viseur noir. Les captures
se prennent donc sur ton iPhone, sur des scènes réelles.

1. Ouvre Luma sur ton iPhone et fais tes captures (**bouton latéral + volume
   haut**). [`metadata.md`](metadata.md) §7 propose cinq scènes, dans l'ordre.
2. Envoie-les sur le Mac par AirDrop.
3. Dépose-les dans `docs/appstore/captures/brutes/` en les nommant `01-…`,
   `02-…` : cet ordre sera celui de la fiche.
4. ```bash
   ./scripts/screenshots.sh
   ```

Le script les met au format exigé par Apple pour le créneau **6,9"**
(1290 × 2796 px) : mise à l'échelle sans déformation, recadrage au centre de
l'excédent (une dizaine de pixels), vérification de l'absence de canal alpha —
qu'Apple refuse. Résultat dans `docs/appstore/captures/6.9/`.

Une seule série suffit : Apple la réduit automatiquement pour les autres tailles
d'iPhone. Les captures en français conviennent aussi pour la fiche anglaise.

## 7. Remplir la fiche

Tout le texte est prêt dans [`metadata.md`](metadata.md), déjà vérifié contre les
limites de caractères d'Apple (`python3 scripts/check-metadata.py`). Sections à
remplir :

- **Fiche française** puis **anglaise** : sous-titre, texte promotionnel,
  mots-clés, description, captures d'écran.
- **Informations générales** : catégories (Photo et vidéo / Utilitaires), droits
  d'auteur, URL de support et de confidentialité.
- **Confidentialité de l'app** → « Nous ne collectons aucune donnée » (§4 de
  `metadata.md`, avec la justification).
- **Classification par âge** → questionnaire tout à « Aucun » → 4+ (§5).
- **Tarifs et disponibilité** → **Gratuit**, tous les pays. Une app gratuite sans
  achat intégré ne demande **ni coordonnées bancaires ni formulaire fiscal**.
- **Informations pour la validation** → coller les notes du §6 ; aucun identifiant
  de test à fournir, l'app n'a pas de compte.
- **Droits sur le contenu** → l'app ne contient aucun contenu de tiers.

### Statut de « professionnel » (obligatoire pour l'UE)

Apple demande à **tout** développeur de déclarer un statut de professionnel
(*trader*), au titre du règlement européen sur les services numériques (DSA).
Sans déclaration, l'app est retirée des boutiques de l'Union européenne.

**Utilisateurs et accès → Informations de conformité → Statut de professionnel.**

D'après Apple, tu n'es probablement **pas** un professionnel si tu agis « à des
fins qui n'entrent pas dans le cadre de ton activité commerciale, industrielle,
artisanale ou libérale » — le cas d'un projet personnel gratuit, développé sans
intention de le commercialiser. Deux conséquences concrètes :

- **Non professionnel** : aucune coordonnée personnelle publiée. Les
  utilisateurs de l'UE sont informés que les droits de la consommation ne
  s'appliquent pas au contrat qui les lie à toi.
- **Professionnel** : nom, adresse postale, téléphone et e-mail sont **affichés
  publiquement** sur la page de l'app, et vérifiés par Apple.

**Choix retenu pour Luma : « This is not a trader account »** — l'app est
gratuite, sans monétisation d'aucune sorte, ce qui correspond à la définition du
non-professionnel, et aucune coordonnée personnelle n'est alors publiée. Cette
déclaration t'engage : si un jour tu monétises l'app, il faudra la mettre à jour.

## 8. Envoyer le build

```bash
./scripts/release.sh
```

Le script enchaîne : vérification de la configuration → régénération du projet →
tests unitaires → archive en Release → export du `.ipa` signé → validation par
Apple → **confirmation demandée** → envoi.

Options utiles : `--dry-run` s'arrête juste après la validation sans rien
envoyer (idéal pour un premier essai), `--bump` incrémente le numéro de build,
`--skip-tests` va plus vite.

> **Un numéro de build est consommé définitivement**, même si tu supprimes le
> build ensuite. Pour tout nouvel envoi : `./scripts/release.sh --bump`.
> Le numéro de build (1, 2, 3…) est interne ; la version publique reste `1.0`.

Le traitement par Apple prend 5 à 30 min, avec un e-mail à la clé. Le build
apparaît ensuite dans la section **Build** de ta version.

## 9. Vérifier via TestFlight

Étape facultative, mais c'est le seul moyen de tester exactement le binaire que
verront les utilisateurs — la configuration Release, signée pour l'App Store,
se comporte parfois différemment du build de développement.

App Store Connect → **TestFlight** → ton build → ajoute-toi comme testeur
interne. Installe **TestFlight** sur ton iPhone, puis Luma depuis TestFlight.

À vérifier en priorité, sur une app **fraîchement installée** :

- la demande d'autorisation caméra s'affiche bien au premier lancement ;
- l'animation de lancement puis la mesure démarrent sans blocage ;
- la pellicule choisie survit à un redémarrage de l'app ;
- les valeurs recommandées correspondent à celles de la version que tu utilises
  déjà (compare sur deux ou trois scènes).

## 10. Soumettre à la validation

Sur la page de la version : sélectionne le build, vérifie que plus rien n'est
marqué comme manquant, puis **Ajouter à la validation** → **Soumettre à la
validation**.

Choisis la mise en vente **manuelle** si tu veux décider du jour de publication,
**automatique** pour qu'elle sorte dès l'approbation.

Compte 24 à 48 h. Trois motifs de refus plausibles ici, et la réponse à donner :

| Motif possible | Réponse |
|---|---|
| « Quel est l'intérêt de l'accès caméra ? » | La caméra *est* le posemètre. C'est expliqué dans les notes de validation (§6) et dans `NSCameraUsageDescription`. |
| Nom ou marque contestés | « Nikon », « FM2 » et « Nikkor » n'apparaissent ni dans le nom ni dans les mots-clés, seulement en description, pour décrire la compatibilité — usage nominatif admis. |
| « Trop simple / pas assez de fonctionnalités » | L'app rend un service réel et complet qu'aucun réglage du téléphone ne remplace ; les captures montrent les cinq écrans. Insister sur la mesure spot, la molette et les messages hors plage. |

En cas de refus, Apple explique précisément quoi corriger dans **App Store
Connect → Résolution Center**. On corrige, `./scripts/release.sh --bump`, et on
resoumet — sans repayer, sans limite de tentatives.

---

## Pour les versions suivantes

1. Coder, tester.
2. Monter `MARKETING_VERSION` dans `project.yml` (`1.0` → `1.1`).
3. App Store Connect → **+ Version** → remplir **Nouveautés de cette version**
   (limite 4000 caractères, dans les deux langues).
4. `./scripts/release.sh --bump`, puis soumettre.

Les métadonnées seules (texte promotionnel, captures) peuvent être modifiées sans
nouveau build ; le texte promotionnel se change même sans nouvelle validation.

---

## Sources

- [Screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) — tailles acceptées pour le créneau 6,9"
- [Manage EU Digital Services Act trader requirements](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/) — définition et conséquences du statut de professionnel
- [Apps without trader status will be removed from the App Store in the EU](https://developer.apple.com/news/?id=einwn76m) — caractère obligatoire de la déclaration
