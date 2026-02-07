import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'dart:convert';
import '../../core/theme.dart';
import '../../data/category_complete.dart';
import '../../data/category_progress_service.dart';

class CategoriesPage extends StatefulWidget {
  final Function(String) onCategorySelected;

  const CategoriesPage({required this.onCategorySelected, Key? key})
      : super(key: key);

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  // ⭐️ CACHE: Kategorinin İlerleme Bilgisi
  final Map<String, CategoryProgress> _categoryProgressCache = {};
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadAllCategoryProgress(); // ⭐️ TÜM KATEGORİLERİN İLERLEMESİNİ YÜKLE
  }

  // ✨ TÜM KATEGORİLERİN İLERLEMESİNİ YÜKLE
  Future<void> _loadAllCategoryProgress() async {
    final categories = [
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
      'Hobiler & Eğlence',
    ];

    for (var categoryName in categories) {
      try {
        // ⭐️ HER KATEGORİ İÇİN İLERLEME HESAPLA
        final progress = 
            await CategoryProgressService.getCategoryProgressInfo(categoryName);
        
        if (mounted) {
          setState(() {
            _categoryProgressCache[categoryName] = progress;
          });
        }
      } catch (e) {
        print('❌ Error loading progress for $categoryName: $e');
      }
    }

    if (mounted) {
      setState(() => _isLoadingProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allCategories = [
      {
        'name': 'A1 Seviye Kelimeler',
        'icon': Icons.looks_one,
        'locked': false,
        'emoji': '🟦',
      },
      {
        'name': 'A2 Seviye Kelimeler',
        'icon': Icons.looks_two,
        'locked': false,
        'emoji': '🟩',
      },
      {
        'name': 'B1 Seviye Kelimeler',
        'icon': Icons.looks_3,
        'locked': false,
        'emoji': '🟪',
      },
      {
        'name': 'B2 Seviye Kelimeler',
        'icon': Icons.looks_4,
        'locked': false,
        'emoji': '🟧',
      },
      {
        'name': 'C1 Seviye Kelimeler',
        'icon': Icons.looks_5,
        'locked': true,
        'emoji': '🟥',
      },
      {
        'name': 'C2 Seviye Kelimeler',
        'icon': Icons.looks_6,
        'locked': true,
        'emoji': '🟨',
      },
      {
        'name': 'Fiiller (Verbs)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '🔤',
      },
      {
        'name': 'Sıfatlar (Adjectives)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '✨',
      },
      {
        'name': 'Zarflar (Adverbs)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '⚡',
      },
      {
        'name': 'İsimler (Nouns)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '📦',
      },
      {
        'name': 'Fiil Öbekleri (Phrasal Verbs)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '🔗',
      },
      {
        'name': 'Deyimler (Idioms)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '💬',
      },
      {
        'name': 'Bağlaçlar (Conjunctions)',
        'icon': Icons.description,
        'locked': true,
        'emoji': '🔀',
      },
      {
        'name': 'Günlük Konuşma',
        'icon': Icons.calendar_today,
        'locked': true,
        'emoji': '☀️',
      },
      {
        'name': 'İş İngilizcesi',
        'icon': Icons.business,
        'locked': true,
        'emoji': '💼',
      },
      {
        'name': 'Akademik İngilizce',
        'icon': Icons.school,
        'locked': true,
        'emoji': '📚',
      },
      {
        'name': 'Alışveriş',
        'icon': Icons.shopping_bag,
        'locked': true,
        'emoji': '🛍️',
      },
      {
        'name': 'Seyahat',
        'icon': Icons.flight,
        'locked': true,
        'emoji': '✈️',
      },
      {
        'name': 'Yiyecek & İçecek',
        'icon': Icons.restaurant,
        'locked': true,
        'emoji': '🍽️',
      },
      {
        'name': 'Ev & Eşyalar',
        'icon': Icons.home,
        'locked': true,
        'emoji': '🏠',
      },
      {
        'name': 'Sağlık & Vücut',
        'icon': Icons.favorite,
        'locked': true,
        'emoji': '💪',
      },
      {
        'name': 'Duygular',
        'icon': Icons.mood,
        'locked': true,
        'emoji': '😊',
      },
      {
        'name': 'Spor',
        'icon': Icons.sports_soccer,
        'locked': true,
        'emoji': '⚽',
      },
      {
        'name': 'Teknoloji',
        'icon': Icons.computer,
        'locked': true,
        'emoji': '💻',
      },
      {
        'name': 'Doğa & Çevre',
        'icon': Icons.eco,
        'locked': true,
        'emoji': '🌍',
      },
      {
        'name': 'Ulaşım',
        'icon': Icons.directions_car,
        'locked': true,
        'emoji': '🚗',
      },
      {
        'name': 'Okul & Eğitim',
        'icon': Icons.book,
        'locked': true,
        'emoji': '📖',
      },
      {
        'name': 'İnsanlar & Meslekler',
        'icon': Icons.people,
        'locked': true,
        'emoji': '👥',
      },
      {
        'name': 'Hayvanlar',
        'icon': Icons.pets,
        'locked': true,
        'emoji': '🐾',
      },
      {
        'name': 'Hobiler & Eğlence',
        'icon': Icons.games,
        'locked': true,
        'emoji': '🎮',
      },
    ];

    final isPremium =
        Hive.box('settingsBox').get('isPremium', defaultValue: false) as bool;

    return SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: allCategories.length,
              itemBuilder: (context, index) {
                final category = allCategories[index];
                final isLocked = category['locked'] as bool && !isPremium;
                final categoryName = category['name'] as String;
                final icon = category['icon'] as IconData;

                // ⭐️ CACHE'DEN İLERLEME BİLGİSİNİ AL
                final progress = _categoryProgressCache[categoryName];
                final color = progress?.color ?? 
                    CategoryProgressService.getCategoryColor(categoryName);
                final isCompleted = progress?.isCompleted() ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildCategoryCard(
                    context,
                    categoryName,
                    icon,
                    color,
                    isLocked,
                    progress,
                    isCompleted,
                    onTap: isLocked
                        ? () => _showPremiumDialog(context)
                        : () => widget.onCategorySelected(categoryName),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kategoriler',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Bir kategori seç ve kelime öğrenmeye başla',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    String categoryName,
    IconData icon,
    Color color,
    bool isLocked,
    CategoryProgress? progress,
    bool isCompleted,
    {required VoidCallback onTap}
  ) {
    final displayProgress = progress ?? CategoryProgress(
      categoryName: categoryName,
      totalWords: 0,
      completedWords: 0,
      maxLevel: 0,
      completedLevel: 0,
      progress: 0.0,
      color: color,
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isCompleted
                  ? LinearGradient(
                      colors: [
                        Colors.green[50]!,
                        Colors.green[50]!.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.7),
                        Colors.white.withOpacity(0.4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted ? Colors.green[300]! : color.withOpacity(0.5),
                width: isCompleted ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: isCompleted 
                      ? Colors.green.withOpacity(0.2)
                      : color.withOpacity(0.15),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isCompleted
                                          ? Colors.green[100]
                                          : color.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      icon,
                                      color: isCompleted
                                          ? Colors.green[700]
                                          : isLocked
                                              ? Colors.grey[400]
                                              : color,
                                      size: 24,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          categoryName,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isCompleted
                                                ? Colors.green[700]
                                                : isLocked
                                                    ? Colors.grey[500]
                                                    : AppColors.text,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          '${displayProgress.completedWords}/${displayProgress.totalWords} kelime',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isCompleted
                                                ? Colors.green[600]
                                                : Colors.grey[600],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        _buildStatusBadge(
                          isLocked,
                          isCompleted,
                          displayProgress.progress,
                          color,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    if (!isLocked)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: displayProgress.progress.clamp(0.0, 1.0),
                              minHeight: 8,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isCompleted ? Colors.green : color,
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'İlerleme',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isCompleted
                                      ? Colors.green[600]
                                      : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                displayProgress.getProgressPercentage(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isCompleted ? Colors.green : color,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          // ✅ Tamamlandı Badge
          if (isCompleted)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.green[400]!,
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 14, color: Colors.green[700]),
                    SizedBox(width: 4),
                    Text(
                      '✅ Tamamlandı',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    bool isLocked,
    bool isCompleted,
    double progress,
    Color color,
  ) {
    if (isLocked) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.amber[300]!,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock, size: 14, color: Colors.amber[700]),
            SizedBox(width: 4),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.amber[700],
              ),
            ),
          ],
        ),
      );
    }

    if (isCompleted) {
      return Container(
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.green[100],
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.green[400]!,
            width: 2,
          ),
        ),
        child: Icon(
          Icons.check,
          size: 18,
          color: Colors.green[700],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward_ios,
            size: 14,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showPremiumDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.lock,
                        color: Colors.amber[700],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bu Kategori Kilitli',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'Premium üyelik ile 30 kategori ve sınırsız swipe özgürlüğü',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber[50]!, Colors.amber[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Premium avantajları:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[900],
                        ),
                      ),
                      SizedBox(height: 12),
                      _buildBenefit('30 kategri (şu anda 4)', Colors.amber),
                      _buildBenefit('Sınırsız swipe', Colors.amber),
                      _buildBenefit('Reklam yok', Colors.amber),
                      _buildBenefit('Gelişmiş istatistikler', Colors.amber),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Kapat',
                      style: TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: Colors.amber[300]!,
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Premium Al ⭐',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefit(String text, Color color) {
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
}