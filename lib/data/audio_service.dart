import 'package:audioplayers/audioplayers.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  late AudioPlayer _audioPlayer;
  bool _isInitialized = false;

  factory AudioService() {
    return _instance;
  }

  AudioService._internal();

  // ✨ İLK AÇILIŞTA BU ÇAĞIR (main.dart'da)
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      _audioPlayer = AudioPlayer();
      
      // Her bir sesi önceden yükle (preload)
      await _audioPlayer.setSource(AssetSource('sounds/correct.wav'));
      await _audioPlayer.setSource(AssetSource('sounds/wrong.mp3'));
      await _audioPlayer.setSource(AssetSource('sounds/category_complete.mp3'));
      await _audioPlayer.setSource(AssetSource('sounds/combo.mp3'));
      
      _isInitialized = true;
      print('✅ AudioService initialized successfully');
    } catch (e) {
      print('❌ AudioService initialization error: $e');
    }
  }

  /// Doğru cevap sesi
  Future<void> playCorrect() async {
    try {
      if (!_isInitialized) await initialize();
      
      await _audioPlayer.stop(); // Önceki sesi durdur
      await _audioPlayer.play(AssetSource('sounds/correct.wav'));
      print('🔊 Correct sound played');
    } catch (e) {
      print('❌ Error playing correct sound: $e');
    }
  }

  /// Yanlış cevap sesi
  Future<void> playWrong() async {
    try {
      if (!_isInitialized) await initialize();
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/wrong.mp3'));
      print('🔊 Wrong sound played');
    } catch (e) {
      print('❌ Error playing wrong sound: $e');
    }
  }

  /// Kategori tamamlama sesi
  Future<void> playCategoryComplete() async {
    try {
      if (!_isInitialized) await initialize();
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/category_complete.mp3'));
      print('🔊 Category complete sound played');
    } catch (e) {
      print('❌ Error playing category complete sound: $e');
    }
  }

  /// Combo sesi
  Future<void> playCombo() async {
    try {
      if (!_isInitialized) await initialize();
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/combo.mp3'));
      print('🔊 Combo sound played!');
    } catch (e) {
      print('❌ Combo sound error: $e');
    }
  }

  void dispose() {
    try {
      _audioPlayer.dispose();
      _isInitialized = false;
    } catch (e) {
      print('Error disposing AudioService: $e');
    }
  }
}