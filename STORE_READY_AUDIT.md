# Troona Store-Ready Audit

Scope: full read of `lib/`, Android and iOS platform config, the merged release manifest and the test suite, on `main` at `70971b5` (2026-10-26). Follows `AUDIT_V0.md` (2026-10-24): every V0 item was re-checked against the code, not against the commit messages.

Note on the brief: it mentions Riverpod and isolates. The project uses `flutter_bloc` only and has no isolate (`Isolate`, `compute`): everything below is written for what exists.

## Baseline measured during the audit

| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | **179 passed, 10 failed** (stale tests, see T1) |
| Release signing | **Debug key** (`android/app/build.gradle.kts:37`) |
| App icons (Android and iOS) | **Flutter default logo** (same MD5 as the Flutter template icons) |
| Merged release manifest | **No `INTERNET` permission**; `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `WRITE_EXTERNAL_STORAGE` still declared |
| UI language | French and English mixed on every screen, no i18n setup |
| Non-functional UI in the player | Lyrics (demo text), sleep timer, equalizer, speed, cast |

---

## Implementation status (updated 2026-10-26, branch `chore/store-ready`)

The findings below are kept as written during the audit. This section records what changed since, checked against the code. Each fix is covered by a test; what is not done is listed under Open.

**Updated verdict: Go for Android internal testing once S1 and S8 are done** (they need the owner's keystore and logo). Not yet Go for production: run section 5 on real devices first. iOS stays a separate milestone.

| Check | Now |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 317 passed, 0 failed (CI workflow in `.github/workflows/ci.yml`) |
| UI language | English source, French translation, gen-l10n (277 keys) |
| Merged manifest | `INTERNET`, `READ_MEDIA_AUDIO`, `READ_EXTERNAL_STORAGE` (max SDK 32), playback and notification permissions only |

### Done

| Item | What was done |
|---|---|
| T1 | Stale tests fixed; CI runs analyze and test on every push. |
| C1 to C5, P0.1, P0.2 | Lyrics, EQ and cast removed; real sleep timer and speed; fake settings removed; no "100%", "audiophile" or "Bêta" text left; "Lossless" only when every song is FLAC or WAV, otherwise the shared format, and no badge with an unknown file. |
| P0.3, S2, T11 | Online extras shipped opt-in, off by default, with two switches: bios (Last.fm) and photos (Deezer, plus Last.fm image servers). Each switch gates its own service; unreadable settings count as off. Turning photos off deletes downloaded photos, and artist or album pages already open reload without their online pictures; a photo that survives the delete stays hidden. Downloads go to a side file and are renamed into place; leftovers are removed at boot. A Deezer answer, match or miss, is remembered for the session; a network failure is not, so the next visit asks again. |
| S3, S4, S5, T6 (first half) | Photo, video and write permissions removed, read capped at API 32, backup off. **Correction to S3:** removing the permissions was not enough. `on_audio_query_plus_android` refused every query without `READ_MEDIA_IMAGES` and `WRITE_EXTERNAL_STORAGE`, so the plugin is vendored in `third_party/` with a two-line patch (see `TROONA_PATCH.md`). |
| S7, S13 (Android part) | Privacy policy in `docs/privacy-policy.md` and in Settings. Data Safety answers below. |
| S10 | Version read with `package_info_plus`. |
| P0.7, U2 | gen-l10n, EN and FR, sentence case; data and domain no longer produce UI text (failure messages are for logs only). French plurals use `one{}` so zero reads "0 morceau". |
| T2, T3, T4, T5, T7, T8 | Pure filter and sort on copies, accent and "The" aware; one Isar read per load; albums by id; 10 s floor, no size floor; no playlist cap; rows select only what they show. |
| T9, T10, U7 | Artwork checked once per track, written in batches of 50, progress streamed; silent rescans with a toast for added or removed songs, and a toast when a rescan fails. A rescan that restarts or fails keeps the library on screen; events of a superseded scan are dropped. |
| T12 | Crash log writes are queued and asynchronous; the file is trimmed to 500 lines when opened and after every 500 lines appended. A fatal error followed by an immediate process death can lose its last entry. |
| T13 | Session stored in two keys: the queue, written only when it changes, and the small playback state. Both carry a queue revision, so a session cut between the two writes is dropped instead of restored with the wrong queue. The old key still loads and is migrated. |
| T14 | Lock screen position re-anchored on every track change and after in-app seeks; `queueIndex` published; a queue edit no longer rewinds the position. **Open:** playback speed is not forwarded to the OS (the port exposes no speed stream), so at 1.5x the lock screen drifts until the next 2 s correction. |
| T15 | Permission state cached; no automatic jump to system settings. |
| G1, G2, G3 | Permission page without blur; Now Playing keeps two blurs (lens and dock), dock sheets opaque; headers read the sigma from `GlassTheme` and skip the filter at 0. |
| U1, U3, U4, U5, U9, U10 | One toast (`AppToast`, also usable after its route closes) and one dialog; `EmptyState` with title, body and action; Home in three states without repeating the song count; late-night greeting; one `SectionHeader`; leftover comment gone. |
| U8 | Dock reduced to queue, sleep timer and speed, 44 px targets. |
| Shuffle | Every Shuffle button starts on a random song with shuffle mode on, in one queue load, and keeps the source order so turning shuffle off restores it. |
| Accessibility | Labelled controls keep their tap action for screen readers; the nav bar is icon only with labels and selection exposed. |
| Notification | Channel name localized from the device languages. |
| Android launch | Dark launch window and Android 12 splash background instead of a white flash. |
| T16 | `PlayerBloc` restores the session through `GetTracksByIdsUseCase`, without Isar or `flutter_animate`; playlist widgets go through use cases, and the Likes id lives on the domain entity. |
| 1.4 (items 1 and 2), plan item 23 | Daily totals that outlive the 500-event cap, built once from the stored events. "Your week in music" card on Home (last finished week, refreshed on Mondays) and its page: listening time, plays, top song, top artist, first listens, and the month as dots. First listens are shown only once the history reaches four weeks before the week, so an old favourite is not taken for a discovery. Weeks rebuilt from old events have no listening time and show plays instead. |
| T17 | No em dash and no French left in code comments (the two RegExp character classes in the Last.fm DTOs keep theirs on purpose). |

### Open

| Item | Status |
|---|---|
| S1 | Signing is wired (`key.properties`, example in `android/key.properties.example`). The owner still has to create the upload key and enroll in Play App Signing. |
| S8, S14, P0.6 | Needs the Troona logo. The launcher icon is still Flutter's; the splash will pick up the real icon automatically. Adaptive (foreground, background) and monochrome layers to add once the artwork exists. |
| S9 | Store screenshots, feature graphic, listing text. |
| U6, T6 (second half), 1.4 item 3 | P2: personal artist ranking, stable track identity, monthly "Replay" playlist. |
| S11, S12, S15 | iOS milestone, postponed by the owner. |

### Data Safety answers (Google Play)

| Question | Answer |
|---|---|
| Does the app collect or share user data? | No data collected. Shared: only when the user turns on an online extra. |
| Shared data | "Music files" category does not apply (files never leave the device). Artist and album names are sent to Last.fm and Deezer as search terms when a switch is on; Play has no exact category, declare "App activity: other user-generated content" as shared, optional, not linked to an identity. |
| Encrypted in transit | Yes (HTTPS). |
| Can users request deletion? | Yes: "Clear downloaded info" in Settings, or uninstall. Nothing is stored server side by Troona. |
| Account | None. |
| Ads, analytics, crash reporting SDKs | None. Problem reports are shared manually by the user through the share sheet. |

---

## 0. Verdict

**Not ready. No-Go for both stores.** The engine is good: the player bloc, the queue editing, session restore and the error stream wiring are solid and tested. What blocks is everything a store reviewer or a first-day user sees in five minutes:

1. **Fake features** in the Now Playing dock and in Settings. Apple rejects these under Guideline 2.1 (App Completeness); Google under its Deceptive Behavior policy when the store listing promises them.
2. **Claims that are false**: "100% private", "no tracking", "100% local data", "Lossless" on every album, while artist and album names are sent to Last.fm and Deezer by default.
3. **Store hygiene**: debug signing, Flutter placeholder icon, unused photo and video permissions (Google Play Photo and Video Permissions policy), no privacy policy, no Data Safety answers.
4. **A release build that cannot reach the network**, so the online metadata feature is silently dead for every user while still being advertised in Settings.
5. **A language that changes from one screen to the next**, and a red test suite.

Estimated effort to reach a submittable Android build: **5 to 7 working days** for P0 and P1 in section 4. iOS is a separate milestone (see S7).

---

## 1. Product, UI/UX and copy

### 1.1 Design system and aesthetics

The token hierarchy (`lib/core/theme/`) and the Now Playing morph are at the level of the references. The gaps are consistency gaps, not taste gaps.

| # | Severity | Finding | Where | Fix |
|---|---|---|---|---|
| U1 | High | Three visual languages coexist: custom glass (player, nav bar), stock Material (`CircularProgressIndicator`, `SnackBar`, `ElevatedButton`, `AlertDialog`) and Cupertino (`CupertinoActivityIndicator`, `CupertinoAlertDialog`). Loading on Home is a Material spinner, on Settings a Cupertino one. | `home_page.dart:53`, `error_view.dart`, `app_shell.dart` (notices), every `showSnackBar` | One `AppToast` (glass pill above the mini player), one `AppDialog`, one loading skeleton (`shimmer_row.dart` exists and is unused on Home). |
| U2 | High | Title Case everywhere ("Recently Played", "View All", "Your Top This Week"). Apple Music and Spotify both use sentence case for headers and buttons. | Home, Library, nav bar | Sentence case across the app (section 1.3). |
| U3 | Medium | `EmptyState` ignores its `icon` parameter and always draws `Icons.playlist_play`. Every empty state shows the same icon. | `empty_state.dart:17` | Use `icon`, add an optional title, body and action (snippet below). |
| U4 | Medium | Cold start is wrong: `isColdStart` means "no plays", not "no music". A user with 2,000 songs and no plays yet sees a **"Scan Library"** hero, which suggests nothing was found. | `home_feed.dart:39`, `home_hero_banner.dart:115` | Three states: empty library (scan CTA), library but no plays ("Shuffle all {n} songs"), warm (resume). |
| U5 | Medium | The greeting says "Good Evening" from 17:00 to 04:59. At 2 AM it reads as a bug. | `home_page.dart:307` | Add a late-night variant (23:00 to 05:00). |
| U6 | Medium | "Your Artists" on Home is the first 5 artists in Isar insertion order (alphabetical by first track title), not personal. "New in Library" sorts by `indexedAt`, which is identical for every track of the first scan. | `isar_library_data_source.dart` `getUniqueArtists` / `getUniqueAlbums` | Artists: rank by plays over 30 days, fall back to track count. New: sort by `dateAdded` (MediaStore), not `indexedAt`. |
| U7 | Medium | A rescan banner slides over the content **on every launch**, because every launch rescans and the artwork phase retries every track that has no cover (T9). | `app_shell.dart` `_LibraryRescanBanner` | Silent background rescan. Only surface a toast when something changed: "3 new songs added". |
| U8 | Medium | Dock items are 38 px high in a dock 60% of the screen wide with 6 items (about 39 px each). Below the 44 pt (Apple) and 48 dp (Material) minimum touch targets. | `player_utility_dock.dart` | Keep 3 items (queue, sleep timer, speed) at 44 px minimum. |
| U9 | Low | The playlist detail page lives in `presentation/widgets/` and the "section heater" file name has a typo (`section_heater.dart`, a duplicate of `home/.../section_header.dart`). | `playlist/presentation/widgets/playlist_detail_page.dart`, `shared/widgets/section_heater.dart` | Move and dedupe. |
| U10 | Low | Leftover generated comment in production code: `// (I am keeping them identical to your previous version but ensuring they are in the file)`. | `app_shell.dart:283` | Delete. |

