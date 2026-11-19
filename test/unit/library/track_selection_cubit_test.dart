import 'package:flutter_test/flutter_test.dart';
import 'package:troona/features/library/presentation/bloc/selection/track_selection_cubit.dart';

import '../../helpers/fake_player.dart';

void main() {
  final a = testTrack('a', durationMs: 1000);
  final b = testTrack('b', durationMs: 1000);
  final c = testTrack('c', durationMs: 1000);
  final list = Object();
  final other = Object();
  late TrackSelectionCubit cubit;

  setUp(() => cubit = TrackSelectionCubit());
  tearDown(() => cubit.close());

  List<String> ids() => [for (final t in cubit.state.tracks) t.id];

  test('nothing picked at first', () {
    expect(cubit.state.active, isFalse);
    expect(cubit.state.count, 0);
  });

  test('a start picks its song in that list', () {
    cubit.start(list, [a, b, c], b);
    expect(cubit.state.active, isTrue);
    expect(cubit.state.owner, list);
    expect(ids(), ['b']);
  });

  test('songs come in the list order, not the order picked', () {
    cubit
      ..start(list, [a, b, c], c)
      ..toggle(list, a);
    expect(ids(), ['a', 'c']);
    expect(cubit.state.count, 2);
  });

  test('letting the last song go ends the selection', () {
    cubit
      ..start(list, [a, b, c], b)
      ..toggle(list, b);
    expect(cubit.state.active, isFalse);
  });

  test('another list cannot touch it', () {
    cubit
      ..start(list, [a, b, c], b)
      ..toggle(other, a)
      ..end(other);
    expect(ids(), ['b']);
    cubit.end(list);
    expect(cubit.state.active, isFalse);
  });

  test('a start elsewhere replaces it', () {
    cubit
      ..start(list, [a, b, c], b)
      ..start(other, [c], c);
    expect(cubit.state.owner, other);
    expect(ids(), ['c']);
  });

  test('select all, then again ends it', () {
    cubit
      ..start(list, [a, b, c], b)
      ..toggleAll();
    expect(cubit.state.allSelected, isTrue);
    expect(ids(), ['a', 'b', 'c']);
    cubit.toggleAll();
    expect(cubit.state.active, isFalse);
  });

  test('a song listed twice is picked, counted and played once', () {
    cubit
      ..start(list, [a, b, a], a)
      ..toggle(list, b);
    expect(cubit.state.count, 2);
    expect(ids(), ['a', 'b']);
    cubit.toggleAll();
    // Two songs picked are all of them.
    expect(cubit.state.active, isFalse);
  });

  test('a new list order keeps the songs still in it', () {
    cubit
      ..start(list, [a, b, c], a)
      ..toggle(list, c)
      ..updateSource(list, [c, b]);
    expect(ids(), ['c']);
    cubit.updateSource(list, [b]);
    expect(cubit.state.active, isFalse);
  });

  test('the list it holds cannot be changed from outside', () {
    final source = [a, b];
    cubit.start(list, source, a);
    source.add(c);
    expect(cubit.state.source, hasLength(2));
    expect(() => cubit.state.source.add(c), throwsUnsupportedError);
  });
}
