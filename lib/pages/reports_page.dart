import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models.dart';
import '../providers.dart';

enum PeriodType { giorno, settimana, mese, anno }
enum ChartMode { overview, income, expense }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  PeriodType selectedPeriod = PeriodType.mese;
  ChartMode chartMode = ChartMode.overview;
  DateTime selectedDate = DateTime.now();

  // ✅ FIX: Navigazione bloccata al passato
  void _navigatePrevious() {
    setState(() {
      switch (selectedPeriod) {
        case PeriodType.giorno:
          selectedDate = selectedDate.subtract(const Duration(days: 1));
          break;
        case PeriodType.settimana:
          selectedDate = selectedDate.subtract(const Duration(days: 7));
          break;
        case PeriodType.mese:
          selectedDate = DateTime(selectedDate.year, selectedDate.month - 1, 1);
          break;
        case PeriodType.anno:
          selectedDate = DateTime(selectedDate.year - 1, 1, 1);
          break;
      }
    });
  }

  // ✅ FIX: Non può andare oltre oggi
  void _navigateNext() {
    setState(() {
      DateTime newDate;
      final now = DateTime.now();
      
      switch (selectedPeriod) {
        case PeriodType.giorno:
          newDate = selectedDate.add(const Duration(days: 1));
          if (newDate.isAfter(now)) return;
          selectedDate = newDate;
          break;
        case PeriodType.settimana:
          newDate = selectedDate.add(const Duration(days: 7));
          if (newDate.isAfter(now)) return;
          selectedDate = newDate;
          break;
        case PeriodType.mese:
          newDate = DateTime(selectedDate.year, selectedDate.month + 1, 1);
          if (newDate.isAfter(now)) return;
          selectedDate = newDate;
          break;
        case PeriodType.anno:
          newDate = DateTime(selectedDate.year + 1, 1, 1);
          if (newDate.isAfter(now)) return;
          selectedDate = newDate;
          break;
      }
    });
  }

  // ✅ FIX: DatePicker non può selezionare futuro
  Future<void> _pickPeriod() async {
    switch (selectedPeriod) {
      case PeriodType.giorno:
      case PeriodType.settimana:
      case PeriodType.mese:
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
          locale: const Locale('it', 'IT'),
        );
        if (picked != null) {
          setState(() => selectedDate = picked);
        }
        break;
      case PeriodType.anno:
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Seleziona Anno'),
            content: SizedBox(
              width: 300,
              height: 300,
              child: YearPicker(
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                selectedDate: selectedDate,
                onChanged: (date) {
                  setState(() => selectedDate = DateTime(date.year, 1, 1));
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = Provider.of<MoneyModel>(context);
    
    if (model.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredTransactions = _getFilteredTransactions(model);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Report Finanziario'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPeriodSelector(isDarkMode),
            _buildPeriodNavigator(isDarkMode),
            _buildChartSection(filteredTransactions, model, isDarkMode),
            _buildTransactionsList(filteredTransactions, model, isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodNavigator(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _navigatePrevious,
            iconSize: 28,
          ),
          const SizedBox(width: 16),
          InkWell(
            onTap: _pickPeriod,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getSelectedPeriodText(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF10B981)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _navigateNext,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: PeriodType.values.map((period) {
          final isSelected = selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  selectedPeriod = period;
                  selectedDate = DateTime.now();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getPeriodName(period),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChartSection(List<MoneyTx> transactions, MoneyModel model, bool isDarkMode) {
    final totalIncome = transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final netBalance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (totalIncome + totalExpense > 0) ...[
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 4,
                  centerSpaceRadius: 60,
                  sections: [
                    if (totalIncome > 0)
                      PieChartSectionData(
                        color: Colors.green.shade600,
                        value: totalIncome,
                        title: '${((totalIncome / (totalIncome + totalExpense)) * 100).toInt()}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    if (totalExpense > 0)
                      PieChartSectionData(
                        color: Colors.red.shade600,
                        value: totalExpense,
                        title: '${((totalExpense / (totalIncome + totalExpense)) * 100).toInt()}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalCard('Entrate', totalIncome, Colors.green.shade600, model, Icons.arrow_upward),
                _buildTotalCard('Uscite', totalExpense, Colors.red.shade600, model, Icons.arrow_downward),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: netBalance >= 0
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Saldo Netto', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                  Text(model.format(netBalance.abs()), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pie_chart_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text('Nessuna transazione nel periodo', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double amount, Color color, MoneyModel model, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(model.format(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<MoneyTx> transactions, MoneyModel model, bool isDarkMode) {
    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.receipt_long_rounded, size: 64, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.4)),
              const SizedBox(height: 16),
              Text('Nessuna transazione trovata', style: TextStyle(fontSize: 16, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6))),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Transazioni (${transactions.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (transactions.isNotEmpty)
                  Text('Swipe ← per eliminare', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final tx = transactions[index];
              final style = model.getTransactionStyle(tx.category);
              final isRecurring = tx.note?.startsWith('🔁') ?? false;

              return Dismissible(
                key: Key('${tx.id}_${tx.date.millisecondsSinceEpoch}'),
                direction: isRecurring ? DismissDirection.none : DismissDirection.endToStart,
                background: Container(
                  margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: index == 0 ? 0 : 8,
                    bottom: index == transactions.length - 1 ? 16 : 8,
                  ),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                confirmDismiss: (direction) async {
                  if (isRecurring) return false;
                  return await showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Elimina Transazione'),
                      content: const Text('Sei sicuro di voler eliminare questa transazione?'),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annulla')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: const Text('Elimina'),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  model.deleteTransaction(tx.id!);
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
                  margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: index == 0 ? 0 : 8,
                    bottom: index == transactions.length - 1 ? 16 : 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isRecurring
                          ? const Color(0xFF6366F1).withOpacity(0.5)
                          : Theme.of(context).dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (isRecurring)
                        Container(
                          margin: const EdgeInsets.only(right: 12),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.repeat, color: Color(0xFF6366F1), size: 16),
                        ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: style.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(style.icon, color: style.color, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.category, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Theme.of(context).textTheme.bodyLarge?.color)),
                            const SizedBox(height: 4),
                            Text(
                              tx.note ?? DateFormat('d MMMM yyyy', 'it_IT').format(tx.date),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6), fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                              color: tx.isIncome ? Colors.green.shade700 : Colors.red.shade700,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('HH:mm', 'it_IT').format(tx.date),
                            style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5), fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getPeriodName(PeriodType period) {
    switch (period) {
      case PeriodType.giorno: return 'Giorno';
      case PeriodType.settimana: return 'Settimana';
      case PeriodType.mese: return 'Mese';
      case PeriodType.anno: return 'Anno';
    }
  }

  String _getSelectedPeriodText() {
    switch (selectedPeriod) {
      case PeriodType.giorno:
        return DateFormat('d MMMM yyyy', 'it_IT').format(selectedDate);
      case PeriodType.settimana:
        final startOfWeek = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        return '${DateFormat('d', 'it_IT').format(startOfWeek)}-${DateFormat('d MMMM', 'it_IT').format(endOfWeek)}';
      case PeriodType.mese:
        return DateFormat('MMMM yyyy', 'it_IT').format(selectedDate);
      case PeriodType.anno:
        return DateFormat('yyyy', 'it_IT').format(selectedDate);
    }
  }

  // ✅ INCLUDI RICORRENTI
  List<MoneyTx> _getFilteredTransactions(MoneyModel model) {
    DateTime start, end;
    
    switch (selectedPeriod) {
      case PeriodType.giorno:
        start = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        end = start.add(const Duration(days: 1));
        break;
      case PeriodType.settimana:
        start = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
        end = start.add(const Duration(days: 7));
        break;
      case PeriodType.mese:
        start = DateTime(selectedDate.year, selectedDate.month, 1);
        end = DateTime(selectedDate.year, selectedDate.month + 1, 1);
        break;
      case PeriodType.anno:
        start = DateTime(selectedDate.year, 1, 1);
        end = DateTime(selectedDate.year + 1, 1, 1);
        break;
    }

    final normalTxs = model.transactions.where((tx) {
      return tx.date.isAfter(start.subtract(const Duration(milliseconds: 1))) && tx.date.isBefore(end);
    }).toList();
    
    final recurringTxs = model.getRecurringTransactionsForPeriod(start, end);
    
    final allTxs = [...normalTxs, ...recurringTxs];
    allTxs.sort((a, b) => b.date.compareTo(a.date));
    
    return allTxs;
  }
}
