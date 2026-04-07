import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:troona/features/library/domain/entities/track.dart';
import 'package:troona/features/library/domain/use_cases/add_track_to_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/is_track_in_likes_use_case.dart';
import 'package:troona/features/library/domain/use_cases/remove_track_from_likes_use_case.dart';

part 'likes_state.dart';

final class LikesCubit extends Cubit<LikesState> {
  LikesCubit({
    required AddTrackToLikesUseCase addTrack,
    required RemoveTrackFromLikesUseCase removeTrack,
    required IsTrackInLikesUseCase isTrackLiked,
  }) : _addTrack = addTrack,
       _removeTrack = removeTrack,
       _isTrackLiked = isTrackLiked,
       super(const LikesState(id: null, isLiked: false));

  final AddTrackToLikesUseCase _addTrack;
  final RemoveTrackFromLikesUseCase _removeTrack;
  final IsTrackInLikesUseCase _isTrackLiked;
  final Map<String, bool> _knownLikes = {};
  int _syncRequestId = 0;

  Future<void> syncTrack(Track? track) async {
    if (track == null) {
      emit(const LikesState(id: null, isLiked: false));
      return;
    }
    final immediateLiked =
        _knownLikes[track.id] ?? (state.id == track.id ? state.isLiked : false);
    emit(LikesState(id: track.id, isLiked: immediateLiked));

    final requestId = ++_syncRequestId;
    final result = await _isTrackLiked(track.id);
    if (requestId != _syncRequestId) return;

    final nextLiked = result.fold((_) => immediateLiked, (liked) => liked);
    _knownLikes[track.id] = nextLiked;
    emit(LikesState(id: track.id, isLiked: nextLiked));
  }

  Future<void> toggle(Track? track) async {
    if (track == null) return;

    final previousLiked =
        _knownLikes[track.id] ?? (state.id == track.id ? state.isLiked : false);
    final nextLiked = !previousLiked;

    _knownLikes[track.id] = nextLiked;
    emit(LikesState(id: track.id, isLiked: nextLiked));

    final result = nextLiked
        ? await _addTrack(track.id)
        : await _removeTrack(track.id);

    if (result.isLeft()) {
      _knownLikes[track.id] = previousLiked;
      emit(LikesState(id: track.id, isLiked: previousLiked));
    }
  }
}
