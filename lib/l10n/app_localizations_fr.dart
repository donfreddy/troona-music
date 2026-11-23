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
  String singleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count singles',
      one: '1 single',
    );
    return '$_temp0';
  }

  @override
  String get albumSingle => 'Single';

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
  String get settingsOnlineBios => 'Biographies et notes d\'albums';

  @override
  String get settingsOnlinePhotos => 'Photos d\'artistes et pochettes';

  @override
  String get settingsOnlineClear => 'Effacer les infos téléchargées';

  @override
  String get settingsOnlineConfirmTitle => 'Effacer les infos téléchargées ?';

  @override
  String get settingsOnlineConfirmBody =>
      'Les biographies, notes d\'albums, photos et paroles trouvées en ligne seront retéléchargées à leur ouverture, si elles sont toujours activées. Les paroles importées sont gardées.';

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
  String get settingsGlassBalanced => 'Équilibré';

  @override
  String get settingsGlassOff => 'Sans flou';

  @override
  String settingsGlassFooter(String tier) {
    return 'Auto : $tier sur ce téléphone. Équilibré ne garde le flou que dans les en-têtes, Sans flou n\'en dessine aucun : les deux défilent plus fluidement sur les téléphones anciens.';
  }

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
      'Il y a deux interrupteurs distincts. Les biographies envoient les noms d\'artistes et d\'albums à Last.fm. Les photos les envoient à Deezer, avec jusqu\'à trois titres de morceaux de chaque artiste (ses plus écoutés) pour que la photo trouvée soit bien la sienne et non celle d\'un homonyme, et téléchargent les images depuis Deezer ou Last.fm. Ces services voient aussi votre adresse IP, comme pour toute requête web. Aucun fichier, compte ni nombre d\'écoutes n\'est envoyé. Désactivez l\'un ou l\'autre à tout moment dans les Réglages : les requêtes vers ce service s\'arrêtent, et désactiver les photos supprime aussi celles déjà téléchargées.';

  @override
  String get privacyReportsTitle => 'Signalements de problèmes';

  @override
  String get privacyReportsBody =>
      'Les erreurs sont écrites dans un journal sur cet appareil. Il peut contenir des noms de fichiers. Rien n\'est envoyé, sauf si vous choisissez Signaler un problème et le partagez vous-même.';

  @override
  String get privacyBackupTitle => 'Sauvegardes';

  @override
  String get privacyBackupBody =>
      'Une sauvegarde contient les éléments que vous choisissez (playlists, likes, historique d\'écoute, paroles importées et leur décalage, réglages, égaliseur), avec les noms et tailles de vos fichiers musicaux, sans chiffrement. Troona l\'écrit dans le dossier que vous avez choisi pour vos sauvegardes, ou la confie à l\'app de votre choix quand vous la partagez. Elle ne part nulle part ailleurs. La restauration ne lit que la sauvegarde que vous choisissez, et n\'écrit que les éléments que vous gardez.';

  @override
  String get privacyDeleteTitle => 'Supprimer vos données';

  @override
  String get privacyDeleteBody =>
      'Désinstaller Troona supprime tout ce qu\'il a enregistré. Vos fichiers musicaux et vos sauvegardes, dans votre dossier de sauvegarde ou exportées, ne sont jamais modifiés.';

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
  String get permissionFooter => 'Gratuit • Sans publicité • Sans compte';

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
  String get openedFileNotInLibrary =>
      'Ce fichier n\'est pas dans votre bibliothèque. Pour l\'instant, Troona n\'ouvre que les titres de votre musique.';

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
  String get playerQueueReplaced => 'File d\'attente remplacée';

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
  String get libraryIndex => 'Index alphabétique';

  @override
  String libraryIndexJump(String letter) {
    return 'Aller à $letter';
  }

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
  String get librarySortPlays => 'Les plus écoutés';

  @override
  String get libraryUpdating => 'Mise à jour de la bibliothèque…';

  @override
  String get libraryShuffleAll => 'Tout lire en aléatoire';

  @override
  String albumByArtist(String artist, String songs) {
    return '$artist • $songs';
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
  String get detailSingles => 'Singles';

  @override
  String get detailDiscography => 'Discographie';

  @override
  String get detailLatestRelease => 'Dernière sortie';

  @override
  String get detailAppearsOn => 'Apparaît dans';

  @override
  String get detailAlsoInLibrary => 'Aussi dans votre bibliothèque';

  @override
  String get detailPopular => 'Populaires';

  @override
  String detailSeeAllSongs(int count) {
    return 'Voir les $count morceaux';
  }

  @override
  String get detailShowLess => 'Afficher moins';

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
    return '$songs • $albums';
  }

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
  String get recentlyAddedTitle => 'Ajouts récents';

  @override
  String get recentlyAddedEmptyTitle => 'Rien d\'ajouté pour l\'instant';

  @override
  String get recentlyAddedEmptyBody =>
      'Les titres ajoutés à votre téléphone s\'affichent ici, du plus récent au plus ancien.';

  @override
  String get recentAlbumsTitle => 'Albums récents';

  @override
  String get recentAlbumsEmptyBody =>
      'Les albums ajoutés à votre téléphone s\'affichent ici, du plus récent au plus ancien.';

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
  String get likesEmptyTitle => 'Vos titres aimés vivront ici';

  @override
  String get likesEmptyBody =>
      'Touchez le cœur d\'un morceau pour l\'enregistrer.';

  @override
  String likesSubtitle(String songs) {
    return '$songs • Vos favoris réunis';
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
  String get homeNowPlaying => 'En cours';

  @override
  String get queueOriginAlbum => 'Album';

  @override
  String get queueOriginArtist => 'Artiste';

  @override
  String get queueOriginPlaylist => 'Playlist';

  @override
  String homeTimeLeft(String time) {
    return 'encore $time';
  }

  @override
  String get homeQuickRecent => 'Ajouts récents';

  @override
  String get homeRecentlyPlayed => 'Écoutés récemment';

  @override
  String get homeOnRepeat => 'En boucle cette semaine';

  @override
  String get homeRediscover => 'À redécouvrir';

  @override
  String get homeRecentlyAdded => 'Ajouts récents';

  @override
  String homeWeeklyPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes cette semaine',
      one: '1 écoute cette semaine',
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
      'Troona peut les récupérer sur Last.fm et Deezer à partir des noms d\'artistes et d\'albums, et de quelques titres de morceaux pour les photos. Vos fichiers restent sur cet appareil.';

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
      zero: 'Aucun nouveau morceau',
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
  String get recapPageTitle => 'Vos écoutes';

  @override
  String get recapWeek => 'Semaine';

  @override
  String get recapMonth => 'Mois';

  @override
  String get recapThisWeek => 'Cette semaine';

  @override
  String get recapLastWeek => 'La semaine dernière';

  @override
  String get recapThisMonth => 'Ce mois-ci';

  @override
  String get recapLastMonth => 'Le mois dernier';

  @override
  String get recapPreviousSpan => 'Période précédente';

  @override
  String get recapNextSpan => 'Période suivante';

  @override
  String get recapInProgress => 'En cours';

  @override
  String recapActiveDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours en musique',
      one: '$count jour en musique',
    );
    return '$_temp0';
  }

  @override
  String get recapNothingYet => 'Aucune écoute pour l\'instant.';

  @override
  String get recapNothing => 'Aucune écoute sur cette période.';

  @override
  String get recapTopSongs => 'Top morceaux';

  @override
  String get recapPlaysHeader => 'Écoutes';

  @override
  String get recapShare => 'Partager';

  @override
  String get recapStoryWeek => 'Ma semaine en musique';

  @override
  String get recapStoryMonth => 'Mon mois en musique';

  @override
  String get recapTopAlbums => 'Top albums';

  @override
  String get recapDayByDay => 'Jour après jour';

  @override
  String get recapLess => 'Moins';

  @override
  String get recapMore => 'Plus';

  @override
  String recapDayPlays(String date, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes',
      one: '$count écoute',
      zero: 'pas de musique',
    );
    return '$date, $_temp0';
  }

  @override
  String recapBusiestDay(String date, String plays) {
    return 'Plus grosse journée : $date, $plays';
  }

  @override
  String get recapMoments => 'Quand vous écoutez';

  @override
  String get recapMomentsEmpty =>
      'Vos moments d\'écoute apparaissent au fil des morceaux.';

  @override
  String recapPeak(String weekday, String part) {
    return 'Pic d\'écoute : $weekday $part';
  }

  @override
  String recapPeakNight(String eve, String day) {
    return 'Pic d\'écoute : la nuit du $eve au $day';
  }

  @override
  String get recapMorning => 'Matin';

  @override
  String get recapAfternoon => 'Après-midi';

  @override
  String get recapEvening => 'Soir';

  @override
  String get recapNight => 'Nuit';

  @override
  String replayName(String month) {
    return 'Replay $month';
  }

  @override
  String replayReady(String name) {
    return '$name est dans vos playlists : vos morceaux les plus écoutés le mois dernier.';
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
    return 'À suivre • $count';
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
  String get metaAbout => 'À propos';

  @override
  String metaSource(String source) {
    return 'Source : $source';
  }

  @override
  String get metaReadMore => 'Lire la suite';

  @override
  String get metaReadLess => 'Réduire';

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

  @override
  String get whatsNewTitle => 'Nouveautés';

  @override
  String whatsNewVersion(String version) {
    return 'Version $version';
  }

  @override
  String get whatsNewAdded => 'Nouveau';

  @override
  String get whatsNewImproved => 'Amélioré';

  @override
  String get whatsNewFixed => 'Corrigé';

  @override
  String get whatsNewContinue => 'Continuer';

  @override
  String get whatsNewLatest => 'Dernière';

  @override
  String get whatsNewEarlier => 'Versions précédentes';

  @override
  String whatsNewShowAll(int count) {
    return 'Voir les $count changements';
  }

  @override
  String get whatsNewShowLess => 'Voir moins';

  @override
  String whatsNewCountAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouveautés',
      one: '$count nouveauté',
    );
    return '$_temp0';
  }

  @override
  String whatsNewCountImproved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count améliorations',
      one: '$count amélioration',
    );
    return '$_temp0';
  }

  @override
  String whatsNewCountFixed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count corrections',
      one: '$count correction',
    );
    return '$_temp0';
  }

  @override
  String get whatsNew100WeekTitle => 'Votre semaine en musique';

  @override
  String get whatsNew100WeekBody =>
      'Chaque lundi sur l\'accueil : temps d\'écoute, artiste et morceau phares, avec un calendrier de vos jours d\'écoute.';

  @override
  String get whatsNew100ReplayTitle => 'Replay du mois';

  @override
  String get whatsNew100ReplayBody =>
      'En début de mois, vos 25 morceaux les plus écoutés du mois précédent deviennent une playlist.';

  @override
  String get whatsNew100SleepTitle => 'Minuterie et vitesse';

  @override
  String get whatsNew100SleepBody =>
      'Arrêtez la musique après 15, 30 ou 45 minutes, une heure ou à la fin du morceau, et écoutez de 0,75x à 2x.';

  @override
  String get whatsNew100QueueTitle => 'File d\'attente';

  @override
  String get whatsNew100QueueBody =>
      'Voyez ce qui est passé et ce qui suit. Glissez pour réorganiser, balayez pour retirer, annulez d\'un geste.';

  @override
  String get whatsNew100ExtrasTitle =>
      'Photos et biographies, à vous de choisir';

  @override
  String get whatsNew100ExtrasBody =>
      'Deux interrupteurs dans les Réglages, désactivés par défaut. Vos fichiers ne quittent jamais votre téléphone.';

  @override
  String get whatsNew100LibraryTitle => 'Votre bibliothèque, hors ligne';

  @override
  String get whatsNew100LibraryBody =>
      'Les morceaux, albums et artistes de votre téléphone, avec une recherche sur les trois. L\'analyse affiche sa progression en direct.';

  @override
  String get whatsNew100PlayerTitle => 'Lecture en cours';

  @override
  String get whatsNew100PlayerBody =>
      'Passez d\'une pochette à l\'autre d\'un geste, avancez dans le morceau sur l\'anneau, avec des fondus doux à la lecture, à la pause et entre les morceaux.';

  @override
  String get whatsNew100PlaylistsTitle => 'Playlists et titres aimés';

  @override
  String get whatsNew100PlaylistsBody =>
      'Créez vos playlists, réorganisez leurs morceaux, et retrouvez tous vos titres aimés au même endroit.';

  @override
  String get whatsNew100LanguageTitle => 'Anglais et français';

  @override
  String get whatsNew100LanguageBody =>
      'Toute l\'application suit la langue de votre téléphone.';

  @override
  String get settingsBackupFooter =>
      'Une sauvegarde contient ce que vous choisissez ci-dessus, avec les noms et tailles de vos fichiers musicaux, sans chiffrement. Gardez-la en lieu sûr.';

  @override
  String get backupExportSubtitle =>
      'Enregistrez-la dans Fichiers, Drive ou une autre app.';

  @override
  String get backupShareSubject => 'Sauvegarde Troona';

  @override
  String get backupRestore => 'Restaurer une sauvegarde';

  @override
  String get backupRestoreInvalid =>
      'Ce fichier n\'est pas une sauvegarde Troona, ou il est endommagé.';

  @override
  String get backupRestoreTooNew =>
      'Cette sauvegarde vient d\'une version plus récente de Troona. Mettez l\'app à jour, puis réessayez.';

  @override
  String get backupRestoreDoneTitle => 'Sauvegarde restaurée';

  @override
  String get backupRestoreDoneBody =>
      'Tout ce que vous avez choisi est restauré.';

  @override
  String backupRestoreFound(int found, int total) {
    return 'Morceaux retrouvés sur ce téléphone : $found sur $total.';
  }

  @override
  String backupRestoreMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count morceaux ne sont pas sur ce téléphone. Ajoutez-les, puis restaurez à nouveau le même fichier pour les relier.',
      one:
          '1 morceau n\'est pas sur ce téléphone. Ajoutez-le, puis restaurez à nouveau le même fichier pour le relier.',
    );
    return '$_temp0';
  }

  @override
  String backupRestoreMore(int count) {
    return 'et $count autres';
  }

  @override
  String get backupRestoreOnline =>
      'Les extras en ligne étaient activés dans cette sauvegarde. Ils restent tels qu\'ils sont sur ce téléphone : activez-les dans les Réglages si vous le souhaitez.';

  @override
  String get backupTitle => 'Sauvegarde et restauration';

  @override
  String backupSettingsLast(String date) {
    return 'Dernière sauvegarde : $date';
  }

  @override
  String get backupSettingsNone => 'Playlists, likes, historique et réglages';

  @override
  String get backupAutoSection => 'Sauvegarde automatique';

  @override
  String get backupAuto => 'Sauvegarder automatiquement';

  @override
  String get backupAutoOff =>
      'Dans un dossier de votre choix, à l\'ouverture de Troona';

  @override
  String backupAutoLast(String date) {
    return 'Dernière : $date';
  }

  @override
  String get backupAutoNone => 'Aucune pour l\'instant';

  @override
  String get backupFrequency => 'Fréquence';

  @override
  String get backupDaily => 'Chaque jour';

  @override
  String get backupWeekly => 'Chaque semaine';

  @override
  String get backupFolder => 'Dossier';

  @override
  String get backupFolderChoose => 'Choisir un dossier';

  @override
  String backupFolderLost(String name) {
    return 'Impossible d\'atteindre $name. Choisissez-le à nouveau.';
  }

  @override
  String get backupFolderFooter =>
      'Troona y garde ses 5 dernières sauvegardes automatiques, et toutes celles que vous faites. Le dossier reste si vous désinstallez Troona : choisissez-le à nouveau après la réinstallation pour retrouver vos sauvegardes.';

  @override
  String get backupManualSection => 'Sauvegarder';

  @override
  String get backupParts => 'Éléments à sauvegarder';

  @override
  String get backupPartsEverything => 'Tout';

  @override
  String get backupPartHistory => 'Historique d\'écoute';

  @override
  String get backupPartSettings => 'Réglages';

  @override
  String get backupPartLyrics => 'Paroles';

  @override
  String get backupNow => 'Sauvegarder maintenant';

  @override
  String backupNowInto(String name) {
    return 'Dans $name';
  }

  @override
  String get backupSaved => 'Sauvegarde enregistrée';

  @override
  String get backupRestoreSection => 'Restaurer';

  @override
  String get backupNone => 'Aucune sauvegarde dans ce dossier pour l\'instant';

  @override
  String get backupFromFile => 'Restaurer depuis un fichier';

  @override
  String get backupFromFileSubtitle =>
      'Une sauvegarde enregistrée ailleurs, ou venue d\'un autre téléphone';

  @override
  String get backupAutoBadge => 'Auto';

  @override
  String get backupOptions => 'Options de la sauvegarde';

  @override
  String get backupShare => 'Partager';

  @override
  String get backupDeleteTitle => 'Supprimer cette sauvegarde ?';

  @override
  String backupDeleteBody(String name) {
    return 'Elle est supprimée de $name.';
  }

  @override
  String backupSummaryPlaylists(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count playlists',
      one: '1 playlist',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryLikes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres aimés',
      one: '1 titre aimé',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryPlays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count écoutes',
      one: '1 écoute',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryLyrics(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Paroles ou décalage de $count titres',
      one: 'Paroles ou décalage d\'1 titre',
    );
    return '$_temp0';
  }

  @override
  String backupSummaryProfiles(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Son réglage et $count profils',
      one: 'Son réglage et 1 profil',
      zero: 'Son réglage, aucun profil enregistré',
    );
    return '$_temp0';
  }

  @override
  String get backupSettingsReplace => 'Ils remplacent les vôtres';

  @override
  String get backupRestoreTitle => 'Restaurer cette sauvegarde';

  @override
  String backupRestoreFrom(String date) {
    return 'Faite le $date. Les playlists, likes et historique s\'ajoutent aux vôtres ; les réglages et l\'égaliseur remplacent les vôtres.';
  }

  @override
  String get backupRestoreButton => 'Restaurer';

  @override
  String get backupRestoreNothing =>
      'Cette sauvegarde ne contient rien à restaurer.';

  @override
  String get backupFolderLostError =>
      'Impossible d\'atteindre le dossier de sauvegarde. Choisissez-le à nouveau.';

  @override
  String get backupAutoFolderLost =>
      'La sauvegarde automatique n\'atteint plus son dossier. Choisissez-le à nouveau dans Réglages, Sauvegarde et restauration.';

  @override
  String get settingsUpdateCheck => 'Rechercher les mises à jour';

  @override
  String get settingsUpdateCheckSubtitle => 'Une fois par jour, sur GitHub';

  @override
  String get updateCheckNow => 'Vérifier maintenant';

  @override
  String get updateUpToDate => 'Troona est à jour';

  @override
  String get updateCheckFailed =>
      'Impossible de vérifier les mises à jour. Réessayez plus tard.';

  @override
  String updateAvailable(String version) {
    return 'Troona $version est disponible';
  }

  @override
  String get updateAvailableBody =>
      'Elle se télécharge depuis la page de la version sur GitHub.';

  @override
  String get updateView => 'Voir';

  @override
  String get updateSkip => 'Ignorer cette version';

  @override
  String get updateOpenFailed => 'Impossible d\'ouvrir le navigateur';

  @override
  String get privacyUpdatesTitle =>
      'Recherche de mises à jour (désactivée par défaut)';

  @override
  String get privacyUpdatesBody =>
      'Activée, la recherche demande une fois par jour à GitHub le numéro de la dernière version de Troona. « Vérifier maintenant » ne le demande qu\'une fois, quand vous appuyez dessus. GitHub voit votre adresse IP, comme pour toute requête web ; aucune donnée sur vous ou votre musique n\'est envoyée. Troona ne télécharge ni n\'installe jamais de mise à jour lui-même : « Voir » ouvre la page de la version dans votre navigateur.';

  @override
  String get whatsNew110BackupTitle => 'Sauvegarde et restauration';

  @override
  String get whatsNew110BackupBody =>
      'Enregistrez vos playlists, titres aimés, historique d\'écoute et réglages dans un fichier, et retrouvez-les sur ce téléphone ou un nouveau. Dans les Réglages, rubrique Sauvegarde.';

  @override
  String get whatsNew110UpdatesTitle => 'Soyez prévenu des mises à jour';

  @override
  String get whatsNew110UpdatesBody =>
      'Activez « Rechercher les mises à jour » dans les Réglages : une carte sur l\'accueil vous signale chaque nouvelle version. Désactivé par défaut, rien n\'est installé à votre place.';

  @override
  String get whatsNew110ControlsTitle =>
      'Aimer et reprendre depuis l\'écran de verrouillage';

  @override
  String get whatsNew110ControlsBody =>
      'Un cœur dans la notification de lecture aime le morceau en cours (Android 13 et plus). Troona fermé, les commandes multimédia reprennent votre dernier morceau (Android 11 et plus).';

  @override
  String get whatsNew110RenameTitle => 'Renommer une playlist';

  @override
  String get whatsNew110RenameBody =>
      'Appuyez longuement sur une playlist, puis sur Modifier la playlist.';

  @override
  String get whatsNew110ScreensTitle => 'Petits écrans et grands textes';

  @override
  String get whatsNew110ScreensBody =>
      'Sur les petits téléphones, l\'écran de lecture garde ses commandes visibles, et toute l\'application suit la taille de texte de votre téléphone.';

  @override
  String get whatsNew110NotificationTitle => 'Icône de notification';

  @override
  String get whatsNew110NotificationBody =>
      'La notification de lecture affiche la note de Troona dans la barre d\'état.';

  @override
  String get whatsNew111ChangelogTitle => 'Toutes les versions au même endroit';

  @override
  String get whatsNew111ChangelogBody =>
      'Nouveautés garde désormais les notes de chaque version, de la plus récente à la plus ancienne. Ouvrez-les quand vous voulez depuis les Réglages, rubrique Aide et retours.';

  @override
  String get whatsNew111StartupTitle => 'Démarrage fiable';

  @override
  String get whatsNew111StartupBody =>
      'Troona ne reste plus bloqué sur son écran de démarrage quand vous l\'ouvrez après avoir relancé la musique depuis les commandes multimédia ou un casque.';

  @override
  String get whatsNew111HomeTitle => 'L\'accueil dès la première recherche';

  @override
  String get whatsNew111HomeBody =>
      'Votre musique apparaît sur l\'accueil dès que la première recherche la trouve, sans actualiser.';

  @override
  String get whatsNew120ArtistsTitle => 'Artistes lus dans le nom du fichier';

  @override
  String get whatsNew120ArtistsBody =>
      'Les morceaux téléchargés sans artiste le prennent dans leur nom de fichier, par exemple « Artiste - Titre », et rejoignent les autres morceaux de cet artiste. Les autres s\'affichent en Artiste inconnu.';

  @override
  String get whatsNew120UndoTitle => 'Annuler le remplacement de la file';

  @override
  String get whatsNew120UndoBody =>
      'Lancer un autre album alors que des morceaux ajoutés avec Lire ensuite ou Ajouter à la file restent à venir propose maintenant Annuler, qui remet votre file comme elle était.';

  @override
  String get whatsNew120MenusTitle => 'Menus et boîtes de dialogue';

  @override
  String get whatsNew120MenusBody =>
      'Les menus des morceaux, albums et playlists s\'ouvrent dans une feuille au style de Troona, et les boîtes de dialogue apparaissent en fondu.';

  @override
  String get whatsNew120LookTitle => 'Un même style partout';

  @override
  String get whatsNew120LookBody =>
      'Icônes, boutons, boutons retour et pochettes manquantes ont le même aspect sur tous les écrans, et les boutons sont plus faciles à toucher.';

  @override
  String get whatsNew120PagesTitle => 'Pages qui glissent';

  @override
  String get whatsNew120PagesBody =>
      'Les Réglages, la politique de confidentialité et Votre semaine en musique ne laissent plus voir la page précédente pendant leur ouverture.';

  @override
  String get whatsNew130ArtistsTitle => 'Chaque artiste d\'un morceau';

  @override
  String get whatsNew130ArtistsBody =>
      'Un morceau de plusieurs artistes, comme « Nicki Minaj, Beyoncé » ou « Chiké feat Mohbad », compte maintenant pour chacun d\'eux : il apparaît sur la page de chaque artiste et la recherche les trouve tous. Un nom comme « Tyler, The Creator » reste un seul artiste.';

  @override
  String get whatsNew130ArtistPageTitle => 'Pages artiste';

  @override
  String get whatsNew130ArtistPageBody =>
      'La page d\'un artiste commence par ses cinq morceaux les plus écoutés, puis ses albums, ses singles, les albums où il apparaît et des artistes similaires de votre bibliothèque.';

  @override
  String get whatsNew130AlbumPageTitle => 'Pages album';

  @override
  String get whatsNew130AlbumPageBody =>
      'Les albums affichent leur année, et les morceaux téléchargés sans numéro de piste viennent dans l\'ordre de leur téléchargement. Les invités que le titre ne nomme pas s\'affichent dessous.';

  @override
  String get whatsNew130AboutTitle =>
      'À propos, quand il y a quelque chose à lire';

  @override
  String get whatsNew130AboutBody =>
      'Avec les infos en ligne activées, À propos n\'apparaît que si Last.fm a une bio ou une présentation, avec les auditeurs et quelques genres dessous.';

  @override
  String get whatsNew130AlbumsTitle => 'Un album, pas plusieurs copies';

  @override
  String get whatsNew130AlbumsBody =>
      'Un album téléchargé dans plusieurs dossiers, ou des singles enregistrés chacun dans le leur, apparaissaient plusieurs fois. C\'est de nouveau un seul album, et son année s\'affiche.';

  @override
  String get whatsNew140TopTitle => 'Retour en haut';

  @override
  String get whatsNew140TopBody =>
      'Touchez l\'onglet où vous êtes pour remonter en haut de sa page.';

  @override
  String get whatsNew140EdgeTitle => 'Bord à bord';

  @override
  String get whatsNew140EdgeBody =>
      'Les listes défilent maintenant sous la barre d\'état et sous la barre d\'onglets flottante, sur toutes les versions d\'Android, et s\'estompent en douceur sous la barre d\'onglets au lieu de s\'arrêter net.';

  @override
  String get whatsNew140TitlesTitle => 'Grands titres';

  @override
  String get whatsNew140TitlesBody =>
      'Chaque page s\'ouvre sur un grand titre qui se replie en barre de verre quand vous défilez, avec le bouton retour et les actions de la page. Un titre laissé à mi-chemin s\'ouvre ou se replie de lui-même.';

  @override
  String get whatsNew140CoversTitle => 'Pages album et playlist';

  @override
  String get whatsNew140CoversBody =>
      'Leur pochette et leurs boutons défilent sous la même barre de verre, qui affiche alors leur nom.';

  @override
  String get whatsNew140ArtistPhotoTitle => 'Photos d\'artiste';

  @override
  String get whatsNew140ArtistPhotoBody =>
      'Un artiste avec une photo s\'ouvre sur celle-ci, bord à bord, avec son nom par-dessus. Tirez vers le bas pour l\'agrandir.';

  @override
  String get whatsNew140SearchTitle => 'Recherche';

  @override
  String get whatsNew140SearchBody =>
      'Le champ de recherche reste en haut dans une barre de verre pendant que les résultats défilent dessous, et faire défiler les résultats ferme le clavier.';

  @override
  String get whatsNew150CoverTitle => 'La pochette s\'envole';

  @override
  String get whatsNew150CoverBody =>
      'Touchez un album : sa pochette part de la carte et vient se poser sur la page de l\'album, puis y retourne quand vous la quittez.';

  @override
  String get whatsNew150TitlesTitle => 'Titres en gras';

  @override
  String get whatsNew150TitlesBody =>
      'Les grands titres sont en gras, dans le même ton que les noms d\'albums et d\'artistes et les titres de section.';

  @override
  String get whatsNew150TabTitle => 'Un point sous l\'onglet';

  @override
  String get whatsNew150TabBody =>
      'L\'onglet où vous êtes affiche un point sous son icône, pas seulement une couleur plus vive.';

  @override
  String get whatsNew150PagesTitle => 'Les infos sur une ligne';

  @override
  String get whatsNew150PagesBody =>
      'Les pages album donnent leur année, leur nombre de morceaux et leur durée, et les pages artiste leurs morceaux, sorties et durée, sur une ligne de texte au lieu de pastilles. Sans perte garde son badge.';

  @override
  String get whatsNew150AlbumTitle => 'Pages album';

  @override
  String get whatsNew150AlbumBody =>
      'La liste des morceaux n\'a plus de titre Morceaux. Sous les morceaux, une ligne discrète donne la taille et les formats de l\'album à la place de la carte Dans votre bibliothèque.';

  @override
  String get whatsNew150ArtistTitle => 'Pages artiste';

  @override
  String get whatsNew150ArtistBody =>
      'Chaque morceau affiche son album et son année sous son titre au lieu de répéter le nom de l\'artiste, et les cartes d\'albums et de singles indiquent l\'année. La carte Dans votre bibliothèque disparaît : ses chiffres sont sous le nom.';

  @override
  String get whatsNew150MoreByTitle => 'Plus de';

  @override
  String get whatsNew150MoreByBody =>
      'Sur les pages album, Plus de donne l\'année de chaque album au lieu du nom de l\'artiste, avec Single sur les singles.';

  @override
  String get whatsNew150LibraryTitle => 'Une bibliothèque plus légère';

  @override
  String get whatsNew150LibraryBody =>
      'La bibliothèque n\'affiche plus ses nombres de morceaux, d\'albums et d\'artistes au-dessus de Tout.';

  @override
  String get whatsNew150BackTitle => 'Retour d\'où vous venez';

  @override
  String get whatsNew150BackBody =>
      'Ouvrez l\'artiste d\'un album alors que vous venez de cet artiste, et vous revenez sur sa page au lieu de l\'ouvrir une deuxième fois. Pareil dans l\'autre sens.';

  @override
  String get whatsNew150ScrollTitle => 'Plus de bande vide';

  @override
  String get whatsNew150ScrollBody =>
      'Une page album ou playlist garde sa pochette et ses boutons en vue pendant qu\'ils défilent, au lieu de laisser une bande vide sous la barre.';

  @override
  String get whatsNew150NamesTitle => 'Noms d\'artistes en grande police';

  @override
  String get whatsNew150NamesBody =>
      'Avec une grande police, la rangée d\'artistes de la bibliothèque ne coupe plus leurs noms.';

  @override
  String get whatsNew160RecapTitle => 'Vos écoutes';

  @override
  String get whatsNew160RecapBody =>
      'Chaque semaine ou chaque mois en un coup d\'œil : votre temps d\'écoute, les jours où vous avez écouté de la musique, vos morceaux, artiste et albums phares. Ouvrez-le depuis la carte de l\'accueil, et remontez le temps avec les flèches.';

  @override
  String get whatsNew160StoryTitle => 'Partagez-le en story';

  @override
  String get whatsNew160StoryBody =>
      'Faites d\'une semaine ou d\'un mois une image pour vos stories, aux couleurs de votre morceau phare. Un mois terminé se partage comme son Replay.';

  @override
  String get whatsNew160SwipeTitle => 'Glissez un morceau';

  @override
  String get whatsNew160SwipeBody =>
      'Dans la bibliothèque, les albums, les artistes et la recherche, glissez un morceau vers la droite pour le lire ensuite, ou vers la gauche pour l\'ajouter à la file d\'attente.';

  @override
  String get whatsNew160MiniPlayerTitle =>
      'Glissez et maintenez le mini lecteur';

  @override
  String get whatsNew160MiniPlayerBody =>
      'Glissez-le vers la gauche pour le morceau suivant, vers la droite pour le précédent. Maintenez-le pour aimer le morceau en cours, ou retirer votre j\'aime.';

  @override
  String get whatsNew160CalendarTitle => 'Un calendrier de vos écoutes';

  @override
  String get whatsNew160CalendarBody =>
      'Chaque jour est un carré, rempli en cinq niveaux, d\'aucune écoute à 30 lectures ou plus. Touchez un jour pour voir son total.';

  @override
  String get whatsNew160MomentsTitle => 'Quand vous écoutez';

  @override
  String get whatsNew160MomentsBody =>
      'Vos lectures par jour de la semaine et moment de la journée, avec celui qui se démarque, comme le vendredi soir. Les morceaux écoutés après minuit comptent pour la veille au soir.';

  @override
  String get whatsNew160RecordTitle => 'Le disque tourne';

  @override
  String get whatsNew160RecordBody =>
      'Sur une page album, le disque sort de sa pochette et tourne pendant la lecture. Touchez-le pour lire, mettre en pause ou reprendre.';

  @override
  String get whatsNew160LatestTitle => 'Dernière sortie';

  @override
  String get whatsNew160LatestBody =>
      'Les pages artiste montrent leur album ou single le plus récent à part, au-dessus du reste.';

  @override
  String get whatsNew160ResumeTitle => 'Reprenez où vous en étiez';

  @override
  String get whatsNew160ResumeBody =>
      'Reprendre, sur l\'accueil, repart là où le morceau s\'est arrêté, avec l\'album, l\'artiste ou la playlist d\'origine et le temps restant. Pendant la lecture, il ouvre l\'écran En lecture.';

  @override
  String get whatsNew160ArtistTitle => 'Pages artiste';

  @override
  String get whatsNew160ArtistBody =>
      'Un seul bouton rond Aléatoire sur leur photo, puisque les morceaux d\'un artiste n\'ont pas d\'ordre ; touchez un morceau pour lire dans l\'ordre à partir de lui. Les sorties vont de la plus récente à la plus ancienne, aussi dans Plus de sur les pages album. Un artiste sans photo s\'ouvre sur un halo aux couleurs de sa pochette.';

  @override
  String get whatsNew160PlayingTitle => 'Le morceau en cours, partout pareil';

  @override
  String get whatsNew160PlayingBody =>
      'Dans chaque liste, sa pochette est assombrie sous l\'égaliseur animé, qui s\'arrête en pause, et son titre prend la couleur d\'accent.';

  @override
  String get whatsNew160HapticsTitle => 'Des vibrations cohérentes';

  @override
  String get whatsNew160HapticsBody =>
      'Un appui ferme quand la lecture démarre ou s\'arrête, un léger pour un saut, une actualisation ou un menu, et un petit clic pour un choix. Lancer un morceau ne vibre plus deux fois.';

  @override
  String get whatsNew160BackgroundTitle => 'Un fond plus calme';

  @override
  String get whatsNew160BackgroundBody =>
      'Les couleurs derrière les onglets mettent deux secondes à suivre un nouveau morceau au lieu de changer d\'un coup.';

  @override
  String get whatsNew160BackupTitle => 'Sauvegardes';

  @override
  String get whatsNew160BackupBody =>
      'Elles gardent aussi vos moments d\'écoute.';

  @override
  String get whatsNew160HapticsOffTitle => 'Vibrations désactivées respectées';

  @override
  String get whatsNew160HapticsOffBody =>
      'Les onglets en haut de la bibliothèque vibraient même avec les vibrations désactivées dans les réglages. Ils suivent maintenant le réglage.';

  @override
  String get whatsNew170IndexTitle => 'Sautez à une lettre';

  @override
  String get whatsNew170IndexBody =>
      'Les morceaux, albums et artistes triés par nom ont un index alphabétique sur le bord droit.';

  @override
  String get whatsNew170RecentTitle => 'Ajouts récents';

  @override
  String get whatsNew170RecentBody =>
      'Les derniers morceaux et albums ajoutés, du plus récent au plus ancien, depuis la recherche et l\'accueil.';

  @override
  String get whatsNew170ArtistsTitle => 'Plus près des artistes';

  @override
  String get whatsNew170ArtistsBody =>
      'Touchez le nom de l\'artiste sur l\'écran En lecture pour ouvrir sa page. Sa photo s\'agrandit de la carte jusqu\'à la page.';

  @override
  String get whatsNew170AlbumMenuTitle => 'Raccourcis d\'album';

  @override
  String get whatsNew170AlbumMenuBody =>
      'Maintenez une carte d\'album pour Lecture, Aléatoire, Lire ensuite et Ajouter à la file.';

  @override
  String get whatsNew170NowPlayingTitle => 'Un écran En lecture plus fluide';

  @override
  String get whatsNew170NowPlayingBody =>
      'Avancer dans le morceau illumine l\'anneau, et fermer renvoie la pochette dans le mini lecteur.';

  @override
  String get whatsNew170ColoursTitle => 'Des pages à leurs couleurs';

  @override
  String get whatsNew170ColoursBody =>
      'Les pages album et artiste prennent les couleurs de leur pochette, et s\'ouvrent dans l\'onglet où vous êtes.';

  @override
  String get whatsNew170HomeTitle => 'Un accueil plus léger';

  @override
  String get whatsNew170HomeBody =>
      'La musique d\'abord, avec une seule carte sur l\'application à la fois.';

  @override
  String get whatsNew170QueueTitle => 'Ajouter sans rien en cours';

  @override
  String get whatsNew170QueueBody =>
      'Lire ensuite et Ajouter à la file lancent maintenant la musique quand rien ne joue, et un album entre entier dans la file.';

  @override
  String get whatsNew170PhotosTitle => 'Photos d\'artistes';

  @override
  String get whatsNew170PhotosBody =>
      'Plus de silhouettes grises ni de photos d\'homonymes, et la recherche affiche les photos téléchargées.';

  @override
  String get whatsNew180SmartTitle => 'Playlists intelligentes';

  @override
  String get whatsNew180SmartBody =>
      'Des playlists qui se remplissent selon des règles : écoutes, dernière écoute, date d\'ajout, j\'aime, artiste, genre, année et plus. Partez d\'un modèle avec le + de l\'onglet Playlists.';

  @override
  String get whatsNew180SelectionTitle => 'Choisir plusieurs titres';

  @override
  String get whatsNew180SelectionBody =>
      'Un appui long sur un titre lance la sélection, puis touchez-en d\'autres. Lisez-les, ajoutez-les à la file ou à une playlist d\'un coup.';

  @override
  String get whatsNew180EqualizerTitle => 'Égaliseur';

  @override
  String get whatsNew180EqualizerBody =>
      'Sur Android, depuis l\'écran En lecture ou Réglages > Lecture : dessinez votre courbe du doigt ou partez d\'un préréglage, enregistrez-la, et gagnez jusqu\'à 6 dB avec Volume +.';

  @override
  String get whatsNew180OrbTitle => 'Un bouton aux couleurs du morceau';

  @override
  String get whatsNew180OrbBody =>
      'Le centre de la barre d\'onglets prend les couleurs du morceau en cours. Touchez-le pour ouvrir l\'écran En lecture, ou lancer la musique quand rien n\'est chargé.';

  @override
  String get whatsNew180GlassTitle =>
      'Des effets de verre pour chaque téléphone';

  @override
  String get whatsNew180GlassBody =>
      'Équilibré ne garde le flou que dans les en-têtes et Sans flou n\'en dessine aucun, avec des surfaces teintées : un défilement plus fluide sur les téléphones anciens. Dans Réglages.';

  @override
  String get whatsNew180MiniPlayerTitle => 'Un mini lecteur plus fluide';

  @override
  String get whatsNew180MiniPlayerBody =>
      'Glissez vers le morceau suivant ou précédent : les titres suivent le doigt et la pochette se fond. Glissez vers le bas pour le fermer.';

  @override
  String get whatsNew180ReadableTitle => 'Plus lisible';

  @override
  String get whatsNew180ReadableBody =>
      'Les petits textes gris sont plus contrastés, et l\'anneau de l\'écran En lecture se lit sur toutes les pochettes.';

  @override
  String get whatsNew180GlassFixTitle =>
      'Les effets de verre s\'appliquent tout de suite';

  @override
  String get whatsNew180GlassFixBody =>
      'Changer les effets de verre redessine maintenant tous les écrans aussitôt, pas seulement ceux ouverts ensuite.';

  @override
  String playlistAddedSongsTo(int count, String name) {
    return '$count morceaux ajoutés à $name';
  }

  @override
  String selectionSelected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count morceaux sélectionnés',
      one: '1 morceau sélectionné',
    );
    return '$_temp0';
  }

  @override
  String selectionSuffix(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sélectionnés',
      one: 'sélectionné',
    );
    return '$_temp0';
  }

  @override
  String get selectionSelectAll => 'Tout sélectionner';

  @override
  String get selectionDeselectAll => 'Tout désélectionner';

  @override
  String get selectionEnd => 'Terminer la sélection';

  @override
  String get selectionHintStart => 'sélectionner des morceaux';

  @override
  String get selectionHintPick => 'sélectionner';

  @override
  String get selectionHintUnpick => 'désélectionner';

  @override
  String get equalizerTitle => 'Égaliseur';

  @override
  String get equalizerOff => 'Désactivé';

  @override
  String get equalizerTurnOnHint => 'Activez l\'égaliseur pour le régler.';

  @override
  String get equalizerNoBands =>
      'Lancez un morceau pour régler l\'égaliseur : votre téléphone donne ses bandes une fois un morceau chargé.';

  @override
  String equalizerBandCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bandes sur ce téléphone.',
      one: '1 bande sur ce téléphone.',
    );
    return '$_temp0';
  }

  @override
  String get equalizerOtherEffects =>
      'Un égaliseur du système, comme Dolby, peut aussi modifier le son.';

  @override
  String get equalizerPresetFlat => 'Neutre';

  @override
  String get equalizerPresetBassBoost => 'Basses +';

  @override
  String get equalizerPresetAcoustic => 'Acoustique';

  @override
  String get equalizerPresetElectronic => 'Électronique';

  @override
  String get equalizerPresetVocal => 'Voix';

  @override
  String get equalizerPresetRock => 'Rock';

  @override
  String get equalizerPresetHipHop => 'Hip-hop';

  @override
  String get equalizerPresetJazz => 'Jazz';

  @override
  String get equalizerPresetTrebleBoost => 'Aigus +';

  @override
  String get equalizerCustom => 'Personnalisé';

  @override
  String get equalizerSaveProfile => 'Enregistrer';

  @override
  String get equalizerSaveProfileTitle => 'Enregistrer cette courbe';

  @override
  String get equalizerProfileName => 'Nom';

  @override
  String get equalizerProfileRename => 'Renommer';

  @override
  String get equalizerProfileUpdate => 'Remplacer par la courbe actuelle';

  @override
  String equalizerProfileDeleteTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get equalizerProfileDeleteBody =>
      'La courbe reste telle quelle ; seul son nom disparaît.';

  @override
  String get equalizerCompare => 'Maintenir pour écouter sans l\'égaliseur';

  @override
  String get equalizerComparing => 'Sans l\'égaliseur';

  @override
  String get equalizerBoost => 'Volume +';

  @override
  String get equalizerAntiClip => 'Éviter la saturation';

  @override
  String get equalizerAntiClipSubtitle =>
      'Baisse le niveau d\'autant que les bandes montent.';

  @override
  String get equalizerReset => 'Réinitialiser la courbe';

  @override
  String equalizerDecibels(String value) {
    return '$value dB';
  }

  @override
  String equalizerBandLabel(String frequency) {
    return '$frequency hertz';
  }

  @override
  String equalizerBandValue(String value) {
    return '$value décibels';
  }

  @override
  String playlistDefaultName(int number) {
    return 'Ma playlist n° $number';
  }

  @override
  String get playlistsCreatePlaylist => 'Playlist';

  @override
  String get playlistsCreateSmart => 'Playlist intelligente';

  @override
  String get smartPlaylistKind => 'Playlist intelligente';

  @override
  String get smartPlaylistNew => 'Nouvelle playlist intelligente';

  @override
  String get smartPlaylistEdit => 'Modifier les règles';

  @override
  String get smartBadge => 'Auto';

  @override
  String get smartStartFrom => 'Partir de';

  @override
  String get smartTemplateTopMonth => 'Les plus écoutés du mois';

  @override
  String get smartTemplateNeverPlayed => 'Jamais écoutés';

  @override
  String get smartTemplateForgotten => 'Oubliés';

  @override
  String get smartTemplateRecent => 'Ajouts récents';

  @override
  String get smartTemplateLossless => 'Sans perte';

  @override
  String get smartKeep => 'Garder les titres qui respectent';

  @override
  String get smartMatchAll => 'Toutes les règles';

  @override
  String get smartMatchAny => 'Au moins une règle';

  @override
  String get smartRules => 'Règles';

  @override
  String get smartNoRules => 'Aucune règle : tous les titres sont gardés.';

  @override
  String get smartAddRule => 'Ajouter une règle';

  @override
  String get smartRemoveRule => 'Retirer cette règle';

  @override
  String get smartSortBy => 'Trier par';

  @override
  String get smartLimit => 'Limite';

  @override
  String get smartNoLimit => 'Sans limite';

  @override
  String smartLimitSongs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres',
      one: '1 titre',
    );
    return '$_temp0';
  }

  @override
  String smartMatchCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count titres correspondent',
      one: '1 titre correspond',
      zero: 'Aucun titre ne correspond',
    );
    return '$_temp0';
  }

  @override
  String get smartEmptyTitle => 'Aucun titre ne correspond pour l\'instant';

  @override
  String get smartEmptyBody =>
      'Vos écoutes et vos ajouts peuvent changer cela, ou vous pouvez assouplir les règles.';

  @override
  String get smartSaveAsPlaylist => 'Enregistrer comme playlist';

  @override
  String smartSavedAsPlaylist(String name) {
    return 'Enregistrée sous $name';
  }

  @override
  String get smartFootnote => 'Les titres sont recalculés à chaque ouverture.';

  @override
  String get smartRulePlays => 'Écoutes';

  @override
  String get smartRuleLastPlayed => 'Dernière écoute';

  @override
  String get smartRuleAdded => 'Date d\'ajout';

  @override
  String get smartRuleLiked => 'Aimés';

  @override
  String get smartRuleArtist => 'Artiste';

  @override
  String get smartRuleAlbum => 'Album';

  @override
  String get smartRuleGenre => 'Genre';

  @override
  String get smartRuleYear => 'Année';

  @override
  String get smartRuleDuration => 'Durée';

  @override
  String get smartRuleLossless => 'Sans perte';

  @override
  String smartPlaysAtLeast(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Écouté au moins $count fois',
      one: 'Écouté au moins une fois',
    );
    return '$_temp0 en $days jours';
  }

  @override
  String smartPlaysNone(int days) {
    return 'Pas écouté depuis $days jours';
  }

  @override
  String smartLastPlayedOlder(int days) {
    return 'Dernière écoute il y a plus de $days jours';
  }

  @override
  String smartLastPlayedWithin(int days) {
    return 'Écouté ces $days derniers jours';
  }

  @override
  String get smartNeverPlayed => 'Jamais écouté';

  @override
  String smartAddedWithin(int days) {
    return 'Ajouté ces $days derniers jours';
  }

  @override
  String get smartLikedYes => 'Aimé';

  @override
  String get smartLikedNo => 'Pas aimé';

  @override
  String smartTextContains(String field, String text) {
    return '$field contient « $text »';
  }

  @override
  String smartTextNotContains(String field, String text) {
    return '$field ne contient pas « $text »';
  }

  @override
  String smartYearRange(String from, String to) {
    return 'De $from à $to';
  }

  @override
  String smartYearFrom(String year) {
    return '$year ou après';
  }

  @override
  String smartYearTo(String year) {
    return '$year ou avant';
  }

  @override
  String smartDurationUnder(int minutes) {
    return 'Moins de $minutes min';
  }

  @override
  String smartDurationOver(int minutes) {
    return 'Plus de $minutes min';
  }

  @override
  String smartDurationBetween(int min, int max) {
    return 'De $min à $max min';
  }

  @override
  String get smartLosslessYes => 'Sans perte';

  @override
  String get smartLosslessNo => 'Avec perte';

  @override
  String get smartContains => 'Contient';

  @override
  String get smartNotContains => 'Ne contient pas';

  @override
  String get smartTextHint => 'Texte à chercher';

  @override
  String smartDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get smartOverLast => 'Sur les derniers';

  @override
  String get smartSortTitle => 'Titre';

  @override
  String get smartSortArtist => 'Artiste';

  @override
  String get smartSortAlbum => 'Album';

  @override
  String get smartSortYear => 'Année, la plus récente d\'abord';

  @override
  String get smartSortAddedNewest => 'Date d\'ajout, la plus récente d\'abord';

  @override
  String get smartSortAddedOldest => 'Date d\'ajout, la plus ancienne d\'abord';

  @override
  String get smartSortMostPlayed => 'Les plus écoutés';

  @override
  String get smartSortMostPlayedMonth => 'Les plus écoutés sur 30 jours';

  @override
  String get smartSortLeastPlayed => 'Les moins écoutés';

  @override
  String get smartSortLastPlayedRecent => 'Écoutés le plus récemment';

  @override
  String get smartSortLastPlayedOldest => 'Écoutés il y a le plus longtemps';

  @override
  String get smartSortRandom => 'Aléatoire';

  @override
  String get lyricsTitle => 'Paroles';

  @override
  String get lyricsShow => 'Afficher les paroles';

  @override
  String get lyricsHide => 'Masquer les paroles';

  @override
  String get lyricsNone => 'Pas de paroles pour ce titre';

  @override
  String get lyricsNoneOnline => 'Aucune trouvée en ligne non plus.';

  @override
  String get lyricsUnreachable =>
      'La recherche de paroles est injoignable. Réessayez plus tard.';

  @override
  String get lyricsImport => 'Importer un fichier .lrc';

  @override
  String get lyricsSearchOnline => 'Chercher en ligne';

  @override
  String get lyricsSearchAgain => 'Chercher à nouveau en ligne';

  @override
  String get lyricsEnableSearch => 'Activer la recherche de paroles';

  @override
  String get lyricsEnableTitle => 'Chercher les paroles en ligne ?';

  @override
  String get lyricsEnableBody =>
      'Quand un titre n\'a pas de paroles, Troona envoie son titre, son artiste, son album et sa durée à LRCLIB, puis à lyrics.ovh, seulement quand vous ouvrez ses paroles. Rien d\'autre ne quitte cet appareil. Vous pouvez le désactiver dans les Réglages.';

  @override
  String get lyricsEnableAction => 'Activer';

  @override
  String get lyricsNotSynced => 'Paroles non synchronisées';

  @override
  String get lyricsBackToLine => 'Revenir à la ligne en cours';

  @override
  String lyricsGoTo(String time) {
    return 'Aller à $time';
  }

  @override
  String get lyricsInstrumental => 'Instrumental';

  @override
  String get lyricsImported => 'Paroles importées';

  @override
  String get lyricsImportInvalid => 'Ce fichier ne contient pas de paroles.';

  @override
  String get lyricsOptions => 'Options des paroles';

  @override
  String get lyricsEarlier => 'Afficher les lignes plus tôt (0,1 s)';

  @override
  String get lyricsLater => 'Afficher les lignes plus tard (0,1 s)';

  @override
  String get lyricsOffsetReset => 'Rétablir le décalage';

  @override
  String lyricsOffsetValue(String value) {
    return 'Décalage : $value s';
  }

  @override
  String get lyricsRemove => 'Supprimer les paroles';

  @override
  String get lyricsRemoveTitle => 'Supprimer ces paroles ?';

  @override
  String get lyricsRemoveBody =>
      'Les paroles trouvées en ligne ne reviennent que si vous relancez la recherche. Des paroles importées devront être importées à nouveau.';

  @override
  String get lyricsSourceImported => 'Depuis un fichier importé';

  @override
  String get lyricsSourceOnline => 'Trouvées en ligne (LRCLIB ou lyrics.ovh)';

  @override
  String get settingsOnlineLyrics => 'Paroles des chansons';

  @override
  String get privacyLyricsTitle =>
      'Recherche de paroles (désactivée par défaut)';

  @override
  String get privacyLyricsBody =>
      'Activée, ouvrir les paroles d\'un titre qui n\'en a pas encore envoie son titre, son artiste, son album et sa durée à LRCLIB (lrclib.net), puis, s\'il n\'en a pas, son artiste et son titre à lyrics.ovh. Rien n\'est envoyé pour les autres titres, et jamais pour toute votre bibliothèque. Ces services voient aussi votre adresse IP, comme pour toute requête web. Les paroles trouvées restent sur ce téléphone ; « Effacer les infos téléchargées » les supprime. Les paroles que vous importez depuis un fichier ne quittent jamais ce téléphone, sauf dans une sauvegarde que vous exportez.';

  @override
  String get settingsAudio => 'Audio';

  @override
  String get settingsAudioSummary => 'Égaliseur, appels et notifications';

  @override
  String get settingsAudioIntro =>
      'Le son de Troona, et ce qu\'il fait quand votre téléphone a besoin du haut-parleur pour autre chose.';

  @override
  String get settingsSound => 'Son';

  @override
  String get settingsInterruptions => 'Interruptions';

  @override
  String get settingsDuckSubtitle =>
      'Quand une notification ou un GPS parle, la musique baisse au lieu de s\'arrêter.';

  @override
  String get settingsPauseOnCallSubtitle =>
      'Pendant un appel, ou quand une autre app joue du son.';

  @override
  String get settingsResumeAfterCallSubtitle =>
      'Une fois l\'appel ou la courte interruption passés.';

  @override
  String get settingsAudioFooter =>
      'Débrancher un casque met toujours la musique en pause.';

  @override
  String get settingsLibrarySummary =>
      'Titres de ce téléphone, filtres, nouvelle analyse';

  @override
  String get settingsLibraryIntro =>
      'Les titres que Troona a trouvés sur ce téléphone, et ce qu\'il écarte.';

  @override
  String get settingsLibraryContents => 'Dans votre bibliothèque';

  @override
  String get settingsScan => 'Analyse';

  @override
  String get settingsScanFooter =>
      'Troona lit les titres que votre téléphone classe comme musique. Les sonneries, notifications et messages vocaux sont toujours écartés.';

  @override
  String get settingsOnlineOff => 'Désactivés';

  @override
  String settingsOnlineOn(String parts) {
    return 'Activés : $parts';
  }

  @override
  String get settingsOnlineBiosShort => 'biographies';

  @override
  String get settingsOnlinePhotosShort => 'photos';

  @override
  String get settingsOnlineLyricsShort => 'paroles';

  @override
  String get settingsOnlineIntro =>
      'Facultatifs, et désactivés tant que vous ne les activez pas. Chacun dit ce qu\'il envoie, et à qui.';

  @override
  String get settingsOnlineBiosSubtitle =>
      'Depuis Last.fm, avec les noms d\'artistes et d\'albums.';

  @override
  String get settingsOnlinePhotosSubtitle =>
      'Depuis Deezer, avec les noms d\'artistes et d\'albums et quelques titres.';

  @override
  String get settingsOnlineLyricsSubtitle =>
      'Depuis LRCLIB, puis lyrics.ovh, quand vous ouvrez les paroles d\'un titre.';

  @override
  String get settingsOnlinePageFooter =>
      'Rien d\'autre sur vous ou votre musique ne quitte ce téléphone. Les infos téléchargées s\'effacent dans Stockage.';

  @override
  String get settingsPrivacySection => 'Confidentialité';

  @override
  String get settingsAppearanceSummary => 'Effets de verre, retours haptiques';

  @override
  String get settingsAppearanceIntro =>
      'L\'allure de Troona, et sa réponse au toucher.';

  @override
  String get settingsTouch => 'Toucher';

  @override
  String get settingsHapticsSubtitle =>
      'De légères vibrations quand vous touchez, sélectionnez ou aimez.';

  @override
  String get settingsApp => 'Application';

  @override
  String get settingsStorage => 'Stockage';

  @override
  String settingsStorageSummary(String size) {
    return 'Cache $size, réinitialisation';
  }

  @override
  String get settingsStorageSummaryPending => 'Cache, réinitialisation';

  @override
  String get settingsStorageIntro =>
      'Ce que Troona garde sur ce téléphone en plus de votre musique, et comment repartir de zéro.';

  @override
  String get settingsCache => 'Cache';

  @override
  String get settingsOnlineClearSubtitle =>
      'Biographies, photos et paroles trouvées en ligne. Les paroles importées restent.';

  @override
  String get settingsForgetQueueSubtitle =>
      'Arrête la musique et oublie la file et où vous en étiez.';

  @override
  String get settingsResetSettingsSubtitle =>
      'Chaque préférence revient à sa valeur par défaut. Votre bibliothèque, vos titres aimés et vos playlists restent.';

  @override
  String get settingsAbout => 'À propos';

  @override
  String settingsAboutSummary(String version) {
    return 'Version $version, nouveautés, mises à jour';
  }

  @override
  String get settingsAboutSummaryPending => 'Nouveautés, mises à jour';

  @override
  String aboutVersion(String version, String build) {
    return 'Version $version ($build)';
  }

  @override
  String get aboutUpdates => 'Mises à jour';

  @override
  String get aboutInformation => 'Informations';

  @override
  String get aboutSource => 'Code source';

  @override
  String get aboutSourceSubtitle => 'Sur GitHub';

  @override
  String get settingsOnlineSources => 'Sources';

  @override
  String get settingsFilters => 'Filtres';

  @override
  String get settingsMinLength => 'Durée minimale';

  @override
  String get settingsMinLengthSubtitle =>
      'Les fichiers plus courts restent hors de votre bibliothèque.';

  @override
  String durationSecondsShort(int seconds) {
    return '$seconds s';
  }

  @override
  String get settingsFolders => 'Dossiers';

  @override
  String get settingsFoldersAll =>
      'Tous les dossiers sont dans votre bibliothèque';

  @override
  String settingsFoldersExcluded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dossiers exclus',
      one: '1 dossier exclu',
    );
    return '$_temp0';
  }

  @override
  String get settingsFoldersIntro =>
      'Les titres d\'un dossier désactivé quittent votre bibliothèque, sous-dossiers compris. Réactivez-le et ils reviennent avec leurs j\'aime, leurs écoutes et leurs playlists.';

  @override
  String get settingsFoldersFooter =>
      'Au moins un titre reste dans votre bibliothèque.';

  @override
  String get settingsFoldersEmpty =>
      'Aucun dossier pour l\'instant : votre bibliothèque est vide.';

  @override
  String settingsFolderCoveredBy(String folder) {
    return 'Exclu avec $folder';
  }

  @override
  String get settingsFolderInPhone => 'Téléphone';

  @override
  String get settingsFolderInSdCard => 'Carte SD';

  @override
  String get settingsFoldersSection => 'Dossiers de musique';

  @override
  String get licensesIntro =>
      'Troona repose sur des logiciels libres. Merci à celles et ceux qui les font.';

  @override
  String get licensesOwnTerms => 'Conditions propres';

  @override
  String get licensesNotFound => 'Cette licence n\'est plus listée.';

  @override
  String get settingsLicensesSubtitle =>
      'Les logiciels sur lesquels Troona repose';

  @override
  String licensesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count licences',
      one: '1 licence',
    );
    return '$_temp0';
  }

  @override
  String get settingsMinLengthTooLong =>
      'Aucun titre de votre bibliothèque n\'est aussi long : elle serait vide.';

  @override
  String get settingsFiltersNotApplied =>
      'Aucun titre de votre bibliothèque ne passe ces filtres : ils ne sont pas appliqués. Réactivez un dossier ou choisissez une durée plus courte.';
}
