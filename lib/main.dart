import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers.dart';
import 'theme_provider.dart';
import 'pages/home_page.dart';
import 'pages/goals_page.dart';
import 'pages/reports_page.dart';
import 'pages/recurring_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'pages/add_tx_page.dart';

void main() {
  runApp(const MoneyYApp());
}

class MoneyYApp extends StatelessWidget {
  const MoneyYApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoneyModel()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MoneyY',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            themeMode: themeProvider.themeMode,
            locale: const Locale('it', 'IT'),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('it', 'IT'),
            ],
            home: const SplashPage(),
            routes: {
              '/home': (context) => const MainNavigationPage(),
            },
          );
        },
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  MoneyModel? _model;
  late AnimationController _fabController;
  late AnimationController _navController;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _initModel();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _navController.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    _model = Provider.of<MoneyModel>(context, listen: false);
    await _model!.loadInitial();
  }

  void _onNavigate(int index, [bool? isIncome]) {
    if (index == 5) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddTxPage(initialIsIncome: isIncome ?? false),
        ),
      );
    } else {
      _navController.forward();
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: _onNavigate),
      const GoalsPage(),
      const ReportsPage(),
      const RecurringPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: pages,
          ),
          // FAB centrale per nuova transazione
          Positioned(
            bottom: 90,
            right: 20,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _fabController, curve: Curves.elasticOut),
              ),
              child: FloatingActionButton.large(
                onPressed: () {
                  _fabController.forward().then((_) => _fabController.reverse());
                  _showQuickAddMenu(context);
                },
                backgroundColor: const Color(0xFF6366F1),
                child: const Icon(Icons.add, size: 32, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildModernDock(),
    );
  }

  Widget _buildModernDock() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: EdgeInsets.only(
        left: isSmallScreen ? 12 : 24,
        right: isSmallScreen ? 12 : 24,
        bottom: MediaQuery.of(context).padding.bottom + (isSmallScreen ? 8 : 16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: isSmallScreen ? 64 : 72,
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.grey[900]!.withOpacity(0.8)
                : Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
              border: Border.all(
                color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  index: 0,
                  isSmall: isSmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.flag_rounded,
                  label: 'Obiettivi',
                  index: 1,
                  isSmall: isSmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report',
                  index: 2,
                  isSmall: isSmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.repeat_rounded,
                  label: 'Ricorrenti',
                  index: 3,
                  isSmall: isSmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: 'Impostazioni',
                  index: 4,
                  isSmall: isSmallScreen,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSmall,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: () => _onNavigate(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        width: isSmall ? 50 : 60,
        height: isSmall ? 50 : 60,
        decoration: BoxDecoration(
          color: isSelected
            ? const Color(0xFF6366F1).withOpacity(0.15)
            : Colors.transparent,
          borderRadius: BorderRadius.circular(isSmall ? 16 : 20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                icon,
                size: isSmall ? 22 : 26,
                color: isSelected
                  ? const Color(0xFF6366F1)
                  : isDark
                    ? Colors.grey[400]
                    : Colors.grey[600],
              ),
            ),
            if (!isSmall) ...[
              const SizedBox(height: 4),
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.7,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected
                      ? const Color(0xFF6366F1)
                      : isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ),
            ] else if (isSelected) ...[
              const SizedBox(height: 2),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Color(0xFF6366F1),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aggiungi Transazione',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildQuickAddButton(
                    context: context,
                    title: 'Nuova Uscita',
                    subtitle: 'Spesa, bolletta...',
                    icon: Icons.arrow_downward,
                    color: Colors.red,
                    isIncome: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickAddButton(
                    context: context,
                    title: 'Nuova Entrata',
                    subtitle: 'Stipendio, regalo...',
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                    isIncome: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAddButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isIncome,
  }) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddTxPage(initialIsIncome: isIncome),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: color,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}