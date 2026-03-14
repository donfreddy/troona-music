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

  Future<void> syncTrack(Track? track) async {
    if (track == null) {
      emit(const LikesState(id: null, isLiked: false));
      return;
    }
    final result = await _isTrackLiked(track.id);
    emit(
      result.fold(
        (_) => LikesState(id: track.id, isLiked: false),
        (liked) => LikesState(id: track.id, isLiked: liked),
      ),
    );
  }

  Future<void> toggle(Track? track) async {
    if (track == null) return;

    final isLikedNow = state.isLiked;
    if (isLikedNow) {
      await _removeTrack(track.id);
      emit(LikesState(id: track.id, isLiked: false));
    } else {
      await _addTrack(track.id);
      emit(LikesState(id: track.id, isLiked: true));
    }
  }
}
