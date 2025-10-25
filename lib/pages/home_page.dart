// Hotfix: avoid RenderFlex overflow by ensuring content scrolls and respecting bottom safe area.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models.dart';
import '../providers.dart';
import 'add_tx_page.dart';

class HomePage extends StatefulWidget {
  final Function(int, [bool?])? onNavigate;
  const HomePage({super.key, this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: true,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 160),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _buildBody(context, isDark, isCompact, bottomPadding),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark, bool isCompact, double bottomPadding) {
    return Consumer<MoneyModel>(
      builder: (context, model, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context, model, isDark, isCompact),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildGlassStatsCard(model, isDark, isCompact),
                  SizedBox(height: isCompact ? 20 : 24),
                  _buildQuickAddGrid(context, model, isDark, isCompact),
                  SizedBox(height: isCompact ? 20 : 24),
                  _buildGlassRecentTransactions(context, model, isDark, isCompact),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    return Container(
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [Colors.black.withOpacity(0.3), Colors.transparent]
              : [Colors.white.withOpacity(0.2), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          _buildLogoSection(isDark, isCompact),
          const SizedBox(height: 12),
          _buildNetWorthCard(model, isDark, isCompact),
        ],
      ),
    );
  }

  // ... keep the rest of helper methods from previous version (logo section, net worth, stats, quick grid, transactions, etc.)
}
