// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appName => 'Troona';

  @override
  String get actionCancel => 'Annuler';

  @override
  String get actionClear => 'Vider';

  @override
  String get actionClose => 'Fermer';

  @override
  String get actionDelete => 'Supprimer';

  @override
  String get actionDone => 'OK';

  @override
  String get actionReset => 'Réinitialiser';

  @override
  String get actionRetry => 'Réessayer';

  @override
  String get actionSave => 'Enregistrer';

  @override
  String get actionSeeAll => 'Tout voir';

  @override
  String get actionUndo => 'Annuler';

  @override
  String get actionPlay => 'Lecture';

  @override
  String get actionShuffle => 'Aléatoire';

  @override
  String get errorGeneric => 'Un problème est survenu. Réessayez.';

  @override
  String songCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux',
      one: '1 morceau',
      zero: 'Aucun morceau',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count albums',
      one: '1 album',
      zero: 'Aucun album',
    );
    return '$_temp0';
  }

  @override
  String artistCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count artistes',
      one: '1 artiste',
      zero: 'Aucun artiste',
    );
    return '$_temp0';
  }

  @override
  String get unknownArtist => 'Artiste inconnu';

  @override
  String get unknownAlbum => 'Album inconnu';

  @override
  String get likedSongs => 'Titres aimés';

  @override
  String sizeMegabytes(String size) {
    return '$size Mo';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navLibrary => 'Bibliothèque';

  @override
  String get navSearch => 'Recherche';

  @override
  String get navPlaylists => 'Playlists';

  @override
  String get settingsTitle => 'Réglages';

  @override
  String get settingsPlayback => 'Lecture';

  @override
  String get settingsDuck => 'Baisser le volume pendant les notifications';

  @override
  String get settingsPauseOnCall => 'Mettre en pause pendant les appels';

  @override
  String get settingsResumeAfterCall => 'Reprendre après les appels';

  @override
  String get settingsLibrary => 'Bibliothèque';

  @override
  String get settingsRescan => 'Actualiser la bibliothèque';

  @override
  String get settingsRescanSubtitle =>
      'Trouver les morceaux ajoutés depuis la dernière recherche';

  @override
  String get settingsRescanning => 'Mise à jour de la bibliothèque…';

  @override
  String get settingsCoversClear => 'Vider le cache des pochettes';

  @override
  String get settingsCoversClearSubtitle =>
      'Les pochettes se reconstruisent automatiquement.';

  @override
  String get settingsCoversConfirmTitle => 'Vider le cache des pochettes ?';

  @override
  String get settingsCoversConfirmBody =>
      'Les pochettes se rechargent en arrière-plan. Votre musique, vos titres aimés et vos playlists ne sont pas touchés.';

  @override
  String get settingsCoversCleared => 'Cache des pochettes vidé';

  @override
  String get settingsOnline => 'Extras en ligne';

  @override
  String get settingsOnlineFooter =>
      'Optionnel. Activé, Troona envoie les noms d\'artistes et d\'albums à Last.fm et Deezer pour récupérer photos et biographies. Vos fichiers ne quittent jamais cet appareil.';

  @override
  String get settingsOnlineBios => 'Biographies et notes d\'albums';

  @override
  String get settingsOnlinePhotos => 'Photos d\'artistes et pochettes';

  @override
  String get settingsOnlineClear => 'Effacer les infos téléchargées';

  @override
  String get settingsOnlineConfirmTitle => 'Effacer les infos téléchargées ?';

  @override
  String get settingsOnlineConfirmBody =>
      'Les biographies, notes d\'albums et photos seront retéléchargées à l\'ouverture d\'un artiste ou d\'un album, si elles sont toujours activées.';

  @override
  String get settingsOnlineCleared => 'Infos téléchargées effacées';

  @override
  String get settingsAppearance => 'Apparence';

  @override
  String get settingsGlass => 'Effets de verre';

  @override
  String get settingsGlassAuto => 'Auto';

  @override
  String get settingsGlassFull => 'Complet';

  @override
  String get settingsGlassLight => 'Léger';

  @override
  String get settingsGlassOff => 'Désactivé';

  @override
  String get settingsGlassFooter =>
      'Auto s\'adapte à votre téléphone. Choisissez Léger ou Désactivé pour plus de fluidité sur les appareils anciens.';

  @override
  String get settingsHaptics => 'Vibrations';

  @override
  String get settingsSupport => 'Aide et retours';

  @override
  String get settingsReport => 'Signaler un problème';

  @override
  String get settingsReportSubtitle =>
      'Partage les infos de l\'appareil et les erreurs récentes. Vous pouvez les relire avant l\'envoi.';

  @override
  String get settingsReportSubject => 'Signalement de problème Troona';

  @override
  String get settingsPrivacy => 'Politique de confidentialité';

  @override
  String get settingsLicenses => 'Licences open source';

  @override
  String get settingsReset => 'Réinitialiser';

  @override
  String get settingsForgetQueue => 'Effacer la file et la position';

  @override
  String get settingsForgetQueueConfirmTitle =>
      'Effacer la file et la position ?';

  @override
  String get settingsForgetQueueConfirmBody =>
      'La lecture s\'arrête et Troona oublie où vous en étiez.';

  @override
  String get settingsForgetQueueDone => 'File effacée';

  @override
  String get settingsResetSettings => 'Réinitialiser les réglages';

  @override
  String get settingsResetConfirmTitle => 'Réinitialiser les réglages ?';

  @override
  String get settingsResetConfirmBody =>
      'Toutes les préférences reviennent à leurs valeurs par défaut. Votre bibliothèque, vos titres aimés et vos playlists restent intacts.';

  @override
  String settingsVersion(String version, String build) {
    return 'Troona $version ($build)';
  }

  @override
  String get settingsTagline => 'Pensé pour la musique qui vous appartient.';

  @override
  String get settingsLoadError => 'Impossible de charger vos réglages.';

  @override
  String get privacyTitle => 'Confidentialité';

  @override
  String get privacyIntro =>
      'Troona lit la musique enregistrée sur votre téléphone. Pas de compte, pas de publicité, pas de mesure d\'audience.';

  @override
  String get privacyLocalTitle => 'Sur cet appareil';

  @override
  String get privacyLocalBody =>
      'Votre bibliothèque, vos titres aimés, vos playlists et votre historique d\'écoute sont stockés uniquement sur ce téléphone. Troona lit vos fichiers audio et jamais vos photos, vidéos ou documents.';

  @override
  String get privacyOnlineTitle => 'Extras en ligne (désactivés par défaut)';

  @override
  String get privacyOnlineBody =>
      'Il y a deux interrupteurs distincts. Les biographies envoient les noms d\'artistes et d\'albums à Last.fm. Les photos les envoient à Deezer et téléchargent les images depuis Deezer ou Last.fm. Ces services voient aussi votre adresse IP, comme pour toute requête web. Aucun fichier, compte ni historique d\'écoute n\'est envoyé. Désactivez l\'un ou l\'autre à tout moment dans les Réglages : les requêtes vers ce service s\'arrêtent, et désactiver les photos supprime aussi celles déjà téléchargées.';

  @override
  String get privacyReportsTitle => 'Signalements de problèmes';

  @override
  String get privacyReportsBody =>
      'Les erreurs sont écrites dans un journal sur cet appareil. Il peut contenir des noms de fichiers. Rien n\'est envoyé, sauf si vous choisissez Signaler un problème et le partagez vous-même.';

  @override
  String get privacyDeleteTitle => 'Supprimer vos données';

  @override
  String get privacyDeleteBody =>
      'Désinstaller Troona supprime tout ce qu\'il a enregistré. Vos fichiers musicaux ne sont jamais modifiés.';

  @override
  String get permissionHeadline =>
      'Toute votre musique.\nRien entre elle et vous.';

  @override
  String get permissionSubhead =>
      'Troona lit les morceaux déjà présents sur votre téléphone. Sans compte, sans publicité, sans streaming.';

  @override
  String get permissionQualityTitle => 'Lit ce qui vous appartient';

  @override
  String get permissionQualityBody =>
      'MP3, FLAC, AAC, WAV, OGG et Opus, dans leur qualité d\'origine.';

  @override
  String get permissionPrivacyTitle => 'Privé par conception';

  @override
  String get permissionPrivacyBody =>
      'Votre musique reste sur cet appareil. Les extras en ligne sont optionnels.';

  @override
  String get permissionLibraryTitle => 'Prête en quelques secondes';

  @override
  String get permissionLibraryBody =>
      'Pochettes, albums et artistes, classés pour vous.';

  @override
  String get permissionAllow => 'Autoriser l\'accès';

  @override
  String get permissionDeniedTitle => 'Troona ne voit pas encore votre musique';

  @override
  String get permissionDeniedBody =>
      'Troona a besoin d\'accéder à vos fichiers audio pour créer votre bibliothèque. Il ne lit jamais vos photos, vidéos ou documents.';

  @override
  String get permissionBlockedTitle => 'L\'accès est désactivé';

  @override
  String get permissionBlockedBody =>
      'Autorisez Troona à accéder à votre musique dans les paramètres du téléphone, puis revenez : on s\'occupe du reste.';

  @override
  String get permissionOpenSettings => 'Ouvrir les paramètres';

  @override
  String get permissionCheckAgain => 'C\'est activé';

  @override
  String get permissionFooter => 'Gratuit · Sans publicité · Sans compte';

  @override
  String get scanTitle => 'On rassemble votre musique';

  @override
  String get scanPhaseScanning => 'Recherche des morceaux sur votre téléphone…';

  @override
  String get scanPhaseIndexing => 'Création de votre bibliothèque…';

  @override
  String get scanPhaseArtwork => 'Ajout des pochettes…';

  @override
  String get scanPhaseDone => 'Presque prêt…';

  @override
  String scanSongsFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux trouvés',
      one: '$count morceau trouvé',
    );
    return '$_temp0';
  }

  @override
  String scanProgress(int count, int total) {
    return '$count sur $total';
  }

  @override
  String scanNewSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveaux morceaux ajoutés',
      one: '$count nouveau morceau ajouté',
    );
    return '$_temp0';
  }

  @override
  String scanRemovedSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux ne sont plus sur votre téléphone',
      one: '$count morceau n\'est plus sur votre téléphone',
    );
    return '$_temp0';
  }

  @override
  String get libraryRescanFailed =>
      'Impossible de rechercher de la nouvelle musique. Votre bibliothèque est inchangée.';

  @override
  String get libraryLoadErrorTitle => 'Impossible d\'ouvrir votre bibliothèque';

  @override
  String get libraryLoadErrorBody =>
      'Vérifiez que Troona a toujours accès à votre musique, puis réessayez.';

  @override
  String get errorTitle => 'Un problème est survenu';

  @override
  String playerCantPlay(String title) {
    return 'Impossible de lire « $title ». Passage au titre suivant.';
  }

  @override
  String get playerCantPlayUnknown =>
      'Ce morceau ne peut pas être lu. Passage au suivant.';

  @override
  String get notificationChannelName => 'Commandes de lecture';

  @override
  String get bootTitle => 'Troona n\'a pas pu démarrer';

  @override
  String get bootBody =>
      'Redémarrez l\'application. Si cela se reproduit, copiez le rapport et envoyez-le-nous.';

  @override
  String get bootCopyReport => 'Copier le rapport';

  @override
  String get bootReportCopied => 'Rapport copié';

  @override
  String get libraryFilterAll => 'Tout';

  @override
  String get libraryFilterSongs => 'Morceaux';

  @override
  String get libraryFilterAlbums => 'Albums';

  @override
  String get libraryFilterArtists => 'Artistes';

  @override
  String get libraryEmptyTitle => 'Pas encore de musique sur cet appareil';

  @override
  String get libraryEmptyBody =>
      'Copiez des morceaux sur votre téléphone, puis relancez la recherche.';

  @override
  String get libraryScanAgain => 'Relancer la recherche';

  @override
  String get libraryNoSongs => 'Aucun morceau pour l\'instant';

  @override
  String get libraryNoAlbums => 'Aucun album pour l\'instant';

  @override
  String get libraryNoArtists => 'Aucun artiste pour l\'instant';

  @override
  String get librarySort => 'Trier';

  @override
  String get librarySortBy => 'Trier par';

  @override
  String get librarySortTitle => 'Titre';

  @override
  String get librarySortArtist => 'Artiste';

  @override
  String get librarySortAlbum => 'Album';

  @override
  String get librarySortRecent => 'Ajout récent';

  @override
  String get libraryUpdating => 'Mise à jour de la bibliothèque…';

  @override
  String get libraryShuffleAll => 'Tout lire en aléatoire';

  @override
  String albumByArtist(String artist, String songs) {
    return '$artist · $songs';
  }

  @override
  String statSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'morceaux',
      one: 'morceau',
    );
    return '$_temp0';
  }

  @override
  String statAlbums(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'albums',
      one: 'album',
    );
    return '$_temp0';
  }

  @override
  String statArtists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'artistes',
      one: 'artiste',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String durationHours(int hours) {
    return '$hours h';
  }

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get trackPlayNext => 'Lire ensuite';

  @override
  String get trackAddToQueue => 'Ajouter à la file';

  @override
  String get detailSongs => 'Morceaux';

  @override
  String get detailAlbums => 'Albums';

  @override
  String detailMoreBy(String artist) {
    return 'Plus de $artist';
  }

  @override
  String get detailMore => 'Plus d\'options';

  @override
  String get detailBack => 'Retour';

  @override
  String detailCountsSummary(String songs, String albums) {
    return '$songs · $albums';
  }

  @override
  String get albumAbout => 'À propos de cet album';

  @override
  String get artistInLibrary => 'Dans votre bibliothèque';

  @override
  String get infoSongs => 'Morceaux';

  @override
  String get infoAlbums => 'Albums';

  @override
  String get infoLength => 'Durée';

  @override
  String get infoYear => 'Année';

  @override
  String get infoSize => 'Taille';

  @override
  String get infoFormat => 'Format';

  @override
  String get formatLossless => 'Sans perte';

  @override
  String get albumLoadError => 'Impossible d\'ouvrir cet album.';

  @override
  String get artistLoadError => 'Impossible d\'ouvrir cet artiste.';

  @override
  String metaListeners(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString auditeurs',
      one: '$countString auditeur',
    );
    return '$_temp0';
  }

  @override
  String metaPlays(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString écoutes',
      one: '$countString écoute',
    );
    return '$_temp0';
  }

  @override
  String get searchHint => 'Morceaux, artistes, albums';

  @override
  String get searchClear => 'Effacer la recherche';

  @override
  String get searchIdleTitle => 'Rechercher dans votre bibliothèque';

  @override
  String get searchIdleBody => 'Morceaux, artistes et albums de cet appareil.';

  @override
  String searchNoResultsTitle(String query) {
    return 'Aucun résultat pour « $query »';
  }

  @override
  String get searchNoResultsBody =>
      'Essayez un mot plus court ou un nom d\'artiste.';

  @override
  String get searchError => 'La recherche est indisponible pour le moment.';

  @override
  String get searchSuggestedArtists => 'Artistes';

  @override
  String get searchSuggestedAlbums => 'Albums';

  @override
  String get searchRecentlyAdded => 'Ajouts récents';

  @override
  String get searchBadgeArtist => 'Artiste';

  @override
  String get searchBadgeAlbum => 'Album';

  @override
  String get searchBadgeSong => 'Morceau';

  @override
  String get playlistsCreate => 'Créer';

  @override
  String get playlistsListView => 'Vue liste';

  @override
  String get playlistsGridView => 'Vue grille';

  @override
  String get playlistsFilterAll => 'Toutes';

  @override
  String get playlistsFilterMine => 'Mes playlists';

  @override
  String get playlistsYours => 'Vos playlists';

  @override
  String get playlistsEmptyTitle => 'Créez votre première playlist';

  @override
  String get playlistsEmptyBody =>
      'Rassemblez des morceaux pour une humeur, un moment ou un road trip.';

  @override
  String get playlistNew => 'Nouvelle playlist';

  @override
  String get playlistEdit => 'Modifier la playlist';

  @override
  String get playlistNameHint => 'Nom de la playlist';

  @override
  String get playlistDescriptionHint => 'Description (facultative)';

  @override
  String get playlistAddCover => 'Ajouter une image';

  @override
  String get playlistCreateAndAdd => 'Créer et ajouter';

  @override
  String get playlistCreate => 'Créer';

  @override
  String get playlistAddTo => 'Ajouter à une playlist';

  @override
  String get playlistNoneYet => 'Aucune playlist pour l\'instant';

  @override
  String playlistAddedTo(String name) {
    return 'Ajouté à $name';
  }

  @override
  String playlistAlreadyIn(String name) {
    return 'Déjà dans $name';
  }

  @override
  String playlistDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get playlistDeleteBody =>
      'Seule la playlist est supprimée. Les morceaux restent dans votre bibliothèque.';

  @override
  String get playlistDeleted => 'Playlist supprimée';

  @override
  String get playlistEmptyTitle => 'Cette playlist est vide';

  @override
  String get playlistEmptyBody =>
      'Ajoutez des morceaux depuis le menu ··· d\'un titre.';

  @override
  String get playlistRemove => 'Retirer de la playlist';

  @override
  String get playlistLoadError => 'Impossible de charger vos playlists.';

  @override
  String get playlistOpenError => 'Impossible d\'ouvrir cette playlist.';

  @override
  String get playlistLabel => 'Playlist';

  @override
  String get likesEmptyTitle => 'Vos titres aimés vivront ici';

  @override
  String get likesEmptyBody =>
      'Touchez le cœur d\'un morceau pour l\'enregistrer.';

  @override
  String likesSubtitle(String songs) {
    return '$songs · Vos favoris réunis';
  }

  @override
  String get likesBadge => 'Favoris';

  @override
  String get likesRemove => 'Retirer des titres aimés';

  @override
  String get trackLike => 'Aimer';

  @override
  String get trackAddToPlaylist => 'Ajouter à une playlist…';

  @override
  String get trackGoToAlbum => 'Voir l\'album';

  @override
  String get trackGoToArtist => 'Voir l\'artiste';

  @override
  String get toastPlaysNext => 'Lu ensuite';

  @override
  String get toastAddedToQueue => 'Ajouté à la file';

  @override
  String get toastLiked => 'Ajouté aux titres aimés';

  @override
  String get toastUnliked => 'Retiré des titres aimés';

  @override
  String get homeGreetingMorning => 'Bonjour';

  @override
  String get homeGreetingAfternoon => 'Bon après-midi';

  @override
  String get homeGreetingEvening => 'Bonsoir';

  @override
  String get homeGreetingNight => 'Session de nuit';

  @override
  String get homeSubtitleWarm => 'Reprenez là où vous en étiez.';

  @override
  String homeSongsReady(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux, prêts quand vous l\'êtes.',
      one: '$count morceau, prêt quand vous l\'êtes.',
    );
    return '$_temp0';
  }

  @override
  String get homeEmptyTitle => 'Pas encore de musique ici';

  @override
  String get homeEmptyBody =>
      'Copiez des morceaux dans le dossier Musique de votre téléphone, puis relancez la recherche.';

  @override
  String get homeFreshTitle => 'Votre bibliothèque est prête';

  @override
  String get homeJumpBackIn => 'Reprendre';

  @override
  String get homeQuickRecent => 'Ajouts récents';

  @override
  String get homeRecentlyPlayed => 'Écoutés récemment';

  @override
  String get homeOnRepeat => 'En boucle cette semaine';

  @override
  String get homeRediscover => 'À redécouvrir';

  @override
  String get homeYourArtists => 'Vos artistes';

  @override
  String get homeRecentlyAdded => 'Ajouts récents';

  @override
  String get homeYourPlaylists => 'Vos playlists';

  @override
  String homeWeeklyPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'écoutes cette semaine',
      one: 'écoute cette semaine',
    );
    return '$_temp0';
  }

  @override
  String get homeLoadError =>
      'Impossible de charger l\'accueil. Tirez vers le bas pour réessayer.';

  @override
  String get homeExtrasTitle => 'Ajouter photos et biographies d\'artistes ?';

  @override
  String get homeExtrasBody =>
      'Troona peut les récupérer sur Last.fm et Deezer à partir des noms d\'artistes et d\'albums. Vos fichiers restent sur cet appareil.';

  @override
  String get homeExtrasAccept => 'Activer';

  @override
  String get homeExtrasDecline => 'Plus tard';

  @override
  String get homeExtrasDeclined =>
      'Vous pourrez les activer à tout moment dans les Réglages.';

  @override
  String get recapTitle => 'Votre semaine en musique';

  @override
  String recapRange(String start, String end) {
    return 'Du $start au $end';
  }

  @override
  String get recapOpen => 'Ouvrir votre semaine en musique';

  @override
  String get recapListened => 'd\'écoute';

  @override
  String get recapTopArtist => 'Artiste phare';

  @override
  String get recapTopSong => 'Morceau phare';

  @override
  String get recapDiscoveries => 'Premières écoutes';

  @override
  String recapDiscoveriesValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux écoutés pour la première fois',
      one: '$count morceau écouté pour la première fois',
      zero: 'Aucun nouveau morceau cette semaine',
    );
    return '$_temp0';
  }

  @override
  String recapPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes',
      one: '$count écoute',
    );
    return '$_temp0';
  }

  @override
  String recapHoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String recapMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get recapEmpty => 'Rien n\'a été écouté la semaine dernière.';

  @override
  String get recapCalendarCaption =>
      'Un point plein marque un jour avec de la musique.';

  @override
  String recapCalendarDay(String date) {
    return '$date, musique écoutée';
  }

  @override
  String replayName(String month) {
    return 'Replay $month';
  }

  @override
  String replayReady(String name) {
    return '$name est dans vos playlists : vos morceaux les plus écoutés le mois dernier.';
  }

  @override
  String recapCalendarQuietDay(String date) {
    return '$date, pas de musique';
  }

  @override
  String get queueTitle => 'File d\'attente';

  @override
  String get queueHistory => 'Historique';

  @override
  String get queueBackToNow => 'Revenir au titre en cours';

  @override
  String get queueNowPlaying => 'En cours';

  @override
  String get queueRepeatOne => 'Lecture en boucle de ce titre';

  @override
  String get queueRepeatAll => 'Puis retour au début';

  @override
  String get queueNothingNext => 'Rien ensuite';

  @override
  String queueUpNext(int count) {
    return 'À suivre · $count';
  }

  @override
  String queueRemoved(String title) {
    return '« $title » retiré';
  }

  @override
  String get sleepTimer => 'Minuteur';

  @override
  String sleepStopsAt(String time) {
    return 'La musique s\'arrête à $time.';
  }

  @override
  String get sleepStopsEndOfSong =>
      'La musique s\'arrête à la fin de ce titre.';

  @override
  String get sleepIdle => 'Arrêter la musique au bout d\'un moment.';

  @override
  String get sleepOneHour => '1 heure';

  @override
  String get sleepEndOfSong => 'Fin du morceau';

  @override
  String get sleepTurnOff => 'Désactiver';

  @override
  String get playbackSpeed => 'Vitesse de lecture';

  @override
  String playbackSpeedNormal(String speed) {
    return '$speed (normale)';
  }

  @override
  String get playbackPosition => 'Position de lecture';

  @override
  String playbackPositionValue(String position, String duration) {
    return '$position sur $duration';
  }

  @override
  String get metaAboutAlbum => 'À propos de cet album';

  @override
  String get metaAboutArtist => 'À propos';

  @override
  String get metaOnTour => 'En tournée';

  @override
  String get metaReadMore => 'Lire la suite';

  @override
  String get metaReadLess => 'Réduire';

  @override
  String get metaSimilarArtists => 'Artistes similaires';

  @override
  String get playerPause => 'Pause';

  @override
  String get playerNext => 'Suivant';

  @override
  String get playerPrevious => 'Précédent';

  @override
  String get playerShuffle => 'Aléatoire';

  @override
  String get playerRepeatOff => 'Répétition désactivée';

  @override
  String get playerRepeatAll => 'Répéter tout';

  @override
  String get playerRepeatOne => 'Répéter ce titre';

  @override
  String get playerClose => 'Fermer le lecteur';

  @override
  String get playerOpen => 'Ouvrir le lecteur';
}
