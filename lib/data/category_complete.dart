import 'package:hive/hive.dart';
import 'swipe_counter.dart';

class CategoryComplete {
  static late Box settingsBox;
  static late Box wordsBox;

  static Future<void> initialize() async {
    settingsBox = Hive.box('settingsBox');
    wordsBox = Hive.box('wordsBox');
  }

  /// Kategori tamamlandı mı kontrol et
  static bool isCategoryCompleted(String category) {
    return settingsBox.get('${category}_completed', defaultValue: false) as bool;
  }

  /// Kategorideki tamamlanan kelime sayısı (level 5)
  static int getCompletedWordsCount(String category) {
    int count = 0;
    try {
      for (var key in wordsBox.keys) {
        final value = wordsBox.get(key);
        
        // Meta key'leri skip et (A1_loaded, isPremium vs)
        if (value is! Map) {
          continue;
        }
        
        // Map kontrolü
        final cat = value['category'];
        final level = value['level'];
        
        // Kategori ve level kontrolü
        if (cat == category && level == 5) {
          count++;
          print('✅ Completed Word: ${value['word']} (Level: $level)');
        }
      }
    } catch (e) {
      print('❌ getCompletedWordsCount Error: $e');
    }
    return count;
  }

  /// Kategorideki toplam kelime sayısı
  static int getTotalWordsCount(String category) {
    int count = 0;
    try {
      for (var key in wordsBox.keys) {
        final value = wordsBox.get(key);
        
        // Meta key'leri skip et
        if (value is! Map) {
          continue;
        }
        
        // Map kontrolü
        final cat = value['category'];
        final word = value['word'];
        
        // Kategori ve word kontrolü
        if (cat == category && word != null && word.isNotEmpty) {
          count++;
          print('📝 Total Word: $word - Category: $category');
        }
      }
    } catch (e) {
      print('❌ getTotalWordsCount Error: $e');
    }
    return count;
  }

  /// Kategori tamamlanmış mı kontrol et ve ödül ver
  static Future<bool> checkAndCompleteCategory(String category) async {
    print('═══════════════════════════════════');
    print('🔍 checkAndCompleteCategory başladı: $category');
    
    final completed = getCompletedWordsCount(category);
    final total = getTotalWordsCount(category);

    print('📊 Sonuç: $category - $completed/$total tamamlandı');
    print('═══════════════════════════════════');

    // Eğer tüm kelimeler level 5 ise kategori tamamlandı
    if (completed == total && total > 0) {
      print('✅✅✅ KATEGORİ TAMAMLANDI! ($completed/$total)');
      
      // Önceden tamamlanmamışsa ödül ver
      final wasCompleted = isCategoryCompleted(category);
      if (!wasCompleted) {
        // Kategoriyi tamamlandı olarak işaretle
        await settingsBox.put('${category}_completed', true);

        // ⭐️ +50 swipe ödülü ver
        try {
          final result = await SwipeCounter.addBonusSwipes(50);
          print('🎉 $category TAMAMLANDI! +50 swipe ödülü verildi (result: $result)');
        } catch (e) {
          print('❌ Bonus swipe error: $e');
          // Hata olsa bile kategoriyi tamamlandı olarak işaretle
        }
      } else {
        print('ℹ️ $category önceden tamamlanmıştı (ödül verilmedi)');
      }
      
      return true;
    }
    
    print('❌ Kategori henüz tamamlanmamış ($completed/$total)');
    return false;
  }

  /// Tüm kategorileri sıfırla (test için)
  static Future<void> resetAll() async {
    final categories = ['A1', 'A2', 'B1', 'Günlük', 'İş İngilizcesi', 'Seyahat'];
    for (var cat in categories) {
      await settingsBox.put('${cat}_completed', false);
    }
    print('🔄 Tüm kategoriler sıfırlandı');
  }
}