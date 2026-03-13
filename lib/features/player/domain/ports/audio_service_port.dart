import 'package:dartz/dartz.dart';
import 'package:troona/features/player/domain/entities/playback_state.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';

/// Interface (Port) entre le Domain et l'implémentation audio concrète.
///
/// Le Domain ne connaît jamais just_audio ni audio_service.
/// L'Adapter (JustAudioAdapter) implémente ce contrat.
///
/// Tous les streams doivent émettre immédiatement une valeur initiale
/// (BehaviorSubject ou StreamController avec seedValue).
abstract interface class AudioServicePort {
  // ── Streams (lecture en temps réel) ────────────────────────────────────────

  /// Position courante, émise ~60fps pendant la lecture.
  Stream<Duration> get positionStream;

  /// Position du buffer réseau/disque.
  Stream<Duration> get bufferedPositionStream;

  /// Statut de lecture (playing, paused, buffering, stopped).
  Stream<PlaybackStatus> get statusStream;

  /// Track actuellement chargée (null si aucune).
  Stream<Track?> get currentTrackStream;

  /// Durée du track courant.
  Stream<Duration> get durationStream;

  /// État complet de la queue.
  Stream<Queue> get queueStream;

  /// Volume courant (0.0 à 1.0).
  Stream<double> get volumeStream;

  // ── Valeurs instantanées (sync) ────────────────────────────────────────────

  PlaybackStatus get currentStatus;
  Track? get currentTrack;
  Duration get currentPosition;
  Duration get currentDuration;
  Queue? get currentQueue;

  // ── Commandes ─────────────────────────────────────────────────────────────

  /// Charge et joue un track. Si [queue] est fourni, initialise la queue.
  Future<Either<Failure, Unit>> playTrack(Track track, {Queue? queue});

  /// Pause la lecture.
  Future<Either<Failure, Unit>> pause();

  /// Reprend la lecture.
  Future<Either<Failure, Unit>> resume();

  /// Seek à une position précise.
  Future<Either<Failure, Unit>> seekTo(Duration position);

  /// Passe au track suivant selon la queue.
  Future<Either<Failure, Unit>> skipToNext();

  /// Revient au track précédent.
  Future<Either<Failure, Unit>> skipToPrevious();

  /// Initialise la queue complète et joue depuis [startIndex].
  Future<Either<Failure, Unit>> setQueue(List<Track> tracks, {int startIndex = 0});

  /// Ajoute un track à la fin de la queue.
  Future<Either<Failure, Unit>> addToQueue(Track track);

  /// Supprime le track à l'index.
  Future<Either<Failure, Unit>> removeFromQueue(int index);

  /// Déplace un item dans la queue.
  Future<Either<Failure, Unit>> moveQueueItem(int oldIndex, int newIndex);

  /// Active/désactive le shuffle.
  Future<Either<Failure, Unit>> setShuffleEnabled(bool enabled);

  /// Change le mode de répétition.
  Future<Either<Failure, Unit>> setRepeatMode(RepeatMode mode);

  /// Change le volume (0.0 – 1.0).
  Future<Either<Failure, Unit>> setVolume(double volume);

  /// Change la vitesse de lecture (0.5 – 2.0).
  Future<Either<Failure, Unit>> setSpeed(double speed);

  /// Stoppe la lecture et libère les ressources audio (pas le service).
  Future<void> stop();

  /// Dispose complet — appeler uniquement à la fermeture de l'app.
  Future<void> dispose();
}
