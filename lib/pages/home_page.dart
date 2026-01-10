import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:ui';
import 'package:intl/intl.dart';

import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../models/models.dart';

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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final isCompact = size.width < 380;

    final wallet = context.watch<WalletProvider>();
    final categoryProvider = context.watch<CategoryProvider>();

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 12 : 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/images/moneyy_icon_home.png', fit: BoxFit.cover, errorBuilder: (c, o, s) => const Icon(Icons.account_balance_wallet)),
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
                    tooltip: 'Profilo',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(isCompact ? 12 : 20, 8, isCompact ? 12 : 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildNetWorthCardSWYPE(wallet, isDark, isCompact),
                    _buildGoalsSection(context, wallet, categoryProvider, isDark, isCompact),
                    SizedBox(height: isCompact ? 20 : 24),
                    _buildQuickAddGrid(context, wallet, categoryProvider, isDark, isCompact),
                    SizedBox(height: isCompact ? 20 : 28),
                    _buildRecentTransactions(wallet, categoryProvider, isDark, isCompact),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCardSWYPE(WalletProvider wallet, bool isDark, bool isCompact) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 340),
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A4D47), Color(0xFF2D7973)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Saldo Netto', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Text(wallet.format(wallet.netBalance), style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: -1.5, shadows: [Shadow(color: Colors.teal.shade300.withOpacity(0.3), blurRadius: 8)])),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection(BuildContext context, WalletProvider wallet, CategoryProvider catProvider, bool isDark, bool isCompact) {
    final activeGoals = wallet.goals.where((g) => g.progress < 100).toList();
    if (activeGoals.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: isCompact ? 20 : 24),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isCompact ? 0 : 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [const Icon(Icons.savings_outlined, color: Color(0xFF6366F1), size: 28), const SizedBox(width: 10), Text('I tuoi Obiettivi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)))]),
              if (activeGoals.length > 1) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text('${activeGoals.length} attivi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6366F1)))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: activeGoals.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final goal = activeGoals[index];
              return Padding(padding: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0), child: _buildHorizontalGoalCard(goal, wallet, catProvider, isDark));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalGoalCard(Goal goal, WalletProvider wallet, CategoryProvider catProvider, bool isDark) {
    final style = catProvider.getGoalStyle(goal.title);
    final iconaDaMostrare = goal.icon ?? style.icon;

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          _showAddMoneyToGoalDialog(context, goal, wallet, isDark);
        },
        borderRadius: BorderRadius.circular(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF6366F1).withOpacity(0.15) : const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 1.5)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Container(width: 48, height: 48, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: Center(child: Icon(iconaDaMostrare, color: Colors.white, size: 24))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(goal.title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis), const SizedBox(height: 4), Text('${wallet.format(goal.saved)} / ${wallet.format(goal.target)}', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[600], fontWeight: FontWeight.w500))])),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ClipRRect(borderRadius: BorderRadius.circular(6), child: LinearProgressIndicator(value: (goal.progress / 100).clamp(0.0, 1.0), minHeight: 8, backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white, valueColor: const AlwaysStoppedAnimation(Color(0xFF6366F1)))),
                    const SizedBox(height: 10),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text('${goal.progress.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)))),
                      Text('Mancano ${wallet.format(goal.target - goal.saved)}', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600])),
                    ]),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ✅ HELPER: RIMUOVE BORDI INTERNI (FIX RETTANGOLI)
  InputDecoration _noBorderDecoration(String label, IconData icon, bool isDark) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: isDark ? Colors.white70 : Colors.grey[600]),
      labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      isDense: true,
    );
  }

  // ✅ DIALOGO GLASS PER ADD MONEY
  void _showAddMoneyToGoalDialog(BuildContext context, Goal goal, WalletProvider wallet, bool isDark) {
    final controller = TextEditingController();
    final remaining = goal.target - goal.saved;

    showDialog(
      context: context,
      builder: (ctx) {
        // padding extra per la tastiera
        final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
        final bottomPadding = keyboardHeight > 0 ? keyboardHeight + 20 : 20.0;
        
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: EdgeInsets.only(left: 20, right: 20, bottom: bottomPadding),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Aggiungi a "${goal.title}"', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text('Mancano ${wallet.format(remaining)}', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14)),
                  const SizedBox(height: 24),
                  _buildGlassField(
                    isDark: isDark,
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                      decoration: _noBorderDecoration('Importo', Icons.euro, isDark),
                      autofocus: true,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(child: _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context))),
                    const SizedBox(width: 12),
                    Expanded(flex: 2, child: _buildGlassButton(isDark: isDark, label: 'Aggiungi', color: const Color(0xFF10B981), onTap: () async {
                      final amount = double.tryParse(controller.text.replaceAll(',', '.'));
                      if (amount == null || amount <= 0) return;
                      await wallet.addMoneyToGoal(goal, amount);
                      if (mounted) Navigator.pop(context);
                    })),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ✅ DIALOGO "AGGIUNTA VELOCE" RIDISEGNATO
  // - Icona della categoria al centro
  // - Nessun "triangolino" (Dialogo fluttuante staccato dai bordi)
  // - Sale sopra la tastiera
  void _showQuickEntryDialog(BuildContext context, String category, bool isIncome) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Recuperiamo stile categoria per l'icona
    final catProvider = context.read<CategoryProvider>();
    final style = catProvider.getTransactionStyle(category);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Trasparente per evitare "triangoli"
      builder: (ctx) {
        // Calcola spazio tastiera
        final keyboardHeight = MediaQuery.of(ctx).viewInsets.bottom;
        
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Padding(
            // Questo padding spinge tutto il box in alto sopra la tastiera
            padding: EdgeInsets.only(
              bottom: keyboardHeight + 20, // 20px sopra la tastiera
              left: 16,
              right: 16,
              top: 50 // Un po' di margine sopra
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end, // Spinge in basso (ma sopra la tastiera)
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(32), // Bordi molto arrotondati
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        offset: const Offset(0, 10)
                      )
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 1. Icona Categoria Grande
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [style.color, style.color.withOpacity(0.6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: style.color.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
                          ]
                        ),
                        child: Icon(style.icon, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      
                      // 2. Titolo
                      Text('Aggiungi a "$category"', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
                      const SizedBox(height: 24),
                      
                      // 3. Campo Importo
                      _buildGlassField(
                        isDark: isDark,
                        child: TextField(
                          controller: amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
                          decoration: _noBorderDecoration('Importo', Icons.euro, isDark),
                          autofocus: true // Apre subito la tastiera
                        )
                      ),
                      const SizedBox(height: 16),
                      
                      // 4. Campo Nota
                      _buildGlassField(
                        isDark: isDark,
                        child: TextField(
                          controller: noteCtrl,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                          decoration: _noBorderDecoration('Nota (Opzionale)', Icons.note, isDark)
                        )
                      ),
                      const SizedBox(height: 24),
                      
                      // 5. Pulsanti
                      Row(children: [
                        Expanded(child: _buildGlassButton(isDark: isDark, label: 'Annulla', color: Colors.grey, onTap: () => Navigator.pop(context))),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: _buildGlassButton(isDark: isDark, label: 'Aggiungi', color: const Color(0xFF10B981), onTap: () {
                          final v = double.tryParse(amountCtrl.text.replaceAll(',', '.'));
                          if (v != null && v > 0) {
                            final tx = MoneyTx(id: null, isIncome: isIncome, category: category, amount: v, date: DateTime.now(), note: noteCtrl.text.isEmpty ? null : noteCtrl.text, payment: PaymentMethod.contanti);
                            context.read<WalletProvider>().addTx(tx);
                            Navigator.pop(context);
                            HapticFeedback.heavyImpact();
                          }
                        })),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- HELPER GRAFICI CONDIVISI ---
  Widget _buildGlassField({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.transparent),
      ),
      child: child,
    );
  }

  Widget _buildGlassButton({required bool isDark, required String label, required Color color, required VoidCallback onTap, bool compact = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: compact ? 10 : 16, horizontal: compact ? 12 : 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.9), color.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildQuickAddGrid(BuildContext context, WalletProvider wallet, CategoryProvider catProvider, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(wallet, catProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [const Icon(Icons.flash_on, color: Color(0xFF38F9D7), size: 26), const SizedBox(width: 10), Text('Aggiunte Veloci', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B)))]),
        const SizedBox(height: 16),
        GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.85), itemCount: 6, itemBuilder: (context, index) { if (index >= mostUsed.length) { return _buildAddMoreButton(isDark); } final cat = mostUsed[index]; final style = catProvider.getTransactionStyle(cat); final isIncome = catProvider.allIncomeCats.contains(cat); final lastUsed = _getLastUsedDate(wallet, cat); return _buildQuickActionCard(context: context, icon: style.icon, label: cat, color: style.color, subtitle: lastUsed, isDark: isDark, onTap: () { HapticFeedback.mediumImpact(); _showQuickEntryDialog(context, cat, isIncome); }); }),
      ],
    );
  }

  Widget _buildQuickActionCard({required BuildContext context, required IconData icon, required String label, required Color color, required String subtitle, required bool isDark, required VoidCallback onTap}) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(16), child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [color, color.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 32), const SizedBox(height: 8), Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)), const SizedBox(height: 4), Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11))])));
  }

  Widget _buildAddMoreButton(bool isDark) {
    return Container(decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade400, width: 2)), child: Center(child: Icon(Icons.add, color: isDark ? Colors.white : Colors.grey.shade700, size: 36)));
  }

  Widget _buildRecentTransactions(WalletProvider wallet, CategoryProvider catProvider, bool isDark, bool isCompact) {
    final recent = wallet.recent.take(6).toList();
    if (recent.isEmpty) return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('Nessuna transazione', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]))));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Transazioni Recenti', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF1E293B))), const SizedBox(height: 12), ...recent.map((tx) => _buildTxCard(tx, wallet, catProvider, isDark, isCompact)).toList()]);
  }

  Widget _buildTxCard(MoneyTx tx, WalletProvider wallet, CategoryProvider catProvider, bool isDark, bool isCompact) {
    final style = catProvider.getTransactionStyle(tx.category);
    return Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1)), child: Row(children: [Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [style.color, style.color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)), child: Icon(style.icon, color: Colors.white, size: 24)), const SizedBox(width: 12),
    Expanded(
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ✅ MODIFICA QUI: Avvolgi il Text in una Row per aggiungere l'icona
      Row(
        children: [
          Text(
            tx.category,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          // Aggiungi l'icona se è ricorrente
          if (tx.isRecurring) ...[
            const SizedBox(width: 6),
            Icon(
              Icons.repeat,
              size: 14,
              color: isDark ? Colors.white60 : Colors.grey,
            ),
          ],
        ],
      ),
      const SizedBox(height: 4),
      Text(
        DateFormat('d MMM yyyy', 'it_IT').format(tx.date),
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
      ),
    ],
  ),
),
 Text('${tx.isIncome ? '+' : '-'} ${wallet.format(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 14))]));
  }

  String _getLastUsedDate(WalletProvider wallet, String category) {
    final txForCategory = wallet.transactions.where((tx) => tx.category == category).toList();
    if (txForCategory.isEmpty) return 'Mai usato';
    final mostRecent = txForCategory.first;
    final now = DateTime.now();
    final d = now.difference(mostRecent.date).inDays;
    if (d == 0) return 'Oggi';
    if (d == 1) return 'Ieri';
    if (d < 7) return '$d giorni fa';
    return DateFormat('d MMM', 'it_IT').format(mostRecent.date);
  }

  List<String> _getMostUsedCategories(WalletProvider wallet, CategoryProvider catProvider) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final recentTxs = wallet.transactions.where((tx) => tx.date.isAfter(lastMonth)).toList();
    final completedGoalTitles = wallet.goals.where((g) => g.progress >= 100).map((g) => g.title).toSet();
    final Map<String, int> count = {};
    for (final tx in recentTxs) { if (tx.category != 'Risparmio' && !catProvider.goalCategories.contains(tx.category) && !completedGoalTitles.contains(tx.category)) { count[tx.category] = (count[tx.category] ?? 0) + 1; } }
    final sorted = count.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final most = sorted.take(6).map((e) => e.key).toList();
    final defaults = ['Stipendio', 'Spesa', 'Trasporti', 'Svago', 'Shopping', 'Casa'];
    for (final d in defaults) { if (most.length < 6 && !most.contains(d) && d != 'Risparmio') { most.add(d); } }
    return most;
  }
}
