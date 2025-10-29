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
import 'pages/scan_receipt_page.dart';

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
              '/scan_receipt': (context) => const ScanReceiptPage(),
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

  // GlobalKey senza tipo privato: usiamo GlobalKey<State<StatefulWidget>>
  final GlobalKey goalsKey = GlobalKey();
  final GlobalKey recurringKey = GlobalKey();

  // slider dock (stile precedente: track larga sotto l'item)
  late ValueNotifier<int> _dockIndex;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _dockIndex = ValueNotifier<int>(_currentIndex);
    _initModel();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _dockIndex.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    _model = Provider.of<MoneyModel>(context, listen: false);
    await _model!.loadInitial();
  }

  void _onNavigate(int index, [bool? isIncome]) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      _dockIndex.value = index;
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
          Padding(
            padding: const EdgeInsets.only(bottom: 90),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero).animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: KeyedSubtree(key: ValueKey(_currentIndex), child: pages[_currentIndex]),
            ),
          ),
          Positioned(right: 20, bottom: 100, child: _buildContextFab()),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildGlassDock()),
        ],
      ),
    );
  }

  // ------------------ GLASS DOCK ------------------
  Widget _buildGlassDock() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.of(context).size.width;
    final horizontal = 16.0;
    final itemCount = 5;
    final itemWidth = (width - (horizontal * 2)) / itemCount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontal, 8, horizontal, paddingBottom > 0 ? 8 : 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                    ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.04)]
                    : [Colors.white.withOpacity(0.20), Colors.white.withOpacity(0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.20 : 0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.35 : 0.12),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _dockIndex,
                    builder: (context, idx, _) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: 8 + idx * itemWidth,
                        top: 8,
                        child: Container(
                          width: itemWidth - 16,
                          height: 54,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(isDark ? 0.12 : 0.20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(isDark ? 0.25 : 0.40),
                              width: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: List.generate(itemCount, (index) {
                      final icons = const [
                        Icons.home_rounded,
                        Icons.flag_rounded,
                        Icons.bar_chart_rounded,
                        Icons.repeat_rounded,
                        Icons.settings_rounded,
                      ];
                      final isSelected = _currentIndex == index;
                      return Expanded(
                        child: InkResponse(
                          onTap: () => _onNavigate(index),
                          radius: 32,
                          splashColor: Colors.white.withOpacity(0.12),
                          highlightColor: Colors.transparent,
                          containedInkWell: true,
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: isSelected ? 1.15 : 1.0,
                              child: Icon(
                                icons[index],
                                size: 26,
                                color: isSelected
                                  ? const Color(0xFF6366F1)
                                  : isDark ? Colors.grey[300] : Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ GLASS FAB ------------------
  Widget _buildContextFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_currentIndex == 0) {
      return _buildGlassFab(
        color: const Color(0xFF6366F1),
        icon: Icons.add,
        tooltip: 'Aggiungi',
        onTap: () {
          HapticFeedback.mediumImpact();
          _showQuickAddMenu(context);
        },
        isDark: isDark,
      );
    } else if (_currentIndex == 1) {
      return _buildGlassFab(
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
      return _buildGlassFab(
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

  Widget _buildGlassFab({
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.6),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.2),
                    blurRadius: 16,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------ GLASS QUICK ADD MENU ------------------
  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                  ? [Colors.black.withOpacity(0.8), Colors.black.withOpacity(0.6)]
                  : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1.0,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
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
                      color: Colors.grey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bottone Glass Scansione Scontrino (AI)
                  _GlassQuickAction(
                    icon: Icons.receipt_long,
                    title: 'Scansione scontrino (AI)',
                    subtitle: 'Estrai importo e negozio automaticamente',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/scan_receipt');
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildGlassQuickAddButton(
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
                        child: _buildGlassQuickAddButton(
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
          ),
        ),
      ),
    );
  }

  Widget _buildGlassQuickAddButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isIncome,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                  ? [color.withOpacity(0.15), color.withOpacity(0.08)]
                  : [color.withOpacity(0.12), color.withOpacity(0.06)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(isDark ? 0.3 : 0.25),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassQuickAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _GlassQuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                  ? [color.withOpacity(0.20), color.withOpacity(0.12)]
                  : [color.withOpacity(0.15), color.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: color.withOpacity(isDark ? 0.35 : 0.30),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isDark ? 0.25 : 0.18),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.4),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 24,
                  color: isDark ? Colors.white.withOpacity(0.8) : Colors.black54,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
