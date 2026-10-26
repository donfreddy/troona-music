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
  String get settingsOnlinePhotos => 'Photos d\'artistes';

  @override
  String get settingsOnlineClear => 'Effacer les infos téléchargées';

  @override
  String get settingsOnlineConfirmTitle => 'Effacer les infos téléchargées ?';

  @override
  String get settingsOnlineConfirmBody =>
      'Les biographies et notes d\'albums seront retéléchargées à l\'ouverture d\'un artiste ou d\'un album.';

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
      'Si vous les activez, Troona envoie les noms d\'artistes et d\'albums à Last.fm et Deezer pour récupérer photos et biographies. Ces services voient aussi votre adresse IP, comme pour toute requête web. Aucun fichier, compte ni historique d\'écoute n\'est envoyé. Désactivez-les à tout moment dans les Réglages.';

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
}
