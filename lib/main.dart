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
  late AnimationController _navController;
  late AnimationController _fabController;

  // GlobalKey per accedere allo State delle pagine
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
    _initModel();
  }

  @override
  void dispose() {
    _navController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    _model = Provider.of<MoneyModel>(context, listen: false);
    await _model!.loadInitial();
  }

  void _onNavigate(int index, [bool? isIncome]) {
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
          IndexedStack(index: _currentIndex, children: pages),
          Positioned(
            right: 20,
            bottom: 90,
            child: _buildContextFab(),
          ),
        ],
      ),
      extendBody: true,
      bottomNavigationBar: _buildModernDock(),
    );
  }

  Widget _buildContextFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentIndex == 0) {
      return _buildSquareFab(
        color: const Color(0xFF6366F1),
        icon: Icons.add,
        tooltip: 'Aggiungi Transazione',
        onTap: () {
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
          final state = goalsKey.currentState;
          if (state is dynamic && state.mounted) {
            final model = Provider.of<MoneyModel>(context, listen: false);
            // chiama in modo riflessivo il metodo se esiste
            try { state._showAddGoalDialog(model); } catch (_) {}
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
          final state = recurringKey.currentState;
          if (state is dynamic && state.mounted) {
            try { state._showAddRecurringDialog(context); } catch (_) {}
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
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  // ... resto invariato: _buildModernDock(), _buildNavItem(), _showQuickAddMenu(), _buildQuickAddButton()
}
