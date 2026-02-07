import 'package:hive/hive.dart';

class SwipeCounter {
  static const String BOX_NAME = 'settingsBox';
  static const int MAX_DAILY_SWIPES = 50;
  static const int SWIPE_BONUS_AT_7_DAYS = 10;
  static const int SWIPE_BONUS_AT_14_DAYS = 7;
  
  static late Box _box;
  
  static Future<void> initialize() async {
    _box = Hive.box(BOX_NAME);
    
    // İlk kurulum
    if (!_box.containsKey('swipeCount')) {
      await _box.put('swipeCount', 0);
      await _box.put('bonusSwipes', 0);  // ⭐️ Bonus swipe'ları ayrı tutuyoruz!
      await _box.put('lastSwipeDate', _todayString());
      await _box.put('streak', 0);
      await _box.put('lastStreakDate', _todayString());
      await _box.put('totalSwipes', 0);
    }
    
    // Gün değişti mi kontrol et
    _checkDailyReset();
  }
  
  /// Gün değişip değişmediğini kontrol et ve reset et
  static void _checkDailyReset() {
    final today = _todayString();
    final lastDate = _box.get('lastSwipeDate', defaultValue: today) as String;
    
    if (lastDate != today) {
      print('📅 Yeni gün! Swipe counter reset ediliyor...');
      // Streak kontrol et
      if (_getDaysDifference(lastDate, today) == 1) {
        // Dün swipe yapıldıysa streak devam et
        final currentStreak = (_box.get('streak', defaultValue: 0) as int) + 1;
        _box.put('streak', currentStreak);
        print('🔥 Streak devam! Gün: $currentStreak');
      } else if (_getDaysDifference(lastDate, today) > 1) {
        // 1 günden fazla boş bırakıldıysa streak sıfırla
        _box.put('streak', 0);
        print('❌ Streak sıfırlandı!');
      }
      
      // ✅ DÜZELTME: Günlük swipe'ı VE bonus'u sıfırla!
      _box.put('swipeCount', 0);
      _box.put('bonusSwipes', 0);  // 🎁 Bonus'u sıfırla! (Ertesi gün 50 hak olur)
      _box.put('lastSwipeDate', today);
      _box.put('lastStreakDate', today);
      
      print('✅ Günlük swipe sıfırlandı: 50 hak');
      print('✅ Bonus swipe\'lar sıfırlandı: 0 (Yeni gün başladı)');
    }
  }
  
  /// Swipe ekle
  static Future<SwipeResult> addSwipe(bool isPremium) async {
    _checkDailyReset();
    
    if (isPremium) {
      // Premium user sınırsız
      final totalSwipes = (_box.get('totalSwipes', defaultValue: 0) as int) + 1;
      await _box.put('totalSwipes', totalSwipes);
      return SwipeResult.success();
    }
    
    final currentSwipes = _box.get('swipeCount', defaultValue: 0) as int;
    final bonusSwipes = (_box.get('bonusSwipes', defaultValue: 0) as int);  // ⭐️ Bonus'u al
    final totalSwipes = (_box.get('totalSwipes', defaultValue: 0) as int);
    final streak = _box.get('streak', defaultValue: 0) as int;
    
    // Streak bonusu hesapla
    int streakBonus = 0;
    if (streak >= 14) {
      streakBonus = SWIPE_BONUS_AT_14_DAYS;
    } else if (streak >= 7) {
      streakBonus = SWIPE_BONUS_AT_7_DAYS;
    }
    
    // Maksimum: 50 (günlük) + bonusSwipes (kazanılmış) + streakBonus
    final maxSwipes = MAX_DAILY_SWIPES + bonusSwipes + streakBonus;
    
    if (currentSwipes >= maxSwipes) {
      print('❌ Günlük swipe limitine ulaştı! (${currentSwipes}/$maxSwipes)');
      print('   Günlük: $currentSwipes/$MAX_DAILY_SWIPES');
      print('   Bonus: +$bonusSwipes');
      print('   Streak: +$streakBonus');
      return SwipeResult.limitReached(
        currentSwipes: currentSwipes,
        maxSwipes: maxSwipes,
        streak: streak,
        bonusSwipes: bonusSwipes,
      );
    }
    
    // Swipe ekle
    await _box.put('swipeCount', currentSwipes + 1);
    await _box.put('totalSwipes', totalSwipes + 1);
    
    print('✅ Swipe eklendi! (${currentSwipes + 1}/$maxSwipes)');
    print('   Günlük: ${currentSwipes + 1}/$MAX_DAILY_SWIPES');
    print('   Bonus: +$bonusSwipes');
    print('   Streak: +$streakBonus');
    
    return SwipeResult.success(
      currentSwipes: currentSwipes + 1,
      maxSwipes: maxSwipes,
      streak: streak,
      bonusSwipes: bonusSwipes,
    );
  }
  
