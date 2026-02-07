import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../core/theme.dart';
import '../../data/swipe_counter.dart';
import '../../data/ad_service.dart';
import '../../data/in_app_purchase_service.dart';
import '../widgets/premium_dialog.dart';

class SettingsPage extends StatefulWidget {
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late Box settingsBox;
  late Box wordsBox;
  late AdService _adService;
  late InAppPurchaseService _iapService;
  bool _isPurchasing = false;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    wordsBox = Hive.box('wordsBox');
    _adService = AdService();
    _iapService = InAppPurchaseService();

    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _adService.loadRewardedAd();
      }
    });
  }

  
void _showRewardedAdDialog() {
  // ⏰ 30 dakika kontrolü - EKLE!
  final cooldownSeconds = _adService.getRewardedAdCooldownSeconds();
  if (cooldownSeconds > 0) {
    final minutes = (cooldownSeconds / 60).ceil();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏳ Reklamı 30 dakikada bir izleyebilirsin. $minutes dakika sonra tekrar deneyebilirsin'),
        backgroundColor: Colors.orange,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
    return;
  }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.video_camera_back,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Video İzle',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Text(
                '30-45 saniye video izle ve +5 soru kazan! 🎬',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.blue[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue[200]!, width: 1.5),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Ödül: +5 SWIPE (hemen geçerli)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _adService.showRewardedAd(
                      onRewardEarned: (amount) {
                        SwipeCounter.addBonusSwipes(amount);
                        settingsBox.put('lastRewardedAdTime',
                            DateTime.now().millisecondsSinceEpoch);
                        setState(() {});

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.celebration, color: Colors.white),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '+$amount soru bonus kazandın! 🎉',
                                    style: TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                            backgroundColor: Colors.green[400],
                            duration: Duration(seconds: 3),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            margin: EdgeInsets.all(16),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      onAdClosed: () {
                        _adService.loadRewardedAd();
                        setState(() {});
                      },
                    );
                  },
                  icon: Icon(Icons.play_arrow),
                  label: Text(
                    'Video İzle',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(color: Colors.grey[300]!, width: 1.5),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'İptal',
                    style: TextStyle(
                      color: AppColors.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, int> _getStatistics() {
    int learnedWords = 0;
    int totalWords = 0;
    int completedCategories = 0;

    for (var value in wordsBox.values) {
      if (value is Map) {
        if (value['level'] != null && value['word'] != null) {
          totalWords++;
          if (value['level'] >= 5) {
            learnedWords++;
          }
        }
      }
    }

    final allCategories = [
      'A1 Seviye Kelimeler',
      'A2 Seviye Kelimeler',
      'B1 Seviye Kelimeler',
      'B2 Seviye Kelimeler',
      'C1 Seviye Kelimeler',
      'C2 Seviye Kelimeler',
      'Fiiller (Verbs)',
      'Sıfatlar (Adjectives)',
      'Zarflar (Adverbs)',
      'İsimler (Nouns)',
      'Fiil Öbekleri (Phrasal Verbs)',
      'Deyimler (Idioms)',
      'Bağlaçlar (Conjunctions)',
      'Günlük Konuşma',
      'İş İngilizcesi',
      'Akademik İngilizce',
      'Alışveriş',
      'Seyahat',
      'Yiyecek & İçecek',
      'Ev & Eşyalar',
      'Sağlık & Vücut',
      'Duygular',
      'Spor',
      'Teknoloji',
      'Doğa & Çevre',
      'Ulaşım',
      'Okul & Eğitim',
      'İnsanlar & Meslekler',
      'Hayvanlar',
      'Hobiler & Eğlence'
    ];

    for (var cat in allCategories) {
      if (settingsBox.get('${cat}_completed', defaultValue: false) as bool) {
        completedCategories++;
      }
    }

    return {
      'learned': learnedWords,
      'total': totalWords,
      'completed': completedCategories,
    };
  }

  String _getRank(int completedCategories) {
    if (completedCategories == 0) return 'Rookie';
    if (completedCategories <= 5) return 'Beginner';
    if (completedCategories <= 10) return 'Learner';
    if (completedCategories <= 15) return 'Explorer';
    if (completedCategories <= 20) return 'Achiever';
    if (completedCategories <= 25) return 'Expert';
    return 'Master';
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = _iapService.isPremium();
    final userName =
        settingsBox.get('userName', defaultValue: 'Kullanıcı') as String;

    final streakInfo = SwipeCounter.getStreakInfo();
    final currentSwipes = SwipeCounter.getDailySwipeCount();
    final maxSwipes = SwipeCounter.getMaxDailySwipes(streakInfo.current);

    final stats = _getStatistics();
    final rank = _getRank(stats['completed']!);

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(userName, rank),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPremiumCard(isPremium),
                  SizedBox(height: 20),
                  if (!isPremium) ...[
                    _buildVideoAdCard(),
                    SizedBox(height: 20),
                  ],
                  _buildStatisticsCard(
                    stats,
                    streakInfo,
                    currentSwipes,
                    maxSwipes,
                  ),
                  SizedBox(height: 20),
                  _buildBadgesSection(stats['completed']!),
                  SizedBox(height: 20),
                  _buildAboutCard(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String userName, String rank) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.3),
            AppColors.accent.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ayarlar',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Hoşgeldin $userName! 👋',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.amber[100]!, Colors.amber[50]!],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.amber[300]!,
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '⭐',
                  style: TextStyle(fontSize: 24),
                ),
                SizedBox(height: 4),
                Text(
                  rank,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[700],
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard(bool isPremium) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[50]!, Colors.amber[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.star,
                      color: Colors.amber[700],
                      size: 20,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    isPremium ? 'Premium Aktif ✓' : 'Premium',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber[800],
                    ),
                  ),
                ],
              ),
              if (isPremium)
                TextButton(
                  onPressed: () {
                    settingsBox.put('isPremium', false);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Premium kaldırıldı'),
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: EdgeInsets.all(16),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Text(
                    'Kaldır',
                    style: TextStyle(
                      color: Colors.red[600],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          _buildPremiumBenefitItem('Sınırsız soru'),
          _buildPremiumBenefitItem('Reklam yok'),
          _buildPremiumBenefitItem('30 kategori'),
          _buildPremiumBenefitItem('Gelişmiş istatistikler'),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: isPremium
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (context) => PremiumDialog(),
                      );
                    },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.amber[700],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isPremium ? 'Premium Aktif' : 'Premium Al',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBenefitItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check,
              size: 12,
              color: Colors.green[700],
            ),
          ),
          SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.text,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoAdCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.blue[100]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue[200],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.video_camera_back,
                  color: Colors.blue[700],
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Video İzle',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Bonus +5 soru kazan 🎬',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Hemen kullanılabilir ✓',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showRewardedAdDialog,
              icon: Icon(Icons.play_arrow, size: 20),
              label: Text(
                'Video İzle',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(
    Map<String, int> stats,
    dynamic streakInfo,
    int currentSwipes,
    int maxSwipes,
  ) {
    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.12),
            AppColors.accent.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.trending_up,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'İstatistikler',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatItem('📚', 'Öğrenilen', '${stats['learned']}', Colors.green),
              _buildStatItem(
                  '📖', 'Toplam', '${stats['total']}', AppColors.primary),
              _buildStatItem(
                  '🏆', 'Kategori', '${stats['completed']}/30', Colors.amber),
              _buildStatItem('🔥', 'Streak', '${streakInfo.current} gün', Colors.red),
            ],
          ),
          if (maxSwipes > 0) ...[
            SizedBox(height: 14),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!, width: 1),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.touch_app, color: Colors.blue[600], size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Günlük Soru',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue[800],
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$currentSwipes/$maxSwipes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String emoji,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 24),
          ),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(int completed) {
    final badges = [
      {'name': 'A1', 'emoji': '🟦', 'unlocked': completed >= 1},
      {'name': 'A2', 'emoji': '🟩', 'unlocked': completed >= 2},
      {'name': 'B1', 'emoji': '🟪', 'unlocked': completed >= 3},
      {'name': 'B2', 'emoji': '🟧', 'unlocked': completed >= 4},
      {'name': 'C1', 'emoji': '🟥', 'unlocked': completed >= 5},
      {'name': 'C2', 'emoji': '🟨', 'unlocked': completed >= 6},
      {'name': 'Fiiller', 'emoji': '🔤', 'unlocked': completed >= 7},
      {'name': 'Sıfatlar', 'emoji': '✨', 'unlocked': completed >= 8},
      {'name': 'Zarflar', 'emoji': '⚡', 'unlocked': completed >= 9},
      {'name': 'İsimler', 'emoji': '📦', 'unlocked': completed >= 10},
      {'name': 'Phrasal', 'emoji': '🔗', 'unlocked': completed >= 11},
      {'name': 'Deyimler', 'emoji': '💬', 'unlocked': completed >= 12},
      {'name': 'Bağlaçlar', 'emoji': '🔀', 'unlocked': completed >= 13},
      {'name': 'Günlük', 'emoji': '☀️', 'unlocked': completed >= 14},
      {'name': 'İş', 'emoji': '💼', 'unlocked': completed >= 15},
      {'name': 'Akademik', 'emoji': '📚', 'unlocked': completed >= 16},
      {'name': 'Alışveriş', 'emoji': '🛍️', 'unlocked': completed >= 17},
      {'name': 'Seyahat', 'emoji': '✈️', 'unlocked': completed >= 18},
      {'name': 'Yemek', 'emoji': '🍽️', 'unlocked': completed >= 19},
      {'name': 'Ev', 'emoji': '🏠', 'unlocked': completed >= 20},
      {'name': 'Sağlık', 'emoji': '💪', 'unlocked': completed >= 21},
      {'name': 'Duygular', 'emoji': '😊', 'unlocked': completed >= 22},
      {'name': 'Spor', 'emoji': '⚽', 'unlocked': completed >= 23},
      {'name': 'Teknoloji', 'emoji': '💻', 'unlocked': completed >= 24},
      {'name': 'Doğa', 'emoji': '🌍', 'unlocked': completed >= 25},
      {'name': 'Ulaşım', 'emoji': '🚗', 'unlocked': completed >= 26},
      {'name': 'Okul', 'emoji': '📖', 'unlocked': completed >= 27},
      {'name': 'Meslekler', 'emoji': '👥', 'unlocked': completed >= 28},
      {'name': 'Hayvanlar', 'emoji': '🐾', 'unlocked': completed >= 29},
      {'name': 'Hobiler', 'emoji': '🎮', 'unlocked': completed >= 30},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.pink.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.card_travel,
                color: Colors.pink,
                size: 22,
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Rozetler',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 5,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 6,
          childAspectRatio: 0.9,
          children: badges.map((badge) {
            final unlocked = badge['unlocked'] as bool;
            return _buildBadge(
              badge['name'] as String,
              badge['emoji'] as String,
              unlocked,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBadge(String name, String emoji, bool unlocked) {
    return Container(
      decoration: BoxDecoration(
        gradient: unlocked
            ? LinearGradient(
                colors: [Colors.amber[100]!, Colors.amber[50]!],
              )
            : LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[100]!],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: unlocked ? Colors.amber[300]! : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            emoji,
            style: TextStyle(fontSize: 22),
          ),
          SizedBox(height: 4),
          Text(
            name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: unlocked ? Colors.amber[700] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (!unlocked)
            Padding(
              padding: EdgeInsets.only(top: 2),
              child: Icon(Icons.lock, size: 8, color: Colors.grey[500]),
            ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.info,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Bilgi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: Colors.grey[300]),
          SizedBox(height: 8),
          _buildAboutItem(Icons.app_shortcut, 'Wordena', 'v1.0.0'),
          SizedBox(height: 8),
          _buildAboutItem(Icons.privacy_tip, 'Gizlilik Politikası', ''),
          SizedBox(height: 8),
          _buildAboutItem(Icons.language, 'Dil', 'Türkçe'),
        ],
      ),
    );
  }

  Widget _buildAboutItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.text),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
              ),
              if (subtitle.isNotEmpty)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}