`EmptyState` with a real hierarchy (title, body, optional action), the base for every empty state in 1.3:

```dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  // const constructor omitted

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // AppTypography only defines the Now Playing styles today: add title
    // and body tokens there rather than inlining sizes on every screen.
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 40, color: colors.labelTertiary),
        const SizedBox(height: AppSpacing.lg),
        Text(title, textAlign: TextAlign.center, style: text.titleMedium),
        if (body != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(body!, textAlign: TextAlign.center,
              style: text.bodyMedium?.copyWith(color: colors.labelSecondary)),
        ],
        if (onAction != null) ...[
          const SizedBox(height: AppSpacing.xl),
          GlassButton.filled(label: actionLabel!, onTap: onAction!),
        ],
      ]),
    );
  }
}
```

### 1.2 Truth in claims (store compliance, not style)

This is the most important part of section 1: these lines get an app rejected or reported, independently of how good they read.

| # | Claim in the app | Reality | Action |
|---|---|---|---|
| C1 | "100% privée", "Aucun compte requis, aucun suivi. Vos morceaux restent exclusivement sur votre appareil." (permission page), "Données 100% locales", "Lecteur audiophile 100% hors-ligne & respectueux de la vie privée" (Settings footer) | `fetchOnlineMetadata` and `fetchArtistArtwork` default to `true` (`app_settings.dart:59`). Artist and album names from the user's library, plus the device IP, go to Last.fm and Deezer. | Either make online extras **opt-in** (recommended, see C5) or remove every "100%" claim. "Your files never leave this device" stays true and is the honest promise. |
| C2 | "Lossless" badge on every album page | Hardcoded (`album_detail_page.dart:484`), shown for MP3 and AAC too. | Show it only when every track of the album is FLAC, ALAC or WAV. Otherwise show the format ("MP3", "FLAC"). |
| C3 | "Qualité Studio Sans Perte", "décodage audiophile", "Décodage haute fidélité sans perte" | The app plays files through ExoPlayer and AVPlayer at their native quality. There is no special decoder. | "Plays your files at their original quality." |
| C4 | Synced lyrics, sleep timer, equalizer, speed, AirPlay/Cast in the player dock | Lyrics show the same French demo text for every song (`lyrics_modal.dart:21`, `kDefaultLyrics`, whose first line literally says these are sample lyrics to replace). Timer, EQ and speed only change a label in `setState`. Cast lists devices that do not exist. | Remove lyrics, EQ and cast. Wire speed (the use case already exists) and implement the sleep timer (snippet in 2.5). |
| C5 | Settings: "Lecture sans blanc (Gapless)", "Uniquement en Wi-Fi", "Pochette dans la notification" | No code reads `gaplessPlayback`, `metadataWifiOnly` or `showAlbumArtInNotification` outside the settings feature. `JustAudioAdapter.applySettings` is fully commented out. | Remove the three toggles (gapless is already the default behaviour of a just_audio playlist). Wire Wi-Fi only later with `connectivity_plus` if the online extras stay. |

