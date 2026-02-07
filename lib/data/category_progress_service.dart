import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import 'package:flutter/services.dart';

class CategoryProgressService {
  static final CategoryProgressService _instance = 
      CategoryProgressService._internal();

  factory CategoryProgressService() {
    return _instance;
  }

  CategoryProgressService._internal();

  // Kategori -> Renk Mapı
  static const Map<String, Color> categoryColors = {
    'A1 Seviye Kelimeler': Color(0xFF2196F3), // Mavi
    'A2 Seviye Kelimeler': Color(0xFF4CAF50), // Yeşil
    'B1 Seviye Kelimeler': Color(0xFF9C27B0), // Mor
    'B2 Seviye Kelimeler': Color(0xFFFF9800), // Turuncu
    'C1 Seviye Kelimeler': Color(0xFFF44336), // Kırmızı
    'C2 Seviye Kelimeler': Color(0xFFFDD835), // Sarı
    'Fiiller (Verbs)': Color(0xFF009688), // Teal
    'Sıfatlar (Adjectives)': Color(0xFFE91E63), // Pembe
    'Zarflar (Adverbs)': Color(0xFF673AB7), // İndigo
    'İsimler (Nouns)': Color(0xFF795548), // Kahverengi
    'Fiil Öbekleri (Phrasal Verbs)': Color(0xFF607D8B), // Gri
    'Deyimler (Idioms)': Color(0xFF00BCD4), // Açık Mavi
    'Bağlaçlar (Conjunctions)': Color(0xFFCDDC39), // Açık Yeşil
    'Günlük Konuşma': Color(0xFFFFC107), // Amber
    'İş İngilizcesi': Color(0xFFFF5722), // Derin Turuncu
    'Akademik İngilizce': Color(0xFF5E35B1), // Derin Mor
    'Alışveriş': Color(0xFFEC407A), // Pembe
    'Seyahat': Color(0xFF29B6F6), // Açık Mavi
    'Yiyecek & İçecek': Color(0xFFFF7043), // Derin Turuncu
    'Ev & Eşyalar': Color(0xFF8D6E63), // Açık Kahverengi
    'Sağlık & Vücut': Color(0xFFEF5350), // Açık Kırmızı
    'Duygular': Color(0xFFAB47BC), // Açık Mor
    'Spor': Color(0xFF66BB6A), // Açık Yeşil
    'Teknoloji': Color(0xFF546E7A), // Mavi Gri
    'Doğa & Çevre': Color(0xFF26A69A), // Teal
    'Ulaşım': Color(0xFF5C6BC0), // İndigo
    'Okul & Eğitim': Color(0xFF1E88E5), // Mavi
    'İnsanlar & Meslekler': Color(0xFF00ACC1), // Cyan
    'Hayvanlar': Color(0xFFFFA726), // Turuncu
    'Hobiler & Eğlence': Color(0xFFEC407A), // Pembe
  };

  // ✅ KATEGORİ RENGİNİ AL
  static Color getCategoryColor(String categoryName) {
    return categoryColors[categoryName] ?? Color(0xFF2196F3);
  }

  // ✅ KATEGORİNİN TOPLAM SEVIYE SAYISINI HESAPLA
  // Örnek: 100 kelime * 5 seviye = 500 toplam seviye
  static Future<int> getCategoryMaxLevel(String categoryName) async {
    try {
      final totalWords = await getCategoryWordCount(categoryName);
      return totalWords * 5; // Her kelimenin max 5 seviyesi var
    } catch (e) {
      print('❌ Error getting max level: $e');
      return 0;
    }
  }

  // ✅ KATEGORİNİN TAMAMLANAN TOPLAM SEVIYE SAYISINI HESAPLA
  static Future<int> getCategoryCompletedLevel(String categoryName) async {
    try {
      final box = Hive.box('wordsBox');
      int totalCompletedLevel = 0;

      // Category prefix'i ile tüm kelimeleri arat
      for (var key in box.keys) {
        final value = box.get(key);
        if (value is Map && value['category'] == categoryName) {
          // Her kelimenin level'ını topla (0-5 arası)
          final level = value['level'] as int? ?? 0;
          totalCompletedLevel += level;
        }
      }

      return totalCompletedLevel;
    } catch (e) {
      print('❌ Error getting completed level: $e');
      return 0;
    }
  }

  // ✅ KATEGORİNİN YÜZDE ILERLEMESINI HESAPLA
  // Formula: (Tamamlanan Seviye / Maksimum Seviye) * 100
  static Future<double> getCategoryProgress(String categoryName) async {
    try {
      final maxLevel = await getCategoryMaxLevel(categoryName);
      if (maxLevel == 0) return 0.0;

      final completedLevel = await getCategoryCompletedLevel(categoryName);
      final progress = completedLevel / maxLevel;

      return progress.clamp(0.0, 1.0);
    } catch (e) {
      print('❌ Error calculating progress: $e');
      return 0.0;
    }
  }

