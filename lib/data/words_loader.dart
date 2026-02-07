import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';

class Word {
  final String id;
  final String word;
  final String correct;
  final String wrong;
  final String category;
  int level;
  int lastSeenIndex;

  Word({
    required this.id,
    required this.word,
    required this.correct,
    required this.wrong,
    required this.category,
    this.level = 0,
    this.lastSeenIndex = -1,
  });

  factory Word.fromMap(Map<String, dynamic> m) => Word(
    id: m['id'],
    word: m['word'],
    correct: m['correct'],
    wrong: m['wrong'],
    category: m['category'] ?? 'a1.json',
    level: m['level'] ?? 0,
    lastSeenIndex: m['lastSeenIndex'] ?? -1,
  );

  Map<String, dynamic> toMap() => {
    'id': id,
    'word': word,
    'correct': correct,
    'wrong': wrong,
    'category': category,
    'level': level,
    'lastSeenIndex': lastSeenIndex,
  };
}

Future<List<Word>> loadWordsFromAsset(String path) async {
  final jsonStr = await rootBundle.loadString(path);
  final list = json.decode(jsonStr) as List<dynamic>;
  return list.map((e) => Word.fromMap(e as Map<String, dynamic>)).toList();
}