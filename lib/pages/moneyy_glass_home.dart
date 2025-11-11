import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers.dart';
import '../widgets/liquid_glass_card.dart';

class MoneyyGlassHome extends StatelessWidget {
  final VoidCallback? onPlusPressed;
  const MoneyyGlassHome({Key? key, this.onPlusPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final padding = MediaQuery.of(context).padding;
    final navBarHeight = 72.0;
    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Color(0xFF0A0E1A) : Color(0xFFF8FAFC),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: navBarHeight + padding.bottom + 28),
        child: FloatingActionButton(
          onPressed: onPlusPressed,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          child: Icon(Icons.add, color: Colors.white, size: 30),
          backgroundColor: Color(0xFF6366F1),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 14, 16, padding.bottom + navBarHeight + 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: LiquidGlassCard(
                  borderRadius: 22,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  thickness: 18,
                  blur: 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/images/moneyy_icon_home.png', width: 28, height: 28, fit: BoxFit.cover),
                      SizedBox(width: 12),
                      Text('Moneyy', style: TextStyle(fontSize: 21, color: isDark ? Colors.white : Color(0xFF1E293B), fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 18),
              Selector<MoneyModel, double>(
                selector: (_, model) => model.netWorth,
                builder: (context, netWorth, _) {
                  final positive = netWorth >= 0;
                  return LiquidGlassCardWithGlow(
                    borderRadius: 26,
                    thickness: 20,
                    blur: 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: positive ? [Color(0xFF10B981), Color(0xFF059669)] : [Color(0xFFEF4444), Color(0xFFDC2626)]),
                            borderRadius: BorderRadius.circular(12)),
                          child: Icon(positive ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: 22)),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Saldo Netto", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[600])),
                            Text(netWorth.toStringAsFixed(2), style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: isDark ? Colors.white : (positive ? Color(0xFF10B981) : Color(0xFFEF4444))),)
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 22),
              Consumer<MoneyModel>(
                builder: (context, model, _) {
                  return LiquidGlassCard(
                    borderRadius: 22,
                    thickness: 15,
                    blur: 9,
                    child: IntrinsicHeight(
                      child: Row(
                        children: [
                          Expanded(
                            child: _statItem(
                              context,
                              'Entrate Mese',
                              model.monthlyIncome,
                              Color(0xFF10B981),
                              Icons.trending_up,
                              isDark,
                            ),
                          ),
                          VerticalDivider(width: 24, thickness: 1, color: isDark ? Colors.white24 : Colors.grey.shade300),
                          Expanded(
                            child: _statItem(
                              context,
                              'Uscite Mese',
                              model.monthlyExpense,
                              Color(0xFFEF4444),
                              Icons.trending_down,
                              isDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 22),
              Consumer<MoneyModel>(
                builder: (context, model, _) {
                  final categories = model.mostUsedCategories.take(6).toList();
                  return LiquidGlassContainer(
                    borderRadius: 22,
                    padding: EdgeInsets.all(14),
                    thickness: 14,
                    blur: 7,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Aggiungi Veloce', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Color(0xFF1E293B))),
                        SizedBox(height: 14),
                        Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            for (final cat in categories) _quickChip(context, model, cat, isDark),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(height: 24),
              Consumer<MoneyModel>(
                builder: (context, model, _) {
                  final txs = model.recent.take(6).toList();
                  if (txs.isEmpty) {
                    return LiquidGlassCard(
                      borderRadius: 20,
                      child: Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Text('Nessuna transazione', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])))),
                    );
                  }
                  return Column(
                    children: txs.map((tx) => _txCard(tx, isDark)).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(BuildContext context, String label, double value, Color color, IconData icon, bool isDark) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w600)),
            Text(value.toStringAsFixed(2), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : color)),
          ]),
        ),
      ],
    );
  }

  Widget _quickChip(BuildContext context, MoneyModel model, String category, bool isDark) {
    final style = model.getTransactionStyle(category);
    final isIncome = model.incomeCats.contains(category);
    return GestureDetector(
      onTap: () { /* logica di aggiunta rapida */ },
      child: LiquidGlassButton(
        borderRadius: 18,
        thickness: 10,
        blur: 7,
        glassColor: style.color.withOpacity(0.35),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(style.icon, color: style.color, size: 21),
            SizedBox(width: 9),
            Text(category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : style.color.withOpacity(0.87))),
          ],
        ),
      ),
    );
  }

  Widget _txCard(tx, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: LiquidGlassCard(
        borderRadius: 18,
        thickness: 11,
        blur: 6,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [tx.categoryColor.withOpacity(0.92), tx.categoryColor.withOpacity(0.75)]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(tx.categoryIcon, color: Colors.white, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tx.category, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Color(0xFF1E293B))),
                  SizedBox(height: 4),
                  Text(tx.dateFormatted, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[500])),
                ],
              ),
            ),
            Text('${tx.isIncome ? '+' : '-'} ${tx.amountFormatted}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.isIncome ? Color(0xFF10B981) : Color(0xFFEF4444), fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
