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
/// asked for again after [recheckAfter]: a database grows.
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

  /// The largest correction kept, either way.
  static const maxOffset = Duration(seconds: 10);

  final _looking = <String, Future<LyricsLookup>>{};

  @override
  Future<LyricsLookup> lyricsFor(
    Track track, {
    bool searchAgain = false,
  }) async {
    try {
      final row = _store.get(track.id);
      final offset = Duration(milliseconds: row?.offsetMs ?? 0);
      if (row?.source == LyricsSource.imported.name) {
        final imported = _parse(row!, LyricsSource.imported);
        if (imported != null) return LyricsFound(imported, offset: offset);
      }
      final stored = row == null ? null : _parse(row, LyricsSource.online);
      if (!searchAgain && row != null) {
        final fresh = _now().difference(row.checkedAt) < recheckAfter;
        if (stored is SyncedLyrics || (stored != null && fresh)) {
          return LyricsFound(stored!, offset: offset);
        }
      }
      final online = await _onlineEnabled();
      if (!online) {
        return stored != null
            ? LyricsFound(stored, offset: offset)
            : const LyricsMissing(onlineEnabled: false);
      }
      if (!searchAgain && row != null && stored == null) {
        final fresh = _now().difference(row.checkedAt) < recheckAfter;
        if (fresh) return const LyricsMissing(onlineEnabled: true);
      }
      // A block: `remove` returns this very future, which `whenComplete`
      // would wait for, forever.
      return await (_looking[track.id] ??= _ask(track, stored).whenComplete(() {
        _looking.remove(track.id);
      }));
    } catch (e, st) {
      appLogger.w('Lyrics lookup failed', error: e, stackTrace: st);
      return const LyricsMissing(onlineEnabled: false, unreachable: true);
    }
  }

  Future<LyricsLookup> _ask(Track track, Lyrics? stored) async {
    final query = LyricsQuery.of(track);
    var unreachable = false;
    Lyrics? found;
    String? raw;
    for (final remote in _remotes) {
      try {
        raw = await remote.find(query);
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
    final at = _now();
    // An answer missing a source is not remembered: the one that could not
    // be reached may have better (synced) lyrics.
    if (found != null) {
      if (!unreachable) await _store.putOnline(track.id, raw, at);
    } else if (!unreachable) {
      if (stored != null) {
        await _store.touch(track.id, at);
      } else {
        await _store.putOnline(track.id, null, at);
      }
    }
    final row = _store.get(track.id);
    final offset = Duration(milliseconds: row?.offsetMs ?? 0);
    // Lyrics imported while the sources were asked win.
    if (row?.source == LyricsSource.imported.name) {
      final imported = _parse(row!, LyricsSource.imported);
      if (imported != null) return LyricsFound(imported, offset: offset);
    }
    final lyrics = found ?? stored;
    if (lyrics != null) return LyricsFound(lyrics, offset: offset);
    return LyricsMissing(onlineEnabled: true, unreachable: unreachable);
  }

  @override
  Future<Either<Failure, Lyrics>> import(Track track, List<int> bytes) async {
    try {
      final text = LrcParser.decode(bytes);
      if (text == null) return left(const LyricsFormatFailure('Too big.'));
      final lyrics = LrcParser.parse(text, source: LyricsSource.imported);
      if (lyrics == null) return left(const LyricsFormatFailure());
      await _store.putImported(track.id, text, _now());
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
        -maxOffset.inMilliseconds,
        maxOffset.inMilliseconds,
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
      await _store.forget(trackId, _now());
      return right(unit);
    } catch (e, st) {
      return left(ErrorHandler.handle(e, st));
    }
  }

  @override
  Future<void> clearOnline() => _store.clearOnline();

  /// Unreadable settings count as off: the app stays offline unless the
  /// user said otherwise.
  Future<bool> _onlineEnabled() async =>
      (await _settings.loadSettings()).fold((_) => false, (s) => s.fetchLyrics);

  static Lyrics? _parse(TrackLyricsModel row, LyricsSource source) {
    final raw = row.raw;
    return raw == null ? null : LrcParser.parse(raw, source: source);
  }
}
