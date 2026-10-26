# 📚 Troona — Audit & Redesign Complet de la Bibliothèque

## 1. Audit Critique de l'Existant

### Ce qui fonctionne bien ✅

| Élément | Détail |
|---------|--------|
| **Architecture BLoC solide** | `LibraryBloc` gère `LibraryFilter`, `LibrarySort`, `LibrarySearchChanged` — les vues visuelles sont calculées une seule fois dans `LibraryLoaded.copyWith()` |
| **Segment Control premium** | [`LibrarySegmentControl`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/library_segment_control.dart) — animated pill avec gradient accent, haptic feedback, palette-reactive |
| **Hero Delegates** | Les deux detail pages utilisent `SliverPersistentHeaderDelegate` pour un header qui collapse proprement avec blur progressif |
| **TrackListTile fonctionnel** | [`TrackListTile`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/track_list_tile.dart) — indicateur "now playing", like rapide, context menu |
| **Track Actions sheet** | [`showTrackActions`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/track_actions/show_track_actions.dart) — Play Next, Queue, Like, Add to Playlist, Go to Album/Artist — complet |
| **DynamicBackground** | Les detail pages appliquent un fond dynamique piloté par la palette de la piste en cours |
| **Scan progress banner** | Glassmorphism progress bar qui apparaît pendant le scan — bonne UX |

---

### Problèmes identifiés ❌

