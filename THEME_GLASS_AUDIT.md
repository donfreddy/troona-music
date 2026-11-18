# Audit du thème : verre, couleurs et performance

Date : 2026-11-18. Périmètre : `lib/core/theme/`, les surfaces qui posent un `BackdropFilter`, les fonds dynamiques et la palette extraite des pochettes. Rien d'autre.

## Méthode et limites

- **Lu** : `glass_theme.dart`, `glass_filter.dart`, `glass_tier.dart`, `blur_budget.dart`, `app_colors.dart`, `color_primitives.dart`, `app_theme.dart`, les six fichiers qui créent un `BackdropFilter`, `dynamic_background.dart`, `track_palette_cubit.dart`, le réglage dans `settings_cubit.dart` et `settings_page.dart`.
- **Calculé** : les rapports de contraste WCAG ci-dessous sont calculés à partir des valeurs du code, pas estimés.
- **Non fait** : aucun profilage sur appareil. Tout ce qui touche au coût GPU réel est un raisonnement à confirmer par mesure. Le protocole est en fin de document.
- **Vérifié en ligne** : deux points sur le moteur de rendu (voir Sources). Projet en Flutter 3.47.5, donc Impeller.
- **Noms** : il n'existe ni `TroonaGlass` ni `primaryColor` dans le code. Les vrais noms sont `GlassTheme`, `GlassConfig`, `GlassFilter`, `GlassTier`, et `AppColors.accent`. `AppColors` est bien une `ThemeExtension` ; la qualité du verre, elle, n'en est pas une (c'est un point de l'audit).

## Verdict

Le système est sérieux : une recette de matériau cohérente (flou, saturation, teinte), un budget de flous respecté, un réglage utilisateur à quatre positions et une détection au démarrage. C'est au-dessus de ce que font la plupart des applications Flutter.

Quatre choses l'empêchent d'être irréprochable :

1. **Le palier « léger » baisse le mauvais curseur.** Il réduit le sigma, qui n'est pas ce qui coûte, et rend le verre plus laid et moins lisible sans le rendre sensiblement moins cher.
2. **Le texte sur le verre de l'en-tête n'a pas de plancher de contraste.** Sur une pochette claire, le titre blanc tombe à 1,4:1.
3. **Le palier « sans flou », celui que reçoivent les téléphones modestes, est le moins soigné** : gris iOS hors palette, plus aucun liseré.
4. **Les jetons du verre ont dérivé** : trois façons de dessiner un bord, des valeurs codées en dur, des presets et des couleurs jamais lus.

---

## 1. Implémentation du verre

### La recette actuelle

| Couche | Présente | Où |
| --- | --- | --- |
| Flou de l'arrière-plan | Oui | `GlassFilter.of`, sigma 30 sur les barres et les feuilles, 26 sur le dock, 12 au plus sur la lentille |
| Saturation de l'arrière-plan | Oui | Matrice Rec. 709 composée avec le flou : 1,25 sur le chrome qui porte du texte, 1,6 sur le verre décoratif |
| Teinte | Oui | 15 % de `#0C0E14` sur les barres, 4 à 8 % de blanc ailleurs |
| Liseré lumineux | Partiel | Dégradé haut vers bas dans `GlassCard` seulement |
| Double trait (clair puis sombre) | Non | |
| Grain | Non | |
| Ombre portée sous ce qui flotte | Non | |
| Reflet spéculaire, réfraction | Non | Sauf le reflet radial de la lentille |

### Est-ce du « verre poli » ?

La recette de base est la bonne : flou, saturation, teinte, c'est exactement ce qui compose un matériau iOS 18. Sur ce plan, ce n'est pas un calque translucide plat, et le choix de composer la saturation dans le même filtre que le flou est propre (un seul passage, luminance conservée).

Deux précisions franches :

