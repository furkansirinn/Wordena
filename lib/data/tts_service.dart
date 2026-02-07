import 'package:flutter_tts/flutter_tts.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  
  // Hız seviyeleri
  static const double FAST_SPEED = 0.5;    // Normal hız
  static const double SLOW_SPEED = 0.1;    // Yarı hız
  
  bool _isInitialized = false;
  int _tapCount = 0;
  String _lastWord = '';

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Dil İngilizce olarak ayarla
      await _flutterTts.setLanguage('en-US');
      
      // Ses şiddeti ve hız
      await _flutterTts.setSpeechRate(FAST_SPEED);
      await _flutterTts.setVolume(1.0);
      
      // Pitch (ses tonu)
      await _flutterTts.setPitch(1.0);
      
      _isInitialized = true;
      print('✅ TTS Service initialized');
    } catch (e) {
      print('❌ TTS initialization error: $e');
    }
  }

  /// Kelimeyi seslendir - hız değiştirme sistemi
  /// İlk basış: hızlı (1.0)
  /// 2. basış: yavaş (0.5)
  /// 3. basış: hızlı (1.0)
  /// 4. basış: yavaş (0.5)
  /// ... sonsuz döngü
  Future<void> speak(String word) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Farklı kelime gelirse tap sayısını sıfırla
      if (_lastWord != word) {
        _tapCount = 0;
        _lastWord = word;
      } else {
        _tapCount++;
      }

      // Hız belirle: çift tap yavaş, tek tap hızlı
      final speed = (_tapCount % 2 == 0) ? FAST_SPEED : SLOW_SPEED;
      
      print('🔊 Speaking: "$word" - Tap: $_tapCount - Speed: $speed');

      // Önceki sesi durdur
      await _flutterTts.stop();

      // Yeni sesi başlat
      await _flutterTts.setSpeechRate(speed);
      await _flutterTts.speak(word);
    } catch (e) {
      print('❌ TTS speak error: $e');
    }
  }

  /// Sesi durdur
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      print('❌ TTS stop error: $e');
    }
  }

  /// Temizle
  void dispose() {
    _flutterTts.stop();
    _tapCount = 0;
    _lastWord = '';
  }

  /// Hız bilgisi get et (UI için gösterebilirsin)
  double getCurrentSpeed() {
    return (_tapCount % 2 == 0) ? FAST_SPEED : SLOW_SPEED;
  }

  /// Hız metnini get et
  String getSpeedText() {
    final speed = (_tapCount % 2 == 0) ? 'Hızlı' : 'Yavaş';
    return speed;
  }
}