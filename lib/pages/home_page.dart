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
    return Scaffold(
      extendBodyBehindAppBar: true,
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
            const Text('Moneyy'),
          ],
        ),
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Consumer<MoneyModel>(
            builder: (context, model, child) {
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                child: Text(
                  model.format(model.netWorth),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
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
                colors: [
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
                padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildQuickStats(model),
                    const SizedBox(height: 24),
                    _buildCategoryBreakdown(context, model),
                    const SizedBox(height: 24),
                    _buildRecentTransactions(context, model),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          HapticFeedback.lightImpact();
          _showAddTransactionDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Nuova'),
        elevation: 6,
      ),
    );
  }

  Widget _buildQuickStats(MoneyModel model) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Entrate Mese',
                    model.format(model.monthlyIncome),
                    const Color(0xFF10B981),
                    Icons.trending_up,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildStatItem(
                    'Uscite Mese',
                    model.format(model.monthlyExpense),
                    const Color(0xFFEF4444),
                    Icons.trending_down,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // ✅ GRAFICA MIGLIORATA PER AGGIUNTE VELOCI
  Widget _buildCategoryBreakdown(BuildContext context, MoneyModel model) {
    final mostUsed = _getMostUsedCategories(model);
    final isDesktop = MediaQuery.of(context).size.width > 600;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.95),
            Colors.white.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flash_on, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Aggiungi Veloce',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up,
                      size: 14,
                      color: Color(0xFF6366F1),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Più usate',
                      style: TextStyle(
                        fontSize: 11,
                        color: const Color(0xFF6366F1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Layout responsivo
          isDesktop
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: mostUsed.length,
                  itemBuilder: (context, index) {
                    final cat = mostUsed[index];
                    final style = model.getTransactionStyle(cat);
                    final isIncome = model.incomeCats.contains(cat);
                    final lastUsed = _getLastUsedDate(model, cat);
                    return _buildCategoryChipEnhanced(cat, style.icon, style.color, isIncome, lastUsed, () {
                      _showQuickEntryDialog(context, cat, isIncome);
                    });
                  },
                )
              : Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: mostUsed.map((cat) {
                    final style = model.getTransactionStyle(cat);
                    final isIncome = model.incomeCats.contains(cat);
                    final lastUsed = _getLastUsedDate(model, cat);
                    return _buildCategoryChipEnhanced(cat, style.icon, style.color, isIncome, lastUsed, () {
                      _showQuickEntryDialog(context, cat, isIncome);
                    });
                  }).toList(),
                ),
        ],
      ),
    );
  }

  // ✅ NUOVO: Ottiene l'ultima data di utilizzo di una categoria
  String _getLastUsedDate(MoneyModel model, String category) {
    final txForCategory = model.transactions
        .where((tx) => tx.category == category)
        .toList();
    
    if (txForCategory.isEmpty) {
      return 'Mai utilizzato';
    }
    
    // Trova la transazione più recente
    final mostRecent = txForCategory.first; // già ordinati per data DESC
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

  // ✅ CHIP MIGLIORATO CON DATA
  Widget _buildCategoryChipEnhanced(String category, IconData icon, Color color, bool isIncome, String lastUsed, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.15),
                color.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: color.withOpacity(0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 8,
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
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // ✅ NUOVO: Mostra la data dell'ultimo utilizzo
                  Text(
                    lastUsed,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.7),
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
      final defaults = ['Spesa', 'Trasporti', 'Ristoranti', 'Shopping', 'Bollette', 'Casa'];
      for (var cat in defaults) {
        if (!mostUsed.contains(cat) && mostUsed.length < 6) {
          mostUsed.add(cat);
        }
      }
    }
    return mostUsed;
  }

  Widget _buildRecentTransactions(BuildContext context, MoneyModel model) {
    final recentTransactions = model.recent.take(8).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transazioni Recenti',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (recentTransactions.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (widget.onNavigate != null) {
                    widget.onNavigate!(2);
                  }
                },
                icon: const Icon(Icons.arrow_forward, size: 16),
                label: const Text('Tutte'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          _buildEmptyState()
        else
          ...recentTransactions.map((tx) => _buildTransactionCard(tx, model)).toList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.receipt_long, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Nessuna transazione',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Inizia aggiungendo la tua prima transazione',
              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(MoneyTx tx, MoneyModel model) {
    final style = model.getTransactionStyle(tx.category);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dismissible(
      key: Key(tx.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
              blurRadius: 10,
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
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [style.color, style.color.withOpacity(0.7)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: style.color.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(style.icon, color: Colors.white, size: 24),
                      ),
                      // ✅ NUOVO: Badge per transazioni ricorrenti
                      if (tx.isFromRecurring)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.repeat,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
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
                                  fontSize: 15,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            // ✅ NUOVO: Tag per transazioni ricorrenti
                            if (tx.isFromRecurring)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6366F1).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'AUTO',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF6366F1),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: isDark ? Colors.white60 : Colors.grey[500],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('d MMM yyyy • HH:mm', 'it_IT').format(tx.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.grey[600],
                              ),
                            ),
                            if (tx.note != null && tx.note!.isNotEmpty) ..[
                              const SizedBox(width: 8),
                              Icon(
                                Icons.note,
                                size: 12,
                                color: isDark ? Colors.white60 : Colors.grey[500],
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
                      Text(
                        '${tx.isIncome ? '+' : '-'} ${model.format(tx.amount)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tx.payment.name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: style.color,
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.edit, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text('Modifica Transazione'),
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
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: (isIncome ? model.incomeCats : model.expenseCats).map((cat) {
                    final style = model.getTransactionStyle(cat);
                    return DropdownMenuItem(
                      value: cat,
                      child: Row(
                        children: [
                          Icon(style.icon, color: style.color, size: 20),
                          const SizedBox(width: 8),
                          Text(cat),
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
                  decoration: const InputDecoration(
                    labelText: 'Importo (€)',
                    prefixIcon: Icon(Icons.euro),
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
                  decoration: const InputDecoration(
                    labelText: 'Metodo Pagamento',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPayment = value!),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nota (opzionale)',
                    prefixIcon: Icon(Icons.note),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTransactionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.add_circle, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            const Text('Nuova Transazione'),
          ],
        ),
        content: const Text('Che tipo di transazione vuoi aggiungere?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTxPage(initialIsIncome: false),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.remove_circle, size: 20),
                label: const Text('Uscita', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTxPage(initialIsIncome: true),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.add_circle, size: 20),
                label: const Text('Entrata', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showQuickEntryDialog(BuildContext context, String category, bool isIncome) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Aggiungi a "$category"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Importo',
                prefixIcon: Icon(Icons.euro),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Nota (Opzionale)',
                prefixIcon: Icon(Icons.note),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
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
