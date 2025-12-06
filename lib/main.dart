// [Codice adattato da 'main.dart' e 'lucasxu0/liquid_glass/lib/main.dart']
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
import 'widgets/liquid_glass_dock.dart';
// ✅ 1. IMPORTA I NUOVI WIDGET
import 'widgets/shader_helpers/background_capture_widget.dart';
import 'dart:ui' as ui;

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
            home: const SplashPage(child: MainNavigationPage()),
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

  // ✅ 2. AGGIUNGI QUESTI PER LA CATTURA DELLO SFONDO
  final GlobalKey<BackgroundCaptureWidgetState> _captureKey = GlobalKey();
  final ValueNotifier<ui.Image?> _backgroundNotifier = ValueNotifier(null);

  final List<DockItem> _dockItems = [
    DockItem(
        icon: Icons.home_rounded,
        label: 'Home',
        activeColor: const Color(0xFF38F9D7)),
    DockItem(
        icon: Icons.calendar_month,
        label: 'Planning',
        activeColor: const Color(0xFF00E676)),
    DockItem(
        icon: Icons.bar_chart_rounded,
        label: 'Reports',
        activeColor: const Color(0xFF00BFA5)),
    DockItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        activeColor: const Color(0xFF76FF03)),
  ];

  @override
  void initState() {
    super.initState();
    _fabController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _dockIndex = ValueNotifier(_currentIndex);
    _initModel();
    // ✅ 3. CAPTURA LO SFONDO AL PRIMO FRAME
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureKey.currentState?.capture();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _dockIndex.dispose();
    _backgroundNotifier.dispose(); // Pulisci il notifier
    super.dispose();
  }

  Future _initModel() async {
    _model = Provider.of(context, listen: false);
    await _model!.loadInitial();
  }

  void _onNavigate(int index, [bool? isIncome]) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      _dockIndex.value = index;
    }
    setState(() => _currentIndex = index);
    // ✅ 4. RICATTURA LO SFONDO OGNI VOLTA CHE CAMBI PAGINA
    _captureKey.currentState?.capture();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    // L'altezza del dock la definiamo nel widget dock stesso
    final dockHeight = 82 + (bottomPadding > 0 ? 8 : 16);
    
    final pages = [
      HomePage(onNavigate: _onNavigate),
      PlanningPage(key: planningKey),
      const ReportsPage(),
      const SettingsPage(),
    ];
    
    // ✅ 5. STRUTTURA DELLO SCAFFOLD CAMBIATA
    // Non usiamo più bottomNavigationBar, ma uno Stack
    return Scaffold(
      extendBody: true, // Fondamentale
      body: Stack(
        children: [
          // Questo è lo sfondo che verrà "fotografato"
          BackgroundCaptureWidget(
            key: _captureKey,
            backgroundNotifier: _backgroundNotifier,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) => SlideTransition(
                position:
                    Tween(begin: const Offset(0.06, 0), end: Offset.zero)
                        .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: KeyedSubtree(
                  key: ValueKey(_currentIndex), child: pages[_currentIndex]),
            ),
          ),
          
          // FAB
          Positioned(
            right: 20,
            bottom: dockHeight + 20, // Posizionato sopra il dock
            child: _buildContextFab(),
          ),

          // IL NUOVO DOCK CON SHADER
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LiquidGlassDock(
              currentIndex: _currentIndex,
              onIndexChanged: _onNavigate,
              items: _dockItems,
              // ✅ 6. PASSA L'IMMAGINE CATTURATA AL DOCK
              backgroundImageNotifier: _backgroundNotifier,
            ),
          ),
        ],
      ),
    );
  }
  
  // ... (Tutto il resto del tuo codice _buildContextFab, _showQuickAddMenu, etc.
  // resta invariato. Copio il resto del file da 'main.dart' che hai caricato)

  Widget _buildContextFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (_currentIndex == 0) {
      // Home: FAB Aggiungi con modal
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
      // Planning: FAB Aggiungi
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
                    ? [Colors.black.withOpacity(0.85), Colors.black.withOpacity(0.75)]
                    : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  _GlassQuickAction(
                    icon: Icons.receipt_long,
                    title: 'Scansione scontrino (AI)',
                    subtitle: 'Estrai importo e negozio automaticamente',
                    color: const Color(0xFF10B981),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ScanReceiptPageWithHome(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 14),
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
                      const SizedBox(width: 14),
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
            builder: (context) => AddTxPage(isIncome: isIncome),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(18),
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
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14.5,
                  ),
                ),
                const SizedBox(height: 5),
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
      borderRadius: BorderRadius.circular(20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [color.withOpacity(0.22), color.withOpacity(0.14)]
                    : [color.withOpacity(0.18), color.withOpacity(0.10)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: color.withOpacity(isDark ? 0.40 : 0.35),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(isDark ? 0.28 : 0.20),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 28),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 26,
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

class ScanReceiptPageWithHome extends StatelessWidget {
  const ScanReceiptPageWithHome({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              title: Text(
                'Scansiona Scontrino',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.home,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                tooltip: 'Torna alla Home',
              ),
              elevation: 0,
              centerTitle: true,
              backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ),
      body: const ScanReceiptPage(),
    );
  }
}
