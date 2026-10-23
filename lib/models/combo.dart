class Combo {
  final String id, gameId, charId, title, notation, author;
  final List<String> tags;
  final int damage, views;
  final int likes;
  final DateTime updated;
  Combo({
    required this.id, required this.gameId, required this.charId, required this.title,
    required this.notation, required this.tags, required this.damage, required this.views,
    required this.likes, required this.author, required this.updated,
  });
}
