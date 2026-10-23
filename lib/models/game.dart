import 'package:flutter/material.dart';

class Game {
  final String id, name, tag;
  final List<Color> colors;
  final IconData icon;
  final List<String> chars;
  const Game(this.id, this.name, this.tag, this.colors, this.icon, this.chars);
}

const games = <Game>[
  Game('mk1', 'MORTAL KOMBAT 1', 'MK1', [Color(0xFF3A0A0E), Color(0xFFB3131F)],
      Icons.local_fire_department,
      ['Scorpion', 'Sub-Zero', 'Noob Saibot', 'Johnny Cage', 'Liu Kang', 'Kitana', 'Sindel', 'Raiden', 'Smoke']),
  Game('t8', 'TEKKEN 8', 'T8', [Color(0xFF1A1033), Color(0xFF6B2BD9)], Icons.bolt,
      ['Jin', 'Kazuya', 'Paul', 'King', 'Law', 'Jun', 'Reina', 'Lili']),
  Game('sf6', 'STREET FIGHTER 6', 'SF6', [Color(0xFF0B2545), Color(0xFFE8A200)],
      Icons.sports_mma, ['Ryu', 'Ken', 'Chun-Li', 'Luke', 'Jamie', 'Kimberly', 'Cammy', 'Guile']),
];

Game gameOf(String id) => games.firstWhere((g) => g.id == id);
