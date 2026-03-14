part of 'likes_cubit.dart';

class LikesState extends Equatable {
  final String? id; // track id
  final bool isLiked;

  const LikesState({required this.id, required this.isLiked});

  @override
  List<Object?> get props => [id, isLiked];
}