Recommendation on online metadata: **opt-in, off by default**, presented once after the first scan as a single card on Home ("Add artist photos and bios?"). It keeps the offline promise true, it is the simplest Data Safety and App Privacy answer, and the feature is better received when chosen. Trade-off: fewer users will see artist photos. The alternative (on by default) forces you to declare third-party data sharing in both stores and to keep a privacy policy that names Last.fm and Deezer.

Also check the API terms before shipping: the Last.fm API and the Deezer API both have their own terms (attribution, commercial use, caching). The Last.fm key is hardcoded (`api_endpoints.dart:3`); a key in a client app is never secret, so this is about quota abuse and terms, not about leaking a credential.

### 1.3 Copy and microcopy

#### Voice

- **Language first.** Today the permission page, Library, Search, Playlists, Settings and the player dock are French; Home, the nav bar, the queue, the track menu, the scan screen and errors are English; French mixes "tu" (Search, Library empty state) and "vous" (everything else). Decision: **English as the source language, French as the first translation**, through `flutter_localizations` and `gen-l10n` (ARB files). Both stores show listings per locale, and an app whose UI does not match its listing language reads as unfinished.
- **Calm, warm, short.** Speak about the user's music, not about the app. "Your library" beats "Troona indexes your files in an Isar database".
- **No internals.** Never show Isar, GPU tier, ducking, crash logs, raw exception text or file paths.
- **Verbs on buttons.** "Allow access", "Shuffle all", "Clear". Not "OK", "Yes".
- **Sentence case** for everything except the app name.
- **Errors say what happened and what happens next**, in that order, without blame and without "Oops".
- **No emoji in UI chrome** ("Hidden Gems 💎"), no ":(" in errors.
- **Plurals through ICU**, never `'$n songs'` ("1 songs found" is shipped today in `app_shell.dart`).

#### Rewritten strings (EN source, FR translation)

**Onboarding and permission** (`permission_page.dart`)

| Key | Today | EN | FR |
|---|---|---|---|
| headline | Votre musique. Sublimée et sans compromis. | All your music. Nothing in the way. | Toute votre musique. Rien entre elle et vous. |
| subhead | Un lecteur audio haute fidélité qui révèle votre collection locale… | Troona plays the songs already on your phone. No account, no ads, no streaming. | Troona lit les morceaux déjà présents sur votre téléphone. Sans compte, sans publicité, sans streaming. |
| feature1 | Qualité Studio Sans Perte / décodage audiophile | **Plays what you own.** MP3, FLAC, AAC, WAV, OGG and Opus, at their original quality. | **Lit ce qui vous appartient.** MP3, FLAC, AAC, WAV, OGG et Opus, dans leur qualité d'origine. |
| feature2 | Aucun compte requis, aucun suivi… | **Private by design.** Your music stays on this device. Online extras are optional. | **Privé par conception.** Votre musique reste sur cet appareil. Les extras en ligne sont optionnels. |
| feature3 | Bibliothèque Intelligente | **Ready in seconds.** Covers, albums and artists, sorted for you. | **Prête en quelques secondes.** Pochettes, albums et artistes, classés pour vous. |
| rationale | Troona a besoin d'accéder à votre stockage audio… | Troona needs access to your audio files to build your library. It never reads your photos, videos or documents. | Troona a besoin d'accéder à vos fichiers audio pour créer votre bibliothèque. Il ne lit jamais vos photos, vidéos ou documents. |
| cta | Explorer ma musique | Allow access | Autoriser l'accès |
| denied.title | Autorisation nécessaire | Troona can't see your music yet | Troona ne voit pas encore votre musique |
| denied.cta | Réessayer l'autorisation | Try again | Réessayer |
| blocked.title | Accès désactivé dans le système | Access is turned off | L'accès est désactivé |
| blocked.body | (none) | Turn on "Music and audio" for Troona in Settings, then come back. We'll take it from there. | Activez « Musique et audio » pour Troona dans les Réglages, puis revenez : on s'occupe du reste. |
| blocked.cta | Ouvrir les Réglages | Open Settings | Ouvrir les Réglages |
| footer | Gratuit • Sans publicité • Données 100% locales | Free · No ads · No account | Gratuit · Sans publicité · Sans compte |

Behaviour fix on the same screen: `requestAudioPermission` calls `openAppSettings()` by itself on a permanent denial (`permission_handler.dart:51`). The user taps "Allow" and lands in system settings without explanation. Show the "blocked" state and let the user tap "Open Settings".

**First scan** (`app_shell.dart`)

| Key | Today | EN | FR |
|---|---|---|---|
| title | Loading your music | Finding your music | On rassemble votre musique |
| phase.scan | Scanning your device for songs... | Looking for songs on your phone… | Recherche des morceaux sur votre téléphone… |
| phase.index | Indexing your library... | Building your library… | Création de votre bibliothèque… |
| phase.covers | Loading album artwork... | Adding album covers… | Ajout des pochettes… |
| phase.done | Preparing your home screen... | Almost ready… | Presque prêt… |
| count | `'${n} songs found'` | `{n, plural, =1{1 song found} other{{n} songs found}}` | `{n, plural, =1{1 morceau trouvé} other{{n} morceaux trouvés}}` |
| rescan.toast | (banner on every launch) | `{n, plural, =1{1 new song added} other{{n} new songs added}}` | `{n, plural, =1{1 nouveau morceau ajouté} other{{n} nouveaux morceaux ajoutés}}` |

**Home** (`home_page.dart`, `home_hero_banner.dart`, `quick_access_row.dart`)

| Key | Today | EN | FR |
|---|---|---|---|
| greeting.morning (05 to 12) | Good Morning | Good morning | Bonjour |
| greeting.afternoon (12 to 18) | Good Afternoon | Good afternoon | Bon après-midi |
| greeting.evening (18 to 23) | Good Evening | Good evening | Bonsoir |
| greeting.night (23 to 05) | Good Evening | Late-night session | Session de nuit |
| subtitle.warm | Welcome back to your music | Pick up where you left off. | Reprenez là où vous en étiez. |
| subtitle.noPlays | Welcome back to your music | `{n} songs, ready when you are.` | `{n} morceaux, prêts quand vous l'êtes.` |
| hero.empty.title | Your music, offline. Always. | No music here yet | Pas encore de musique ici |
| hero.empty.body | (none) | Copy songs to your phone's Music folder, then scan again. | Copiez des morceaux dans le dossier Musique de votre téléphone, puis relancez la recherche. |
| hero.empty.cta | Scan Library | Scan again | Relancer la recherche |
| hero.noPlays.cta | Scan Library | Shuffle all | Tout lire en aléatoire |
| hero.warm.label | Continue listening | Jump back in | Reprendre |
| quick.likes | Likes | Liked songs | Titres aimés |
| quick.shuffle | Shuffle | Shuffle all | Aléatoire |
| quick.recent | Recent | Recently added | Ajouts récents |
| section.recent | Recently Played | Recently played | Écoutés récemment |
| section.top | Your Top This Week | On repeat this week | En boucle cette semaine |
| section.gems | Hidden Gems 💎 | Rediscover | À redécouvrir |
| section.gems.sub | (none) | Songs you liked and haven't played in a while. | Des titres aimés, un peu oubliés. |
| section.artists | Your Artists | Your artists | Vos artistes |
| section.new | New in Library | Recently added | Ajouts récents |
| section.playlists | Your Playlists | Your playlists | Vos playlists |
| seeAll | View All | See all | Tout voir |
| error | raw `state.message` | We couldn't load your home. Pull down to try again. | Impossible de charger l'accueil. Tirez vers le bas pour réessayer. |

