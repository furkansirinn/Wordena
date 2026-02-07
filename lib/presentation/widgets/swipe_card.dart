import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/audio_service.dart';
import '../../data/tts_service.dart';
import '../../data/category_progress_service.dart';
import '../../core/theme.dart';

class SwipeCard extends StatefulWidget {
  final String word;
  final String correctAnswer;
  final String wrongAnswer;
  final int level;
  final int currentCombo;
  final Function(bool isCorrect, int newCombo) onAnswered;
  final bool isEnabled;
  final AudioService audioService;
  final TTSService ttsService;
  final String categoryName; // ⭐️ EKLE: Kategori adı

  const SwipeCard({
    required this.word,
    required this.correctAnswer,
    required this.wrongAnswer,
    this.level = 0,
    required this.currentCombo,
    required this.onAnswered,
    this.isEnabled = true,
    required this.audioService,
    required this.ttsService,
    required this.categoryName, // ⭐️ EKLE
    Key? key,
  }) : super(key: key);

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  bool? _selectedAnswer;
  int? _selectedSide;
  bool _isAnswered = false;
  late bool _correctIsLeft;
  int _combo = 0;
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _correctIsLeft = DateTime.now().millisecond % 2 == 0;

    _scaleController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInBack),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    widget.ttsService.initialize();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _slideController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleAnswer(bool isLeft) {
    if (!widget.isEnabled || _isAnswered) return;

    _selectedSide = isLeft ? 0 : 1;
    final isCorrect =
        (isLeft && _correctIsLeft) || (!isLeft && !_correctIsLeft);

    if (isCorrect) {
      HapticFeedback.heavyImpact();
      _combo = widget.currentCombo + 1;
      widget.audioService.playCorrect();
    } else {
      HapticFeedback.mediumImpact();
      _combo = 0;
      widget.audioService.playWrong();
    }

    _selectedAnswer = isCorrect;
    _isAnswered = true;
    setState(() {});

    final slideDirection = isLeft ? -3.0 : 3.0;

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(slideDirection, 0),
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeInBack),
    );

    _scaleController.forward();

    Future.delayed(Duration(milliseconds: 100), () {
      _pulseController.forward();
    });

    Future.delayed(Duration(milliseconds: 150), () {
      _slideController.forward();
    });

    Future.delayed(Duration(milliseconds: 900), () {
      widget.onAnswered(isCorrect, _combo);
    });
  }

  void _handleSpeak() async {
    if (_isSpeaking) {
      await widget.ttsService.stop();
      setState(() => _isSpeaking = false);
    } else {
      setState(() => _isSpeaking = true);
      await widget.ttsService.speak(widget.word);
      await Future.delayed(Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLevelIndicator(),
              SizedBox(height: 40),
              _buildWordCard(),
              SizedBox(height: 56),
              _buildAnswerButtons(),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.accent.withOpacity(0.15),
            AppColors.primary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.accent.withOpacity(0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final isActive = index < widget.level;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 450),
              width: isActive ? 12 : 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? Color(0xFFFDD835) : Colors.grey[300],
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Color(0xFFFDD835).withOpacity(0.5),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWordCard() {
    // ⭐️ KATEGORİ RENGİNİ AL
    final categoryColor = CategoryProgressService.getCategoryColor(widget.categoryName);

    return ScaleTransition(
      scale: _pulseAnimation,
      child: Stack(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  categoryColor.withOpacity(0.2),
                  categoryColor.withOpacity(0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: categoryColor.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.12),
                  blurRadius: 32,
                  offset: Offset(0, 16),
                ),
                BoxShadow(
                  color: categoryColor.withOpacity(0.06),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: Text(
              widget.word,
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
                letterSpacing: -1.2,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 🔊 Speaker button - sağ alta konumlandırıldı ve küçültüldü
          Positioned(
            bottom: 12,
            right: 12,
            child: GestureDetector(
              onTap: _handleSpeak,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isSpeaking
                      ? categoryColor.withOpacity(0.25)
                      : Colors.white.withOpacity(0.85),
                  border: Border.all(
                    color: categoryColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: categoryColor.withOpacity(0.15),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _isSpeaking ? Icons.volume_up : Icons.volume_off,
                  color: categoryColor,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildAnswerButton(
              isLeft: true,
              isSelected: _isAnswered && _selectedSide == 0,
              isCorrect:
                  _isAnswered && _selectedSide == 0 && _selectedAnswer == true,
              isWrong: _isAnswered && _selectedSide == 0 && _selectedAnswer == false,
              text: _correctIsLeft ? widget.correctAnswer : widget.wrongAnswer,
              onTap: () => _handleAnswer(true),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: _buildAnswerButton(
              isLeft: false,
              isSelected: _isAnswered && _selectedSide == 1,
              isCorrect:
                  _isAnswered && _selectedSide == 1 && _selectedAnswer == true,
              isWrong: _isAnswered && _selectedSide == 1 && _selectedAnswer == false,
              text: !_correctIsLeft ? widget.correctAnswer : widget.wrongAnswer,
              onTap: () => _handleAnswer(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required bool isLeft,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required String text,
    required VoidCallback onTap,
  }) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;
    Color iconColor;
    IconData icon;
    double shadowBlur;
    double scale;

    if (isSelected) {
      if (isCorrect) {
        backgroundColor = Color(0xFF68C957);
        borderColor = Color(0xFF4CAF50);
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.check_circle;
        shadowBlur = 20;
        scale = 1.12;
      } else {
        backgroundColor = Color(0xFFFF6B6B);
        borderColor = Color(0xFFEF5350);
        textColor = Colors.white;
        iconColor = Colors.white;
        icon = Icons.cancel;
        shadowBlur = 20;
        scale = 1.12;
      }
    } else {
      backgroundColor = Colors.white;
      borderColor = AppColors.primary.withOpacity(0.2);
      textColor = AppColors.text;
      iconColor = AppColors.primary;
      icon = Icons.touch_app;
      shadowBlur = 12;
      scale = 1.0;
    }

    return GestureDetector(
      onTap: !_isAnswered ? onTap : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 280),
        curve: Curves.easeOut,
        transform: Matrix4.identity()..scale(isSelected ? scale : 1.0),
        transformAlignment: Alignment.center,
        padding: EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: backgroundColor.withOpacity(0.35),
                blurRadius: shadowBlur,
                offset: Offset(0, 10),
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: shadowBlur,
                offset: Offset(0, 6),
                spreadRadius: 0,
              ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.25) : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: iconColor.withOpacity(0.2),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 30,
              ),
            ),
            SizedBox(height: 14),
            Text(
              text,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textColor,
                letterSpacing: 0.2,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}