| # | Problème | Sévérité | Fichier |
|---|----------|----------|---------|
| 1 | **`TrackShimmer` vide** — renvoie un `Container()` vide au lieu d'un vrai skeleton loading | 🔴 Critique | [`track_shimmer.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/track_shimmer.dart) |
| 2 | **Search bar absente dans le layout** — `LibrarySearchBar` existe mais n'est **jamais montée dans `library_page.dart`** | 🔴 Critique | [`library_page.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart) |
| 3 | **Vue "All" incomplète** — n'affiche que Albums + Tracks (10 max), **pas les artistes** | 🟠 Majeur | [`library_page.dart:225-279`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L225-L279) |
| 4 | **Pas de stats / compteur de bibliothèque** — aucune information "342 tracks · 28 albums · 15 artists" | 🟠 Majeur | — |
| 5 | **Grilles Albums/Artists sans spacing** — `crossAxisSpacing` et `mainAxisSpacing` commentés | 🟠 Majeur | [`library_page.dart:353-358`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L353-L358) |
| 6 | **`_FirstLaunchEmpty` — CupertinoButton.filled** au lieu du design system glass | 🟡 Moyen | [`library_page.dart:658`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L658) |
| 7 | **`_SectionHeader` dupliqué** — une version locale `_SectionHeader` dans `library_page.dart`, une autre globale `SectionHeader` dans `section_heater.dart` | 🟡 Moyen | [`library_page.dart:418-491`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L418-L491) |
| 8 | **Album année en dur** — `'2024 • ${album.trackCount} tracks'` hardcoded au lieu de `album.year` | 🟡 Moyen | [`album_detail_page.dart:238`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/album_detail_page.dart#L238) |
| 9 | **No shuffle state feedback** — le bouton Shuffle dans les detail pages toggle `ShuffleToggleRequested` puis `QueueSetRequested` mais ne reflète pas visuellement si le shuffle est activé | 🟡 Moyen | [`album_detail_page.dart:331-345`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/album_detail_page.dart#L331-L345) |
| 10 | **Empty states messages en français/anglais mix** — "Aucun titre trouvé" vs "View All" vs "Play Album" | 🟡 Moyen | Multiple files |
| 11 | **`ArtistCard` sans badge count** — pas d'indication du nombre de tracks/albums | 🟢 Mineur | [`artist_card.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/artist_card.dart) |
| 12 | **`AlbumCard` sans badge count** — pas d'indication du nombre de tracks | 🟢 Mineur | [`album_card.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/album_card.dart) |
| 13 | **Track entity mutable** — `Track` a tous ses champs en `late`/non-final — risque de mutation accidentelle | 🟢 Mineur | [`track.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/domain/entities/track.dart) |
| 14 | **TODO in code** — `//todo: Also check when miniPlayer is not showing` laissé dans albums/artists grid views | 🟢 Mineur | [`library_page.dart:351,394`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L351) |

---

## 2. Vision UX — Structure de la Nouvelle Library

### Philosophie : "Organized Discovery, Instant Access"

La bibliothèque doit fonctionner comme un **hub de navigation puissant** où l'utilisateur trouve tout en 1-2 taps. Trois piliers :
1. **Recherche immédiate** — la search bar est toujours visible et réactive
2. **Stats contextuelles** — l'utilisateur sait exactement la taille de sa bibliothèque
3. **Grilles visuelles premium** — spacing cohérent, badges de count, shimmer loading

### Layout Proposé

```
┌─────────────────────────────────────┐
│  CustomSliverHeader                  │
│  ┌─────────────────────────────────┐ │
│  │ 📚 Library              ↕ 🔄  │ │  ← Large title + Sort + Refresh
│  │                                 │ │
│  │ ┌─────────────────────────────┐ │ │
│  │ │ 🔍 Tracks, artists, albums…│ │ │  ← NOUVEAU: Search bar intégrée
│  │ └─────────────────────────────┘ │ │
│  │                                 │ │
│  │ ┌─All──┐┌Tracks┐┌Albums┐┌Art.─┐│ │  ← Segment Control (conservé)
│  │ └──────┘└──────┘└──────┘└─────┘│ │
│  └─────────────────────────────────┘ │
│                                       │
│  ── Stats Banner ──────────────────  │  ← NOUVEAU
│  ┌─────────────────────────────────┐ │
│  │ 🎵 342 tracks · 28 albums ·    │ │    Compact glass stats bar
│  │    15 artists                   │ │
│  └─────────────────────────────────┘ │
│                                       │
│  ── Scan Progress (si actif) ──────  │  ← Conservé
│                                       │
│  ══════════════════════════════════  │
│  VUE "ALL" :                         │
│  ── Albums ────────── [View All] ─  │
│  ┌───────┐ ┌───────┐ ┌───────┐      │  ← Horizontal scroll
│  │ Album │ │ Album │ │ Album │ ...  │    + badge "12 tracks"
│  │ 12 tr │ │ 8 tr  │ │ 5 tr  │      │
│  └───────┘ └───────┘ └───────┘      │
│                                       │
│  ── Artists ───────── [View All] ─  │  ← NOUVEAU dans vue "All"
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐               │    + badge "8 songs"
│  │🎤│ │🎤│ │🎤│ │🎤│  ...           │
│  │8s│ │5s│ │3s│ │12s│               │
│  └──┘ └──┘ └──┘ └──┘               │
│                                       │
│  ── Tracks ────────── [View All] ─  │
│  ┌────────────────────────────────┐  │
│  │ 🎵 Title 1 · Artist · ❤️ ··· │  │
│  │ 🎵 Title 2 · Artist · ❤️ ··· │  │
│  │ 🎵 Title 3 · Artist · ❤️ ··· │  │  ← 10 premiers tracks
│  │ ...                            │  │
│  └────────────────────────────────┘  │
│                                       │
│  ══════════════════════════════════  │
│  VUE "TRACKS" :                      │
│  ┌────────────────────────────────┐  │
│  │ ▶ Shuffle All (X tracks)      │  │  ← NOUVEAU: Shuffle banner
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ 🎵 Full track list...         │  │
│  └────────────────────────────────┘  │
│                                       │
│  ══════════════════════════════════  │
│  VUE "ALBUMS" :                      │
│  ┌───────┐ ┌───────┐                │  ← Grid 2 colonnes
│  │ Album │ │ Album │                │    avec spacing correct
│  │ 12 tr │ │ 8 tr  │                │    + badge count
│  ├───────┤ ├───────┤                │
│  │ Album │ │ Album │                │
│  └───────┘ └───────┘                │
│                                       │
│  ══════════════════════════════════  │
│  VUE "ARTISTS" :                     │
│  ┌──────┐ ┌──────┐                  │  ← Grid 2 colonnes
│  │  🎤  │ │  🎤  │                  │    avatar circulaire
│  │ Name │ │ Name │                  │    + "X songs"
│  │ 8 s  │ │ 5 s  │                  │
│  └──────┘ └──────┘                  │
│                                       │
└─────────────────────────────────────┘
```

---

## 3. Plan d'implémentation — Fichier par Fichier

### Phase 1 — Corrections critiques & fondations

| # | Action | Fichier | Détail |
|---|--------|---------|--------|
| 1 | ✏️ **Réimplémenter** | `track_shimmer.dart` | Vrai skeleton avec shimmer animé (artwork + 2 lignes de texte) |
| 2 | ✏️ **Intégrer** | `library_page.dart` | Monter `LibrarySearchBar` dans le `CustomSliverHeader.bottom` |
| 3 | ✏️ **Ajouter** | `library_page.dart` | Section artistes dans `_AllView` |
| 4 | 🆕 **Créer** | `library_stats_banner.dart` | Compteurs "342 tracks · 28 albums · 15 artists" |
| 5 | ✏️ **Corriger** | `library_page.dart` | Dé-commenter `crossAxisSpacing`, `mainAxisSpacing` dans les grilles |

### Phase 2 — Améliorations visuelles

| # | Action | Fichier | Détail |
|---|--------|---------|--------|
| 6 | ✏️ **Refactorer** | `library_page.dart` | Remplacer `_FirstLaunchEmpty` → GlassCard + GlassButton cohérent avec le design system |
| 7 | ✏️ **Supprimer** | `library_page.dart` | Supprimer `_SectionHeader` locale, utiliser `SectionHeader` du design system partout |
| 8 | ✏️ **Corriger** | `album_detail_page.dart` | Utiliser `album.year` dynamique au lieu du hardcodé `'2024'` |
| 9 | 🆕 **Créer** | `shuffle_banner.dart` | Bannière "Shuffle All (X tracks)" en haut de la vue Tracks |
| 10 | ✏️ **Harmoniser** | Multiple | Uniformiser les labels en anglais |

### Phase 3 — Polish & badges

| # | Action | Fichier | Détail |
|---|--------|---------|--------|
| 11 | ✏️ **Enrichir** | `artist_card.dart` | Ajouter badge "X songs" sous le nom |
| 12 | ✏️ **Enrichir** | `album_card.dart` | Ajouter badge "X tracks" sous le nom |
| 13 | ✏️ **Cleanup** | `library_page.dart` | Supprimer les TODO commentés |

---

## 4. Impact Performance

| Changement | Impact |
|------------|--------|
| `TrackShimmer` réel | ✅ Nul — juste un widget statique animé par `shimmer` |
| Search bar montée | ✅ Le `Debouncer` existant évite les rebuilds excessifs |
| Stats banner | ✅ Lit `allTracks.length`, `allAlbums.length`, `allArtists.length` — O(1) |
| Shuffle banner | ✅ Widget passif — le shuffle est déclenché au tap |
| Badge counts | ✅ `Album.trackCount`, `Artist.trackCount` — données déjà présentes dans les entités |


________________________________

# 📚🔍 Troona — Audit & Redesign : Bibliothèque + Search

---

## 1. Architecture des Tabs — Diagnostic Actuel

```
Bottom Nav Bar (5 tabs)
┌───────┬──────────┬─────────┬──────────┬───────────┐
│ Home  │ Library  │ Player  │ Search   │ Playlists │
│ 🏠    │ 📚       │ 🎵      │ 🔍       │ 📋       │
└───────┴──────────┴─────────┴──────────┴───────────┘
```

**Deux systèmes de recherche existent :**

| Système | Fichier | Monté ? | Debounce | Backend |
|---------|---------|---------|----------|---------|
| `LibrarySearchBar` | [`library_search_bar.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/library_search_bar.dart) | ❌ **Jamais** | `Debouncer` custom | `LibraryBloc` → filtre in-memory sur `allTracks/Albums/Artists` |
| `SearchPage` (tab) | [`search_page.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/search/presentation/pages/search_page.dart) | ✅ Oui | `rxdart debounceTime(300ms)` | `SearchBloc` → `SearchRepository` → Isar queries |

---

## 2. 🎯 Recommandation Architecture : UNE SEULE Search

### ❌ Pourquoi PAS de search bar dans Library

| Argument | Détail |
|----------|--------|
| **Redondance** | Tu as déjà un tab dédié Search — deux search bars = confusion |
| **Spotify/Apple Music pattern** | Spotify n'a PAS de search dans Library. La Library est un navigateur (filter/sort/browse), le Search est un outil séparé |
| **Complexité** | Deux BLoCs de search = double logique, double maintenance |
| **Espace perdu** | Le header contient déjà Large Title + Sort + Refresh + Segment Control. Ajouter une search bar mange de l'espace vertical |

### ✅ Ce qu'il faut faire

```
┌─────────────────────────────────────────────┐
│                                             │
│  📚 LIBRARY TAB                             │
│  ─────────────────                          │
│  Rôle : Browse, Filter, Sort, Discover      │
│  Search : ❌ NON                            │
│  Garder : Segment control + Sort            │
│                                             │
│  🔍 SEARCH TAB                              │
│  ─────────────────                          │
│  Rôle : Recherche globale rapide            │
│  Search : ✅ OUI (unique point d'entrée)    │
│  Redesign complet nécessaire                │
│                                             │
└─────────────────────────────────────────────┘
```

> **Conclusion : Supprimer `LibrarySearchBar` du projet (dead code), et faire du Search tab le seul et unique point de recherche. On le redesign complètement.**

---

## 3. 🔍 Audit Complet — Search Page

### Problèmes identifiés

| # | Problème | Sévérité | Détail |
|---|----------|----------|--------|
| S1 | **État initial vide anxiogène** — icon ghost + texte gris "Cherchez vos musiques préférées" | 🔴 Critique | Pas de contenu exploratoire, l'utilisateur voit du vide |
| S2 | **Track `onTap` commenté** — cliquer sur un résultat track ne fait RIEN | 🔴 Critique | [`search_page.dart:135`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/search/presentation/pages/search_page.dart#L134-L136) — `onTap` body est commenté |
| S3 | **Pas d'artwork dans les résultats** — Artist = `CircleAvatar` gris, Album/Track = `Container` gris | 🟠 Majeur | Aucune utilisation de `ArtworkImage` ni de `artworkPath` |
| S4 | **`ListTile` brut** — Material default tiles au lieu du design system Glass | 🟠 Majeur | Pas de `TrackListTile`, pas de `AlbumCard`, pas de `ArtistCard` |
| S5 | **Artists/Albums construits sans données** — `trackCount: 0`, `albumCount: 0`, `artistId: 0` | 🟠 Majeur | [`search_repository_impl.dart:34-35,47-48`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/search/data/repositories/search_repository_impl.dart#L34-L35) — données perdues |
| S6 | **Doublons dans résultats artists/albums** — mapping `Track → Artist` produit des doublons si plusieurs tracks du même artiste matchent | 🟡 Moyen | Pas de `distinct()` / `toSet()` |
| S7 | **Pas de résultats playlists** — le `SearchResult` ne cherche pas dans les playlists | 🟡 Moyen | — |
| S8 | **`_SearchSectionHeader` hardcodé `Colors.purpleAccent`** — hors design system | 🟡 Moyen | [`search_page.dart:198`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/search/presentation/pages/search_page.dart#L198) |
| S9 | **`autofocus: true`** — le clavier s'ouvre automatiquement à chaque switch de tab | 🟡 Moyen | UX irritante quand on browse |
| S10 | **`AppBar` standard** — pas de `CustomSliverHeader` ni de Large Title | 🟢 Mineur | Incohérence avec les autres tabs |
| S11 | **Pas de `SearchError` handling visible** — si l'état est `SearchError`, rien n'est affiché | 🟢 Mineur | Le `BlocBuilder` tombe dans le `SizedBox.shrink()` final |

---

## 4. 🎨 Vision UX — Nouvelle Search Page

### Philosophie : "Spotify Discover + Instant Results"

**État initial (pas de query) → page vivante, pas vide :**
- **Recent searches** (historique local stocké dans Isar/SharedPreferences)
- **Quick Browse** — catégories colorées (Genres, if available) ou stats rapides
- **Browse suggestions** — albums/artistes aléatoires de la bibliothèque

**Résultats → sections prioritaires avec design system :**
- Artists en premier (horizontal chips circulaires)  
- Albums en second (horizontal scroll cards)
- Tracks en dernier (liste verticale avec `TrackListTile`)

### Layout Proposé

```
┌─────────────────────────────────────────────┐
│                                              │
│  SEARCH (pas de query) :                     │
│  ┌─────────────────────────────────────────┐ │
│  │ 🔍 Search your music...            ✕   │ │  ← Glass search bar (pas autofocus)
│  └─────────────────────────────────────────┘ │
│                                              │
│  ── Recent Searches ────── [Clear All] ──  │  ← NOUVEAU: Historique
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ 🕐 Drake │ │ 🕐 Daft  │ │ 🕐 Album │   │  ← Chips cliquables
│  └──────────┘ └──────────┘ └──────────┘    │
│                                              │
│  ── Browse Your Library ───────────────── │  ← NOUVEAU: Exploration
│  ┌───────┐ ┌───────┐ ┌───────┐            │
│  │ 🎤    │ │ 🎤    │ │ 🎤    │ ...        │  ← Artistes aléatoires
│  │Artist │ │Artist │ │Artist │            │
│  └───────┘ └───────┘ └───────┘            │
│                                              │
│  ┌───────┐ ┌───────┐ ┌───────┐            │
│  │ Album │ │ Album │ │ Album │ ...        │  ← Albums récents
│  │ Cover │ │ Cover │ │ Cover │            │
│  └───────┘ └───────┘ └───────┘            │
│                                              │
│  ══════════════════════════════════════════  │
│                                              │
│  SEARCH (avec query "dra") :                 │
│  ┌─────────────────────────────────────────┐ │
│  │ 🔍 dra                             ✕   │ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  ── Top Result ────────────────────────── │  ← NOUVEAU: Mise en avant
│  ┌─────────────────────────────────────────┐ │
│  │  🎤 Drake                               │ │  ← GlassCard large
│  │  42 songs · 5 albums                    │ │
│  └─────────────────────────────────────────┘ │
│                                              │
│  ── Artists ───────────────────────────── │
│  ○ Drake  ○ DragonForce  (chips scroll)    │
│                                              │
│  ── Albums ────────────────────────────── │
│  ┌───────┐ ┌───────┐                       │
│  │ Views │ │ Take  │  → horizontal scroll  │
│  │ Drake │ │ Care  │  → avec ArtworkImage  │
│  └───────┘ └───────┘                       │
│                                              │
│  ── Tracks ────────────────────────────── │
│  ┌──────────────────────────────────────┐   │
│  │ 🎵 God's Plan  · Drake · ❤️ ···    │   │  ← TrackListTile réutilisé
│  │ 🎵 Hotline Bling · Drake · ❤️ ··· │   │
│  │ 🎵 Started From · Drake · ❤️ ···  │   │
│  └──────────────────────────────────────┘   │
│                                              │
└─────────────────────────────────────────────┘
```

---

## 5. 📚 Audit Complet — Library Page (mis à jour)

> **Note : Le point #2 (Search bar absente) est reclassifié de 🔴 Critique → ✅ Résolu par design (suppression du dead code)**

### Problèmes restants

| # | Problème | Sévérité | Fichier |
|---|----------|----------|---------|
| L1 | **`TrackShimmer` vide** — `Container()` vide | 🔴 Critique | [`track_shimmer.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/track_shimmer.dart) |
| L2 | **Vue "All" incomplète** — pas d'artistes | 🟠 Majeur | [`library_page.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L225-L279) |
| L3 | **Grilles sans spacing** — commenté | 🟠 Majeur | [`library_page.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L353-L358) |
| L4 | **`_FirstLaunchEmpty`** — `CupertinoButton.filled` hors design system | 🟡 Moyen | [`library_page.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L658) |
| L5 | **`_SectionHeader` dupliqué** — local vs global `SectionHeader` | 🟡 Moyen | [`library_page.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/library_page.dart#L418-L491) |
| L6 | **Album année hardcodée `'2024'`** | 🟡 Moyen | [`album_detail_page.dart:238`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/pages/album_detail_page.dart#L238) |
| L7 | **Pas de stats banner** | 🟠 Majeur | — |
| L8 | **Pas de Shuffle banner** en vue Tracks | 🟡 Moyen | — |
| L9 | **Cards sans badges** — `ArtistCard` et `AlbumCard` sans count | 🟢 Mineur | — |
| L10 | **Dead code `LibrarySearchBar`** — à supprimer | 🟢 Mineur | [`library_search_bar.dart`](file:///Users/macbookpro/StudioProjects/troona-music/lib/features/library/presentation/widgets/library_search_bar.dart) |

---

## 6. 📋 Plan d'Implémentation Global

### Phase 1 — Search Page Redesign (Priorité : haute)

| # | Action | Fichier | Détail |
|---|--------|---------|--------|
| 1 | 🆕 **Créer** | `search_suggestions.dart` | Widget "Browse Your Library" (artistes/albums aléatoires) pour l'état initial |
| 2 | 🆕 **Créer** | `search_top_result.dart` | GlassCard "Top Result" mise en avant |
| 3 | 🆕 **Créer** | `search_results_view.dart` | Vue résultats avec sections (Artists chips, Albums scroll, Tracks list) |
| 4 | ✏️ **Réécrire** | `search_page.dart` | CustomScrollView + Glass search bar + états initial/loading/results |
| 5 | ✏️ **Corriger** | `search_repository_impl.dart` | Dédoublonner artists/albums, renseigner `trackCount`/`albumCount` |
| 6 | ✏️ **Corriger** | `search_page.dart` | Implémenter `onTap` sur les tracks (lecture + context queue) |
| 7 | 🗑️ **Supprimer** | `library_search_bar.dart` | Dead code |

### Phase 2 — Library Page Fixes

| # | Action | Fichier | Détail |
|---|--------|---------|--------|
| 8 | ✏️ **Réimplémenter** | `track_shimmer.dart` | Vrai skeleton shimmer |
| 9 | ✏️ **Ajouter** | `library_page.dart` | Section artistes dans `_AllView` |
| 10 | ✏️ **Corriger** | `library_page.dart` | Dé-commenter grid spacing |
| 11 | 🆕 **Créer** | `library_stats_banner.dart` | "342 tracks · 28 albums · 15 artists" |
| 12 | 🆕 **Créer** | `shuffle_banner.dart` | Shuffle All en haut de vue Tracks |

### Phase 3 — Polish

| # | Action | Fichier | Détail |
|---|--------|---------|--------|
| 13 | ✏️ **Refactorer** | `_FirstLaunchEmpty` | GlassCard + GlassButton |
| 14 | ✏️ **Supprimer** | `_SectionHeader` locale | Utiliser `SectionHeader` global |
| 15 | ✏️ **Corriger** | `album_detail_page.dart` | `album.year` dynamique |
| 16 | ✏️ **Enrichir** | `artist_card.dart` / `album_card.dart` | Badges count |
