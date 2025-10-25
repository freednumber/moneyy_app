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
    final isCompact = screenWidth < 380; // Very small screens
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: isDark 
        ? const Color(0xFF0F172A)
        : Colors.grey[50],
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: const DecorationImage(
                  image: AssetImage('assets/images/moneyy_icon_home.png'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Moneyy',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        actions: [
          Consumer<MoneyModel>(
            builder: (context, model, child) {
              return Container(
                margin: EdgeInsets.only(
                  right: isCompact ? 12 : 16,
                  top: 4,
                  bottom: 4,
                ),
                constraints: BoxConstraints(
                  minWidth: isCompact ? 80 : 100,
                  maxWidth: screenWidth * 0.35,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 12 : 16, 
                  vertical: isCompact ? 6 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: model.netWorth >= 0
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (model.netWorth >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
                      blurRadius: 8,
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
                      fontSize: isCompact ? 14 : 16,
                      letterSpacing: 0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<MoneyModel>(
        builder: (context, model, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                  ? [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                      Theme.of(context).colorScheme.secondary.withOpacity(0.05),
                    ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                await model.loadInitial();
              },
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: 100, 
                  left: isCompact ? 12 : 16, 
                  right: isCompact ? 12 : 16, 
                  bottom: bottomPadding + 140, // Extra space for dock + bottom safe area
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(model, isDark, isCompact),
                    SizedBox(height: isCompact ? 20 : 24),
                    _buildCategoryBreakdown(context, model, isDark, isCompact),
                    SizedBox(height: isCompact ? 20 : 24),
                    _buildRecentTransactions(context, model, isDark, isCompact),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(MoneyModel model, bool isDark, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        color: isDark 
          ? Colors.grey[900]!.withOpacity(0.8)
          : Colors.white.withOpacity(0.95),
        border: Border.all(
          color: isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 20.0 : 24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Entrate Mese',
                    model.format(model.monthlyIncome),
                    const Color(0xFF10B981),
                    Icons.trending_up,
                    isDark,
                    isCompact,
                  ),
                ),
                Container(
                  width: 1,
                  height: isCompact ? 50 : 60,
                  color: isDark 
                    ? Colors.white.withOpacity(0.15)
                    : Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildStatItem(
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

  Widget _buildStatItem(String label, String value, Color color, IconData icon, bool isDark, bool isCompact) {
    return Column(
      children: [
        Icon(
          icon,
          color: isDark ? color.withOpacity(0.9) : color,
          size: isCompact ? 24 : 28,
        ),
        SizedBox(height: isCompact ? 6 : 8),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 12 : 13,
            color: isDark ? Colors.grey[300] : Colors.grey[600],
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: isCompact ? 2 : 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isCompact ? 16 : 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive grid calculation with better aspect ratios
    int crossAxisCount;
    double childAspectRatio;
    
    if (screenWidth > 800) {
      // Desktop/Large tablet
      crossAxisCount = 3;
      childAspectRatio = 3.2;
    } else if (screenWidth > 600) {
      // Tablet
      crossAxisCount = 2;
      childAspectRatio = 2.8;
    } else if (screenWidth > 380) {
      // Normal phone
      crossAxisCount = 2;
      childAspectRatio = 2.4;
    } else {
      // Small phone
      crossAxisCount = 1;
      childAspectRatio = 4.0;
    }
    
    return Container(
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.grey[900]!.withOpacity(0.8)
          : Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        border: Border.all(
          color: isDark
            ? Colors.white.withOpacity(0.12)
            : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(isCompact ? 8 : 10),
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
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isCompact)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark
                      ? const Color(0xFF6366F1).withOpacity(0.2)
                      : const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(isDark ? 0.4 : 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: isDark ? const Color(0xFF8B9BFF) : const Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Più usate',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF8B9BFF) : const Color(0xFF6366F1),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: isCompact ? 16 : 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: childAspectRatio,
              crossAxisSpacing: isCompact ? 8 : 12,
              mainAxisSpacing: isCompact ? 8 : 12,
            ),
            itemCount: mostUsed.length,
            itemBuilder: (context, index) {
              final cat = mostUsed[index];
              final style = model.getTransactionStyle(cat);
              final isIncome = model.incomeCats.contains(cat);
              final lastUsed = _getLastUsedDate(model, cat);
              return _buildCategoryChipEnhanced(
                cat, 
                style.icon, 
                style.color, 
                isIncome, 
                lastUsed, 
                isDark, 
                isCompact,
                () => _showQuickEntryDialog(context, cat, isIncome),
              );
            },
          ),
        ],
      ),
    );
  }

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

  Widget _buildCategoryChipEnhanced(
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
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16, 
            vertical: isCompact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: isDark
              ? color.withOpacity(0.15)
              : color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
            border: Border.all(
              color: isDark
                ? color.withOpacity(0.5)
                : color.withOpacity(0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                  ? color.withOpacity(0.2)
                  : color.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCompact ? 6 : 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(isCompact ? 10 : 12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon, 
                      color: Colors.white, 
                      size: isCompact ? 16 : 18,
                    ),
                  ),
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 1.5 : 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isIncome 
                            ? [const Color(0xFF10B981), const Color(0xFF059669)]
                            : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 3,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: isCompact ? 6 : 8,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(width: isCompact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: isCompact ? 12 : 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : color,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact) SizedBox(height: 2),
                    Text(
                      lastUsed,
                      style: TextStyle(
                        fontSize: isCompact ? 8 : 10,
                        fontWeight: FontWeight.w500,
                        color: isDark 
                          ? Colors.grey[400]
                          : color.withOpacity(0.7),
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
    );
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

  Widget _buildRecentTransactions(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final recentTransactions = model.recent.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Transazioni Recenti',
                style: TextStyle(
                  fontSize: isCompact ? 18 : 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (recentTransactions.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(2);
                  }
                },
                icon: Icon(
                  Icons.arrow_forward,
                  size: 16,
                  color: isDark ? Colors.grey[300] : const Color(0xFF6366F1),
                ),
                label: Text(
                  'Tutte',
                  style: TextStyle(
                    color: isDark ? Colors.grey[300] : const Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: isCompact ? 12 : 16),
        if (recentTransactions.isEmpty)
          _buildEmptyState(isDark, isCompact)
        else
          ...recentTransactions.map((tx) => _buildTransactionCard(tx, model, isDark, isCompact)).toList(),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark, bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 32 : 40),
      decoration: BoxDecoration(
        color: isDark 
          ? Colors.grey[900]!.withOpacity(0.6)
          : Colors.white,
        borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
        border: Border.all(
          color: isDark
            ? Colors.white.withOpacity(0.1)
            : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: isCompact ? 48 : 60,
              color: isDark ? Colors.grey[600] : Colors.grey[300],
            ),
            SizedBox(height: isCompact ? 12 : 16),
            Text(
              'Nessuna transazione',
              style: TextStyle(
                fontSize: isCompact ? 14 : 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isCompact ? 6 : 8),
            Text(
              'Inizia aggiungendo la tua prima transazione',
              style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                color: isDark ? Colors.grey[500] : Colors.grey[400],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(MoneyTx tx, MoneyModel model, bool isDark, bool isCompact) {
    final style = model.getTransactionStyle(tx.category);

    return Dismissible(
      key: Key(tx.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(
          Icons.delete, 
          color: Colors.white, 
          size: isCompact ? 24 : 28,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Elimina Transazione'),
            content: const Text('Sei sicuro di voler eliminare questa transazione?'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annulla'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Elimina'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        context.read<MoneyModel>().deleteTransaction(tx.id!);
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transazione eliminata'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.only(bottom: isCompact ? 8 : 12),
        decoration: BoxDecoration(
          color: isDark 
            ? Colors.grey[900]!.withOpacity(0.7)
            : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.12)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.lightImpact();
              _showEditTransactionDialog(tx, model);
            },
            child: Padding(
              padding: EdgeInsets.all(isCompact ? 12 : 16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: isCompact ? 40 : 50,
                        height: isCompact ? 40 : 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [style.color, style.color.withOpacity(0.7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: style.color.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          style.icon, 
                          color: Colors.white, 
                          size: isCompact ? 20 : 24,
                        ),
                      ),
                      if (tx.isFromRecurring)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            width: isCompact ? 16 : 20,
                            height: isCompact ? 16 : 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.25),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.repeat,
                              color: Colors.white,
                              size: isCompact ? 8 : 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: isCompact ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                tx.category,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: isCompact ? 13 : 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tx.isFromRecurring)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'AUTO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: isCompact ? 2 : 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: isCompact ? 10 : 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[500],
                            ),
                            SizedBox(width: isCompact ? 3 : 4),
                            Expanded(
                              child: Text(
                                DateFormat('d MMM yyyy • HH:mm', 'it_IT').format(tx.date),
                                style: TextStyle(
                                  fontSize: isCompact ? 10 : 12,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (tx.note != null && tx.note!.isNotEmpty) ...[
                              SizedBox(width: isCompact ? 6 : 8),
                              Icon(
                                Icons.note,
                                size: isCompact ? 10 : 12,
                                color: isDark ? Colors.grey[400] : Colors.grey[500],
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            fontSize: isCompact ? 13 : 16,
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                        ),
                      ),
                      SizedBox(height: isCompact ? 2 : 4),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 6 : 8, 
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                            ? style.color.withOpacity(0.2)
                            : style.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tx.payment.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: isCompact ? 9 : 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : style.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditTransactionDialog(MoneyTx tx, MoneyModel model) {
    final amountCtrl = TextEditingController(text: tx.amount.toString());
    final noteCtrl = TextEditingController(text: tx.note ?? '');
    DateTime selectedDate = tx.date;
    String selectedCategory = tx.category;
    bool isIncome = tx.isIncome;
    PaymentMethod selectedPayment = tx.payment;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Row(
            children: [
              const Icon(Icons.edit, color: Color(0xFF6366F1)),
              const SizedBox(width: 8),
              Text(
                'Modifica Transazione',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('Entrata'), icon: Icon(Icons.add_circle, color: Colors.green)),
                    ButtonSegment(value: false, label: Text('Uscita'), icon: Icon(Icons.remove_circle, color: Colors.red)),
                  ],
                  selected: {isIncome},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      isIncome = newSelection.first;
                      final newCats = isIncome ? model.incomeCats : model.expenseCats;
                      if (!newCats.contains(selectedCategory)) {
                        selectedCategory = newCats.first;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: const Icon(Icons.category),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  items: (isIncome ? model.incomeCats : model.expenseCats).map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            cat,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Importo (€)',
                    prefixIcon: const Icon(Icons.euro),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: const Text('Data'),
                  subtitle: Text(DateFormat('d MMMM yyyy', 'it_IT').format(selectedDate)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  contentPadding: EdgeInsets.zero,
                ),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo Pagamento',
                    prefixIcon: const Icon(Icons.payment),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(
                        method.name.toUpperCase(),
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPayment = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Nota (opzionale)',
                    prefixIcon: const Icon(Icons.note),
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
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
            ElevatedButton.icon(
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount != null && amount > 0) {
                  final updatedTx = MoneyTx(
                    id: tx.id,
                    isIncome: isIncome,
                    category: selectedCategory,
                    amount: amount,
                    date: selectedDate,
                    note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                    payment: selectedPayment,
                    isFromRecurring: tx.isFromRecurring,
                  );
                  await model.updateTransaction(updatedTx);
                  Navigator.pop(context);
                  HapticFeedback.heavyImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Transazione aggiornata'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('Salva'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
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
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Aggiungi a "$category"',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
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
                color: isDark ? Colors.white : Colors.black87,
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
                color: isDark ? Colors.white : Colors.black87,
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
              backgroundColor: isIncome ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }
}