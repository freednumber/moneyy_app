import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:ui' as ui;

// ✅ IMPORT
import 'providers/wallet_provider.dart';
import 'providers/category_provider.dart';
import 'theme_provider.dart';

// Pagine
import 'pages/home_page.dart';
import 'pages/planning_page.dart';
import 'pages/reports_page.dart';
import 'pages/settings_page.dart';
import 'pages/splash_page.dart';
import 'pages/add_tx_page.dart';
import 'pages/scan_receipt_page.dart';

// Widget e Servizi
import 'widgets/liquid_glass_dock.dart';
import 'widgets/shader_helpers/background_capture_widget.dart';
import 'services/notifications_service.dart';
import 'services/biometric_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationsService.initialize();
  final permissionGranted = await NotificationsService.requestPermissions();
  debugPrint('🔔 Permessi notifiche: ${permissionGranted ? "✅ CONCESSI" : "❌ NEGATI"}');
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WalletProvider()..loadInitial()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const MoneyYApp(),
    ),
  );
}

class MoneyYApp extends StatefulWidget {
  const MoneyYApp({super.key});

  @override
  State<MoneyYApp> createState() => _MoneyYAppState();
}

class _MoneyYAppState extends State<MoneyYApp> with WidgetsBindingObserver {
  bool _isLocked = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometricOnStartup();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final wallet = Provider.of<WalletProvider>(context, listen: false);
      wallet.processRecurringTransactions();
    }
  }

  Future<void> _checkBiometricOnStartup() async {
    final isEnabled = await BiometricService.getEnabled();

    if (!isEnabled) {
      if (mounted) {
        setState(() {
          _isLocked = false;
          _isLoading = false;
        });
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 300));
    final authenticated = await BiometricService.authenticate(reason: 'Sblocca Moneyy');

    if (mounted) {
      setState(() {
        _isLocked = !authenticated;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
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
          home: _isLoading
              ? _buildLoadingScreen(themeProvider.themeMode == ThemeMode.dark)
              : _isLocked
                  ? _buildLockScreen(themeProvider.themeMode == ThemeMode.dark)
                  : const SplashPage(child: MainNavigationPage()),
        );
      },
    );
  }

  Widget _buildLoadingScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
    );
  }

  Widget _buildLockScreen(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded, size: 64, color: Color(0xFF6366F1)),
            ),
            const SizedBox(height: 32),
            Text(
              'Moneyy è bloccato',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Autenticati per accedere',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _checkBiometricOnStartup,
              icon: const Icon(Icons.face_rounded),
              label: const Text('Usa Face ID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
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
  WalletProvider? _walletProvider;
  late AnimationController _fabController;
  final GlobalKey planningKey = GlobalKey();
  late ValueNotifier<int> _dockIndex;
  final GlobalKey<BackgroundCaptureWidgetState> _captureKey = GlobalKey();
  final ValueNotifier<ui.Image?> _backgroundNotifier = ValueNotifier(null);
  Timer? _recurringTimer;

  final List<DockItem> _dockItems = [
    DockItem(icon: Icons.home_rounded, label: 'Home', activeColor: const Color(0xFF38F9D7)),
    DockItem(icon: Icons.calendar_month, label: 'Planning', activeColor: const Color(0xFF00E676)),
    DockItem(icon: Icons.bar_chart_rounded, label: 'Reports', activeColor: const Color(0xFF00BFA5)),
    DockItem(icon: Icons.settings_rounded, label: 'Settings', activeColor: const Color(0xFF76FF03)),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _dockIndex = ValueNotifier(_currentIndex);
    _initModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureKey.currentState?.capture();
    });
    
    _recurringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _walletProvider?.processRecurringTransactions();
    });
  }

  @override
  void dispose() {
    _recurringTimer?.cancel();
    _fabController.dispose();
    _dockIndex.dispose();
    _backgroundNotifier.dispose();
    super.dispose();
  }

  Future<void> _initModel() async {
    _walletProvider = Provider.of<WalletProvider>(context, listen: false);
  }

  void _onNavigate(int index, [bool? isIncome]) {
    if (index != _currentIndex) {
      HapticFeedback.selectionClick();
      _dockIndex.value = index;
      setState(() => _currentIndex = index);
      _captureKey.currentState?.capture();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final dockHeight = 82 + (bottomPadding > 0 ? 8 : 16);

    final pages = [
      HomePage(onNavigate: _onNavigate),
      PlanningPage(key: planningKey),
      const ReportsPage(),
      const SettingsPage(),
    ];

    return Scaffold(
      extendBody: true,
      body: Stack(
        children: [
          BackgroundCaptureWidget(
            key: _captureKey,
            backgroundNotifier: _backgroundNotifier,
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
          Positioned(right: 20, bottom: dockHeight + 20, child: _buildContextFab()),
          Positioned(left: 0, right: 0, bottom: 0, child: LiquidGlassDock(currentIndex: _currentIndex, onIndexChanged: _onNavigate, items: _dockItems, backgroundImageNotifier: _backgroundNotifier)),
        ],
      ),
    );
  }

  Widget _buildContextFab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_currentIndex == 0) {
      return _buildGlassFab(color: const Color(0xFF6366F1), icon: Icons.add, tooltip: 'Aggiungi', onTap: () { HapticFeedback.mediumImpact(); _showQuickAddMenu(context); }, isDark: isDark);
    } else if (_currentIndex == 1) {
      return _buildGlassFab(color: const Color(0xFF10B981), icon: Icons.add, tooltip: 'Aggiungi', onTap: () { HapticFeedback.mediumImpact(); final state = planningKey.currentState; if (state != null && state.mounted) { final dynamic dyn = state; try { dyn.showAddDialog(context); } catch (_) {} } }, isDark: isDark);
    }
    return const SizedBox.shrink();
  }

  Widget _buildGlassFab({required Color color, required IconData icon, required VoidCallback onTap, required String tooltip, required bool isDark}) {
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
              width: 56, height: 56,
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.8), color.withOpacity(0.6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.0), boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.4 : 0.2), blurRadius: 16, spreadRadius: 2, offset: const Offset(0, 8)), BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
          ),
        ),
      ),
    );
  }

  void _showQuickAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context, useSafeArea: true, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 42, height: 5, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.45), borderRadius: BorderRadius.circular(2.5))),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.receipt_long, color: Color(0xFF10B981), size: 30),
                  title: const Text('Scansione scontrino (AI)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Estrai importo e negozio automaticamente'),
                  onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ScanReceiptPageWithHome())); },
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTxPage(isIncome: false))); }, icon: const Icon(Icons.arrow_downward), label: const Text("Uscita"), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white))),
                  const SizedBox(width: 10),
                  Expanded(child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const AddTxPage(isIncome: true))); }, icon: const Icon(Icons.arrow_upward), label: const Text("Entrata"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                ]),
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
              title: Text('Scansione Scontrino', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
              leading: IconButton(icon: Icon(Icons.home, color: isDark ? Colors.white : Colors.black87), onPressed: () { HapticFeedback.lightImpact(); Navigator.pop(context); }, tooltip: 'Torna alla Home'),
              elevation: 0, centerTitle: true, backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
            ),
          ),
        ),
      ),
      body: const ScanReceiptPage(),
    );
  }
}
