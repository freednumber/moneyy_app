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
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final isVerySmallScreen = screenWidth < 360; // iPhone SE, schermi stretti
    
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
                ? Colors.grey[900]!.withOpacity(0.85)
                : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(isSmallScreen ? 24 : 28),
              border: Border.all(
                color: isDark
                  ? Colors.white.withOpacity(0.12)
                  : Colors.black.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                  blurRadius: 24,
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
                  isVerySmall: isVerySmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.flag_rounded,
                  label: 'Obiettivi',
                  index: 1,
                  isSmall: isSmallScreen,
                  isVerySmall: isVerySmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Report',
                  index: 2,
                  isSmall: isSmallScreen,
                  isVerySmall: isVerySmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.repeat_rounded,
                  label: isVerySmallScreen ? 'Ricorr.' : 'Ricorrenti', // Abbreviato su schermi stretti
                  index: 3,
                  isSmall: isSmallScreen,
                  isVerySmall: isVerySmallScreen,
                ),
                _buildNavItem(
                  icon: Icons.settings_rounded,
                  label: isVerySmallScreen ? 'Config.' : 'Impostazioni', // Abbreviato su schermi stretti
                  index: 4,
                  isSmall: isSmallScreen,
                  isVerySmall: isVerySmallScreen,
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
    required bool isVerySmall,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Label originali per tooltip
    final originalLabels = ['Home', 'Obiettivi', 'Report', 'Ricorrenti', 'Impostazioni'];
    
    return Tooltip(
      message: originalLabels[index],
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () => _onNavigate(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: isSmall 
            ? (isVerySmallScreen ? 48 : 54) // Più largo per label complete
            : 68,
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
                      ? Colors.grey[300] // Più chiaro in dark mode
                      : Colors.grey[600],
                ),
              ),
              if (!isSmall) ...[
                const SizedBox(height: 4),
                AnimatedOpacity(
                  opacity: isSelected ? 1.0 : 0.8,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: TextStyle(
                      fontSize: 11, // Leggermente più grande
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: 0.2,
                      color: isSelected
                        ? const Color(0xFF6366F1)
                        : isDark
                          ? Colors.grey[300] // Più leggibile in dark
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
              // Label mobile compatta su una riga
              if (isSmall && !isVerySmallScreen) ...[
                const SizedBox(height: 2),
                AnimatedOpacity(
                  opacity: isSelected ? 0.9 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.clip,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.1,
                      color: isSelected
                        ? const Color(0xFF6366F1)
                        : isDark
                          ? Colors.grey[350]
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[600] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Aggiungi Transazione',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
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
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildQuickAddButton(
                    context: context,
                    title: 'Nuova Entrata',
                    subtitle: 'Stipendio, regalo...',
                    icon: Icons.arrow_upward,
                    color: Colors.green,
                    isIncome: true,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
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
    required bool isDark,
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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark 
            ? color.withOpacity(0.15)
            : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
              ? color.withOpacity(0.4)
              : color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : color,
                fontSize: 15,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}