  /// ⭐️ Bonus swipe'lar ekle (kategori tamamlama, combo vs)
  /// Bunlar günlük hak olan 50'ye EK olarak eklenir!
  static Future<int> addBonusSwipes(int amount) async {
    try {
      // Bonus swipe'ları ayrı bir key'e kaydet
      final bonusSwipes = (_box.get('bonusSwipes', defaultValue: 0) as int) + amount;
      await _box.put('bonusSwipes', bonusSwipes);
      
      // Total swipe'a da ekle
      final totalSwipes = (_box.get('totalSwipes', defaultValue: 0) as int) + amount;
      await _box.put('totalSwipes', totalSwipes);
      
      print('🎁 +$amount bonus swipe eklendi! (Total Bonus: $bonusSwipes)');
      return bonusSwipes;
    } catch (e) {
      print('❌ Error adding bonus swipes: $e');
      return (_box.get('bonusSwipes', defaultValue: 0) as int);
    }
  }
  
  /// Günlük swipe sayacı (50 sınırı)
  static int getDailySwipeCount() {
    _checkDailyReset();
    return _box.get('swipeCount', defaultValue: 0) as int;
  }
  
  /// Bonus swipe'lar
  static int getBonusSwipes() {
    return _box.get('bonusSwipes', defaultValue: 0) as int;
  }
  
  /// Maksimum günlük swipe (bonus + streak dahil)
  static int getMaxDailySwipes(int streak) {
    int streakBonus = 0;
    if (streak >= 14) {
      streakBonus = SWIPE_BONUS_AT_14_DAYS;
    } else if (streak >= 7) {
      streakBonus = SWIPE_BONUS_AT_7_DAYS;
    }
    final bonusSwipes = (_box.get('bonusSwipes', defaultValue: 0) as int);
    return MAX_DAILY_SWIPES + bonusSwipes + streakBonus;
  }
  
  /// Streak sayısı
  static int getStreak() {
    _checkDailyReset();
    return _box.get('streak', defaultValue: 0) as int;
  }
  
  /// Toplam tüm zamanlar swipe
  static int getTotalSwipes() {
    return _box.get('totalSwipes', defaultValue: 0) as int;
  }
  
  /// Streak bilgisi
  static StreakInfo getStreakInfo() {
    final streak = getStreak();
    final daysTo7 = 7 - streak;
    final daysTo14 = 14 - streak;
    
    return StreakInfo(
      current: streak,
      daysTo7DayBonus: streak < 7 ? daysTo7 : 0,
      daysTo14DayBonus: streak < 14 ? daysTo14 : 0,
      bonus7Days: SWIPE_BONUS_AT_7_DAYS,
      bonus14Days: SWIPE_BONUS_AT_14_DAYS,
    );
  }
  
  /// Tüm verileri sıfırla (test için)
  static Future<void> resetAll() async {
    await _box.put('swipeCount', 0);
    await _box.put('bonusSwipes', 0);
    await _box.put('lastSwipeDate', _todayString());
    await _box.put('streak', 0);
    await _box.put('lastStreakDate', _todayString());
    await _box.put('totalSwipes', 0);
  }
  
  // HELPER FUNCTIONS
  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
  
  static int _getDaysDifference(String date1, String date2) {
    final d1 = DateTime.parse(date1);
    final d2 = DateTime.parse(date2);
    return d2.difference(d1).inDays;
  }
}

/// Swipe sonucu
class SwipeResult {
  final bool success;
  final int? currentSwipes;
  final int? maxSwipes;
  final int? streak;
  final int? bonusSwipes;
  
  SwipeResult({
    required this.success,
    this.currentSwipes,
    this.maxSwipes,
    this.streak,
    this.bonusSwipes,
  });
  
  factory SwipeResult.success({
    int currentSwipes = 0,
    int maxSwipes = 50,
    int streak = 0,
    int bonusSwipes = 0,
  }) {
    return SwipeResult(
      success: true,
      currentSwipes: currentSwipes,
      maxSwipes: maxSwipes,
      streak: streak,
      bonusSwipes: bonusSwipes,
    );
  }
  
  factory SwipeResult.limitReached({
    required int currentSwipes,
    required int maxSwipes,
    required int streak,
    required int bonusSwipes,
  }) {
    return SwipeResult(
      success: false,
      currentSwipes: currentSwipes,
      maxSwipes: maxSwipes,
      streak: streak,
      bonusSwipes: bonusSwipes,
    );
  }
}

/// Streak bilgisi
class StreakInfo {
  final int current;
  final int daysTo7DayBonus;
  final int daysTo14DayBonus;
  final int bonus7Days;
  final int bonus14Days;
  
  StreakInfo({
    required this.current,
    required this.daysTo7DayBonus,
    required this.daysTo14DayBonus,
    required this.bonus7Days,
    required this.bonus14Days,
  });
}