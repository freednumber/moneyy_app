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
              ? [
                  const Color(0xFF1A1F2E),
                  const Color(0xFF0A0E1A),
                ]
              : [
                  const Color(0xFFE0F2FE).withOpacity(0.3),
                  const Color(0xFFF0F9FF).withOpacity(0.5),
                ],
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
                            color: isDark 
                              ? Colors.white.withOpacity(0.1) 
                              : Colors.white.withOpacity(0.8),
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
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.monetization_on,
                                color: Colors.white,
                                size: 16,
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
                            const SizedBox(width: 16),
                            _buildNetWorthChip(model, isDark, isCompact),
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
                      SizedBox(height: isCompact ? 24 : 32),
                      _buildGlassCategoryBreakdown(context, model, isDark, isCompact),
                      SizedBox(height: isCompact ? 24 : 32),
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

  Widget _buildNetWorthChip(MoneyModel model, bool isDark, bool isCompact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          constraints: BoxConstraints(minWidth: isCompact ? 70 : 90),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 14, 
            vertical: isCompact ? 4 : 6,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: model.netWorth >= 0
                ? [const Color(0xFF10B981).withOpacity(0.9), const Color(0xFF059669).withOpacity(0.8)]
                : [const Color(0xFFEF4444).withOpacity(0.9), const Color(0xFFDC2626).withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (model.netWorth >= 0 
                  ? const Color(0xFF10B981) 
                  : const Color(0xFFEF4444)).withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              model.format(model.netWorth),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: isCompact ? 12 : 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatsCard(MoneyModel model, bool isDark, bool isCompact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 24 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.8),
                  ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
            border: Border.all(
              color: isDark 
                ? Colors.white.withOpacity(0.15) 
                : Colors.white.withOpacity(0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.6),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _buildGlassStatItem(
                    'Entrate Mese',
                    model.format(model.monthlyIncome),
                    const Color(0xFF10B981),
                    Icons.trending_up,
                    isDark,
                    isCompact,
                  ),
                ),
                Container(
                  width: 2,
                  margin: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        (isDark ? Colors.white : Colors.grey.shade400).withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                Expanded(
                  child: _buildGlassStatItem(
                    'Uscite Mese',
                    model.format(model.monthlyExpense),
                    const Color(0xFFEF4444),
                    Icons.trending_down,
                    isDark,
                    isCompact,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatItem(String label, String value, Color color, IconData icon, bool isDark, bool isCompact) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isCompact ? 10 : 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: isCompact ? 28 : 32,
          ),
        ),
        SizedBox(height: isCompact ? 12 : 16),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 12 : 14,
            color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[600],
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isCompact ? 4 : 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 18 : 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCategoryBreakdown(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = screenWidth > 380 ? 2 : 1;

    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 24 : 28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [
                    Colors.white.withOpacity(0.12),
                    Colors.white.withOpacity(0.05),
                  ]
                : [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.8),
                  ],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
            border: Border.all(
              color: isDark 
                ? Colors.white.withOpacity(0.15) 
                : Colors.white.withOpacity(0.9),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.6),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 12 : 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isCompact ? 16 : 18),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withOpacity(0.5),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 2,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.flash_on, 
                      color: Colors.white, 
                      size: isCompact ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  Expanded(
                    child: Text(
                      'Aggiungi Veloce',
                      style: TextStyle(
                        fontSize: isCompact ? 20 : 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: isCompact ? 20 : 24),
              Wrap(
                spacing: isCompact ? 12 : 16,
                runSpacing: isCompact ? 14 : 18,
                children: mostUsed.map((cat) {
                  final style = model.getTransactionStyle(cat);
                  final isIncome = model.incomeCats.contains(cat);
                  final lastUsed = _getLastUsedDate(model, cat);
                  final chipWidth = crossAxisCount == 1 
                    ? double.infinity
                    : (MediaQuery.of(context).size.width - (isCompact ? 80 : 96)) / crossAxisCount;
                  return SizedBox(
                    width: chipWidth,
                    child: _buildGlassCategoryChip(
                      cat, style.icon, style.color, isIncome, lastUsed, isDark, isCompact,
                      () => _showQuickEntryDialog(context, cat, isIncome),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassCategoryChip(
    String category, 
    IconData icon, 
    Color color, 
    bool isIncome, 
    String lastUsed, 
    bool isDark, 
    bool isCompact,
    VoidCallback onTap
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.all(isCompact ? 16 : 20),
              constraints: const BoxConstraints(minHeight: 80),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                    ? [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ]
                    : [
                        color.withOpacity(0.15),
                        color.withOpacity(0.08),
                      ],
                ),
                borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
                border: Border.all(
                  color: isDark
                    ? color.withOpacity(0.4)
                    : color.withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(isDark ? 0.1 : 0.7),
                    blurRadius: 2,
                    offset: const Offset(0, -1),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isCompact ? 12 : 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.5),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          icon, 
                          color: Colors.white, 
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: EdgeInsets.all(isCompact ? 4 : 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isIncome 
                                ? [const Color(0xFF10B981), const Color(0xFF059669)]
                                : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                            color: Colors.white,
                            size: isCompact ? 10 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                            fontSize: isCompact ? 14 : 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : color.withOpacity(0.9),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: isCompact ? 4 : 6),
                        Text(
                          lastUsed,
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            fontWeight: FontWeight.w500,
                            color: isDark 
                              ? Colors.white.withOpacity(0.6)
                              : color.withOpacity(0.6),
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
      ),
    );
  }

  // Resto dei metodi helper rimangono invariati...
  String _getLastUsedDate(MoneyModel model, String category) {
    final txForCategory = model.transactions
        .where((tx) => tx.category == category)
        .toList();
    
    if (txForCategory.isEmpty) {
      return 'Mai usato';
    }
    
    final mostRecent = txForCategory.first;
    final now = DateTime.now();
    final difference = now.difference(mostRecent.date).inDays;
    
    if (difference == 0) {
      return 'Oggi';
    } else if (difference == 1) {
      return 'Ieri';
    } else if (difference < 7) {
      return '$difference giorni fa';
    } else {
      return DateFormat('d MMM', 'it_IT').format(mostRecent.date);
    }
  }

  List<String> _getMostUsedCategories(MoneyModel model) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final recentTxs = model.transactions
        .where((tx) => tx.date.isAfter(lastMonth))
        .toList();
    
    final Map<String, int> categoryCount = {};
    for (var tx in recentTxs) {
      if (!model.goalCategories.contains(tx.category)) {
        categoryCount[tx.category] = (categoryCount[tx.category] ?? 0) + 1;
      }
    }

    final sortedCategories = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final mostUsed = sortedCategories
        .take(6)
        .map((e) => e.key)
        .toList();
    
    if (mostUsed.length < 6) {
      final defaults = ['Spesa', 'Trasporti', 'Svago', 'Shopping', 'Bollette', 'Casa'];
      for (var cat in defaults) {
        if (!mostUsed.contains(cat) && mostUsed.length < 6) {
          mostUsed.add(cat);
        }
      }
    }
    return mostUsed;
  }

  Widget _buildGlassRecentTransactions(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final recentTransactions = model.recent.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transazioni Recenti',
          style: TextStyle(
            fontSize: isCompact ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: isCompact ? 16 : 20),
        if (recentTransactions.isEmpty)
          _buildGlassEmptyState(isDark, isCompact)
        else
          ...recentTransactions.map((tx) => 
            Padding(
              padding: EdgeInsets.only(bottom: isCompact ? 12 : 16),
              child: _buildGlassTransactionCard(tx, model, isDark, isCompact),
            )
          ).toList(),
      ],
    );
  }

  Widget _buildGlassEmptyState(bool isDark, bool isCompact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 32 : 40),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            border: Border.all(
              color: isDark 
                ? Colors.white.withOpacity(0.1) 
                : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                        ? [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                        : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.receipt_long,
                    size: isCompact ? 48 : 60,
                    color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[400],
                  ),
                ),
                SizedBox(height: isCompact ? 16 : 20),
                Text(
                  'Nessuna transazione',
                  style: TextStyle(
                    fontSize: isCompact ? 16 : 18,
                    color: isDark ? Colors.white.withOpacity(0.8) : Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: isCompact ? 8 : 10),
                Text(
                  'Inizia aggiungendo la tua prima transazione',
                  style: TextStyle(
                    fontSize: isCompact ? 13 : 14,
                    color: isDark ? Colors.white.withOpacity(0.5) : Colors.grey[400],
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

  Widget _buildGlassTransactionCard(MoneyTx tx, MoneyModel model, bool isDark, bool isCompact) {
    final style = model.getTransactionStyle(tx.category);
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
            border: Border.all(
              color: isDark 
                ? Colors.white.withOpacity(0.12) 
                : Colors.white.withOpacity(0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(isDark ? 0.1 : 0.5),
                blurRadius: 2,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: isCompact ? 48 : 56,
                height: isCompact ? 48 : 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [style.color.withOpacity(0.9), style.color.withOpacity(0.7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  style.icon, 
                  color: Colors.white, 
                  size: isCompact ? 24 : 28,
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tx.category,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: isCompact ? 14 : 16,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('d MMM yyyy', 'it_IT').format(tx.date),
                      style: TextStyle(
                        fontSize: isCompact ? 11 : 12,
                        color: isDark ? Colors.white.withOpacity(0.6) : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 8 : 10, 
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: style.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: style.color.withOpacity(0.3),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      tx.payment.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: isCompact ? 9 : 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white.withOpacity(0.8) : style.color,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickEntryDialog(BuildContext context, String category, bool isIncome) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Aggiungi a "$category"',
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                labelText: 'Importo',
                prefixIcon: const Icon(Icons.euro),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : null,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              decoration: InputDecoration(
                labelText: 'Nota (Opzionale)',
                prefixIcon: const Icon(Icons.note),
                labelStyle: TextStyle(
                  color: isDark ? Colors.grey[400] : null,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annulla',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountCtrl.text);
              if (amount != null && amount > 0) {
                final tx = MoneyTx(
                  id: null,
                  isIncome: isIncome,
                  category: category,
                  amount: amount,
                  date: DateTime.now(),
                  note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  payment: PaymentMethod.contanti,
                );
                context.read<MoneyModel>().addTx(tx);
                Navigator.pop(context);
                HapticFeedback.heavyImpact();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }
}