  // ✅ KATEGORİNİN KELIME SAYISINI AL
  static Future<int> getCategoryWordCount(String categoryName) async {
    try {
      // JSON dosyası adını bul
      final jsonFileName = _getCategoryJsonFileName(categoryName);
      final jsonString = 
          await rootBundle.loadString('assets/data/$jsonFileName');
      final List<dynamic> words = jsonDecode(jsonString);
      return words.length;
    } catch (e) {
      print('❌ Error loading word count: $e');
      return 0;
    }
  }

  // ✅ TAMAMLANAN KELIME SAYISINI AL (seviye >= 5)
  static Future<int> getCategoryCompletedWords(String categoryName) async {
    try {
      final box = Hive.box('wordsBox');
      int completedCount = 0;

      for (var key in box.keys) {
        final value = box.get(key);
        if (value is Map && value['category'] == categoryName) {
          final level = value['level'] as int? ?? 0;
          if (level >= 5) {
            completedCount++;
          }
        }
      }

      return completedCount;
    } catch (e) {
      print('❌ Error getting completed words: $e');
      return 0;
    }
  }

  // ✅ KATEGORİNİN İLERLEME BİLGİSİNİ AL (Hepsi Bir Seferde)
  static Future<CategoryProgress> getCategoryProgressInfo(
      String categoryName) async {
    try {
      final maxLevel = await getCategoryMaxLevel(categoryName);
      final completedLevel = await getCategoryCompletedLevel(categoryName);
      final wordCount = await getCategoryWordCount(categoryName);
      final completedWords = await getCategoryCompletedWords(categoryName);
      final progress = maxLevel > 0 ? completedLevel / maxLevel : 0.0;

      return CategoryProgress(
        categoryName: categoryName,
        totalWords: wordCount,
        completedWords: completedWords,
        maxLevel: maxLevel,
        completedLevel: completedLevel,
        progress: progress.clamp(0.0, 1.0),
        color: getCategoryColor(categoryName),
      );
    } catch (e) {
      print('❌ Error getting category progress: $e');
      return CategoryProgress(
        categoryName: categoryName,
        totalWords: 0,
        completedWords: 0,
        maxLevel: 0,
        completedLevel: 0,
        progress: 0.0,
        color: Color(0xFF2196F3),
      );
    }
  }

  // ✅ JSON DOSYA ADINI BULMA HELPER
  static String _getCategoryJsonFileName(String categoryName) {
    const Map<String, String> categoryMap = {
      'A1 Seviye Kelimeler': 'a1.json',
      'A2 Seviye Kelimeler': 'a2.json',
      'B1 Seviye Kelimeler': 'b1.json',
      'B2 Seviye Kelimeler': 'b2.json',
      'C1 Seviye Kelimeler': 'c1.json',
      'C2 Seviye Kelimeler': 'c2.json',
      'Fiiller (Verbs)': 'verbs.json',
      'Sıfatlar (Adjectives)': 'adjectives.json',
      'Zarflar (Adverbs)': 'adverbs.json',
      'İsimler (Nouns)': 'nouns.json',
      'Fiil Öbekleri (Phrasal Verbs)': 'phrasal_verbs.json',
      'Deyimler (Idioms)': 'idioms.json',
      'Bağlaçlar (Conjunctions)': 'conjunctions.json',
      'Günlük Konuşma': 'daily_conversation.json',
      'İş İngilizcesi': 'business_english.json',
      'Akademik İngilizce': 'academic_english.json',
      'Alışveriş': 'shopping.json',
      'Seyahat': 'travel.json',
      'Yiyecek & İçecek': 'food_drink.json',
      'Ev & Eşyalar': 'home_furniture.json',
      'Sağlık & Vücut': 'health_body.json',
      'Duygular': 'emotions.json',
      'Spor': 'sports.json',
      'Teknoloji': 'technology.json',
      'Doğa & Çevre': 'nature_environment.json',
      'Ulaşım': 'transportation.json',
      'Okul & Eğitim': 'school_education.json',
      'İnsanlar & Meslekler': 'people_professions.json',
      'Hayvanlar': 'animals.json',
      'Hobiler & Eğlence': 'hobbies_entertainment.json',
    };

    return categoryMap[categoryName] ?? 'a1.json';
  }
}

// ✅ KATEGORI İLERLEME DATA SINIFI
class CategoryProgress {
  final String categoryName;
  final int totalWords;
  final int completedWords;
  final int maxLevel;
  final int completedLevel;
  final double progress; // 0.0 - 1.0 arası
  final Color color;

  CategoryProgress({
    required this.categoryName,
    required this.totalWords,
    required this.completedWords,
    required this.maxLevel,
    required this.completedLevel,
    required this.progress,
    required this.color,
  });

  // %lik ilerlemeyi string olarak döndür
  String getProgressPercentage() {
    return '${(progress * 100).toStringAsFixed(0)}%';
  }

  // Tamamlandı mı?
  bool isCompleted() {
    return progress >= 1.0;
  }
}