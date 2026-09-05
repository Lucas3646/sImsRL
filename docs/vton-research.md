# Choix Virtual Try-On — septembre 2026

Cette note sépare la validation technique de la future exploitation commerciale. Les coûts et offres d'API changent : vérifier les pages liées avant une décision de production.

| Solution | Qualité / portée | Intégration V1 | Coût / GPU | Licence et risque | Décision |
|---|---|---|---|---|---|
| IDM-VTON via Replicate | Très bon rendu de vêtement en conditions réelles, une pièce par passage | API simple, environ 17 s annoncées par génération | La page modèle annonce environ 0,024 USD par exécution au moment de l'étude | CC BY-NC-SA 4.0, donc non commercial | Provider de **test** retenu pour valider le flow |
| CatVTON | Bon compromis qualité/légèreté, image statique | Auto-hébergement possible, preprocessing simplifié | Le dépôt annonce moins de 8 Go de VRAM en 1024×768 BF16 | Licence non commerciale dans le dépôt ; demandes de licence commerciale encore ouvertes | Bon candidat self-hosted de recherche, pas de release commerciale directe |
| CatV2TON | Images et vidéos avec un même DiT | Outillage plus orienté recherche/datasets | GPU requis ; poids 256 et 512 publiés | Valider précisément la licence et la maturité avant usage produit | À réévaluer pour une phase vidéo, pas nécessaire en V1 |
| Mobile-VTON (CVPR 2026) | Recherche orientée haute fidélité « mobile » | Le dépôt public reste une stack Python/dataset, pas un SDK Flutter prêt à embarquer | Pipeline de recherche à mesurer sur appareils réels | CC BY-NC-SA 4.0 | Trop tôt pour l'intégration on-device de cette V1 |
| API commerciale spécialisée | Qualité, SLA et catégories selon fournisseur | Généralement la plus rapide pour publier | Prix par rendu ou volume | Contrat commercial et traitement des données à auditer | Meilleure piste avant publication si les tests produit sont concluants |

## Pourquoi IDM-VTON/Replicate pour le prototype

Le but immédiat est de savoir si une personne trouve utile de photographier son dressing puis de composer ses propres tenues. Replicate évite de maintenir un GPU durant ce test et IDM-VTON dispose d'un chemin API concret. Le coût est variable et chaque pièce appliquée séquentiellement correspond à une exécution supplémentaire.

Cette décision n'engage pas le produit : l'application appelle notre propre contrat `VirtualTryOnProvider`, et seul le backend connaît Replicate.

## Préservation de l'identité et multi-vêtements

La génération séquentielle permet d'assembler un haut et un bas avec un modèle mono-vêtement, mais chaque passage peut modifier légèrement le visage, la silhouette, les mains, les motifs ou la pièce appliquée précédemment. Pour la V1 :

- appliquer le haut, puis l'outerwear, puis le bas ;
- conserver la pose et éviter tout prompt créatif ;
- fixer le seed lors d'un essai comparable ;
- ne pas prétendre appliquer les chaussures avec IDM-VTON ;
- comparer plus tard un provider full-body à la stratégie séquentielle sur un même jeu de 20 à 50 photos.

## Sources primaires

- [IDM-VTON — dépôt officiel et licence](https://github.com/yisol/IDM-VTON)
- [IDM-VTON sur Replicate — API, licence et estimation par exécution](https://replicate.com/cuuupid/idm-vton)
- [Tarification Replicate](https://replicate.com/pricing)
- [CatVTON — dépôt officiel, mémoire GPU et inférence](https://github.com/Zheng-Chong/CatVTON)
- [CatV2TON — dépôt officiel](https://github.com/zheng-chong/catv2ton)
- [Mobile-VTON — dépôt officiel et licence](https://github.com/tmllab/2026_CVPR_Mobile-VTON)
