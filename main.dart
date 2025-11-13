// main.dart aggiornato con aggiunte veloci simmetriche e griglia 3x2
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers.dart';
import 'theme_provider.dart';
import 'pages/home_page.dart';
import 'pages/planning_page.dart';
import 'pages/reports_page.dart';
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
            supportedLocales: const [Locale('it', 'IT')],
            home: const SplashPage(),
            routes: {'/home': (context) => const MainNavigationPage()},
          );
        },
      ),
    );
  }
}

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});
  @override
  State createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  MoneyModel? _model;
  late AnimationController _fabController;
  final GlobalKey planningKey = GlobalKey();
  late ValueNotifier<int> _dockIndex;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _dockIndex = ValueNotifier(_currentIndex);
    _initModel();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _dockIndex.dispose();
    super.dispose();
  }

  Future _initModel() async {
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
      PlanningPage(key: planningKey),
      const ReportsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 100),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween(begin: const Offset(0.06, 0), end: Offset.zero)
                    .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: KeyedSubtree(
                  key: ValueKey(_currentIndex), child: pages[_currentIndex]),
            ),
          ),
          Positioned(
            right: 20,
            bottom: MediaQuery.of(context).padding.bottom + 110,
            child: _buildContextFab(),
          ),
          Positioned(left: 0, right: 0, bottom: 0, child: _buildGlassDock()),
        ],
      ),
    );
  }

  Widget _buildGlassDock() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paddingBottom = MediaQuery.of(context).padding.bottom;
    final width = MediaQuery.of(context).size.width;
    final horizontal = 16.0;
    final itemCount = 4;
    final dockWidth = width - (horizontal * 2);
    final slotWidth = dockWidth / itemCount;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            horizontal, 8, horizontal, paddingBottom > 0 ? 8 : 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 82,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [
                          Colors.white.withOpacity(0.18),
                          Colors.white.withOpacity(0.10)
                        ]
                      : [
                          Colors.white.withOpacity(0.70),
                          Colors.white.withOpacity(0.50)
                        ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.35 : 0.60),
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.50 : 0.12),
                    blurRadius: 35,
                    spreadRadius: 0,
                    offset: const Offset(0, 15),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.25 : 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: _dockIndex,
                    builder: (context, idx, _) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        left: idx * slotWidth,
                        top: 10,
                        child: Container(
                          width: slotWidth,
                          height: 62,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark
                                  ? [
                                      Colors.white.withOpacity(0.22),
                                      Colors.white.withOpacity(0.14),
                                    ]
                                  : [
                                      Colors.white.withOpacity(0.85),
                                      Colors.white.withOpacity(0.65),
                                    ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color:
                                  Colors.white.withOpacity(isDark ? 0.40 : 0.70),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white
                                    .withOpacity(isDark ? 0.15 : 0.30),
                                blurRadius: 15,
                                spreadRadius: -2,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Row(
                    children: List.generate(itemCount, (index) {
                      final icons = const [
                        Icons.home_rounded,
                        Icons.calendar_month,
                        Icons.bar_chart_rounded,
                        Icons.settings_rounded,
                      ];
                      final colors = [
                        const Color(0xFF6366F1),
                        const Color(0xFF10B981),
                        const Color(0xFF8B5CF6),
                        const Color(0xFF6B7280),
                      ];
                      final isSelected = _currentIndex == index;

                      return SizedBox(
                        width: slotWidth,
                        child: InkResponse(
                          onTap: () => _onNavigate(index),
                          radius: 32,
                          splashColor: Colors.white.withOpacity(0.15),
                          highlightColor: Colors.transparent,
                          containedInkWell: true,
                          child: Center(
                            child: AnimatedScale(
                              duration: const Duration(milliseconds: 300),
                              scale: isSelected ? 1.15 : 1.0,
                              curve: Curves.easeOutCubic,
                              child: Icon(
                                icons[index],
                                size: isSelected ? 30 : 26,
                                color: isSelected
                                    ? colors[index]
                                    : (isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[700]),
                                shadows: isSelected
                                    ? [
                                        Shadow(
                                          color:
                                              colors[index].withOpacity(0.4),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
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
        color: const Color(0xFF10B981),
        icon: Icons.add,
        tooltip: 'Aggiungi',
        onTap: () {
          HapticFeedback.mediumImpact();
          final state = planningKey.currentState;
          if (state != null && state.mounted) {
            final dynamic dyn = state;
            try {
              dyn.showAddDialog(context);
            } catch (_) {}
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

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.75)
                      ]
                    : [
                        Colors.white.withOpacity(0.95),
                        Colors.white.withOpacity(0.85)
                      ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildGlassQuickAddButton(
                        context: context,
                        title: 'Spesa',
                        subtitle: 'Supermercato, negozi',
                        icon: Icons.shopping_cart,
                        color: const Color(0xFF10B981),
                        isIncome: false,
                      ),
                      _buildGlassQuickAddButton(
                        context: context,
                        title: 'Trasporti',
                        subtitle: 'Auto, bus, treno',
                        icon: Icons.directions_car,
                        color: const Color(0xFF3B82F6),
                        isIncome: false,
                      ),
                      _buildGlassQuickAddButton(
                        context: context,
                        title: 'Svago',
                        subtitle: 'Ristoranti, bar',
                        icon: Icons.restaurant,
                        color: const Color(0xFFF59E0B),
                        isIncome: false,
                      ),
                      _buildGlassQuickAddButton(
                        context: context,
                        title: 'Casa',
                        subtitle: 'Affitto, bollette',
                        icon: Icons.home,
                        color: const Color(0xFF06B6D4),
                        isIncome: false,
                      ),
                      _buildGlassQuickAddButton(
                        context: context,
                        title: 'Salute',
                        subtitle: 'Farmacia, medico',
                        icon: Icons.local_hospital,
                        color: const Color(0xFFEF4444),
                        isIncome: false,
                      ),
                      _buildGlassQuickAddButton(
                        context: context,
                        title: 'Altro',
                        subtitle: 'Altre spese',
                        icon: Icons.more_horiz,
                        color: const Color(0xFF8B5CF6),
                        isIncome: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [color.withOpacity(0.18), color.withOpacity(0.10)]
                    : [color.withOpacity(0.15), color.withOpacity(0.08)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: color.withOpacity(isDark ? 0.35 : 0.28),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.22),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.9),
                            color.withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
