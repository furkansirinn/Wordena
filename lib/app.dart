import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/pages/home_page.dart';
import 'presentation/pages/categories_page.dart';
import 'presentation/pages/settings_page.dart';
import 'package:hive_flutter/hive_flutter.dart';

class MyApp extends StatefulWidget {
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Box settingsBox;

  @override
  void initState() {
    super.initState();
    settingsBox = Hive.box('settingsBox');
    // Dark mode değişikliklerini dinle
    settingsBox.watch(key: 'isDarkMode').listen((_) {
      setState(() {});
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
      home: MainScaffold(),
    );
  }
}

class MainScaffold extends StatefulWidget {
  @override
  _MainScaffoldState createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  late String _selectedCategory;
  final PageController _pageController = PageController();
  
  @override
  void initState() {
    super.initState();
    // ✨ Son kategoriye dön
    final settingsBox = Hive.box('settingsBox');
    _selectedCategory = settingsBox.get('lastCategory', defaultValue: 'A1 Seviye Kelimeler') as String;
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCategorySelected(String category) {
    setState(() {
      _selectedCategory = category;
      _selectedIndex = 0;
    });
    
    // ✨ Kategoriyi kaydet
    Hive.box('settingsBox').put('lastCategory', category);
    
    _pageController.jumpToPage(0);
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = Hive.box('settingsBox').get('isPremium', defaultValue: false) as bool;
    
    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: NeverScrollableScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _selectedIndex = index);
        },
        children: [
          HomePage(
            key: ValueKey('home_$_selectedCategory'),
            category: _selectedCategory,
            isPremium: isPremium,
          ),
          CategoriesPage(
            onCategorySelected: _onCategorySelected,
          ),
          SettingsPage(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: 'Öğren',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Kategoriler',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Ayarlar',
          ),
        ],
      ),
    );
  }
}