**Settings** (`settings_page.dart`). Trimmed to what works, in this order:

| Key | Today | EN | FR |
|---|---|---|---|
| title | Réglages | Settings | Réglages |
| section.playback | Lecture & Audio | Playback | Lecture |
| duck | Atténuer le volume sur notification | Lower volume for notifications | Baisser le volume pendant les notifications |
| pauseOnCall | Pause lors d'un appel entrant | Pause during calls | Mettre en pause pendant les appels |
| resumeAfterCall | Reprendre la lecture après l'appel | Resume after calls | Reprendre après les appels |
| section.library | Bibliothèque & Stockage | Library | Bibliothèque |
| library.footer | Troona indexe vos fichiers audio locaux dans une base Isar ultra-rapide… | (remove) | (supprimer) |
| rescan | Réanalyser la bibliothèque / Actualiser les nouveaux morceaux ajoutés | Rescan library / Updated {relativeTime} | Actualiser la bibliothèque / Mise à jour {relativeTime} |
| covers.clear | Vider le cache des pochettes | Clear cover cache / Frees {size} | Vider le cache des pochettes / Libère {size} |
| covers.confirm.title | Vider le cache des pochettes ? | Clear cover cache? | Vider le cache des pochettes ? |
| covers.confirm.body | Toutes les images d'albums mises en cache seront supprimées… | Covers reload in the background. Your music, likes and playlists aren't affected. | Les pochettes se rechargent en arrière-plan. Votre musique, vos titres aimés et vos playlists ne sont pas touchés. |
| section.online | Métadonnées en ligne | Online extras | Extras en ligne |
| online.footer | Télécharge les biographies d'artistes… via Last.fm… (30 jours) | Optional. When on, Troona sends artist and album names to Last.fm and Deezer to fetch photos and bios. Your music files never leave this device. | Optionnel. Activé, Troona envoie les noms d'artistes et d'albums à Last.fm et Deezer pour récupérer photos et biographies. Vos fichiers ne quittent jamais cet appareil. |
| online.bios | Métadonnées en ligne | Artist bios and album notes | Biographies et notes d'albums |
| online.photos | Photos d'artistes en ligne | Artist photos | Photos d'artistes |
| online.clear | Vider le cache des métadonnées | Clear downloaded info | Effacer les infos téléchargées |
| section.appearance | Apparence & Performance | Appearance | Apparence |
| glass | Qualité du Glassmorphism / Auto · Haute · Éco · Off | Glass effects / Auto · Full · Light · Off | Effets de verre / Auto · Complet · Léger · Désactivé |
| glass.footer | Mode GPU matériel détecté : HIGH… | Auto adapts to your phone. Choose Light or Off for smoother scrolling on older devices. | Auto s'adapte à votre téléphone. Choisissez Léger ou Désactivé pour plus de fluidité sur les appareils anciens. |
| haptics | Retours haptiques / Vibrations subtiles lors des interactions | Haptics | Vibrations |
| section.support | Support & Bêta Testeurs | Help and feedback | Aide et retours |
| feedback | Envoyer un feedback / Signaler un bug | Send feedback | Envoyer un avis |
| report | Copier le rapport de diagnostic / Presse-papiers complet (OS, GPU, mémoire, Isar) | Report a problem / Includes device info and recent errors. No music or personal data. | Signaler un problème / Inclut les infos de l'appareil et les erreurs récentes. Aucune musique ni donnée personnelle. |
| crashLogs | Journaux d'erreurs (Crash Logs) | (fold into "Report a problem") | (intégré à « Signaler un problème ») |
| privacy | (missing) | Privacy policy | Politique de confidentialité |
| licenses | (missing) | Open-source licenses (`showLicensePage`) | Licences open source |
| section.reset | Maintenance & Réinitialisation | Reset | Réinitialiser |
| forgetQueue | Effacer la session de lecture | Clear queue and position | Effacer la file et la position |
| resetSettings.body | Toutes les options seront réinitialisées… | All preferences go back to their defaults. Your library, likes and playlists stay as they are. | Toutes les préférences reviennent à leurs valeurs par défaut. Votre bibliothèque, vos titres aimés et vos playlists restent intacts. |
| footer | Troona Music • Version 1.0.0 • Build 1 (hardcoded) | Troona {version} ({build}) from `package_info_plus` | Troona {version} ({build}) |
| tagline | Lecteur audiophile 100% hors-ligne… | Made for the music you own. | Pensé pour la musique qui vous appartient. |

**Empty states**

| Screen | EN title / body / action | FR |
|---|---|---|
| Library, no music | No music on this device yet / Copy songs to your phone, then scan again. / Scan again | Pas encore de musique sur cet appareil / Copiez des morceaux sur votre téléphone, puis relancez la recherche. / Relancer la recherche |
| Library, filter with no match | No results for "{query}" / Check the spelling or try another word. | Aucun résultat pour « {query} » / Vérifiez l'orthographe ou essayez un autre mot. |
| Albums / Artists empty | No albums yet / No artists yet | Aucun album pour l'instant / Aucun artiste pour l'instant |
| Liked songs empty | Songs you like will live here / Tap the heart on any song to save it. | Vos titres aimés vivront ici / Touchez le cœur d'un morceau pour l'enregistrer. |
| Playlist empty | This playlist is empty / Add songs from the ··· menu on any track. / Add songs | Cette playlist est vide / Ajoutez des morceaux depuis le menu ··· d'un titre. / Ajouter des morceaux |
| Playlists tab empty | Make your first playlist / Group songs for a mood, a moment or a road trip. / New playlist | Créez votre première playlist / Rassemblez des morceaux pour une humeur, un moment ou un road trip. / Nouvelle playlist |
| Search, idle | Search your library / Songs, artists and albums on this device. Hint: "Songs, artists, albums" | Rechercher dans votre bibliothèque / Morceaux, artistes et albums de cet appareil. Indice : « Morceaux, artistes, albums » |
| Search, no result | No results for "{query}" / Try a shorter word or an artist name. | Aucun résultat pour « {query} » / Essayez un mot plus court ou un nom d'artiste. |
| Queue, nothing next | Nothing up next (keep "Repeating this song", "Then back to the start") | Rien ensuite / Lecture en boucle de ce titre / Puis retour au début |

**Menus and toasts** (`show_track_actions.dart`, `add_to_playlist_sheet.dart`, `playlist_page.dart`)

