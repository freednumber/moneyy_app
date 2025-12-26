import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../providers.dart';
import '../widgets/goal_card.dart';
import 'scan_receipt_page.dart';

class HomePage extends StatefulWidget {
  final Function(int, [bool?])? onNavigate;
  final ScrollController? scrollController;

  const HomePage({super.key, this.onNavigate, this.scrollController});

  @override
  State createState() => _HomePageState();
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

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Header
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
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset('assets/images/moneyy_icon_home.png', fit: BoxFit.cover),
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
                    onPressed: () {
                      // TODO: implement profile page
                    },
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  isCompact ? 12 : 20,
                  8,
                  isCompact ? 12 : 20,
                  100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildNetWorthCardSWYPE(model, isDark, isCompact),
                    ),
                    
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildGoalsSection(context, model, isDark, isCompact),
                    ),
                    
                    SizedBox(height: isCompact ? 20 : 24),
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildQuickAddGrid(context, model, isDark, isCompact),
                    ),
                    SizedBox(height: isCompact ? 20 : 28),
                    Consumer<MoneyModel>(
                      builder: (context, model, _) => _buildRecentTransactions(model, isDark, isCompact),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNetWorthCardSWYPE(MoneyModel model, bool isDark, bool isCompact) {
    return Center(
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxWidth: 340),
        padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A4D47), Color(0xFF2D7973)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Saldo Netto',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Text(
              model.format(model.netBalance),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: -1.5,
                shadows: [
                  Shadow(
                    color: Colors.teal.shade300.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🐷 SEZIONE OBIETTIVI - ICONA SALVADANAIO
  Widget _buildGoalsSection(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final activeGoals = model.goals.where((g) => g.progress < 100).toList();
    
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
              Row(
                children: [
                  // 🐷 SALVADANAIO OUTLINED
                  Icon(Icons.savings_outlined, color: Color(0xFF6366F1), size: 28),
                  SizedBox(width: 10),
                  Text(
                    'I tuoi Obiettivi',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              if (activeGoals.length > 1)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeGoals.length} attivi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6366F1),
                    ),
                  ),
                ),
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
              return Padding(
                padding: EdgeInsets.only(right: 12, left: index == 0 ? 0 : 0),
                child: _buildHorizontalGoalCard(goal, model, isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalGoalCard(Goal goal, MoneyModel model, bool isDark) {
    final style = model.getGoalStyle(goal.title);
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        _showGoalOptionsDialog(goal, model, isDark);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              style.color.withOpacity(0.15),
              style.color.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: style.color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: style.color.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [style.color, style.color.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: style.color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(style.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${model.format(goal.saved)} / ${model.format(goal.target)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: goal.progress / 100,
                    minHeight: 10,
                    backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(style.color),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: style.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${goal.progress.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : style.color,
                        ),
                      ),
                    ),
                    Text(
                      'Mancano ${model.format(goal.target - goal.saved)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showGoalOptionsDialog(Goal goal, MoneyModel model, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          goal.title,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obiettivo di risparmio',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '€ ${goal.saved.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                  ),
                ),
                Text(
                  ' / € ${goal.target.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: goal.progress / 100,
              minHeight: 6,
              backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
            const SizedBox(height: 8),
            Text(
              '${goal.progress.toStringAsFixed(1)}% completato',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.grey[700],
                fontSize: 13,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showAddMoneyDialog(context, goal, model);
            },
            child: const Text('Aggiungi Denaro'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showEditGoalDialog(context, goal, model);
            },
            child: const Text('Modifica'),
          ),
        ],
      ),
    );
  }

  // 🐷 AGGIUNTE VELOCI - ESCLUDI RISPARMIO E OBIETTIVI COMPLETATI
  Widget _buildQuickAddGrid(BuildContext context, MoneyModel model, bool isDark, bool isCompact) {
    final mostUsed = _getMostUsedCategories(model);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flash_on, color: Color(0xFF38F9D7), size: 26),
            SizedBox(width: 10),
            Text(
              'Aggiunte Veloci',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.85,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            if (index >= mostUsed.length) {
              return _buildAddMoreButton(isDark);
            }
            final cat = mostUsed[index];
            final style = model.getTransactionStyle(cat);
            final isIncome = model.incomeCats.contains(cat);
            final lastUsed = _getLastUsedDate(model, cat);
            return _buildQuickActionCard(
              context: context,
              icon: style.icon,
              label: cat,
              color: style.color,
              subtitle: lastUsed,
              isDark: isDark,
              onTap: () {
                HapticFeedback.mediumImpact();
                _showQuickEntryDialog(context, cat, isIncome);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMoreButton(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.2) : Colors.grey.shade400,
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.add,
          color: isDark ? Colors.white : Colors.grey.shade700,
          size: 36,
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(MoneyModel model, bool isDark, bool isCompact) {
    final recent = model.recent.take(6).toList();
    if (recent.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'Nessuna transazione',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[600]),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transazioni Recenti',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 12),
        ...recent.map((tx) => _buildTxCard(tx, model, isDark, isCompact)).toList(),
      ],
    );
  }

  Widget _buildTxCard(MoneyTx tx, MoneyModel model, bool isDark, bool isCompact) {
    final style = model.getTransactionStyle(tx.category);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [style.color, style.color.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(style.icon, color: Colors.white, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  DateFormat('d MMM yyyy', 'it_IT').format(tx.date),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: tx.isIncome ? Color(0xFF10B981) : Color(0xFFEF4444),
              fontSize: 14,
            ),
          ),
        ],
      ),
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

  // 🐛 FIX: Escludi "Risparmio" + categorie obiettivi + obiettivi COMPLETATI
  List<String> _getMostUsedCategories(MoneyModel model) {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, now.day);
    final recentTxs = model.transactions.where((tx) => tx.date.isAfter(lastMonth)).toList();
    
    final completedGoalTitles = model.goals
        .where((g) => g.progress >= 100)
        .map((g) => g.title)
        .toSet();
    
    final Map<String, int> count = {};
    for (final tx in recentTxs) {
      if (tx.category != 'Risparmio' &&
          !model.goalCategories.contains(tx.category) &&
          !completedGoalTitles.contains(tx.category)) {
        count[tx.category] = (count[tx.category] ?? 0) + 1;
      }
    }
    
    final sorted = count.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final most = sorted.take(6).map((e) => e.key).toList();
    
    final defaults = ['Stipendio', 'Spesa', 'Trasporti', 'Svago', 'Shopping', 'Casa'];
    for (final d in defaults) {
      if (most.length < 6 && !most.contains(d) && d != 'Risparmio') {
        most.add(d);
      }
    }
    
    return most;
  }

  void _showQuickEntryDialog(BuildContext context, String category, bool isIncome) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Aggiungi a "$category"',
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Importo',
                  prefixIcon: Icon(Icons.euro),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nota (Opzionale)',
                  prefixIcon: Icon(Icons.note),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Annulla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final v = double.tryParse(amountCtrl.text);
                        if (v != null && v > 0) {
                          final tx = MoneyTx(
                            id: null,
                            isIncome: isIncome,
                            category: category,
                            amount: v,
                            date: DateTime.now(),
                            note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                            payment: PaymentMethod.contanti,
                          );
                          context.read<MoneyModel>().addTx(tx);
                          Navigator.pop(context);
                          HapticFeedback.heavyImpact();
                        }
                      },
                      child: const Text('Aggiungi'),
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

  void _showAddMoneyDialog(BuildContext context, Goal goal, MoneyModel model) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final remaining = goal.target - goal.saved;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Aggiungi a "${goal.title}"',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mancano ancora €${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                color: Color(0xFF6366F1),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: 'Importo (max €${remaining.toStringAsFixed(2)})',
                prefixText: '€ ',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⚠️ Inserisci un importo valido'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              if (amount > remaining) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⚠️ Puoi aggiungere max €${remaining.toStringAsFixed(2)}'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              
              await model.addMoneyToGoal(goal, amount);
              if (context.mounted) {
                Navigator.pop(context);
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('€${amount.toStringAsFixed(2)} aggiunti a ${goal.title}!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Aggiungi'),
          ),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, Goal goal, MoneyModel model) {
    final nameController = TextEditingController(text: goal.title);
    final targetController = TextEditingController(text: goal.target.toString());
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        title: Text(
          'Modifica Obiettivo',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Nome obiettivo',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Importo target',
                  prefixText: '€ ',
                  labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Elimina Obiettivo'),
                  content: Text('Vuoi eliminare "${goal.title}"?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Annulla'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Elimina'),
                    ),
                  ],
                ),
              );
              if (confirm == true && goal.id != null) {
                await model.deleteGoal(goal.id!);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Obiettivo eliminato')),
                  );
                }
              }
            },
            child: const Text('Elimina', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final target = double.tryParse(targetController.text);
              
              if (name.isNotEmpty && target != null && target > 0) {
                final updatedGoal = goal.copyWith(
                  title: name,
                  target: target,
                );
                await model.updateGoal(updatedGoal);
                if (context.mounted) {
                  Navigator.pop(context);
                  HapticFeedback.mediumImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Obiettivo aggiornato!'),
                      backgroundColor: Color(0xFF10B981),
                    ),
                  );
                }
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }
}
