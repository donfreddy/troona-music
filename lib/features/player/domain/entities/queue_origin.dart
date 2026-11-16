/// What a queue was built from, as the person chose it.
enum QueueOriginKind { album, artist, playlist }

/// The album, artist or playlist a queue was started from: Home's resume
/// card names it ("Album • Love, Damini"). None for a queue of songs from
/// the Library's song list, search or Home.
///
/// [name] is the name it had then: a playlist renamed since keeps its old
/// name here until it is played again.
final class QueueOrigin {
  final QueueOriginKind kind;
  final String id;
  final String name;

  const QueueOrigin(this.kind, {required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is QueueOrigin &&
      other.kind == kind &&
      other.id == id &&
      other.name == name;

  @override
  int get hashCode => Object.hash(kind, id, name);

  @override
  String toString() => 'QueueOrigin(${kind.name}, $id, $name)';
}
