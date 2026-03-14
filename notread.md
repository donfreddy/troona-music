# Priorité basse (scaling long terme)

Pagination — GetTracksUseCase retourne tout en mémoire. Avec 10k+ tracks, ça devient problématique. Prévoir un GetTracksPagedUseCase avec offset/limit.

Isolate pour le scan — déplacer MediaScannerService dans un Isolate pour ne pas bloquer le UI thread sur les gros catalogues.

Feature flag / navigation guard — ajouter un redirect GoRouter pour vérifier les permissions avant /home. Actuellement PermissionHandler est un utilitaire mais rien ne bloque la navigation si la permission est refusée.

Logs structurés — remplacer dart:developer par le package logger avec niveaux (debug/info/warning/error) et possibilité de désactiver en prod.

Monitoring — pas de crash reporting (Firebase Crashlytics ou Sentry) pour tracker les failures en production.

Tests — ajouter des tests unitaires pour les UseCases et des tests d’intégration pour les routes principales.

## Features "Senior Architect" à considérer pour la roadmap

_1._ Expérience Audio & Moteur (Core)

* Gapless Playback : Indispensable pour les albums live ou conceptuels. Aucune micro-pause entre les pistes.
* Fade-in / Fade-out (Crossfade) : Transitions fluides lors du changement de morceau ou de la mise en pause/reprise.
* Normalisation du volume (Loudness Normalization) : Évite de devoir ajuster le volume manuellement entre un morceau de jazz calme et un morceau de rock compressé.
* Support Hi-Res : Lecture des formats sans perte comme le FLAC ou l'ALAC (Apple Lossless) avec affichage du débit binaire (kbps/kHz).

_2._ Interface & Design (Glassmorphism)

* Dynamic Theme (Adaptive UI) : L'interface change de couleur en fonction de la pochette de l'album en cours (en utilisant un algorithme comme PaletteGenerator de Flutter), tout en conservant l'effet de transparence.
* Haptic Feedback raffiné : Utilisation de vibrations subtiles (haptics) lors du défilement de la file d'attente ou de l'appui sur les boutons, pour une sensation "physique".
* Animations 60/120 FPS : Utilisation de transitions partagées (Hero animations) entre la liste des morceaux et le lecteur plein écran.
* Visualiseur de spectre (Audio Visualizer) : Un rendu fluide des fréquences audio, idéalement intégré en arrière-plan derrière les éléments vitrés.

_3._ Gestion de Bibliothèque (Smart Indexing)

* Smart Playlists : Playlists automatiques basées sur des critères (ex: "Ajoutés récemment", "Le plus écouté", "Oubliés depuis longtemps").
* Recherche Instantanée (Fuzzy Search) : Recherche qui tolère les fautes de frappe et indexée localement avec Isar pour des résultats immédiats.
* Éditeur de Tags intégré : Possibilité de modifier les métadonnées (ID3 tags) et de choisir une nouvelle pochette directement depuis l'app.
* Multi-Folder Watcher : Surveille les dossiers de musique en arrière-plan et met à jour la bibliothèque dès qu'un fichier est ajouté ou supprimé.

_4._ Connectivité & Écosystème

* Android Auto & Apple CarPlay : Support des interfaces embarquées pour une conduite sécurisée.
* Support des touches média avancées : Gestion des casques Bluetooth, des boutons de volume et du contrôle depuis une montre connectée (WearOS/watchOS).
* Sleep Timer intelligent : Arrêt progressif de la musique après un certain temps ou à la fin de l'album en cours.
* Partage de "Story" : Génération d'une image esthétique (Glassmorphism) avec les infos du morceau pour un partage rapide sur les réseaux sociaux.
