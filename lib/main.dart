import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/swipe_counter.dart';
import 'data/category_complete.dart';
import 'data/in_app_purchase_service.dart';
import 'presentation/pages/name_dialog.dart';
import 'presentation/pages/splash_screen.dart';
import 'core/theme.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();


  
  // ⭐️ SADECE Hive başlat (çok hızlı)
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');
  await Hive.openBox('wordsBox');
  
  // ⭐️ Initialization'ları SPLASH'TE YAP (bloke etme!)
  // await SwipeCounter.initialize();
  // await CategoryComplete.initialize();
  // await InAppPurchaseService().initialize();
  
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Box settingsBox;
  bool _appInitialized = false;
  bool _showNameDialog = false;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    
    // İlk açılışta isim sorusu
    _showNameDialog = !settingsBox.containsKey('userName');
    
    // Dark mode değişikliklerini dinle
    settingsBox.watch(key: 'isDarkMode').listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = settingsBox.get('isDarkMode', defaultValue: false) as bool;

    return MaterialApp(
      title: "Wordena",
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: !_appInitialized
          ? SplashScreen(
              onComplete: () {
                if (mounted) {
                  setState(() {
                    _appInitialized = true;
                  });
                }
              },
            )
          : Stack(
              children: [
                MainScaffold(),
                if (_showNameDialog)
                  Scaffold(
                    backgroundColor: Colors.black54,
                    body: Center(
                      child: NameDialog(
                        onNameSaved: () {
                          if (mounted) {
                            setState(() {
                              _showNameDialog = false;
                            });
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

// Dinamik kategori yükleme (lazy loading)
Future<void> loadCategoryWords(String category, Box box) async {
  try {
    // Zaten yüklenmiş mi kontrol et
    if (box.containsKey('${category}_loaded')) {
      print('✅ $category zaten yüklü, skip');
      return;
    }

    print('⏳ $category yükleniyor...');

    // Kategori dosyasını belirle
    final categoryFile = _getCategoryFile(category);
    
    // JSON dosyasını oku
    final jsonStr = await rootBundle.loadString('assets/data/$categoryFile');
    final list = json.decode(jsonStr) as List;

    print('📊 $category için ${list.length} kelime yükleniyor...');

    // Batch import
    final Map<String, dynamic> batch = {};

    for (int i = 0; i < list.length; i++) {
      final item = list[i];
      batch[item['id']] = {
        'word': item['word'],
        'correct': item['correct'],
        'wrong': item['wrong'],
        'category': category, // ✨ JSON'daki category yerine parametre kullan
        'level': 0,
        'lastSeenIndex': -1,
      };

      // Her 500 kelimede bir DB'ye yaz
      if (batch.length >= 500) {
        await box.putAll(batch);
        batch.clear();

        if (i % 1000 == 0) {
          print('📊 ${i + 1}/${list.length} kelime yüklendi...');
          await Future.delayed(Duration(milliseconds: 10));
        }
      }
    }

    // Kalan kelimeleri yaz
    if (batch.isNotEmpty) {
      await box.putAll(batch);
    }

    // Kategori yüklendi işaretini koy
    await box.put('${category}_loaded', true);

    print('✅ $category başarıyla yüklendi! (${list.length} kelime)');

  } catch (e) {
    print('❌ Error loading $category: $e');
  }
}



String _getCategoryFile(String category) {
  final categoryMap = {
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

  final result = categoryMap[category];
  
  if (result == null) {
    print('⚠️ Kategori bulunamadı: $category');
    return 'a1.json' ; // Default olarak a1 dön
  }
  
  print('✅ Kategori yükleniyor: $category -> $result');
  return result;
}