| Key | Today | EN | FR |
|---|---|---|---|
| playNext | Play Next | Play next | Lire ensuite |
| addToQueue | Add to Queue | Add to queue | Ajouter à la file |
| like / unlike | Like / Unlike | Like / Remove from Liked songs | Aimer / Retirer des titres aimés |
| addToPlaylist | Add to Playlist... | Add to playlist… | Ajouter à une playlist… |
| goAlbum / goArtist | Go to Album / Go to Artist | Go to album / Go to artist | Voir l'album / Voir l'artiste |
| toast.playNext | Playing next: {title} | Plays next | Lu ensuite |
| toast.queued | Added to queue: {title} | Added to queue | Ajouté à la file |
| toast.liked | Added to Likes | Added to Liked songs | Ajouté aux titres aimés |
| toast.playlist | Ajouté à "{name}" | Added to {name} · Undo | Ajouté à {name} · Annuler |
| likes.name | Titres likés (stored in Isar, `isar_library_data_source.dart:244`) | Liked songs (display string, not data, see T6) | Titres aimés |
| deletePlaylist.title | Supprimer la playlist | Delete "{name}"? | Supprimer « {name} » ? |
| deletePlaylist.body | Voulez-vous vraiment supprimer… Cette action est irréversible. | This removes the playlist only. The songs stay in your library. | Seule la playlist est supprimée. Les morceaux restent dans votre bibliothèque. |
| deletePlaylist.cta | Supprimer | Delete | Supprimer |

**Errors** (`error_view.dart`, `error_handler.dart`, `boot_failure_app.dart`, player notices)

| Case | Today | EN | FR |
|---|---|---|---|
| Generic | "Oups, une erreur est survenue :(" + raw message (`CacheFailure('Unexpected error: $error')`, `error_handler.dart:37`) | Something went wrong. Try again. | Un problème est survenu. Réessayez. |
| Unplayable track | raw ExoPlayer message ("Source error") | Can't play "{title}". Skipping to the next song. | Impossible de lire « {title} ». Passage au titre suivant. |
| Three in a row | (none) | Several songs couldn't be played, so playback is paused. | Plusieurs morceaux n'ont pas pu être lus : lecture en pause. |
| File gone | (none) | This song is no longer on your phone. | Ce morceau n'est plus sur votre téléphone. |
| Boot failure | Failed to start Troona / An unexpected error occurred during initialization… / Retry -> "Please relaunch the app" | Troona couldn't open your library / Restart the app. If it keeps happening, send us a report. / Copy report | Troona n'a pas pu ouvrir votre bibliothèque / Redémarrez l'application. Si cela se reproduit, envoyez-nous un rapport. / Copier le rapport |

The "Retry" button on the boot screen that only opens a dialog saying "relaunch the app" should go: a button that does not do what it says is worse than no button.

**Player dock** (after removing the fake items)

| Key | EN | FR |
|---|---|---|
| queue | Queue | File d'attente |
| sleep | Sleep timer | Minuteur |
| sleep.options | 15 min · 30 min · 45 min · 1 hour · End of song · Off | 15 min · 30 min · 45 min · 1 heure · Fin du morceau · Désactivé |
| sleep.toast | Music stops in {duration}. | La musique s'arrête dans {duration}. |
| speed | Playback speed / 0.75× · 1× · 1.25× · 1.5× · 2× | Vitesse de lecture |

Android also shows strings outside the app: `android:label="troona"` (`AndroidManifest.xml:17`) should be "Troona", and the notification channel name "Troona Music" (`audio_service_initializer.dart`) is what users see in system settings: "Playback controls" / "Commandes de lecture" is clearer.

Minimal i18n setup (no new runtime dependency besides the SDK one):

```yaml
# pubspec.yaml
dependencies:
  flutter_localizations:
    sdk: flutter
  intl: any
flutter:
  generate: true
```

```yaml
# l10n.yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
```

```json
{
  "scanSongsFound": "{count, plural, =1{1 song found} other{{count} songs found}}",
  "@scanSongsFound": { "placeholders": { "count": { "type": "int" } } }
}
```

Domain and data layers must stop producing user-facing text (`Failure.message`, `likesPlaylistName`, scan labels in `library_state.dart`): they return types, the presentation maps them to `AppLocalizations`.

### 1.4 Listening streaks

**Verdict: no streak counter. Yes to a weekly ritual built on the same data.**

Why not a "days in a row" counter:
- A streak works when the action is a chore the user wants to be pushed into (language learning, fitness). Listening to music is already intrinsically rewarding. A counter turns pleasure into an obligation, and breaking it creates guilt, which is the opposite of what a music app should make people feel.
- Its main lever is the loss-aversion notification ("Don't lose your 12-day streak"). Troona has no notification channel other than the playback one, and adding reminders for an offline player would be intrusive.
- Streaks punish the most normal behaviours: a day without headphones, a flight, a week of podcasts in another app.
- Neither Apple Music nor Spotify builds its engagement on daily streaks. They lean on **recaps** (Replay, Wrapped, "On Repeat"): looking back at what you loved, not counting what you missed. That is the brand register Troona is aiming for.

What to build instead, in order, all local:

1. **"Your week in music"** card on Home, refreshed every Monday: listening time, top artist, top song, number of songs discovered (first play ever). Tapping it opens a single glass page. One card, no badge, no notification.
2. **Listening calendar** inside that page: the current month as a row of dots, filled on days with at least one counted play. It shows rhythm without a number to protect, and a missed day is just an empty dot.
3. **Monthly "Replay"** playlist generated on the 1st: the 25 most played songs of the previous month, saved as a normal playlist the user can keep or delete.

Data prerequisite: the play history is capped at 500 events (`IsarPlayHistoryDataSource`, `maxEvents = 500`). A daily listener with 40 plays a day loses everything older than about 12 days, so no weekly or monthly feature is possible on the current model. Add an uncapped daily aggregate (365 small rows a year), written by the same `PlayHistoryRecorder` in the same transaction as the event:

```dart
@collection
class ListeningDayModel {
  /// Days since epoch in local time: one row per calendar day.
  @Index(unique: true)
  late int day;
  int plays = 0;
  int listenedSeconds = 0;
  /// First plays ever of a track on that day.
  int discoveries = 0;
}
```

`listenedSeconds` needs the recorder to accumulate position deltas (ignoring seeks), which `PlayCounter` already almost does. Test cases: play across midnight counts on both days; a seek forward does not add time; a track replayed the same day is not a discovery; DST change day still maps to one row.

---

## 2. Engine: performance, memory, robustness

### 2.1 Subscriptions and lifecycle

| Owner | Subscriptions | Lifetime | Verdict |
|---|---|---|---|
| `PlayerBloc` | 8 port streams, notices controller, `ValueNotifier` | Singleton; `close()` cancels all, disposes the notifier after `super.close()` | OK |
| `LibraryBloc` | `_scanSub` | Factory per shell mount; `_cancelScan` now calls the scanner's `cancel()` | OK (V0 S1 fixed) |
| `AppShell` | router delegate listener, notices subscription | Removed and cancelled in `dispose()` | OK |
| `AudioHandlerImpl` | 3 port streams | App lifetime, never cancelled | Acceptable: process-wide singleton |
| `PlayHistoryRecorder`, `AudioSessionService` | 2 and 3 | Singletons with `dispose()` | OK |
| `MetadataRepositoryImpl` | broadcast controller | Singleton, never closed | Acceptable |
| `JustAudioAdapter` | `currentIndexStream.listen` not stored | App lifetime | Acceptable; store it to make `dispose()` complete |
| Isar | one instance opened in `AppDatabase.open()` | App lifetime, never closed | Correct for Isar: closing on background is not needed |

