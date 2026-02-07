import 'package:hive/hive.dart';
import 'dart:collection';
import 'words_loader.dart';

class WordManager {
  static const int CACHE_SIZE = 30;
  static const int BATCH_SIZE = 10;
  
  final String category;
  final Box wordsBox;
  
  final LinkedHashMap<String, Word> _cache = LinkedHashMap();
  List<WordMeta> _wordMetas = [];
  int _currentIndex = 0;
  
  WordManager({
    required this.category,
    required this.wordsBox,
  });
  
  Future<void> initialize() async {
    print('WordManager: Initializing for category: $category');
    
    _wordMetas.clear();
    _cache.clear();
    _currentIndex = 0;
    
    try {
      // Kelimeleri yükle - wordsBox'ın bütün keylerini kontrol et
      final allKeys = wordsBox.keys.toList();
      print('WordManager: Total keys in box: ${allKeys.length}');
      
      for (var key in allKeys) {
        // Meta key'leri skip et
        if (key == 'imported' || key == 'isPremium' || key == 'defaultCategory' || key.toString().endsWith('_loaded')) {
          continue;
        }
        
        try {
          final data = wordsBox.get(key);
          
          // Null kontrol
          if (data == null) {
            print('WordManager: Data is null for key: $key');
            continue;
          }
          
          // Map mi kontrol et (boolean değilse)
          if (data is! Map) {
            print('WordManager: Data is not Map for key: $key, type: ${data.runtimeType}');
            continue;
          }
          
          // Kategorileri kontrol et
          final wordCategory = data['category'];
          if (wordCategory == null) {
            print('WordManager: Category is null for key: $key');
            continue;
          }
          
          if (wordCategory == category) {
            _wordMetas.add(WordMeta(
              id: key.toString(),
              level: data['level'] ?? 0,
              lastSeenIndex: data['lastSeenIndex'] ?? -1,
            ));
          }
        } catch (e) {
          print('WordManager: Error processing key $key: $e');
          continue;
        }
      }
      
      print('WordManager: Found ${_wordMetas.length} words for category: $category');
      
      if (_wordMetas.isEmpty) {
        print('⚠️ WordManager: NO WORDS FOUND FOR CATEGORY: $category');
        return;
      }
      
      _sortWordMetas();
      print('✅ WordManager: Initialization complete');
      
    } catch (e) {
      print('❌ WordManager: CRITICAL ERROR during initialize: $e');
      rethrow;
    }
  }
  
  void _sortWordMetas() {
    _wordMetas.sort((a, b) {
      // Öncelikle görülmesi gerekenler
      final now = _currentIndex;
      final aShouldShow = a.lastSeenIndex <= now;
      final bShouldShow = b.lastSeenIndex <= now;
      
      if (aShouldShow && !bShouldShow) return -1;
      if (!aShouldShow && bShouldShow) return 1;
      
      // Level'e göre sırala (düşük level önce)
      if (a.level != b.level) return a.level.compareTo(b.level);
      
      return a.lastSeenIndex.compareTo(b.lastSeenIndex);
    });
  }
  
  Future<Word?> getWord(int index) async {
    if (_wordMetas.isEmpty) {
      print('WordManager: No words available');
      return null;
    }
    
    // Sonsuz döngü için modulo
    final actualIndex = index % _wordMetas.length;
    final meta = _wordMetas[actualIndex];
    
    // Cache kontrolü
    if (_cache.containsKey(meta.id)) {
      final word = _cache.remove(meta.id)!;
      _cache[meta.id] = word; // LRU için sona taşı
      return word;
    }
    
    // DB'den yükle
    final data = wordsBox.get(meta.id);
    if (data == null) {
      print('WordManager: Data not found for ${meta.id}');
      return null;
    }
    
    final word = Word(
      id: meta.id,
      word: data['word'] ?? '',
      correct: data['correct'] ?? '',
      wrong: data['wrong'] ?? '',
      category: data['category'] ?? category,
      level: meta.level,
      lastSeenIndex: meta.lastSeenIndex,
    );
    
    _addToCache(meta.id, word);
    return word;
  }
  
