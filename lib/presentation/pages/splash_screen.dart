import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/swipe_counter.dart';
import '../../data/category_complete.dart';
import '../../data/in_app_purchase_service.dart';
import '../../data/audio_service.dart';
import '../../data/license_service.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const SplashScreen({required this.onComplete, Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _startAnimationsAndInitialize();
  }

  void _startAnimationsAndInitialize() async {
    // ⭐️ Animasyonları başlat
    await _scaleController.forward();
    await _slideController.forward();
    _fadeController.forward();

    // ⭐️ Initialization'ları arkada yap (animasyon sırasında)
    await _initializeApp();

    // 3 saniye sonra tamamla
    await Future.delayed(Duration(seconds: 3));
    widget.onComplete();
  }

  Future<void> _initializeApp() async {
    try {
      print('⏳ SwipeCounter initializing...');
      await SwipeCounter.initialize();
      
      print('⏳ CategoryComplete initializing...');
      await CategoryComplete.initialize();
      
      print('⏳ InAppPurchase initializing...');
      await InAppPurchaseService().initialize();

      print('⏳ LicenseService initializing...');
      await LicenseService.initialize();

      print('⏳ AudioService initializing...');
      await AudioService().initialize();
      
      print('✅ Tüm initialization tamamlandı!');
    } catch (e) {
      print('❌ Initialization error: $e');
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // LOGO + ICON
            _buildLogoSection(),
            SizedBox(height: 40),
            // APP NAME
            _buildAppNameSection(),
            SizedBox(height: 60),
            // LOADING INDICATOR
            _buildLoadingIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: EdgeInsets.all(28),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.3),
              AppColors.accent.withOpacity(0.25),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 32,
              offset: Offset(0, 12),
              spreadRadius: 4,
            ),
            BoxShadow(
              color: AppColors.accent.withOpacity(0.15),
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.accent,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '📚',
              style: TextStyle(fontSize: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppNameSection() {
    return SlideTransition(
      position: _slideAnimation,
      child: Column(
        children: [
          Text(
            'Wordena',
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.2),
                  AppColors.accent.withOpacity(0.15),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '✨ Her Gün Bir Kelime, Hayat Değişir ✨',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Hazırlanıyor...',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}