No leak found in the Bloc layer. The memory risks are elsewhere: whole-library lists held three times (T3) and synchronous work on the UI isolate.

### 2.2 Findings

| # | Severity | Finding | Where | Fix |
|---|---|---|---|---|
| T1 | **Blocker** | 10 tests fail: the Home fake library has no `getLikedTrackIds`, the settings tests expect `themeMode` dark and an old `CrossfadeStyle` order, and the queue sheet test still expects `PlayerError` on a decoder error (the V0 fix deliberately removed that). The fixes landed without their tests. | `test/unit/home/`, `test/unit/settings/`, `test/widget/player/queue_sheet_test.dart:296` | Update fakes and expectations; add the CI step in section 5 so it cannot drift again. |
| T2 | **Blocker** | Library sort mutates the source list. With an empty query, `filteredTracks` **is** `allTracks`, and `.sort()` sorts it in place. "Date added" then does nothing ("already in insertion order"), so after any other sort it keeps that order. It also mutates the state's lists behind Equatable. Sorting is case-sensitive and accent-sensitive ("été" after "Zebra", "a" after "Z"). | `library_bloc.dart:371`, `:416`, `:429` | Copy before sorting, sort on a normalized key, sort "date added" on `dateAdded` (snippet below). |
| T3 | High | `_readLoadedState` calls `getTracks`, `getAlbums` and `getArtists` in parallel; each one runs `getAllTracks()`, a synchronous full Isar read on the UI isolate. Three full reads and three entity mappings per load, at boot and after every scan. Around 5,000 tracks this is a visible freeze. | `library_bloc.dart:171`, `library_repository_impl.dart` | One read, group in memory (snippet below). |
| T4 | High | Albums are grouped by album **name** only. Every "Greatest Hits", "Live", "Unknown Album" or "Untitled" across artists becomes one album. | `library_repository_impl.dart:54` | Group by `albumId` (MediaStore already distinguishes them), fall back to `(album, albumArtist)`. |
| T5 | High | Tracks under 45 s or 512 KB are dropped by the scanner. Intros, skits and interludes are common on albums: those albums look incomplete and users report "missing songs". | `local_audio_data_source.dart:38-39` | Rely on MediaStore flags (`isRingtone`, `isNotification`, `isAlarm`) already checked below; lower the floor to 10 s and drop the size floor. |
| T6 | High | Library identity is the MediaStore `_ID`, and Android Auto Backup is on by default (no `android:allowBackup` in the manifest). On a new phone, the restored Isar file keeps likes, playlists and history pointing at IDs that now belong to **other songs**. | `track_model.dart` (`deviceId`), `AndroidManifest.xml` | Set `android:allowBackup="false"` now. Later: a stable key (relative path + size + duration) to survive MediaStore rebuilds. |
| T7 | High | Silent playlist loss: `getPlaylists({int limit = 50})`. A user's 51st playlist never appears. | `isar_library_data_source.dart:103` | No limit on the Playlists tab; keep `limit` only for the Home row. |
| T8 | Medium | Every visible track row rebuilds on every `PlayerState` emission (`context.watch<PlayerBloc>().state`): status, queue edits, duration, and each step of a volume drag. | `track_list_tile.dart:43`, `album_track_list_tile.dart:49` | `context.select` on the two booleans the row uses (snippet below). |
| T9 | Medium | Tracks without embedded artwork are never marked as checked. Every launch rescans and calls `queryArtwork` again for each of them, then writes **one Isar transaction per cover** on the UI isolate. On a library with many untagged files, this is minutes of work and battery at every start, and it keeps the rescan banner on screen. | `artwork_extractor.dart:117`, `isar_library_data_source.dart:400`, `library_bloc.dart:79` | Store a "no artwork" marker (empty string) and exclude it from `getTracksWithoutArtwork`; batch artwork updates by 50 in one `write`. |
| T10 | Medium | Artwork progress is still buffered (V0 S2 not fixed): the dispatch loop awaits the semaphore before `yield* controller.stream`, so no artwork progress reaches the UI until all but the last 4 extractions are dispatched. | `artwork_extractor.dart:78`, `:101` | Start the dispatcher unawaited, then `yield*` (snippet below). |
| T11 | Medium | Artist and album images are downloaded straight to their final path. A timeout or a killed process leaves a truncated JPEG that the `length() > 0` check treats as cached **forever**. | `metadata_repository_impl.dart:165`, `:228` | Download to `*.part`, then `rename` (snippet below). |
| T12 | Medium | `CrashLog.record` reads the whole log file and rewrites it **synchronously** for every line, on the UI isolate. In release, every `appLogger.w` line goes through it, so a burst of warnings (scan errors, network failures) blocks frames. Trimming counts lines, but entries are multi-line stack traces. | `crash_log.dart:34`, `:60` | Async append to a file; trim by size once at `init()`. |
| T13 | Medium | Session persistence JSON-encodes the full queue (original and playback ID lists) and writes `SharedPreferences` on **every** state change: status, track, volume step, duration. With a 5,000-song "play all" queue that is two 5,000-element lists per volume step. | `player_bloc.dart` `_persistSession` (called from about 10 handlers) | Persist the queue only on `_QueueChanged`; persist position, index, volume and speed through a 2 s debounce and on `AppLifecycleState.paused`. |
| T14 | Medium | Lock screen position drifts after an automatic track change: `playbackState.updatePosition` is only refreshed on status changes, and a gapless advance does not change the status. `queueIndex` is never set. | `audio_handler_impl.dart:26`, `:45` | Also publish `updatePosition: Duration.zero` and `queueIndex` when the current track changes (snippet below). |
| T15 | Medium | The permission check runs on every navigation (router `redirect`), with up to three platform channel calls per push (device info, permission status, plugin status). V0 P3, not fixed. | `app_router.dart:70` | Cache the granted state; re-check on `AppLifecycleState.resumed` only. |
| T16 | Low | `PlayerBloc` imports the data layer (`IsarLibraryDataSource`) and `flutter_animate` (for `.ms`). Presentation must go through a repository or use case. | `player_bloc.dart:7`, `:47` | `GetTracksByIdsUseCase`; plain `Duration`. |
| T17 | Low | 119 em dashes in `lib/` comments and strings, and French comments in `player_bloc.dart` and `library_bloc.dart`. | `grep -rn $'\xe2\x80\x94' lib` | Clean up with the copy pass. |

T2 and T3 together, the one place to change:

```dart
// library_repository_impl.dart: one read, three views.
Future<Either<Failure, LibrarySnapshot>> getSnapshot() async {
  try {
    final models = await _cache.getAllTracks();
    final tracks = [for (final m in models) m.toEntity()];
    return right(LibrarySnapshot(
      tracks: tracks,
      albums: _groupAlbums(models),   // keyed by albumId (T4)
      artists: _groupArtists(models),
    ));
  } catch (e, st) {
    return left(ErrorHandler.handle(e, st));
  }
}
```