- **La réfraction n'appartient pas à iOS 18.** Les matériaux d'iOS 18 ne déforment pas ce qui est derrière eux. La lentille qui courbe la lumière est le Liquid Glass d'iOS 26. Dans Flutter cela demande un shader de fragment sur l'arrière-plan, sur chaque image. Je ne le recommande pas : c'est l'exact opposé de ton objectif sur les téléphones modestes.
- **Ce qui manque est la sensation d'épaisseur, pas le flou.** Un matériau paraît solide grâce à son bord et à ce qui le détache du fond. Aujourd'hui la barre du bas a une bordure uniforme, la feuille une bordure uniforme sur trois côtés, l'en-tête aucune, et seule la lentille a un vrai traitement (liseré en dégradé, reflet, trait intérieur). La lentille est la référence interne à généraliser.

### Points de friction

**1.1 Trois traitements du bord.** `GlassCard` peint un dégradé (`_GlassEdgePainter`). La barre du bas utilise `Border.all(glass.border)`. La feuille utilise un `Border` uniforme, avec un commentaire qui explique que Flutter ne sait pas peindre un bord arrondi multicolore, alors que le peintre de `GlassCard` le fait déjà. Le dock et `GlassIconButton` codent leur bordure en dur (blanc à 12 %).

**1.2 Deux sources de vérité pour le verre.** `ColorPrimitives.glassFillDark` vaut 3 %, `_cardDark.fill` 4 %, le dock 4 % en dur, la lentille 8 % en dur. `AppColors.glassFill`, `glassBorder` et `glassHighlight` doublent `GlassConfig` et sont lus à 14 endroits (lignes de liste, dialogues, mosaïque de playlist, carte d'artiste) qui contournent donc les paliers : quand l'utilisateur passe en « sans flou », ces surfaces ne changent pas.

**1.3 Du code mort dans le thème.**

- Huit presets clairs, `AppColors.light`, `AppTheme.light` : l'application est en `ThemeMode.dark` avec `AppTheme.dark` pour les deux thèmes.
- `AppColors.vibrancyLabel`, `vibrancySecondary`, `accentGlow` : aucun usage.
- Les presets `miniPlayer` : seul `border` est lu. `nowPlaying` : seul `blurSigma` est lu.
- La documentation a dérivé : `GlassConfig.highlight` est décrit comme un « reflet diagonal » alors qu'il sert de couleur des côtés du liseré ; les commentaires annoncent 14 px de flou là où le code en met 20 ; le tableau des paliers annonce « 14 à 26 px » alors que les barres sont à 30.

Ce n'est pas cosmétique : un thème où un tiers des valeurs ne sert à rien est un thème où l'on corrige la mauvaise.

**1.4 Une règle du projet non respectée.** `GlassCard` appelle `GlassFilter.of(cfg.blurSigma)` sans `saturation: cfg.saturation` ([glass_card.dart](lib/shared/widgets/glass_card.dart)), donc toujours 1,6. Aucun appelant ne passe de flou aujourd'hui, donc c'est sans effet visible, mais c'est un piège pour le prochain.

### Correctifs proposés

**Un seul peintre de bord, public, à double trait.** Promouvoir `_GlassEdgePainter` et l'utiliser sur la barre, la feuille, le dock et les boutons ronds. Le second trait, sombre, juste à l'intérieur du premier, est ce qui donne une épaisseur :

```dart
// Light caught by the top edge, then a dark line just inside it: the pair
// reads as the thickness of the glass.
final outer = borderRadius.toRRect(rect.deflate(width / 2));
canvas
  ..drawRRect(outer, lightStroke) // the existing gradient stroke
  ..drawRRect(
    outer.deflate(width),
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..color = const Color(0x33000000),
  );
```

**Une ombre portée sous la barre flottante.** Peinte hors du `ClipRRect` du flou, donc sans coût de filtre. C'est ce qui détache réellement une surface du contenu, bien plus que le flou.

**Un grain, mais d'abord dans le fond.** Le grain a deux rôles : casser les paliers des dégradés sombres (fréquents sur les dalles Android) et donner de la matière. Une tuile de bruit de 64 px générée une fois, répétée en `ImageShader` à environ 3 %, à l'échelle du pixel physique. À mettre dans le fond avant de le mettre sur le verre, et à ne garder sur les barres que s'il ne gêne pas la lecture. Je n'ai pas vu les paliers sur appareil : c'est à constater avant de coder.

**Un seul jeu de jetons.** Supprimer les presets clairs et les couleurs jamais lues ; faire passer les widgets qui lisent `colors.glassFill` par `GlassTheme`, pour que les paliers s'appliquent partout.

---

## 2. Couleurs et lisibilité

### Ce qui est bien fait

- **Le plafond de luminance du halo** (`DynamicBackground.fitForText`). Limiter la luminance relative plutôt que la clarté HSL est la bonne approche, et le commentaire sur le jaune est exact. Le calcul confirme la promesse : le texte secondaire garde 4,98:1 sur le point le plus clair du halo.
- **L'accent lilas** `#B79CFF` : 9,2:1 sur noir, 5,6:1 sur le halo le plus clair. Texte sombre sur accent : 8,5:1.
- **La saturation qui conserve la luminance** : le contraste du texte ne bouge pas quand la saturation change.

### Contrastes calculés

| Paire | Rapport | Verdict |
| --- | --- | --- |
| Texte secondaire (60 %) sur noir | 6,36 | Bon |
| Texte secondaire sur halo le plus clair | 4,98 | Bon, de justesse |
| **Texte tertiaire (30 %) sur noir** | **2,25** | **Insuffisant pour du texte** |
| Accent sur noir, sur halo | 9,21 / 5,62 | Bon |
| Onglet inactif (blanc 40 %) sur noir, sur halo | 3,66 / 3,43 | Suffisant pour une icône (3:1) |
| **Titre blanc sur le verre de l'en-tête, pochette blanche dessous** | **1,39** | **Illisible** |
| Même cas, pochette claire (`#E0E0E0`) | 1,81 | Illisible |
| Même cas, pochette gris moyen | 5,03 | Bon |
| **Même cas, palier léger** (voile blanc 12 %) | **1,00 à 1,27** | **Pire que le palier haut** |
| Nom d'artiste sur photo blanche (dégradé 55 %) | 4,76 | Bon |

### Points de friction

**2.1 Pas de plancher de contraste sur l'en-tête.** Le flou étale la pochette mais ne l'assombrit pas, et 15 % de teinte ne suffisent pas. Une pochette claire de 160 dp qui passe sous le titre replié donne une tache presque blanche sous du texte blanc. La barre du bas n'a pas ce problème : le shell assombrit déjà le contenu avant qu'il n'arrive sous elle (`_BottomFade`). L'en-tête n'a rien d'équivalent.

Le correctif ne coûte rien au GPU : ajouter une exposition à la matrice qui porte déjà la saturation.

```dart
/// Colour matrix scaling saturation by [s] around the luminance axis, then
/// brightness by [e]: 1 leaves it, 0.5 halves what the glass lets through.
static List<double> materialMatrix(double s, double e) {
  const r = 0.2126, g = 0.7152, b = 0.0722;
  final i = 1 - s;
  return [
    (r * i + s) * e, g * i * e, b * i * e, 0, 0, //
    r * i * e, (g * i + s) * e, b * i * e, 0, 0, //
    r * i * e, g * i * e, (b * i + s) * e, 0, 0, //
    0, 0, 0, 1, 0, //
  ];
}
```

Effet calculé sur le pire cas (pochette blanche, teinte de 15 % conservée) :

| Exposition | Titre blanc | Texte secondaire |
| --- | --- | --- |
| 1,0 (aujourd'hui) | 1,39 | 1,10 |
| 0,7 | 2,82 | 1,74 |
| 0,6 | 3,73 | 2,10 |
| 0,5 | 5,06 | 2,60 |
| 0,45 | 5,95 | 2,91 |

Recommandation : `exposure` devient un champ de `GlassConfig`, à 0,5 pour l'en-tête et à 1 pour la barre du bas. Le prix : un verre d'en-tête plus sombre sur les contenus clairs. Tu avais écarté un matériau épais parce qu'il était « trop terne » ; l'exposition n'assombrit que ce qui est clair (le noir reste noir), donc l'effet sur un fond sombre est nul. À régler à l'oeil sur le Pixel 8 entre 0,5 et 0,6.

**2.2 Le texte tertiaire est utilisé comme du texte.** 46 usages, dont des libellés de 11 à 12 px (pied de section des réglages, bannière d'accueil). À 2,25:1, c'est sous le seuil de 4,5:1, et sous 3:1. Soit le réserver aux icônes et aux états désactivés et passer ces textes en secondaire, soit remonter son alpha vers 48 %, ce qui donne environ 4,5:1 sur noir.

**2.3 La palette peut afficher les couleurs du mauvais morceau.** Dans [track_palette_cubit.dart](lib/features/player/presentation/bloc/palette/track_palette_cubit.dart), `_requestId` n'est incrémenté que sur le chemin asynchrone. Scénario : l'extraction du morceau A est en cours, l'utilisateur passe au morceau B, déjà en cache. B est émis tout de suite sans toucher au compteur ; quand l'extraction de A se termine, le test `requestId != _requestId` passe et les couleurs de A remplacent celles de B. Même chose vers un morceau sans pochette.

```dart
Future<void> updateTrack(Track? track) async {
  // Every call supersedes the one in flight, cached or not.
  final requestId = ++_requestId;
  // ... unchanged, without the later `++_requestId`
}
```

**2.4 Le cache de palette est indexé par morceau, pas par pochette.** Les douze titres d'un album partagent une image et déclenchent douze extractions. Indexer par `artworkPath` supprime onze calculs sur douze. À vérifier aussi : si `PaletteGeneratorMaster` quantifie sur l'isolate d'interface, ce travail tombe pendant l'animation de changement de piste (260 ms) et pendant le vol des héros. Je n'ai pas lu le paquet.

**2.5 Le palier « sans flou » sort de la palette.** `_cardOffDark` est `#1C1C1E` à 90 %, le gris d'iOS, alors que les surfaces de l'application sont des noirs bleutés (`#07090E`, `#0C0E14`, `#14161D`), échantillonnés sur ta référence. Bordure et reflet y sont transparents. Résultat : sur les téléphones sous 3 Go, les barres deviennent des pavés gris neutres sans bord, dans une application bleu nuit. Passer sur `bgTertiary` à 94 % et garder le liseré.

**2.6 Trois familles de teintes.** Lilas pour l'accent, bleu glacé pour la progression, et la couleur de la pochette pour le fond. Sur un halo orange ou vert, le lilas et le bleu glacé cohabitent mal. Je garderais un seul accent de marque, et je ferais dériver l'arc de progression de la palette du morceau (`palette.primary`, déjà calculé et lu à un seul endroit aujourd'hui) plutôt que d'un bleu fixe. C'est un choix de goût, pas un défaut.

---

## 3. Performance et paliers

### Ce qui existe

Le mécanisme demandé existe déjà, et il est bien câblé :

- `GlassQuality { auto, high, low, off }`, exposé dans Réglages, Apparence, par un contrôle à quatre segments.
- `GlassTier.detect()` au démarrage : moins de 3 Go de RAM donne `off`, moins de 6 Go ou avant Android 10 donne `low`, sinon `high`. « Supprimer les animations » donne `off`.
- Le palier détecté figure dans le rapport de diagnostic.
- Chemin rapide partout : sigma 0 signifie aucun `BackdropFilter`.
- Budget de deux flous, feuilles opaques au-dessus de Now Playing (`BlurBudgetSpent`), flou de l'en-tête activé seulement quand du contenu passe dessous.

Il ne faut donc pas créer ce réglage, mais corriger ce qu'il fait.

### Points de friction

**3.1 Le palier léger baisse le sigma, qui n'est pas ce qui coûte.** `_barLowDark` passe de 30 à 8. Or Impeller réduit la résolution de travail en fonction du sigma : pas de réduction jusqu'à 4, puis une réduction croissante qui plafonne, avec un noyau limité à une cinquantaine d'échantillons. Un grand flou est donc calculé sur une image plus petite. Le coût d'un `BackdropFilter` vient surtout de la capture de l'arrière-plan (une passe de rendu supplémentaire), de la surface en pixels et du nombre de filtres, très peu du sigma.

Conséquence : le palier léger est probablement à peine moins cher que le palier haut, alors qu'il est nettement moins beau (un flou de 8 laisse les formes reconnaissables) et moins lisible (voir le tableau : 1,00 à 1,27 sur une pochette claire, à cause du voile blanc de 12 %). Le commentaire de `glass_sliver_header.dart` le dit d'ailleurs lui-même : « small sigmas are the costliest to blur ».

Je n'ai pas trouvé de courbe publiée du coût selon le sigma : c'est à mesurer. Mais la conception du palier doit changer de levier : **moins de filtres et moins de surface, pas moins de sigma.**

**3.2 La RAM n'est pas le GPU.** Beaucoup de téléphones de milieu de gamme ont 6 ou 8 Go de RAM, un écran 1080 x 2400 et un GPU d'entrée de gamme. Ils reçoivent `high` : deux flous de sigma 30, la lentille, et un troisième flou sur les feuilles. Ce sont précisément les téléphones de bêta-testeurs sur lesquels le verre saccadera, et rien ne le détectera. En cas d'échec de la détection sur Android, le repli est aussi `high` : il devrait être `low`.

**3.3 Le réglage ne se propage pas.** La qualité est un champ statique (`GlassTheme._override`). `setGlassQuality` le modifie puis émet un état de réglages, mais aucune surface de verre n'écoute ce cubit : chacune lit la valeur statique dans son `build`. Déduit du code : en changeant le réglage, la barre du bas (visible sous la page Réglages) garde son ancien rendu jusqu'à sa prochaine reconstruction, c'est-à-dire un changement de piste ou de lecture. À confirmer à l'écran. Un état global statique fuit aussi d'un test à l'autre.

**3.4 Un écran « immobile » ne l'est pas.** `RepaintBoundary` évite de réenregistrer la peinture, pas de refaire le flou : dès qu'une image est produite, chaque `BackdropFilter` visible est recalculé. Or plusieurs animations tournent en permanence pendant la lecture : les trois barres de `MiniEqualizer` (répétition sans fin), le vinyle de la page Album (un tour en 3,6 s), le défilement des titres longs. Un ticker actif demande une image à chaque rafraîchissement. Sur la page Album en lecture, écran posé, le téléphone calcule donc deux flous 60 ou 120 fois par seconde. Dans un lecteur de musique, c'est l'état le plus fréquent, et c'est de la batterie autant que de la fluidité.

**3.5 Le fond est cher et peint deux fois.** `DynamicBackground` empile cinq couches plein écran (noir, trois dégradés radiaux, un dégradé linéaire), toutes mélangées en alpha. Sur une page Album ou Artiste, `AmbientBackground` du shell est toujours peint dessous ([app_shell.dart](lib/app_shell.dart)), et la page peint le sien par-dessus : dix passes plein écran avant le premier pixel de contenu. À ma connaissance Impeller ne met pas ces images en cache, donc ce coût est payé à chaque image produite, y compris à cause du point 3.4. Sur un GPU limité par son débit de remplissage, c'est un candidat sérieux, à mesurer avant d'y toucher.

**3.6 Détails.** `GlassFilter.of` alloue un filtre composé et une matrice de vingt valeurs à chaque `build` : à mémoriser par couple (sigma, saturation, exposition). La transition de fond de 2 s derrière les onglets fait recalculer les flous pendant 120 images ou plus à chaque changement de piste : à raccourcir hors palier haut.

### Architecture proposée

**A. Redéfinir les paliers par le nombre et la surface des flous.**

| | Complet | Équilibré (remplace Léger) | Sans flou |
| --- | --- | --- | --- |
| En-tête replié | Flou 30 | Flou 30 | Teinte opaque |
| Barre du bas | Flou 30 | Teinte opaque à 88 %, liseré, ombre | Teinte opaque à 94 %, liseré, ombre |
| Lentille Now Playing | Flou | Voile sans flou | Voile sans flou |
| Dock Now Playing | Flou | Voile sans flou | Voile sans flou |
| Feuilles | Troisième flou | Opaques | Opaques |
| Flous simultanés au plus | 3 | 1 | 0 |
| Animations perpétuelles | Fluides | Cadencées à 8 ou 10 images par seconde | Fluides (les images ne coûtent plus rien) |
| Transition du fond | 2 s et 380 ms | 380 ms partout | 380 ms partout |

Pourquoi garder le flou de l'en-tête plutôt que celui de la barre en Équilibré : sous la barre, le contenu est déjà assombri par le shell, donc une teinte opaque y perd peu. Sous l'en-tête, des lignes de texte nettes passent derrière le titre : c'est là que le flou sert à lire.

Le palier Sans flou doit rester une surface dessinée (teinte de la palette, liseré, ombre), pas un état dégradé.

**B. Faire de la qualité une `ThemeExtension`.** Tous les presets lisent déjà `Theme.of(context)` : placer la qualité dans le thème fait reconstruire chaque surface automatiquement, et supprime l'état statique.

```dart
@immutable
final class GlassSettings extends ThemeExtension<GlassSettings> {
  /// The resolved quality: never [GlassQuality.auto].
  final GlassQuality quality;

  const GlassSettings(this.quality);

  @override
  GlassSettings copyWith({GlassQuality? quality}) =>
      GlassSettings(quality ?? this.quality);

  // A quality does not blend: switch halfway.
  @override
  GlassSettings lerp(GlassSettings? other, double t) =>
      t < .5 || other == null ? this : other;
}
```

`MaterialApp.router` est construit sous un `BlocSelector<SettingsCubit, SettingsState, GlassQuality>` qui résout `auto` avec le palier détecté et passe la valeur à `AppTheme.dark`. `GlassTheme._resolveQuality` lit alors `Theme.of(ctx).extension<GlassSettings>()!.quality`. `overrideQuality` et `setDetectedTier` disparaissent. Prix : toute l'application se reconstruit quand le réglage change, ce qui arrive une fois dans la vie d'un utilisateur.

**C. Un garde-fou à l'exécution, en mode Auto seulement.** C'est la seule réponse correcte au point 3.2 : mesurer au lieu de deviner.

```dart
/// Lowers the glass by one tier when frames keep missing their budget.
/// Auto mode only. Never raises it back: the decision is stored.
void _onTimings(List<FrameTiming> timings) {
  for (final t in timings) {
    _raster.add(t.rasterDuration.inMicroseconds);
    if (_raster.length > _window) _raster.removeFirst();
  }
  if (_raster.length < _window) return;
  final slow = _raster.where((d) => d > _budgetMicros).length;
  if (slow > _window * _slowShare) _lowerOneTier();
}
```

Paramètres de départ : fenêtre de 240 images, seuil à 20 % d'images au-dessus du budget (16,6 ms à 60 Hz, 8,3 ms à 120 Hz, lu sur l'écran), dix premières secondes ignorées (démarrage, scan). Branché par `SchedulerBinding.instance.addTimingsCallback`. Le plafond retenu est stocké dans `SharedPreferences`, ajouté au rapport de diagnostic, et annoncé une fois par un toast qui renvoie au réglage. Un choix explicite de l'utilisateur (Complet) n'est jamais contredit.

Mon avis sur l'ordre : **A et B d'abord, C seulement si la bêta le demande.** A et B sont des corrections. C est une pièce mobile de plus : elle se justifie si des testeurs en `high` signalent des saccades, pas avant.

**D. Regrouper les flous qui restent.** Flutter fournit `BackdropGroup` et `BackdropFilter.grouped` : les filtres d'un même groupe partagent une seule capture de l'arrière-plan. L'en-tête et la barre du bas utilisent le même preset et ne se recouvrent pas, ce qui en fait le cas idéal. La documentation annonce un gain sans le chiffrer : à mesurer. À ne pas appliquer à une feuille, qui doit flouter la barre déjà peinte.

**E. Cuire le fond.** Une fois les couleurs stabilisées, rendre le fond une fois dans une image à basse résolution (les dégradés supportent très bien un agrandissement) et la dessiner en une passe opaque. Pendant les 380 ms d'une transition, dessin direct comme aujourd'hui. La même image sert au shell et à la page de détail, ce qui règle aussi la double peinture. Le grain du point 1 se cuit dans la même image, gratuitement.

**F. Le réglage dans l'interface.** Quatre positions suffisent : Auto, Complet, Équilibré, Sans flou. Deux ajouts : afficher sous le contrôle ce que Auto a retenu (« Auto : Équilibré sur cet appareil »), sans quoi le testeur ne sait pas ce qu'il compare ; et renommer « Léger », qui ne dit rien, en « Équilibré ».

---

## Plan d'action

| Priorité | Action | Section | Coût |
| --- | --- | --- | --- |
| P1 | Corriger la course de `TrackPaletteCubit` | 2.3 | Une ligne |
| P1 | Exposition dans `GlassFilter`, 0,5 sur l'en-tête | 2.1 | Faible |
| P1 | Qualité en `ThemeExtension` | 3.3, B | Faible |
| P1 | Redéfinir Léger en Équilibré, refaire Sans flou | 3.1, 2.5, A | Moyen |
| P2 | Un seul peintre de bord, ombre sous la barre | 1.1 | Faible |
| P2 | Nettoyer presets et jetons morts, unifier les sources | 1.2, 1.3 | Faible |
| P2 | Texte tertiaire | 2.2 | Faible |
| P2 | Cache de palette par pochette | 2.4 | Faible |
| P2 | Cadencer les animations perpétuelles en Équilibré | 3.4 | Moyen |
| P3 | `BackdropGroup`, mémorisation du filtre | D, 3.6 | Faible, à mesurer |
| P3 | Fond cuit, grain | E, 1 | Moyen, à mesurer |
| P3 | Garde-fou à l'exécution | C | Moyen, si la bêta le demande |

## Protocole de mesure

Rien de ce qui précède en section 3 ne doit être codé sans chiffres avant et après.

- **Appareils** : le Pixel 8 de référence, et au moins un téléphone à GPU modeste avec 6 Go ou plus (celui que la détection classe à tort en `high`), plus un appareil sous 3 Go.
- **Mode** : `flutter run --profile`, DevTools, onglet Performance, temps de rasterisation par image.
- **Scénarios**, 10 secondes chacun :
  1. Défilement de la grille d'albums, en-tête replié.
  2. Page Album en lecture, écran immobile (mesure le point 3.4).
  3. Now Playing, balayage de pochettes.
  4. Ouverture de la file par-dessus les onglets.
  5. Changement de piste sur un onglet (transition de fond de 2 s).
- **Comparaisons** : palier haut contre léger actuel (vérifie le point 3.1), puis chaque correctif isolément.
- **Seuil** : 90e centile du temps de rasterisation sous le budget de l'écran.

## Tests à écrire

- `TrackPaletteCubit` : morceau non mis en cache puis morceau en cache avant la fin de l'extraction ; l'état final est celui du second.
- `GlassFilter.materialMatrix` : l'exposition 1 redonne la matrice de saturation actuelle ; un blanc à 0,5 sort à la moitié.
- Contraste : pour chaque preset qui porte du texte, blanc sur (teinte sur arrière-plan blanc exposé) au moins égal à 4,5.
- Qualité : changer le réglage reconstruit la barre du bas sans autre événement.
- Paliers : en Équilibré, au plus un `BackdropFilter` dans l'arbre sur chaque page ; en Sans flou, aucun.

## Sources

- [BackdropGroup, documentation de l'API Flutter](https://api.flutter.dev/flutter/widgets/BackdropGroup-class.html)
- [Impeller, source de gaussian_blur_filter_contents](https://api.flutter.dev/impeller/gaussian__blur__filter__contents_8cc_source.html)
- [Impeller, blur: hold on to 1/8 downsample until the kernel overflows (#50363)](https://flutter.googlesource.com/mirrors/engine/+/refs/heads/flutter-3.20-candidate.2%5E%21/)
