import 'package:dartz/dartz.dart';
import 'package:troona/core/error/error_handler.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/core/utils/app_logger.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/lyrics/data/models/track_lyrics_model.dart';
import 'package:troona/features/lyrics/data/sources/isar_lyrics_data_source.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_query.dart';
import 'package:troona/features/lyrics/data/sources/lyrics_remote_source.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics.dart';
import 'package:troona/features/lyrics/domain/entities/lyrics_lookup.dart';
import 'package:troona/features/lyrics/domain/repositories/lyrics_repository.dart';
import 'package:troona/features/lyrics/domain/services/lrc_parser.dart';
import 'package:troona/features/settings/domain/repositories/settings_repository.dart';

/// Imported lyrics first, then the ones found online, kept for good when
/// synced. Plain lyrics found online, and what was found nowhere, are
/// asked for again after [recheckAfter] (a database grows), or after
/// [retryPartial] when a source could not be reached.
///
/// The online sources are asked in order, the first with lyrics winning,
/// and only while the user's switch is on; one look per song at a time.
final class LyricsRepositoryImpl implements LyricsRepository {
  final IsarLyricsDataSource _store;
  final List<LyricsRemoteSource> _remotes;
  final SettingsRepository _settings;
  final DateTime Function() _now;

  LyricsRepositoryImpl({
    required IsarLyricsDataSource store,
    required List<LyricsRemoteSource> remotes,
    required SettingsRepository settings,
    DateTime Function()? now,
  }) : _store = store,
       _remotes = remotes,
       _settings = settings,
       _now = now ?? DateTime.now;

  static const recheckAfter = Duration(days: 30);

  /// Plain lyrics and misses from a look on which a source could not be
  /// reached are asked again after this.
  static const retryPartial = Duration(days: 1);

  final _looking = <String, Future<LyricsLookup>>{};

  /// Bumped per song by an import or a delete: a look started before
  /// answers what they left, and writes nothing.
  final _generation = <String, int>{};

  bool _fresh(TrackLyricsModel row) =>
      _now().difference(row.checkedAt) <
      (row.partial ? retryPartial : recheckAfter);

  @override
  Future<LyricsLookup> lyricsFor(
    Track track, {
    bool searchAgain = false,
  }) async {
    final online = await _onlineEnabled();
    try {
      final row = _store.get(track.id);
      final offset = Duration(milliseconds: row?.offsetMs ?? 0);
      if (row?.source == LyricsSource.imported.name) {
        final imported = _parse(row!, LyricsSource.imported);
        if (imported != null) return LyricsFound(imported, offset: offset);
      }
      final stored = row == null ? null : _parse(row, LyricsSource.online);
      if (!searchAgain && row != null) {
        if (stored is SyncedLyrics || (stored != null && _fresh(row))) {
          return LyricsFound(stored!, offset: offset);
        }
      }
      if (!online) {
        return stored != null
            ? LyricsFound(stored, offset: offset)
            : const LyricsMissing(onlineEnabled: false);
      }
      if (!searchAgain && row != null && stored == null && _fresh(row)) {
        return const LyricsMissing(onlineEnabled: true);
      }
      // A block: `remove` returns this very future, which `whenComplete`
      // would wait for, forever.
      return await (_looking[track.id] ??= _ask(track, stored).whenComplete(() {
        _looking.remove(track.id);
      }));
    } catch (e, st) {
      appLogger.w('Lyrics lookup failed', error: e, stackTrace: st);
      return LyricsMissing(onlineEnabled: online, unreachable: true);
    }
  }

  Future<LyricsLookup> _ask(Track track, Lyrics? stored) async {
    final id = track.id;
    final generation = _generation[id] ?? 0;
    final query = LyricsQuery.of(track);
    var answered = 0;
    var unreachable = false;
    var switchedOff = false;
    Lyrics? found;
    String? raw;
    for (final remote in _remotes) {
      // Turned off while an earlier source was asked: no further request.
      if (!await _onlineEnabled()) {
        switchedOff = true;
        break;
      }
      try {
        raw = await remote.find(query);
        answered++;
      } on LyricsUnreachable catch (e) {
        appLogger.d('$e');
        unreachable = true;
        continue;
      }
      found = raw == null
          ? null
          : LrcParser.parse(raw, source: LyricsSource.online);
      if (found != null) break;
    }
    final superseded = (_generation[id] ?? 0) != generation;
    // Nothing remembered when no source answered (no network): the next
    // look asks again. A look that missed a source is asked again sooner,
    // unless it found synced lyrics, which nothing improves.
    if (!superseded && !switchedOff && answered > 0) {
      final at = _now();
      final partial = unreachable && found is! SyncedLyrics;
      if (found != null) {
        await _store.putOnline(id, raw, at, partial: partial);
      } else if (stored != null) {
        await _store.touch(id, at, partial: partial);
      } else {
        await _store.putOnline(id, null, at, partial: partial);
      }
    }
    final row = _store.get(id);
    final offset = Duration(milliseconds: row?.offsetMs ?? 0);
    // Lyrics imported while the sources were asked win.
    if (row?.source == LyricsSource.imported.name) {
      final imported = _parse(row!, LyricsSource.imported);
      if (imported != null) return LyricsFound(imported, offset: offset);
    }
    // Deleted meanwhile: what the delete left, not the answer.
    if (superseded) {
      final kept = row == null ? null : _parse(row, LyricsSource.online);
      return kept != null
          ? LyricsFound(kept, offset: offset)
          : const LyricsMissing(onlineEnabled: true);
    }
    final lyrics = found ?? stored;
    if (lyrics != null) return LyricsFound(lyrics, offset: offset);
    return LyricsMissing(onlineEnabled: true, unreachable: unreachable);
  }

  @override
  Future<Either<Failure, Lyrics>> import(
    String trackId,
    List<int> bytes,
  ) async {
    try {
      final text = LrcParser.decode(bytes);
      if (text == null) return left(const LyricsFormatFailure());
      final lyrics = LrcParser.parse(text, source: LyricsSource.imported);
      if (lyrics == null) return left(const LyricsFormatFailure());
      _generation[trackId] = (_generation[trackId] ?? 0) + 1;
      await _store.putImported(trackId, text, _now());
      return right(lyrics);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> setOffset(
    String trackId,
    Duration offset,
  ) async {
    try {
      final ms = offset.inMilliseconds.clamp(
        -LyricsRepository.maxOffset.inMilliseconds,
        LyricsRepository.maxOffset.inMilliseconds,
      );
      final set = await _store.setOffset(trackId, ms);
      return set ? right(unit) : left(const CacheFailure('No lyrics.'));
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<Either<Failure, Unit>> delete(String trackId) async {
    try {
      _generation[trackId] = (_generation[trackId] ?? 0) + 1;
      await _store.forget(trackId, _now());
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<void> clearOnline() => _store.clearOnline();

  @override
  Future<int> onlineSizeBytes() async => _store.onlineBytes();

  /// Unreadable settings count as off: the app stays offline unless the
  /// user said otherwise.
  Future<bool> _onlineEnabled() async =>
      (await _settings.loadSettings()).fold((_) => false, (s) => s.fetchLyrics);

  static Lyrics? _parse(TrackLyricsModel row, LyricsSource source) {
    final raw = row.raw;
    return raw == null ? null : LrcParser.parse(raw, source: source);
  }
}
