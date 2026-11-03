/// One artist credited on a song.
final class ArtistCredit {
  final int id;
  final String name;

  const ArtistCredit({required this.id, required this.name});

  @override
  bool operator ==(Object other) =>
      other is ArtistCredit && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  String toString() => 'ArtistCredit($id, $name)';
}
