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
    super.build(context); // INDISPENSABILE per AutomaticKeepAliveClientMixin
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
                ? [const Color(0xFF1A1F2E), const Color(0xFF0A0E1A)]
                : [const Color(0xFFE0F2FE).withOpacity(0.3), const Color(0xFFF0F9FF).withOpacity(0.5)],
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
                            vertical: isCompact ? 6 : 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isDark
                                ? [
                                    Colors.white.withOpacity(0.08),
                                    Colors.white.withOpacity(0.03)
                                  ]
                                : [
                                    Colors.white.withOpacity(0.9),
                                    Colors.white.withOpacity(0.6)
                                  ],
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
                              color: Colors.black.withOpacity(
                                  isDark ? 0.5 : 0.08),
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
                              decoration:
                                  const BoxDecoration(shape: BoxShape.circle),
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
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1E293B),
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
                      _buildQuickAddGrid(context, model, isDark, isCompact),
                      SizedBox(height: isCompact ? 20 : 24),
                      _buildGlassRecentTransactions(
                          context, model, isDark, isCompact),
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

  Widget _buildGlassStatsCard(MoneyModel model, bool isDark, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.05)]
              : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.8)],
        ),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.9),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      child: Row(
        children: [
          Expanded(
              child: _buildStatItem('Entrate Mese',
                  model.format(model.monthlyIncome),
                  const Color(0xFF10B981), Icons.trending_up, isDark, isCompact)),
          Container(
              width: 1,
              height: isCompact ? 50 : 60,
              color: isDark
                  ? Colors.white.withOpacity(0.15)
                  : Colors.grey.shade300),
          Expanded(
              child: _buildStatItem('Uscite Mese',
                  model.format(model.monthlyExpense),
                  const Color(0xFFEF4444), Icons.trending_down, isDark, isCompact)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon,
      bool isDark, bool isCompact) {
    return Column(
      children: [
        Icon(icon,
            color: isDark ? color.withOpacity(0.9) : color,
            size: isCompact ? 24 : 28),
        SizedBox(height: isCompact ? 6 : 8),
        Text(label,
            style: TextStyle(
                fontSize: isCompact ? 12 : 13,
                height: 1.05,
                color: isDark ? Colors.grey[300] : Colors.grey[600],
                fontWeight: FontWeight.w500)),
        SizedBox(height: isCompact ? 2 : 4),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value,
                style: TextStyle(
                    fontSize: isCompact ? 16 : 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : color))),
      ],
    );
  }

  Widget _buildQuickAddGrid(BuildContext context, MoneyModel model, bool isDark,
      bool isCompact) {
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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: isCompact ? 8 : 16,
              mainAxisSpacing: isCompact ? 10 : 16,
              childAspectRatio: 2.9),
          itemCount: mostUsed.length,
          itemBuilder: (context, i) {
            final cat = mostUsed[i];
            final style = model.getTransactionStyle(cat);
            final isIncome = model.incomeCats.contains(cat);
            final lastUsed = _getLastUsedDate(model, cat);
            return _buildGlassCategoryChip(cat, style.icon, style.color, isIncome,
                lastUsed, isDark, isCompact, () => _showQuickEntryDialog(context, cat, isIncome));
          },
        )
      ],
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
      VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.all(isCompact ? 16 : 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
            gradient: LinearGradient(
              colors: isDark
                  ? [color.withOpacity(0.2), color.withOpacity(0.1)]
                  : [color.withOpacity(0.15), color.withOpacity(0.08)],
            ),
            border:
                Border.all(color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 12 : 14),
                decoration: BoxDecoration(
                  gradient:
                      LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]),
                  borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                child: Icon(icon, color: Colors.white, size: isCompact ? 20 : 24),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 14 : 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : color.withOpacity(0.9))),
                    SizedBox(height: isCompact ? 4 : 6),
                    Text(lastUsed, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 11 : 12, color: isDark ? Colors.white.withOpacity(0.6) : color.withOpacity(0.6))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassRecentTransactions(BuildContext context, MoneyModel model,
      bool isDark, bool isCompact) {
    final recentTransactions = model.recent.take(8).toList();
    if (recentTransactions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(isCompact ? 32 : 40),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 20 : 24),
          gradient: LinearGradient(
              colors: isDark
                  ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                  : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)]),
          border: Border.all(
              color:
                  isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8),
              width: 1.5),
        ),
        child: Center(
            child: Text('Nessuna transazione',
                style: TextStyle(fontSize: isCompact ? 16 : 18, color: isDark ? Colors.white70 : Colors.grey[600]))),
      );
    }
    return Column(
      children: recentTransactions
          .map((tx) => _buildGlassTransactionCard(tx, model, isDark, isCompact))
          .toList(),
    );
  }

  Widget _buildGlassTransactionCard(MoneyTx tx, MoneyModel model, bool isDark,
      bool isCompact) {
    final style = model.getTransactionStyle(tx.category);
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        gradient: LinearGradient(
            colors: isDark
                ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)]
                : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.7)]),
        border:
            Border.all(color: isDark ? Colors.white.withOpacity(0.12) : Colors.white.withOpacity(0.8), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: isCompact ? 48 : 56,
            height: isCompact ? 48 : 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [style.color.withOpacity(0.9), style.color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
            ),
            child:
                Icon(style.icon, color: Colors.white, size: isCompact ? 24 : 28),
          ),
          SizedBox(width: isCompact ? 12 : 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.category,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: isCompact ? 14 : 16,
                          color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text(
                      DateFormat('d MMM yyyy', 'it_IT').format(tx.date),
                      style: TextStyle(
                          fontSize: isCompact ? 11 : 12,
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : Colors.grey[500])),
                ]),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                fontSize: isCompact ? 14 : 16),
          ),
        ],
      ),
    );
  }

  String _getLastUsedDate(MoneyModel model, String category) {
    final txForCategory =
        model.transactions.where((tx) => tx.category == category).toList();
    if (txForCategory.isEmpty) return 'Mai usato';
    final mostRecent = txForCategory.first;
    final now = DateTime.now();
    final difference = now.difference(mostRecent.date).inDays;
    if (difference == 0) return 'Oggi';
    if (difference == 1) return 'Ieri';
    if (difference < 7) return '$difference giorni fa';
    return DateFormat('d MMM', 'it_IT').format(mostRecent.date);
  }

  List<String> _getMostUsedCategories(MoneyModel model) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final recentTxs =
        model.transactions.where((tx) => tx.date.isAfter(lastMonth)).toList();
    final Map<String, int> categoryCount = {};
    for (var tx in recentTxs) {
      if (!model.goalCategories.contains(tx.category)) {
        categoryCount[tx.category] = (categoryCount[tx.category] ?? 0) + 1;
      }
    }
    final sorted = categoryCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final mostUsed = sorted.take(6).map((e) => e.key).toList();
    final defaults = ['Spesa', 'Trasporti', 'Svago', 'Shopping', 'Bollette', 'Casa'];
    for (var cat in defaults) {
      if (mostUsed.length >= 6) break;
      if (!mostUsed.contains(cat)) mostUsed.add(cat);
    }
    return mostUsed;
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
        title: Text('Aggiungi a "$category"', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Importo', prefixIcon: Icon(Icons.euro))),
          const SizedBox(height: 12),
          TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Nota (Opzionale)', prefixIcon: Icon(Icons.note))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(onPressed: () { final amount = double.tryParse(amountCtrl.text); if (amount != null && amount > 0) { final tx = MoneyTx(id: null, isIncome: isIncome, category: category, amount: amount, date: DateTime.now(), note: noteCtrl.text.isEmpty ? null : noteCtrl.text, payment: PaymentMethod.contanti); context.read<MoneyModel>().addTx(tx); Navigator.pop(context); HapticFeedback.heavyImpact(); } }, child: const Text('Aggiungi')),
        ],
      ),
    );
  }
}
