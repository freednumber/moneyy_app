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
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomPadding + 56, right: 4),
        child: _buildFab(context),
      ),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomPadding + 120),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: _HomeBody(isDark: isDark),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onNavigate?.call(4);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.85),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.35), blurRadius: 18, offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  final bool isDark;
  const _HomeBody({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoneyModel>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 380;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLogoSection(isDark, isCompact),
          const SizedBox(height: 16),
          _buildNetWorthCard(model, isDark, isCompact),
          SizedBox(height: isCompact ? 18 : 22),
          _buildGlassStatsCard(model, isDark, isCompact),
          SizedBox(height: isCompact ? 18 : 22),
          _buildQuickAddBlock(context, model, isDark, isCompact),
          SizedBox(height: isCompact ? 18 : 22),
          _buildGlassRecentTransactions(context, model, isDark, isCompact),
        ],
      ),
    );
  }

  Widget _buildLogoSection(bool isDark, bool isCompact) {
    return Center(...);
  }
  
  Widget _buildNetWorthCard(MoneyModel model, bool isDark, bool isCompact) {
    ...
  }

  Widget _buildGlassStatsCard(MoneyModel model, bool isDark, bool isCompact) {
    ...
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, bool isDark, bool isCompact) {
    ...
  }

  Widget _buildQuickAddBlock(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 20 : 22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 10 : 14),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
            borderRadius: BorderRadius.circular(isCompact ? 20 : 22),
            border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 10 : 12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                      borderRadius: BorderRadius.circular(isCompact ? 14 : 16)),
                    child: Icon(Icons.flash_on, color: Colors.white, size: isCompact ? 18 : 20)),
                  SizedBox(width: isCompact ? 10 : 12),
                  Expanded(child: Text('Aggiungi Veloce', style: TextStyle(fontSize: isCompact ? 20 : 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))))
                ]),
              SizedBox(height: isCompact ? 10 : 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: isCompact ? 10 : 14,
                  mainAxisSpacing: isCompact ? 12 : 18,
                  childAspectRatio: 2.4,
                ),
                itemCount: mostUsed.length,
                itemBuilder: (context, i) {
                  final cat = mostUsed[i];
                  final style = model.getTransactionStyle(cat);
                  final isIncome = model.incomeCats.contains(cat);
                  final lastUsed = _getLastUsedDate(model, cat);
                  return _buildQuickChip(cat, style.icon, style.color, isIncome, lastUsed, isDark, isCompact, () => _showQuickEntryDialog(context, cat, isIncome));
                },
              ),
            ]),
        ),
      ),
    );
  }

  Widget _buildQuickChip(String category, IconData icon, Color color, bool isIncome, String lastUsed, bool isDark, bool isCompact, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        child: Container(
          height: isCompact ? 54 : 64,
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 10 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
            color: isDark ? color.withOpacity(0.13) : color.withOpacity(0.10),
            border: Border.all(color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.28), width: 1.1),
          ),
          child: Row(children: [
            Container(padding: EdgeInsets.all(isCompact ? 9 : 11), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.75)]), borderRadius: BorderRadius.circular(isCompact ? 12 : 14)), child: Icon(icon, color: Colors.white, size: isCompact ? 20 : 24)),
            SizedBox(width: isCompact ? 8 : 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 14 : 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : color.withOpacity(0.9))),
              SizedBox(height: isCompact ? 3 : 4),
              Text(lastUsed, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 10 : 12, color: isDark ? Colors.white60 : color.withOpacity(0.57))),
            ]))
          ]),
        ),
      ),
    );
  }
  // ...metodi recent e utils come prima...
}
