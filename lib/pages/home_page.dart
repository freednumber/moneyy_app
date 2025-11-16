import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import 'scan_receipt_page.dart';

class HomePage extends StatefulWidget {
  final Function(int, [bool?])? onNavigate;
  final ScrollController? scrollController;

  const HomePage({super.key, this.onNavigate, this.scrollController});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _openScannerReceipt() {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanReceiptPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 380;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(shape: BoxShape.circle),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/images/moneyy_icon_home.png', fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Moneyy',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                          fontWeight: FontWeight.w700,
                          fontSize: isCompact ? 18 : 22,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.person_rounded, color: isDark ? Colors.white : const Color(0xFF1E293B), size: 28),
                    tooltip: 'Profilo personale',
                    onPressed: () {
                      // TODO: implement login/profile page
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 12 : 16,
                  8,
                  isCompact ? 12 : 16,
                  84,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildNetWorthCard(model, isDark, isCompact),
                    ),
                    SizedBox(height: isCompact ? 18 : 22),
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildGlassStatsCard(model, isDark, isCompact),
                    ),
                    SizedBox(height: isCompact ? 18 : 22),
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildQuickAddSection(context, model, isDark, isCompact),
                    ),
                    SizedBox(height: isCompact ? 18 : 22),
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildGlassRecentTransactions(model, isDark, isCompact),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ...includi tutti i metodi _buildNetWorthCard, _buildGlassStatsCard, _buildQuickAddSection, _buildGlassRecentTransactions, _getLastUsedDate, _getMostUsedCategories, _showQuickEntryDialog qui come già nell'implementazione SWYPE style
}
