class NewsItem {
  final String title, body, game;
  final DateTime date;
  const NewsItem(this.title, this.body, this.game, this.date);
}

final newsList = <NewsItem>[
  NewsItem('Patch notes preview', 'Placeholder article. Connect your backend to load real news.', 'mk1', DateTime(2026, 10, 8)),
  NewsItem('Community tournament this weekend', 'Placeholder article. Connect your backend to load real news.', 't8', DateTime(2026, 10, 7)),
  NewsItem('Top 10 combos of the week', 'Placeholder article. Connect your backend to load real news.', 'sf6', DateTime(2026, 10, 6)),
  NewsItem('Beginner mistakes to avoid', 'Placeholder article. Connect your backend to load real news.', 'mk1', DateTime(2026, 10, 4)),
  NewsItem('Frame data cheat sheet', 'Placeholder article. Connect your backend to load real news.', 't8', DateTime(2026, 10, 3)),
  NewsItem('Drive system explained', 'Placeholder article. Connect your backend to load real news.', 'sf6', DateTime(2026, 10, 1)),
];