```dart
// library_bloc.dart, _applyFilterAndSort: never sort the state's lists.
String _key(String s) => removeDiacritics(s).toLowerCase()
    .replaceFirst(RegExp(r'^the '), '');

final sorted = [...filteredTracks];
switch (sort) {
  case LibrarySort.title:
    sorted.sort((a, b) => _key(a.title).compareTo(_key(b.title)));
  case LibrarySort.dateAdded:
    sorted.sort((a, b) => (b.dateAdded ?? DateTime(0))
        .compareTo(a.dateAdded ?? DateTime(0)));
  // ...
}
```

`removeDiacritics` is a 30-line table or the `diacritic` package; precompute the key once per track in the snapshot rather than inside the comparator. Tests: mixed case, accents, leading "The", switching title -> date added -> title returns the same orders, the state's `allTracks` is unchanged after a sort.

T8:

```dart
final (isActive, isPlaying) = context.select<PlayerBloc, (bool, bool)>((b) {
  final s = b.state;
  final active = s is PlayerActive && s.currentTrack.id == widget.track.id;
  return (active, active && (s as PlayerActive).isPlaying);
});
```

T10, T9:

```dart
Stream<TrackModel> extractArtworks(List<TrackModel> tracks) {
  final controller = StreamController<TrackModel>();
  unawaited(_dispatch(tracks, controller)); // acquires, extracts, closes
  return controller.stream;                 // listened to immediately
}

// In _doExtract, when the platform returns no bytes:
return track..artworkPath = ''; // checked, none: excluded from the next scan
```

T11:

```dart
final part = File('${targetFile.path}.part');
await _client.dio.download(imageUrl, part.path, options: ...);
await part.rename(targetFile.path); // atomic on the same filesystem
```

T14:

```dart
_port.currentTrackStream.listen((track) {
  if (track == null) return;
  mediaItem.add(_trackToMediaItem(track));
  playbackState.add(playbackState.value.copyWith(
    updatePosition: Duration.zero,
    queueIndex: _port.currentQueue?.currentIndex,
  ));
});
```

### 2.3 GPU and jank

| # | Severity | Finding | Fix |
|---|---|---|---|
| G1 | High | The **first screen a new user sees** (permission page) runs a full-screen `BackdropFilter` at sigma **70** (`permission_page.dart:203`) over glow layers, with two infinite `repeat` animations on the same page. The blur is re-sampled every frame. It is also the screen of the store reviewer's first impression. | Replace the blur by pre-blurred radial gradients (they are already soft): same look, zero blur cost. |
| G2 | High | Sheets opened from the player dock use a `BackdropFilter` at sigma 30 (`player_utility_dock.dart:286`) on top of the page's two blurs (lens and dock): three blurs on screen, against the project rule. The dock's own blur is hardcoded at 18 and ignores `GlassQuality`, and is not wrapped in a `RepaintBoundary`. | Go through `GlassTheme`; opaque sheets over Now Playing (the queue sheet already does this). |
| G3 | Medium | Detail page and sliver headers build their blur by hand (`album_detail_page.dart:657`, `artist_detail_page.dart:601`, `custom_sliver_header.dart:187`). Check they skip the filter when the collapse factor is 0 and read the sigma from `GlassTheme` so "Light" and "Off" apply. | Single `GlassSurface` widget for headers. |
| G4 | Medium | Synchronous Isar work on the UI isolate: full reads (T3), one write per cover (T9), `getUniqueArtists` / `getUniqueAlbums` full reads on every Home refresh, and Home refreshes after every recorded play. | T3 and T9 fixes; replace the two "unique" helpers by indexed queries or by the snapshot. An isolate is not required at this scale once the duplicated reads are gone; revisit with `Isar.openAsync` reads in an isolate only if profiling on 10,000 tracks still shows frames above budget. |
| G5 | Low | `GlassTier.detect` reads RAM on Android and returns `high` on iOS whatever the device. Good enough for the launch; the measured downgrade (frame timings) from V0 2.2 is the follow-up if users report jank. | None for the launch. |

What is already right and should stay: position ticks bypass the bloc through a `ValueNotifier`, the full player and nav bar rebuild on structural keys only, `ArtworkImage` decodes at display size, the Hero flight has no blur.

### 2.4 Crash-free behaviour

| Scenario | Current behaviour | Verdict and fix |
|---|---|---|
| Corrupted file in the middle of a queue | `errorStream` wired, `maxSkipsOnError: 3`, notice toast | OK since V0. The toast shows the raw engine message: map it (1.3, Errors). |
| Corrupted **first** track | `PlayerError` emitted from `_onPlayTrackRequested` | OK; check the mini player does not disappear on `PlayerError` with a previous queue. |
| File deleted while in the queue | Fails as a decoding error | Acceptable; a dedicated "This song is no longer on your phone" message needs an existence check in the adapter. |
| Missing metadata | `Unknown Artist`, `Unknown Album`, filename as title | OK, but "Unknown Album" groups every untagged file into one album (T4), and these strings are English data stored in Isar: store `null`, localize at display. |
| Malformed `SongModel` | Per-song `try`, skipped | OK (V0 E3 fixed). |
| Permission revoked in system settings | Android kills the process; the redirect sends the next launch to `/permission` | OK. |
| SD card removed, then scan | Every SD track is deleted from Isar as an orphan; playlists keep their IDs | Acceptable; T6 covers the identity question. |
| Isar fails to open | `BootFailureApp` | OK, copy to fix (1.3). |
| No network | Every metadata call is wrapped and returns `null` | OK, and in release the network is unreachable anyway (S2). |
| Uncaught errors | `FlutterError.onError` and `PlatformDispatcher.onError` to `CrashLog` | OK; T12 for the cost. A user cannot send the file today: "Report a problem" should share it with `share_plus`, copying text to the clipboard is not a feedback channel a public user will use. |

### 2.5 Sleep timer and speed (replacing the fake dock items)

Speed: dispatch the existing event instead of `setState`: `context.read<PlayerBloc>().add(SpeedChangeRequested(speed))`, and read the value from `PlayerActive.speed`.

Sleep timer: a small singleton cubit, no domain change needed beyond pausing.

```dart
final class SleepTimerCubit extends Cubit<SleepTimerState> {
  Timer? _timer;
  StreamSubscription<Track?>? _endOfTrack;

  void startFor(Duration d) {
    cancel();
    _timer = Timer(d, _stop);
    emit(SleepTimerState.until(DateTime.now().add(d)));
  }

  void startEndOfTrack() {
    cancel();
    // skip(1): the stream replays the current track on listen.
    _endOfTrack = _port.currentTrackStream.skip(1).listen((_) => _stop());
    emit(const SleepTimerState.endOfTrack());
  }

  void _stop() { _port.pause(); cancel(); }
  // cancel() clears both and emits off; close() calls cancel()
}
```

Fade the volume over the last 10 s before pausing for the timed variant; it is the detail people notice. Tests: timer fires and pauses; restarting replaces the previous timer; "end of song" pauses on the next track change, not on a queue edit that keeps the same track; cancel leaves playback untouched.

---

## 3. Store compliance

### Android (Google Play)

