import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import '../models.dart';
import '../providers.dart';
import 'scan_receipt_page.dart';

class HomePage extends StatefulWidget {
  final Function(int, [bool?])? onNavigate;
  const HomePage({super.key, this.onNavigate});

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
    final padding = MediaQuery.of(context).padding;
    final navBarHeight = 72.0;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      floatingActionButton: _AdaptiveFab(
        bottomInset: padding.bottom,
        navBarHeight: navBarHeight,
        onPressed: _openScannerReceipt, // collegato allo scanner scontrini
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: const _HomeContent(),
    );
  }
}

class _AdaptiveFab extends StatelessWidget {
  final double bottomInset;
  final double navBarHeight;
  final VoidCallback onPressed;
  const _AdaptiveFab({required this.bottomInset, required this.navBarHeight, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final double bottomOffset = bottomInset + navBarHeight;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomOffset, right: 6),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF6366F1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.receipt_long, color: Colors.white, size: 28), // icona scontrino
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = context.watch<MoneyModel>();
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 380;

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isCompact ? 12 : 16, 14, isCompact ? 12 : 16, (MediaQuery.of(context).padding.bottom + 140)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLogoSection(isDark, isCompact),
            const SizedBox(height: 16),
            _buildNetWorthCard(model, isDark, isCompact),
            SizedBox(height: isCompact ? 18 : 22),
            _buildGlassStatsCard(model, isDark, isCompact),
            SizedBox(height: isCompact ? 18 : 22),
            _buildQuickAddSection(context, model, isDark, isCompact),
            SizedBox(height: isCompact ? 18 : 22),
            _buildGlassRecentTransactions(model, isDark, isCompact),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(bool isDark, bool isCompact) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 8 : 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isDark ? [Colors.white.withOpacity(0.08), Colors.white.withOpacity(0.03)] : [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.6)]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white.withOpacity(0.8), width: 1.5),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 32, height: 32, decoration: const BoxDecoration(shape: BoxShape.circle), clipBehavior: Clip.antiAlias, child: Image.asset('assets/images/moneyy_icon_home.png', fit: BoxFit.cover)),
              const SizedBox(width: 12),
              Text('Moneyy', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w700, fontSize: isCompact ? 18 : 22, letterSpacing: -0.5)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(MoneyModel model, bool isDark, bool isCompact) {
    final positive = model.netWorth >= 0;
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCompact ? 22 : 24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: isCompact ? 18 : 22, vertical: isCompact ? 12 : 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: isDark ? [(positive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.14), (positive ? const Color(0xFF059669) : const Color(0xFFDC2626)).withOpacity(0.08)] : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)]),
              borderRadius: BorderRadius.circular(isCompact ? 22 : 24),
              border: Border.all(color: isDark ? (positive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.28) : Colors.white.withOpacity(0.9), width: 1.8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(padding: EdgeInsets.all(isCompact ? 8 : 10), decoration: BoxDecoration(gradient: LinearGradient(colors: positive ? [const Color(0xFF10B981), const Color(0xFF059669)] : [const Color(0xFFEF4444), const Color(0xFFDC2626)]), borderRadius: BorderRadius.circular(isCompact ? 10 : 12)), child: Icon(positive ? Icons.trending_up : Icons.trending_down, color: Colors.white, size: isCompact ? 18 : 22)),
              SizedBox(width: isCompact ? 10 : 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('Saldo Netto', style: TextStyle(fontSize: isCompact ? 12 : 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[600])),
                SizedBox(height: isCompact ? 2 : 4),
                Text(model.format(model.netWorth), style: TextStyle(fontSize: isCompact ? 18 : 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : (positive ? const Color(0xFF10B981) : const Color(0xFFEF4444))))
              ])
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassStatsCard(MoneyModel model, bool isDark, bool isCompact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 20 : 22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 18 : 20),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.08) : Colors.white, borderRadius: BorderRadius.circular(isCompact ? 20 : 22), border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 1.2)),
          child: IntrinsicHeight(
            child: Row(children: [
              Expanded(child: _buildStatItem('Entrate Mese', model.format(model.monthlyIncome), const Color(0xFF10B981), Icons.trending_up, isDark, isCompact)),
              VerticalDivider(width: 24, thickness: 1, color: isDark ? Colors.white24 : Colors.grey.shade300),
              Expanded(child: _buildStatItem('Uscite Mese', model.format(model.monthlyExpense), const Color(0xFFEF4444), Icons.trending_down, isDark, isCompact)),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, bool isDark, bool isCompact) {
    return Row(children: [
      Container(padding: EdgeInsets.all(isCompact ? 10 : 12), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(isCompact ? 12 : 14)), child: Icon(icon, color: Colors.white, size: isCompact ? 18 : 20)),
      SizedBox(width: isCompact ? 10 : 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: isCompact ? 12 : 13, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: isCompact ? 18 : 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : color)),
      ])),
    ]);
  }

  Widget _buildQuickAddSection(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 20 : 22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 10 : 14),
          decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.06) : Colors.white, borderRadius: BorderRadius.circular(isCompact ? 20 : 22), border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 1.2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: EdgeInsets.all(isCompact ? 10 : 12), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]), borderRadius: BorderRadius.circular(isCompact ? 14 : 16)), child: const Icon(Icons.flash_on, color: Colors.white, size: 20)),
              SizedBox(width: isCompact ? 10 : 12),
              Expanded(child: Text('Aggiungi Veloce', style: TextStyle(fontSize: isCompact ? 20 : 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))))
            ]),
            SizedBox(height: isCompact ? 10 : 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: isCompact ? 12 : 14,
                mainAxisSpacing: isCompact ? 14 : 18,
                childAspectRatio: 2.0,
              ),
              itemCount: mostUsed.length,
              itemBuilder: (context, i) {
                final cat = mostUsed[i];
                final style = model.getTransactionStyle(cat);
                final isIncome = model.incomeCats.contains(cat);
                final lastUsed = _getLastUsedDate(model, cat);
                return _buildQuickChip(context, cat, style.icon, style.color, isIncome, lastUsed, isDark, isCompact);
              },
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildQuickChip(BuildContext context, String category, IconData icon, Color color, bool isIncome, String lastUsed, bool isDark, bool isCompact) {
    return InkWell(
      onTap: () { HapticFeedback.mediumImpact(); _showQuickEntryDialog(context, category, isIncome); },
      borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
      child: Container(
        height: isCompact ? 64 : 74,
        padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: isCompact ? 10 : 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
          color: isDark ? color.withOpacity(0.13) : color.withOpacity(0.10),
          border: Border.all(color: isDark ? color.withOpacity(0.35) : color.withOpacity(0.28), width: 1.1),
        ),
        child: Row(children: [
          Container(padding: EdgeInsets.all(isCompact ? 10 : 12), decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.95), color.withOpacity(0.75)]), borderRadius: BorderRadius.circular(isCompact ? 12 : 14)), child: Icon(icon, color: Colors.white, size: isCompact ? 22 : 24)),
          SizedBox(width: isCompact ? 10 : 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 14 : 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : color.withOpacity(0.9))),
            SizedBox(height: isCompact ? 3 : 4),
            Text(lastUsed, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 10.5 : 12, color: isDark ? Colors.white60 : color.withOpacity(0.57))),
          ]))
        ]),
      ),
    );
  }

  Widget _buildGlassRecentTransactions(MoneyModel model, bool isDark, bool isCompact) {
    final recent = model.recent.take(6).toList();
    if (recent.isEmpty) {
      return Center(child: Padding(padding: EdgeInsets.symmetric(vertical: isCompact ? 18 : 22), child: Text('Nessuna transazione', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]))));
    }
    return Column(children: recent.map((tx) => _buildTxCard(tx, model, isDark, isCompact)).toList());
  }

  Widget _buildTxCard(MoneyTx tx, MoneyModel model, bool isDark, bool isCompact) {
    final style = model.getTransactionStyle(tx.category);
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 12 : 14),
      padding: EdgeInsets.all(isCompact ? 14 : 16),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(isCompact ? 16 : 18), color: isDark ? Colors.white.withOpacity(0.06) : Colors.white, border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 1.1)),
      child: Row(children: [
        Container(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50, decoration: BoxDecoration(gradient: LinearGradient(colors: [style.color.withOpacity(0.92), style.color.withOpacity(0.75)]), borderRadius: BorderRadius.circular(isCompact ? 12 : 14)), child: Icon(style.icon, color: Colors.white, size: isCompact ? 22 : 24)),
        SizedBox(width: isCompact ? 10 : 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.category, style: TextStyle(fontSize: isCompact ? 13.5 : 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          const SizedBox(height: 4),
          Text(DateFormat('d MMM yyyy', 'it_IT').format(tx.date), style: TextStyle(fontSize: isCompact ? 10.5 : 11.5, color: isDark ? Colors.white60 : Colors.grey[500]))
        ])),
        Text('${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: isCompact ? 13.5 : 15))
      ]),
    );
  }

  String _getLastUsedDate(MoneyModel model, String category) {
    final txForCategory = model.transactions.where((tx) => tx.category == category).toList();
    if (txForCategory.isEmpty) return 'Mai usato';
    final mostRecent = txForCategory.first;
    final now = DateTime.now();
    final d = now.difference(mostRecent.date).inDays;
    if (d == 0) return 'Oggi';
    if (d == 1) return 'Ieri';
    if (d < 7) return '$d giorni fa';
    return DateFormat('d MMM', 'it_IT').format(mostRecent.date);
  }

  List<String> _getMostUsedCategories(MoneyModel model) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final recentTxs = model.transactions.where((tx) => tx.date.isAfter(lastMonth)).toList();
    final Map<String, int> count = {};
    for (final tx in recentTxs) { if (!model.goalCategories.contains(tx.category)) { count[tx.category] = (count[tx.category] ?? 0) + 1; } }
    final sorted = count.entries.toList()..sort((a,b)=>b.value.compareTo(a.value));
    final most = sorted.take(6).map((e)=>e.key).toList();
    final defaults = ['Spesa','Trasporti','Svago','Shopping','Bollette','Casa'];
    for (final d in defaults) { if (most.length<6 && !most.contains(d)) most.add(d); }
    return most;
  }

  void _showQuickEntryDialog(BuildContext context, String category, bool isIncome) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(context: context, builder: (context) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Aggiungi a "$category"', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B), fontWeight: FontWeight.w600)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Importo', prefixIcon: Icon(Icons.euro))),
        const SizedBox(height: 12),
        TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Nota (Opzionale)', prefixIcon: Icon(Icons.note))),
      ]),
      actions: [
        TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Annulla')),
        ElevatedButton(onPressed: () { final v = double.tryParse(amountCtrl.text); if (v!=null && v>0) { final tx = MoneyTx(id:null,isIncome:isIncome,category:category,amount:v,date:DateTime.now(),note: noteCtrl.text.isEmpty? null: noteCtrl.text,payment: PaymentMethod.contanti); context.read<MoneyModel>().addTx(tx); Navigator.pop(context); HapticFeedback.heavyImpact(); } }, child: const Text('Aggiungi')),
      ],
    ));
  }
}
