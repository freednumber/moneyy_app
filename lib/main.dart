import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late AnimationController _navController;
  late AnimationController _fabController;
  late AnimationController _sliderController;
  late Animation<double> _sliderAnimation;

  // GlobalKey senza tipo privato: usiamo GlobalKey<State<StatefulWidget>>
  final GlobalKey goalsKey = GlobalKey();
  final GlobalKey recurringKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _navController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _sliderController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _sliderAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _sliderController,
      curve: Curves.easeInOut,
    ));
    _initModel();
  }

  @override
  void dispose() {
    _navController.dispose();
    _fabController.dispose();
    _sliderController.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    _model = Provider.of<MoneyModel>(context, listen: false);
    await _model!.loadInitial();
  }

  void _onNavigate(int index, [bool? isIncome]) {
    if (index != _currentIndex) {
      _sliderController.reset();
      _sliderController.forward();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(onNavigate: _onNavigate),
      GoalsPage(key: goalsKey),
      const ReportsPage(),
      RecurringPage(key: recurringKey),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Aggiungi padding bottom per evitare sovrapposizioni con il dock fisso
          Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: pages[_currentIndex],
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: 100,
            child: _buildContextFab(),
          ),
          // Dock fisso posizionato in basso
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildModernDock(),
          ),
        ],
      ),
    );
  }

  // ------------------ DOCK RETTANGOLARE CON SLIDER ------------------
  Widget _buildModernDock() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 48) / 5; // 5 items, margins 24 per lato
    
    return Container(
      margin: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16), // Più rettangolare
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: isDark 
                ? Colors.grey[900]!.withOpacity(0.9)
                : Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.black.withOpacity(0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Slider animato
                AnimatedBuilder(
                  animation: _sliderAnimation,
                  builder: (context, child) {
                    return AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _currentIndex * itemWidth + 8,
                      top: 8,
                      child: Container(
                        width: itemWidth - 16,
                        height: 54,
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF6366F1).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Icone di navigazione
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      icon: Icons.home_rounded,
                      index: 0,
                    ),
                    _buildNavItem(
                      icon: Icons.flag_rounded,
                      index: 1,
                    ),
                    _buildNavItem(
                      icon: Icons.bar_chart_rounded,
                      index: 2,
                    ),
                    _buildNavItem(
                      icon: Icons.repeat_rounded,
                      index: 3,
                    ),
                    _buildNavItem(
                      icon: Icons.settings_rounded,
                      index: 4,
                    ),
                  ],
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
    required int index,
  }) {
    final isSelected = _currentIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final tooltipLabels = ['Home', 'Obiettivi', 'Report', 'Ricorrenti', 'Impostazioni'];
    
    return Expanded(
      child: Tooltip(
        message: tooltipLabels[index],
        waitDuration: const Duration(milliseconds: 500),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            _onNavigate(index);
          },
          child: Container(
            height: 70,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: isSelected ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon,
                    size: 26,
                    color: isSelected
                      ? const Color(0xFF6366F1)
                      : isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                // Indicatore con animazione
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: isSelected ? 6 : 4,
                  height: isSelected ? 6 : 4,
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? const Color(0xFF6366F1)
                      : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ FAB Contestuale ------------------
  Widget _buildContextFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentIndex == 0) {
      return _buildSquareFab(
        color: const Color(0xFF6366F1),
        icon: Icons.add,
        tooltip: 'Aggiungi Transazione',
        onTap: () {
          HapticFeedback.mediumImpact();
          _fabController.forward().then((_) => _fabController.reverse());
          _showQuickAddMenu(context);
        },
        isDark: isDark,
      );
    } else if (_currentIndex == 1) {
      return _buildSquareFab(
        color: const Color(0xFF6366F1),
        icon: Icons.flag,
        tooltip: 'Nuovo Obiettivo',
        onTap: () {
          HapticFeedback.mediumImpact();
          final state = goalsKey.currentState;
          if (state != null && state.mounted) {
            final dynamic dyn = state;
            final model = Provider.of<MoneyModel>(context, listen: false);
            try { dyn.showAddGoalDialog(model); } catch (_) {}
          }
        },
        isDark: isDark,
      );
    } else if (_currentIndex == 3) {
      return _buildSquareFab(
        color: const Color(0xFF6366F1),
        icon: Icons.add,
        tooltip: 'Nuova Ricorrente',
        onTap: () {
          HapticFeedback.mediumImpact();
          final state = recurringKey.currentState;
          if (state != null && state.mounted) {
            final dynamic dyn = state;
            try { dyn.showAddRecurringDialog(context); } catch (_) {}
          }
        },
        isDark: isDark,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSquareFab({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required bool isDark,
  }) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
        CurvedAnimation(parent: _fabController, curve: Curves.easeOutBack),
      ),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.5 : 0.25),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: color.withOpacity(isDark ? 0.3 : 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  // ------------------ Banner Aggiunta Veloce ------------------
  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
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
            const SizedBox(height: 16),
            const Text('Aggiungi Transazione', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
        HapticFeedback.lightImpact();
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
            Text(title, style: TextStyle(fontWeight: FontWeight.w600, color: color, fontSize: 14)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[600]), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}