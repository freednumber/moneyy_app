// Estratto principale: modifica layout compact-grid più logo originale
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
      backgroundColor: isDark 
        ? const Color(0xFF0A0E1A)
        : const Color(0xFFF8FAFC),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
              ? [const Color(0xFF1A1F2E),const Color(0xFF0A0E1A)]
              : [const Color(0xFFE0F2FE).withOpacity(0.3),const Color(0xFFF0F9FF).withOpacity(0.5)],
          ),
        ),
        child: Consumer<MoneyModel>(
          builder: (context, model, child) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 120,
                  floating: false,
                  pinned: true,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: isDark
                            ? [Colors.black.withOpacity(0.3), Colors.transparent]
                            : [Colors.white.withOpacity(0.2), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  title: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 16, 
                          vertical: isCompact ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                              ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                              : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.5 : 0.08),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // LOGO ORIGINALE APP QUI
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Image.asset(
                                'assets/images/moneyy_icon_home.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Moneyy',
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                                fontWeight: FontWeight.w700,
                                fontSize: isCompact ? 16 : 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  centerTitle: true,
                  automaticallyImplyLeading: false,
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: isCompact ? 12 : 16,
                    right: isCompact ? 12 : 16,
                    top: 20,
                    bottom: bottomPadding + 140,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildGlassStatsCard(model, isDark, isCompact),
                      SizedBox(height: isCompact ? 20 : 24),
                      // GRIGLIA AGGIUNGI VELOCE 2x3
                      _buildQuickAddGrid(context, model, isDark, isCompact),
                      SizedBox(height: isCompact ? 20 : 24),
                      _buildGlassRecentTransactions(context, model, isDark, isCompact),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickAddGrid(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 10 : 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.flash_on, 
                color: Colors.white, 
                size: isCompact ? 18 : 20,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Flexible(
              child: Text(
                'Aggiungi Veloce',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 16 : 20),
        // Griglia simmetrica 2x3
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: isCompact ? 8 : 16,
            mainAxisSpacing: isCompact ? 10 : 16,
            childAspectRatio: 2.9,
          ),
          itemCount: mostUsed.length,
          itemBuilder: (context, i) {
            final cat = mostUsed[i];
            final style = model.getTransactionStyle(cat);
            final isIncome = model.incomeCats.contains(cat);
            final lastUsed = _getLastUsedDate(model, cat);
            return _buildGlassCategoryChip(
              cat, style.icon, style.color, isIncome, lastUsed, isDark, isCompact,
              () => _showQuickEntryDialog(context, cat, isIncome),
            );
          },
        )
      ],
    );
  }
  // Resto invariato... (statistiche, transazioni etc)
}