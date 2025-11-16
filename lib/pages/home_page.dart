import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui'; // Per ImageFilter
import '../models.dart';
import '../providers.dart';

// 1. DEFINIAMO LA CLASSE 'HomePage' CHE MANCAVA
class HomePage extends StatefulWidget {
  final Function(int, [bool?]) onNavigate;
  const HomePage({Key? key, required this.onNavigate}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

// 2. CREIAMO LA CLASSE '_HomePageState'
class _HomePageState extends State<HomePage> {
  
  // Questo è il metodo build() che costruisce l'interfaccia
  @override
  Widget build(BuildContext context) {
    final model = context.watch<MoneyModel>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Usiamo size.height per 'isCompact', non size.width
    final isCompact = MediaQuery.of(context).size.height < 800;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          pinned: true,
          floating: false, // Meglio false per questo stile
          expandedHeight: 120.0,
          backgroundColor: Colors.transparent, // Reso trasparente
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: isCompact ? 12 : 14,
            ),
            centerTitle: true,
            title: _buildLogoSection(isDark, isCompact),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                icon: Icon(Icons.settings_rounded, color: isDark ? Colors.white70 : Colors.black87),
                onPressed: () => widget.onNavigate(3), // Indice 3 per Impostazioni
                tooltip: 'Impostazioni',
              ),
            ),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 120), // Padding per il dock
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildNetWorthCard(model, isDark, isCompact),
              const SizedBox(height: 24),
              _buildGlassStatsCard(model, isDark, isCompact),
              const SizedBox(height: 32),
              Text(
                'Aggiunte Veloci',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
              ),
              const SizedBox(height: 16),
              _buildQuickAddGrid(context, model, isDark, isCompact), // QUESTA È LA GRIGLIA 2x3
              const SizedBox(height: 32),
              Text(
                'Transazioni Recenti',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
              ),
              const SizedBox(height: 16),
              _buildGlassRecentTransactions(context, model, isDark, isCompact),
            ]),
          ),
        ),
      ],
    );
  }

  // --- 3. TUTTI I METODI HELPER SPOSTATI QUI DENTRO ---

  Widget _buildLogoSection(bool isDark, bool isCompact) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 12 : 16,
            vertical: isCompact ? 8 : 10,
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
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(shape: BoxShape.circle),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/moneyy_icon_home.png',
                  fit: BoxFit.cover,
                ),
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
        ),
      ),
    );
  }

  Widget _buildNetWorthCard(MoneyModel model, bool isDark, bool isCompact) {
    final isPositive = model.netWorth >= 0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 20 : 28,
            vertical: isCompact ? 16 : 20,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                      (isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626)).withOpacity(0.08),
                    ]
                  : [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.8)],
            ),
            borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
            border: Border.all(
              color: isDark
                  ? (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3)
                  : Colors.white.withOpacity(0.9),
              width: 2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isPositive
                        ? [const Color(0xFF10B981), const Color(0xFF059669)]
                        : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 14),
                ),
                child: Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: Colors.white,
                  size: isCompact ? 20 : 24,
                ),
              ),
              SizedBox(width: isCompact ? 12 : 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Saldo Netto', style: TextStyle(fontSize: isCompact ? 12 : 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : Colors.grey[600])),
                  SizedBox(height: isCompact ? 2 : 4),
                  Text(
                    model.format(model.netWorth),
                    style: TextStyle(
                      fontSize: isCompact ? 20 : 26,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
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

  Widget _buildGlassStatsCard(MoneyModel model, bool isDark, bool isCompact) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 24 : 28),
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 1.5),
      ),
      padding: EdgeInsets.all(isCompact ? 20 : 24),
      child: Row(
        children: [
          Expanded(child: _buildStatItem('Entrate Mese', model.format(model.monthlyIncome), const Color(0xFF10B981), Icons.trending_up, isDark, isCompact)),
          Container(width: 1, height: isCompact ? 50 : 60, color: isDark ? Colors.white12 : Colors.grey.shade300),
          Expanded(child: _buildStatItem('Uscite Mese', model.format(model.monthlyExpense), const Color(0xFFEF4444), Icons.trending_down, isDark, isCompact)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, bool isDark, bool isCompact) {
    return Column(
      children: [
        Icon(icon, color: isDark ? color.withOpacity(0.9) : color, size: isCompact ? 24 : 28),
        const SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: isCompact ? 12 : 13, color: isDark ? Colors.grey[300] : Colors.grey[600], fontWeight: FontWeight.w500)),
        const SizedBox(height: 2),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, style: TextStyle(fontSize: isCompact ? 16 : 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : color))),
      ],
    );
  }

  Widget _buildQuickAddGrid(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: isCompact ? 12 : 16,
        mainAxisSpacing: isCompact ? 12 : 16,
        childAspectRatio: 2.8, // Questo determina la forma
      ),
      itemCount: mostUsed.length,
      itemBuilder: (context, i) {
        final cat = mostUsed[i];
        final style = model.getTransactionStyle(cat);
        final isIncome = model.incomeCats.contains(cat);
        final lastUsed = _getLastUsedDate(model, cat);
        return _buildGlassCategoryChip(cat, style.icon, style.color, isIncome, lastUsed, isDark, isCompact, () => _showQuickEntryDialog(context, cat, isIncome));
      },
    );
  }

  Widget _buildGlassCategoryChip(String category, IconData icon, Color color, bool isIncome, String lastUsed, bool isDark, bool isCompact, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () { HapticFeedback.mediumImpact(); onTap(); },
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        child: Container(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
            color: isDark ? color.withOpacity(0.12) : color.withOpacity(0.1),
            border: Border.all(color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.3), width: 1.2),
          ),
          child: Row(children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 8 : 10),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(isCompact ? 10 : 12)),
              child: Icon(icon, color: Colors.white, size: isCompact ? 16 : 18),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(category, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 12 : 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : color.withOpacity(0.9))),
              SizedBox(height: isCompact ? 2 : 4),
              Text(lastUsed, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isCompact ? 9 : 10, color: isDark ? Colors.white60 : color.withOpacity(0.6))),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildGlassRecentTransactions(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final recent = model.recent.take(6).toList();
    if (recent.isEmpty) {
      return Center(child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Text('Nessuna transazione', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600])),
      ));
    }
    return Column(children: recent.map((tx) => _buildGlassTransactionCard(tx, model, isDark, isCompact)).toList());
  }

  Widget _buildGlassTransactionCard(MoneyTx tx, MoneyModel model, bool isDark, bool isCompact) {
    final style = model.getTransactionStyle(tx.category);
    return Container(
      margin: EdgeInsets.only(bottom: isCompact ? 12 : 16),
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(isCompact ? 18 : 20),
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        border: Border.all(color: isDark ? Colors.white12 : Colors.white, width: 1.2),
      ),
      child: Row(children: [
        Container(
          width: isCompact ? 48 : 56,
          height: isCompact ? 48 : 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [style.color.withOpacity(0.9), style.color.withOpacity(0.7)]),
            borderRadius: BorderRadius.circular(isCompact ? 14 : 16),
          ),
          child: Icon(style.icon, color: Colors.white, size: isCompact ? 24 : 28),
        ),
        SizedBox(width: isCompact ? 12 : 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tx.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: isCompact ? 14 : 16, color: isDark ? Colors.white : const Color(0xFF1E293B))),
          SizedBox(height: 4),
          Text(DateFormat('d MMM yyyy', 'it_IT').format(tx.date), style: TextStyle(fontSize: isCompact ? 11 : 12, color: isDark ? Colors.white60 : Colors.grey[500])),
        ])),
        Text('${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444)))
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
    for (final tx in recentTxs) {
      if (!model.goalCategories.contains(tx.category)) {
        count[tx.category] = (count[tx.category] ?? 0) + 1;
      }
    }
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
          TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('Annulla')),
          ElevatedButton(onPressed: () { final v = double.tryParse(amountCtrl.text); if (v!=null && v>0) { final tx = MoneyTx(id:null,isIncome:isIncome,category:category,amount:v,date:DateTime.now(),note: noteCtrl.text.isEmpty? null: noteCtrl.text,payment: PaymentMethod.contanti); context.read<MoneyModel>().addTx(tx); Navigator.pop(context); HapticFeedback.heavyImpact(); } }, child: const Text('Aggiungi')),
        ],
      ),
    );
  }
}
