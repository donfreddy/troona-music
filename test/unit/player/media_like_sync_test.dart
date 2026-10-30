import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:troona/core/error/failures.dart';
import 'package:troona/features/library/domain/entities/playlist.dart';
import 'package:troona/features/library/domain/repositories/library_repository.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/get_likes_playlist_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';
import 'package:troona/features/player/data/adapters/media_like_button.dart';
import 'package:troona/features/player/domain/entities/queue.dart';
import 'package:troona/features/player/domain/entities/repeat_mode.dart';
import 'package:troona/features/player/presentation/bloc/likes/likes_cubit.dart';
import 'package:troona/services/audio/media_like_sync.dart';

import '../../helpers/fake_player.dart';

/// Liked songs kept in memory.
final class _Likes implements LibraryRepository {
  _Likes(this.ids);

  final Set<String> ids;

  @override
  Future<Either<Failure, Playlist>> getLikesPlaylist() async =>
      right(Playlist(id: 'likes', name: 'Likes', trackIds: ids.toList()));

  @override
  Future<Either<Failure, Unit>> addTrackToLikes(String trackId) async {
    ids.add(trackId);
    return right(unit);
  }

  @override
  Future<Either<Failure, Unit>> removeTrackFromLikes(String trackId) async {
    ids.remove(trackId);
    return right(unit);
  }

  @override
  Future<Either<Failure, bool>> isTrackInLikes(String trackId) async =>
      right(ids.contains(trackId));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeAudioPort port;
  late _Likes repo;
  late LikesCubit likes;
  late MediaLikeButton button;
  late MediaLikeSync sync;

  final a = testTrack('a', durationMs: 200000);
  final b = testTrack('b', durationMs: 200000);

  Queue queueAt(int index) => Queue(
    originalTracks: [a, b],
    playbackTracks: [a, b],
    currentIndex: index,
    shuffleEnabled: false,
    repeatMode: RepeatMode.off,
  );

  setUp(() async {
    port = FakeAudioPort();
    repo = _Likes({'a'});
    likes = LikesCubit(
      addTrack: AddTrackToLikesUseCase(repo),
      removeTrack: RemoveTrackFromLikesUseCase(repo),
      isTrackLiked: IsTrackInLikesUseCase(repo),
      getLikesPlaylist: GetLikesPlaylistUseCase(repo),
    );
    await likes.stream.first; // the liked songs are loaded
    button = MediaLikeButton(likeLabel: 'Like', unlikeLabel: 'Unlike');
    sync = MediaLikeSync(button: button, likes: likes, port: port)..start();
  });

  tearDown(() async {
    await sync.dispose();
    await likes.close();
    await port.close();
  });

  test('no track hides the heart', () {
    expect(button.liked.value, isNull);
  });

  test('the heart follows the current track', () {
    port.queueCtrl.add(queueAt(0));
    expect(button.liked.value, isTrue);

    port.queueCtrl.add(queueAt(1));
    expect(button.liked.value, isFalse);
  });

  test('a press likes the current track and fills the heart', () async {
    port.queueCtrl.add(queueAt(1));

    button.press();
    await pumpEventQueue();

    expect(repo.ids, contains('b'));
    expect(likes.state.isTrackLiked('b'), isTrue);
    expect(button.liked.value, isTrue);
  });

  test('a press unlikes the current track', () async {
    port.queueCtrl.add(queueAt(0));

    button.press();
    await pumpEventQueue();

    expect(repo.ids, isNot(contains('a')));
    expect(button.liked.value, isFalse);
  });

  test('a like made in the app redraws the heart', () async {
    port.queueCtrl.add(queueAt(1));

    await likes.toggle(b);

    expect(button.liked.value, isTrue);
  });

  test('a press with no track does nothing', () async {
    button.press();
    await pumpEventQueue();

    expect(repo.ids, {'a'});
  });
}
