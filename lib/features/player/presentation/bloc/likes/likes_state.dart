part of 'likes_cubit.dart';

class LikesState extends Equatable {
  final String? id; // track id
  final bool isLiked;
  final Set<String> likedTrackIds;

  const LikesState({
    required this.id,
    required this.isLiked,
    this.likedTrackIds = const <String>{},
  });

  bool isTrackLiked(String trackId) => likedTrackIds.contains(trackId);

  LikesState copyWith({
    String? id,
    bool? isLiked,
    Set<String>? likedTrackIds,
  }) =>
      LikesState(
        id: id ?? this.id,
        isLiked: isLiked ?? this.isLiked,
        likedTrackIds: likedTrackIds ?? this.likedTrackIds,
      );

  @override
  List<Object?> get props => [id, isLiked, likedTrackIds];
}
