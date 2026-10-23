class Guide {
  final String id, gameId, charId, title, author, body;
  final int likes;
  final DateTime updated;
  Guide({
    required this.id, required this.gameId, required this.charId, required this.title,
    required this.author, required this.body, required this.likes, required this.updated,
  });
  int get comboCount => '[COMBO:'.allMatches(body).length;
}