  void _addToCache(String id, Word word) {
    if (_cache.length >= CACHE_SIZE) {
      _cache.remove(_cache.keys.first);
    }
    _cache[id] = word;
  }
  
  Future<List<Word>> preloadNext(int startIndex, {int count = BATCH_SIZE}) async {
    final words = <Word>[];
    
    for (int i = 0; i < count; i++) {
      final word = await getWord(startIndex + i);
      if (word != null) {
        words.add(word);
      }
    }
    
    return words;
  }
  
  void updateWord(String id, int newLevel) {
    // Meta veriyi güncelle
    final metaIndex = _wordMetas.indexWhere((m) => m.id == id);
    if (metaIndex != -1) {
      final meta = _wordMetas[metaIndex];
      meta.level = newLevel;
      meta.lastSeenIndex = _currentIndex + _calculateRepeatOffset(newLevel);
      
      // DB'ye kaydet
      _scheduleDBUpdate(id, meta);
    }
    
    // Cache güncelle
    if (_cache.containsKey(id)) {
      _cache[id]!.level = newLevel;
      _cache[id]!.lastSeenIndex = _currentIndex + _calculateRepeatOffset(newLevel);
    }
  }
  
  final Map<String, WordMeta> _pendingUpdates = {};
  DateTime? _lastFlush;
  
  void _scheduleDBUpdate(String id, WordMeta meta) {
    _pendingUpdates[id] = meta;
    
    if (_pendingUpdates.length >= 5 ||
        (_lastFlush != null && 
         DateTime.now().difference(_lastFlush!).inSeconds > 3)) {
      // Async flush'ı arka planda yap, bloke etme!
      _flushUpdates();
    }
  }
  
  Future<void> _flushUpdates() async {
    if (_pendingUpdates.isEmpty) return;
    
    try {
      final batch = <String, dynamic>{};
      for (var entry in _pendingUpdates.entries) {
        final existing = wordsBox.get(entry.key);
        if (existing != null) {
          existing['level'] = entry.value.level;
          existing['lastSeenIndex'] = entry.value.lastSeenIndex;
          batch[entry.key] = existing;
        }
      }
      
      if (batch.isNotEmpty) {
        await wordsBox.putAll(batch);
        print('✅ Flushed ${batch.length} updates to DB');
      }
    } catch (e) {
      print('❌ Error flushing updates: $e');
    }
    
    _pendingUpdates.clear();
    _lastFlush = DateTime.now();
  }
  
  // ⭐️ Public flush method
  Future<void> flushUpdates() => _flushUpdates();
  
  int _calculateRepeatOffset(int level) {
    switch (level) {
      case 0: return 2;   // Yeni kelime - çok sık
      case 1: return 5;   // Öğreniliyor - sık
      case 2: return 10;  // Neredeyse öğrenildi - orta
      case 3: return 20;  // Öğrenildi - seyrek
      case 4: return 30;  // Neredeyse master
      case 5: return 50;  // Master - çok seyrek
      default: return 50;
    }
  }
  
  void dispose() {
    // Arka planda flush'ı yap ama bloke etme
    _flushUpdates();
    _cache.clear();
    _wordMetas.clear();
  }
  
  int get totalWords => _wordMetas.length;
  int get currentIndex => _currentIndex;
  
  void incrementIndex() {
    _currentIndex++;
    // Sonsuz döngü
    if (_currentIndex >= _wordMetas.length && _wordMetas.isNotEmpty) {
      _currentIndex = 0;
      _sortWordMetas(); // Yeniden sırala
    }
  }
  
  // Belirli bir index'e git
  void jumpToIndex(int index) {
    if (_wordMetas.isNotEmpty) {
      _currentIndex = index % _wordMetas.length;
    }
  }
}

class WordMeta {
  final String id;
  int level;
  int lastSeenIndex;
  
  WordMeta({
    required this.id,
    required this.level,
    required this.lastSeenIndex,
  });
}