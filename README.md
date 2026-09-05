# sImsRL

sImsRL est une application mobile Flutter de dressing virtuel personnel. La V1 permet de créer un modèle depuis une photo en pied, enregistrer ses vrais vêtements, composer une tenue avec une interaction rapide, générer un aperçu via un provider Virtual Try-On interchangeable, puis sauvegarder ses looks.

## État de la V1

- Android et iOS depuis une seule codebase Flutter
- onboarding court et visuel
- modèle utilisateur depuis caméra ou galerie
- dressing local avec catégories, modification, suppression et favoris
- filtres visuels `Tous / Hauts / Bas / Vestes / Chaussures`
- Dressing Room avec sélecteurs précédent/suivant
- génération asynchrone, erreurs lisibles, régénération, partage et sauvegarde
- galerie des tenues et favoris
- mode de démonstration séparé des vraies données
- stockage local privé, sans compte obligatoire
- provider mock local et provider HTTP réel configurable
- backend de test Replicate/IDM-VTON avec génération séquentielle

La V1 privilégie un premier test produit sans imposer Firebase. Les photos sont copiées dans le dossier privé de l'application et les métadonnées sont sauvegardées dans un JSON local écrit atomiquement.

## Installation

Prérequis : Flutter stable récent, Android Studio avec le SDK Android et, pour iOS, macOS avec Xcode.

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

Pour cibler un téléphone Android :

```bash
flutter devices
flutter run -d <device-id>
```

Build Android :

```bash
flutter build apk --debug
flutter build appbundle --release
```

Build iOS, sur macOS uniquement :

```bash
flutter build ios --release
```

Le bundle Android est `com.lucas.simsrl` et le bundle iOS est `com.lucas.simsrl`. Il faudra configurer une vraie signature avant publication.

## Tester immédiatement

Sans configuration externe, l'application utilise `MockVirtualTryOnProvider`. Il valide tout le parcours, mais réaffiche volontairement la photo du modèle avec le badge `Aperçu démo` : ce n'est pas présenté comme un résultat IA.

Dans Profil, active `Vêtements de démonstration` pour charger plusieurs hauts, bas, vestes et chaussures sans prendre dix photos.

## Activer une vraie génération

La clé du fournisseur ne doit jamais se trouver dans l'APK. L'application envoie les images vers le backend privé inclus dans `server/`, lequel appelle le provider IA.

### 1. Démarrer le backend de test

Le provider inclus utilise IDM-VTON sur Replicate. IDM-VTON est sous licence **CC BY-NC-SA 4.0** : cette configuration convient au prototype et à la validation du concept, pas à une commercialisation.

```bash
cd server
npm install
export REPLICATE_API_TOKEN="r8_..."
npm start
```

Replicate est payant à l'usage. Ne lance pas ce provider sans avoir vérifié le tarif courant et défini un budget/une limite côté compte.

### 2. Passer l'URL du backend au build Flutter

Émulateur Android avec un backend local :

```bash
flutter run \
  --dart-define=VTON_API_BASE_URL=http://10.0.2.2:8080
```

Téléphone physique : utilise une URL HTTPS joignable par le téléphone. Le HTTP non chiffré n'est autorisé que dans le manifest Android `debug` pour le développement local.

```bash
flutter run \
  --dart-define=VTON_API_BASE_URL=https://vton.example.com
```

Avant d'exposer le backend publiquement, ajoute une authentification utilisateur (Firebase Auth convient), App Check, du rate limiting, des quotas par utilisateur, une validation stricte des images et une politique d'expiration des résultats.

## Contrat du provider mobile

L'abstraction `VirtualTryOnProvider` expose :

```dart
Future<TryOnGeneration> generateOutfit(TryOnRequest request);
Future<TryOnGeneration> getStatus(String generationId);
```

Le provider HTTP attend :

- `POST /v1/try-on/generations` en multipart, avec `person`, plusieurs `garments` et le champ JSON `categories` ;
- `GET /v1/try-on/generations/{id}` pour le polling ;
- un résultat `{ id, status, createdAt, resultUrl?, message? }`.

Le backend range les providers dans `server/src/providers/`. Pour remplacer Replicate/IDM-VTON, implémente `generate()` dans un nouveau provider sans modifier l'application Flutter.

## Stratégie multi-vêtements

IDM-VTON accepte une pièce à la fois. Le provider de test applique donc :

1. haut ;
2. veste/outerwear ;
3. bas.

Chaque résultat devient l'image utilisateur de l'étape suivante. Les chaussures et accessoires sont ignorés par ce provider, car forcer un modèle non prévu pour ces catégories dégrade fortement le rendu. Un futur provider compatible full-body pourra recevoir toutes les pièces avec le même contrat mobile.

## Architecture

```text
lib/
  core/                  thème et widgets communs
  models/                UserProfile, Garment, Outfit, TryOnGeneration
  services/              stockage, média et providers VTON
  state/                 état applicatif léger
  features/
    onboarding/
    model/
    wardrobe/
    dressing_room/
    outfits/
    profile/
server/
  src/providers/         providers IA interchangeables
docs/
  vton-research.md       comparaison et décision technique
```

La gestion d'état repose volontairement sur `ChangeNotifier` + `InheritedNotifier` pour limiter les dépendances de cette V1. Une migration Riverpod restera simple si l'application grandit.

## Données et confidentialité

- aucune photo n'est publique ;
- aucune clé API ne doit être commitée ou injectée dans l'application ;
- les vraies photos et les données démo restent séparées ;
- l'application demande un consentement explicite avant un envoi au backend IA ;
- un résultat distant sauvegardé est téléchargé dans le stockage privé local ;
- `Supprimer toutes mes données` efface le dossier local de l'application ;
- le backend conserve seulement l'état des jobs en mémoire pendant environ 30 minutes.

Pour une version avec synchronisation, utiliser Firebase Auth, Firestore et Storage avec des chemins par UID et des règles interdisant tout accès croisé. Prévoir aussi une fonction serveur qui efface Firestore, Storage et l'utilisateur Auth lors de la suppression de compte.

## Limites connues de cette première version

- pas encore de détourage automatique ni d'éditeur de recadrage avancé ; la photo originale reste utilisable ;
- le provider de test n'applique pas les chaussures ;
- le rendu démo n'est pas un rendu IA ;
- les jobs du backend d'exemple sont en mémoire et doivent passer sur une file durable en production ;
- la qualité dépend beaucoup de la photo en pied et des photos de vêtements ;
- IDM-VTON ne peut pas être le provider d'une application commerciale sans licence adaptée.

## Tests

```bash
flutter analyze
flutter test

cd server
npm test
```

Les tests couvrent la sérialisation des modèles et l'ordre séquentiel haut/bas du provider Replicate. Le parcours à valider sur appareil est : onboarding → photo en pied → ajout T-shirt → ajout pantalon → sélection → génération → sauvegarde → nouvelle tenue.
