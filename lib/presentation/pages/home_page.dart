import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/theme.dart';
import '../../data/word_manager.dart';
import '../../data/words_loader.dart';
import '../../data/swipe_counter.dart';
import '../../data/category_complete.dart';
import '../../data/ad_service.dart';
import '../../data/audio_service.dart';
import '../../data/tts_service.dart';
import '../../data/category_progress_service.dart';
import '../../data/in_app_purchase_service.dart';
import '../../main.dart' as main_module;
import '../widgets/swipe_card.dart';
import '../widgets/premium_dialog.dart';

class HomePage extends StatefulWidget {
  final String category;
  final bool isPremium;

  const HomePage({
    required this.category,
    required this.isPremium,
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  WordManager? _wordManager;
  Word? _currentWord;
  Word? _nextWord;
  bool _isLoading = true;
  String _currentCategory = '';
  int _currentSwipes = 0;
  int _maxSwipes = 50;
  int _currentCombo = 0;
  int _maxCombo = 0;
  bool _categoryCompletedShown = false;
  int _totalQuestionsAnswered = 0;
  late AdService _adService;
  late AudioService _audioService;
  late TTSService _ttsService;
  late AnimationController _comboAnimation;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.category;
    _adService = AdService();
    _audioService = AudioService();
    _ttsService = TTSService();

    _comboAnimation = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _audioService.initialize();
    _ttsService.initialize();

    if (!widget.isPremium) {
      _adService.loadBannerAd();
      _adService.loadInterstitialAd();
    }

    _updateSwipeInfo();
    _initializeManager();
  }

  @override
  void didUpdateWidget(HomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.category != widget.category) {
      _currentCategory = widget.category;
      _currentCombo = 0;
      _totalQuestionsAnswered = 0;
      _categoryCompletedShown = false;
      _reinitialize();
    }
    
    if (oldWidget.isPremium != widget.isPremium) {
      print('🔄 Premium durumu değişti: ${widget.isPremium}');
      _updateSwipeInfo();
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _updateSwipeInfo() {
    _currentSwipes = SwipeCounter.getDailySwipeCount();
    _maxSwipes = SwipeCounter.getMaxDailySwipes(0);
  }

  @override
  void dispose() {
    _wordManager?.dispose();
    _audioService.dispose();
    _ttsService.dispose();
    _comboAnimation.dispose();
    if (!widget.isPremium) {
      _adService.disposeBannerAd();
    }
    super.dispose();
  }

  Future<void> _reinitialize() async {
    _wordManager?.dispose();
    _wordManager = null;
    _currentWord = null;
    _nextWord = null;
    _categoryCompletedShown = false;

    if (mounted) {
      setState(() => _isLoading = true);
    }

    await Future.delayed(Duration(milliseconds: 100));
    await _initializeManager();
  }

  Future<void> _initializeManager() async {
    if (!mounted) return;

    try {
      await _loadCategoryWords();

      _wordManager = WordManager(
        category: _currentCategory,
        wordsBox: Hive.box('wordsBox'),
      );

      await _wordManager!.initialize();

      if (_wordManager!.totalWords > 0) {
        await _loadWords();
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadCategoryWords() async {
    if (!mounted) return;

    try {
      final box = Hive.box('wordsBox');

      if (box.containsKey('${_currentCategory}_loaded')) {
        return;
      }

      await main_module.loadCategoryWords(_currentCategory, box);
    } catch (e) {
      print('❌ Error loading category words: $e');
    }
  }

  Future<void> _loadWords() async {
    if (_wordManager == null || !mounted) return;

    try {
      _currentWord = await _wordManager!.getWord(_wordManager!.currentIndex);

      if (_currentWord == null && _wordManager!.totalWords > 0) {
        _wordManager!.jumpToIndex(0);
        _currentWord = await _wordManager!.getWord(0);
      }

      if (_currentWord != null) {
        _nextWord = await _wordManager!.getWord(_wordManager!.currentIndex + 1);
      }

      if (_wordManager!.totalWords > 2) {
        Future.microtask(() async {
          if (_wordManager != null && mounted) {
            await _wordManager!.preloadNext(_wordManager!.currentIndex + 2, count: 5);
          }
        });
      }
    } catch (e) {
      print('HomePage: Error loading words: $e');
    }
  }

  void _showComboMessage(int combo) {
    final userName =
        Hive.box('settingsBox').get('userName', defaultValue: 'Kullanıcı') as String;

    String message = '';

    if (combo == 5) {
      message = '🔥 5 Combo! Çok iyisin $userName! +2 Soru';
    } else if (combo == 10) {
      message = '🌟 10 Combo! Mükemmelsin $userName! +5 Soru';
    } else if (combo == 15) {
      message = '💎 15 Combo! Harikasın $userName!';
    } else if (combo == 20) {
      message = '🚀 20 Combo! İnanılmazsın $userName! +7 Soru';
    } else if (combo > 0 && combo % 5 == 0 && combo > 20) {
      message = '⭐️ $combo Combo! Müthiş!';
    }

    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          backgroundColor: combo <= 5
              ? Colors.orange[400]
              : combo <= 10
                  ? Colors.amber[400]
                  : combo <= 15
                      ? Colors.purple[400]
                      : Colors.pink[400],
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.all(16),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleSwipe(bool isCorrect, int newCombo) async {
    if (_currentWord == null || _wordManager == null || !mounted) return;

    setState(() {
      _currentCombo = newCombo;
      if (newCombo > _maxCombo) {
        _maxCombo = newCombo;
      }
    });

    if (isCorrect &&
        (newCombo == 5 ||
            newCombo == 10 ||
            newCombo == 15 ||
            newCombo == 20 ||
            (newCombo > 20 && newCombo % 5 == 0))) {
      _showComboMessage(newCombo);

      _audioService.playCombo();

      int bonusSwipes = 0;
      if (newCombo == 5)
        bonusSwipes = 2;
      else if (newCombo == 10)
        bonusSwipes = 5;
      else if (newCombo == 20)
        bonusSwipes = 7;
      else if (newCombo > 20 && newCombo % 5 == 0) bonusSwipes = 3;

      if (bonusSwipes > 0) {
        await SwipeCounter.addBonusSwipes(bonusSwipes);
        print('🎁 Combo Bonus: +$bonusSwipes Swipe!');
      }
    }

    if (!widget.isPremium) {
      final swipeResult = await SwipeCounter.addSwipe(widget.isPremium);

      if (!swipeResult.success) {
        _updateSwipeInfo();
        setState(() {});
        return;
      }
    } else {
      await SwipeCounter.addSwipe(widget.isPremium);
    }

    final newLevel = isCorrect
        ? (_currentWord!.level + 1).clamp(0, 5)
        : _currentWord!.level;

    _wordManager!.updateWord(_currentWord!.id, newLevel);
    _wordManager!.incrementIndex();

    await _wordManager!.flushUpdates();

    if (isCorrect && newLevel == 5) {
      final categoryCompleted =
          await CategoryComplete.checkAndCompleteCategory(_currentCategory);

      final isCategoryComplete =
          CategoryComplete.isCategoryCompleted(_currentCategory);

      if (isCategoryComplete && !_categoryCompletedShown) {
        _categoryCompletedShown = true;
        _audioService.playCategoryComplete();
        _showCategoryCompletedDialog();

        setState(() {});
      }
    }

    _updateSwipeInfo();
    await _loadNextWord();

    _totalQuestionsAnswered++;
    if (_totalQuestionsAnswered % 30 == 0 && !widget.isPremium) {
      print('🎬 30 soru doldu! Interstitial Ad gösteriliyor...');
      if (_adService.isInterstitialAdReady) {
        _adService.showInterstitialAd(
          onAdClosed: () {
            print('📺 Reklam kapatıldı, quiz devam ediyor...');
          },
        );
      }
    }
  }

  void _showCategoryCompletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: Colors.amber, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kategori Tamamlandı!',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 16),
            Text(
              '🎉',
              style: TextStyle(fontSize: 48),
            ),
            SizedBox(height: 12),
            Text(
              'Harika!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              '$_currentCategory kategorisinin\ntüm kelimelerini öğrendin!',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber[100]!, Colors.amber[50]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber[300]!, width: 1.5),
              ),
              child: Column(
                children: [
                  Icon(Icons.card_travel, color: Colors.amber[700], size: 40),
                  SizedBox(height: 12),
                  Text(
                    'Rozet Kazandın!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[700],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '+50 Swipe Ödülü 🎁',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.amber[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                child: Text(
                  'Harika!',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadNextWord() async {
    if (_wordManager == null || !mounted) return;

    try {
      final currentIndex = _wordManager!.currentIndex;

      _currentWord = await _wordManager!.getWord(currentIndex);

      if (_currentWord == null && _wordManager!.totalWords > 0) {
        _wordManager!.jumpToIndex(0);
        _currentWord = await _wordManager!.getWord(0);
      }

      if (_currentWord != null) {
        _nextWord = await _wordManager!.getWord(currentIndex + 1);
      }

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('❌ Error loading next word: $e');
    }
  }

  Color _getComboColor() {
    if (_currentCombo >= 20) return Color(0xFFFF6B9D);
    if (_currentCombo >= 15) return Color(0xFF9C27B0);
    if (_currentCombo >= 10) return Color(0xFFFFD700);
    if (_currentCombo >= 5) return Color(0xFFFF9800);
    if (_currentCombo > 0) return Colors.blue;
    return Colors.grey[400]!;
  }

  String _getComboEmoji() {
    if (_currentCombo >= 20) return '🚀';
    if (_currentCombo >= 15) return '💎';
    if (_currentCombo >= 10) return '🌟';
    if (_currentCombo >= 5) return '🔥';
    return '⭐';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
            SizedBox(height: 24),
            Text(
              'Kelimeler hazırlanıyor...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kategori: $_currentCategory',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    if (_wordManager == null || _wordManager!.totalWords == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.folder_open,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Bu kategoride kelime bulunamadı',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Kategori: $_currentCategory',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            SizedBox(height: 24),
            FilledButton(
              onPressed: _reinitialize,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              ),
              child: Text(
                'Yeniden Dene',
                style: TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_currentWord == null) {
      Future.microtask(() => _loadWords());

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Kelimeler yükleniyor...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    final isLimitReached = _currentSwipes >= _maxSwipes && !widget.isPremium;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          if (isLimitReached) _buildLimitBanner(),
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: SwipeCard(
                  key: ValueKey('${_currentWord!.id}'),
                  word: _currentWord!.word,
                  correctAnswer: _currentWord!.correct,
                  currentCombo: _currentCombo,
                  wrongAnswer: _currentWord!.wrong,
                  level: _currentWord!.level,
                  onAnswered: _handleSwipe,
                  audioService: _audioService,
                  ttsService: _ttsService,
                  categoryName: _currentCategory,
                  isEnabled: !isLimitReached,
                ),
              ),
            ),
          ),
          if (!widget.isPremium && _adService.bannerAd != null)
            SizedBox(
              height: 50,
              child: AdWidget(ad: _adService.bannerAd!),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isCategoryComplete = CategoryComplete.isCategoryCompleted(_currentCategory);
    final categoryColor = CategoryProgressService.getCategoryColor(_currentCategory);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            categoryColor.withOpacity(0.3),
            categoryColor.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCategoryComplete
                        ? Colors.green[100]
                        : categoryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCategoryComplete
                          ? Colors.green[400]!
                          : categoryColor,
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    _currentCategory,
                    style: TextStyle(
                      color: isCategoryComplete
                          ? Colors.green[700]
                          : categoryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              if (isCategoryComplete)
                Padding(
                  padding: EdgeInsets.only(left: 12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green[400]!,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                        SizedBox(width: 4),
                        Text(
                          'Tamamlandı',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildHeaderStat(
                Icons.style,
                '${_wordManager!.currentIndex + 1}',
                '${_wordManager!.totalWords}',
                'Kelime',
              ),
              _buildHeaderStat(
                Icons.local_fire_department,
                '$_currentCombo',
                'Max: $_maxCombo',
                'Combo',
                color: _getComboColor(),
              ),
              _buildHeaderStat(
                Icons.star,
                '${_currentWord?.level ?? 0}',
                '5',
                'Seviye',
              ),
              if (!widget.isPremium)
                _buildHeaderStat(
                  Icons.touch_app,
                  '$_currentSwipes',
                  '$_maxSwipes',
                  'Soru',
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(
    IconData icon,
    String current,
    String max,
    String label, {
    Color? color,
  }) {
    color ??= AppColors.text;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        SizedBox(height: 8),
        Text(
          current,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
        ),
        SizedBox(height: 2),
        Text(
          max,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLimitBanner() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[50]!, Colors.orange[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[300]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange[200],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.info, color: Colors.orange[700], size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Günlük limitine ulaştın!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Sınırsız swipe için Premium\'u dene',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12),
          FilledButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => PremiumDialog(),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange[700],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              'Premium',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}