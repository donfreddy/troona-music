part of 'player_bloc.dart';

abstract class PlayerState extends Equatable {
  const PlayerState();  

  @override
  List<Object> get props => [];
}
class PlayerInitial extends PlayerState {}