| # | Item | State | Action |
|---|---|---|---|
| S1 | Release signing | Debug key | Upload keystore + `key.properties` (already gitignored), enroll in Play App Signing. Do it **before** any external install: changing the key later forces a reinstall and loses likes, playlists and history. |
| S2 | `INTERNET` permission | Absent from the main manifest; Flutter only adds it to debug and profile builds. Confirmed on the merged release manifest. | Add it if online extras ship; otherwise remove `dio` and the metadata feature from the launch build. |
| S3 | `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO` | Declared, unused | Remove: the Photo and Video Permissions policy rejects apps that declare them without a core use. |
| S4 | `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE` | No `maxSdkVersion` | Remove WRITE; `android:maxSdkVersion="32"` on READ. |
| S5 | Auto Backup | Default on | `android:allowBackup="false"` (T6). |
| S6 | Target SDK | 36 (Flutter 3.47 default) | OK. |
| S7 | Data Safety form, privacy policy URL | Missing | Required for every app. With online extras opt-in, declare "data shared with third parties: none by default; optional, user-initiated". A hosted page (GitHub Pages is enough). |
| S8 | App name and icon | `troona`, Flutter logo | "Troona", real adaptive icon (foreground + background layers, monochrome layer for Android 13 themed icons). |
| S9 | Store listing assets | `screenshots/` holds desktop screen captures | Phone screenshots 1080×1920 or larger, feature graphic 1024×500, short and full description consistent with section 1.2. |
| S10 | Version | `1.0.0+1`, hardcoded in Settings | Read it with `package_info_plus`; bump `versionCode` on every upload. |

```kotlin
// android/app/build.gradle.kts
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) load(FileInputStream(f))
}

android {
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }
    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
        }
    }
}
```

Test the release build after enabling minification: plugins that use reflection (audio_service, Isar native loading) can need keep rules.

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET"/> <!-- only if online extras ship -->
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
<!-- removed: WRITE_EXTERNAL_STORAGE, READ_MEDIA_IMAGES, READ_MEDIA_VIDEO -->
<application android:label="Troona" android:allowBackup="false" ...>
```

### iOS (App Store)

| # | Item | State | Action |
|---|---|---|---|
| S11 | Product fit | `on_audio_query` on iOS reads the Music library: only songs synced from a computer, without DRM. Most iPhone users have none, so a reviewer will likely see an empty library. V0 also found type issues on iOS (`_size: nil`, `UInt64` persistent IDs parsed as `int`). | **Ship Android first.** The real iOS story is importing files (Files app, `UIFileSharingEnabled`, document picker), which is a feature, not a fix. |
| S12 | Orientations | `Info.plist` declares landscape on iPhone while the app is locked to portrait in Dart, and the target includes iPad (`TARGETED_DEVICE_FAMILY = "1,2"`). | iPhone only (`"1"`) for the launch, portrait only in `Info.plist`. iPad with multitasking requires all orientations or `UIRequiresFullScreen`. |
| S13 | App Privacy label, privacy policy URL | Missing | Required for every app. |
| S14 | Icon | Flutter placeholder | Real 1024 px icon without alpha. |
| S15 | `CFBundleName` | `troona` | `Troona`. |

---

## 4. Action plan

Ordered by impact. P0 blocks submission; P1 is what a reviewer or a first-week user will hit; P2 can ship in the first update.

### P0: submission blockers

1. **Remove the fake features.** Dock: delete lyrics, equalizer and cast; wire speed to `SpeedChangeRequested`; implement the sleep timer (2.5). Settings: delete gapless, Wi-Fi only, album art in notification, and every "Bêta" wording (`betaChannel`, "Support & Bêta Testeurs", "Feedback & Rapport Bêta").
2. **Make every claim true** (1.2): online extras opt-in and off by default, "Lossless" only for lossless formats, no "100%", no "audiophile decoding".
3. **Decide online extras for the launch.** Either ship them (add `INTERNET`, atomic downloads T11, privacy policy naming Last.fm and Deezer, check both API terms) or remove `dio` and the metadata feature from this build. Recommendation: ship them opt-in, it is a visible differentiator on artist pages.
4. **Release signing** with an upload key and Play App Signing (S1).
5. **Manifest cleanup**: remove photo, video and write permissions, `maxSdkVersion` on read, `allowBackup="false"`, label "Troona" (S3 to S5, S8).
6. **Real app icon** on Android (adaptive + monochrome) and iOS; splash screen in the brand colors.
7. **One language**: set up `gen-l10n`, move every string to `app_en.arb` with the copy from 1.3, then `app_fr.arb`. Domain and data stop producing UI text.
8. **Green suite**: fix the 10 failing tests (T1).
9. **Privacy policy** page and Data Safety answers (S7, S13).

### P1: before pressing "Submit"

10. Library sort fix and single library read (T2, T3), with the tests listed under the snippet.
11. Albums grouped by `albumId` (T4); scanner duration floor lowered (T5).
12. No playlist cap on the Playlists tab (T7).
13. Track rows rebuild on their own state only (T8).
14. Artwork: "checked, none" marker, batched writes, live progress (T9, T10); silent rescans with a "{n} new songs added" toast (U7).
15. Permission page: no blur, no auto-open of system settings (G1, 1.3).
16. Three blurs over Now Playing (G2).
17. User-safe error messages everywhere (`ErrorHandler` maps to typed failures, presentation maps to strings; no raw `$error`).
18. Home cold start states: empty library, no plays yet, warm (U4); greeting with late night (U5).
19. `EmptyState` with title, body and action, applied to every screen in 1.3 (U3).
20. One toast and one dialog component (U1).
21. "Report a problem" shares the log file and diagnostics with `share_plus`; version from `package_info_plus`.
22. Lock screen position after auto-advance (T14).

### P2: first update

23. "Your week in music" card and listening calendar, on the daily aggregate (1.4).
24. Session persistence split and debounced (T13); async crash log (T12).
25. Permission check cached (T15); `PlayerBloc` off the data layer (T16).
26. Personal "Your artists" ranking, "Recently added" by `dateAdded` (U6).
27. Stable track identity to survive MediaStore rebuilds (T6, second half).
28. iOS milestone: file import, iPad decision, device validation (S11, S12).

---

## 5. Validation before the final build

```
[ ] flutter analyze: no issues
[ ] flutter test: all green, run in CI on every push (GitHub Actions, flutter-action, analyze + test)
[ ] grep -rn "kDefaultLyrics\|Bêta\|Lossless\|100%" lib: only intended matches
[ ] grep -rn $'\xe2\x80\x94' lib (em dash): nothing
[ ] Every Text() in lib/features/*/presentation reads from AppLocalizations
[ ] flutter build appbundle --release, then bundletool: merged manifest has exactly the permissions of S2 to S4
[ ] Install the release AAB through Play internal testing (not adb), on:
    - a 3 to 4 GB RAM Android 10 device: scroll Library during playback with the performance overlay
    - an Android 14+ device: fresh install, deny, deny permanently, grant from system settings, come back
[ ] Library of 5,000+ tracks: cold start time, first scan, rescan with nothing changed (must be silent)
[ ] Queue with a corrupted file in the middle, at the end, and four in a row
[ ] Airplane mode with online extras on: artist page opens, no spinner forever, no error text
[ ] Lock screen: play, pause, next, auto-advance, seek: position correct each time
[ ] Sleep timer: 15 min fires with fade; "end of song" pauses at the next track
[ ] Version bumped, CHANGELOG entry, store listing text matches section 1.2
```

The adversarial review step (fresh-context review of the diff against this checklist) applies to items 1, 2, 7 and 10 of the plan: they touch most screens and the library model.
