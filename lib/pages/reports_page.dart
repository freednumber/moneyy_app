import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late ValueNotifier<PeriodType> _periodNotifier;

  @override
  void initState() {
    super.initState();
    _periodNotifier = ValueNotifier(selectedPeriod);
  }

  @override
  void dispose() {
    _periodNotifier.dispose();
    super.dispose();
  }

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

  Future<void> _pickPeriod() async {
    switch (selectedPeriod) {
      case PeriodType.giorno:
        await _showDayPicker();
        break;
      case PeriodType.settimana:
        await _showWeekPicker();
        break;
      case PeriodType.mese:
        await _showMonthPicker();
        break;
      case PeriodType.anno:
        await _showYearPicker();
        break;
    }
  }

  static const _sliderDuration = Duration(milliseconds: 300);

  Future<void> _showDayPicker() async {
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
  }

  Future<void> _showYearPicker() async {
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
  }

  Future<void> _showMonthPicker() async {
    final now = DateTime.now();
    DateTime cursor = DateTime(now.year, now.month, 1);
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final months = List.generate(36, (i) => DateTime(cursor.year, cursor.month - i, 1));
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seleziona mese', style: TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: months.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = months[index];
                    final label = DateFormat('MMMM yyyy', 'it_IT').format(m);
                    return ListTile(
                      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selectedDate = m);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showWeekPicker() async {
    DateTime startOfWeek(DateTime d) => d.subtract(Duration(days: d.weekday - 1));
    final start = startOfWeek(DateTime.now());
    final weeks = List.generate(52, (i) => start.subtract(Duration(days: 7 * i)));
    await showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Theme.of(context).dialogBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Seleziona settimana', style: TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: weeks.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final wStart = weeks[index];
                    final wEnd = wStart.add(const Duration(days: 6));
                    final label = '${DateFormat('d MMM', 'it_IT').format(wStart)} - ${DateFormat('d MMM yyyy', 'it_IT').format(wEnd)}';
                    return ListTile(
                      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => selectedDate = wStart);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final model = Provider.of<MoneyModel>(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    if (model.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredTransactions = _getFilteredTransactions(model);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Report Finanziario',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
        backgroundColor: isDarkMode ? const Color(0xFF1E293B) : Colors.white,
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

  Widget _buildPeriodSelector(bool isDarkMode) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontal = 16.0;
    final itemWidth = (screenWidth - horizontal * 2) / 4;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900]!.withOpacity(0.9) : Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            ValueListenableBuilder<PeriodType>(
              valueListenable: _periodNotifier,
              builder: (context, period, _) {
                final idx = PeriodType.values.indexOf(period);
                return AnimatedPositioned(
                  duration: _sliderDuration,
                  curve: Curves.easeInOut,
                  left: 8 + idx * itemWidth,
                  top: 4,
                  child: Container(
                    width: itemWidth - 16,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF6366F1).withOpacity(0.3),
                        width: 1.2,
                      ),
                    ),
                  ),
                );
              },
            ),
            Row(
              children: PeriodType.values.map((period) {
                final isSelected = selectedPeriod == period;
                return Expanded(
                  child: InkResponse(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        selectedPeriod = period;
                        if (period == PeriodType.settimana) {
                          final d = DateTime.now();
                          selectedDate = d.subtract(Duration(days: d.weekday - 1));
                        } else if (period == PeriodType.mese) {
                          final d = DateTime.now();
                          selectedDate = DateTime(d.year, d.month, 1);
                        } else {
                          selectedDate = DateTime.now();
                        }
                        _periodNotifier.value = period;
                      });
                    },
                    radius: 28,
                    splashColor: const Color(0xFF6366F1).withOpacity(0.1),
                    highlightColor: Colors.transparent,
                    containedInkWell: true,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                        child: Text(
                          _getPeriodName(period),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected ? const Color(0xFF6366F1) : isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 13,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
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
            icon: Icon(Icons.chevron_left, color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
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
                color: isDarkMode ? const Color(0xFF10B981).withOpacity(0.15) : const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getSelectedPeriodText(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDarkMode ? const Color(0xFF34D399) : const Color(0xFF10B981),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.chevron_right, color: isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            onPressed: _navigateNext,
            iconSize: 28,
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<MoneyTx> transactions, MoneyModel model, bool isDarkMode) {
    final totalIncome = transactions.where((tx) => tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final totalExpense = transactions.where((tx) => !tx.isIncome).fold(0.0, (sum, tx) => sum + tx.amount);
    final netBalance = totalIncome - totalExpense;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]!.withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
              children: [
                Expanded(
                  child: _buildTotalCard('Entrate', totalIncome, Colors.green.shade600, model, Icons.arrow_upward, isDarkMode),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTotalCard('Uscite', totalExpense, Colors.red.shade600, model, Icons.arrow_downward, isDarkMode),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: netBalance >= 0
                      ? [const Color(0xFF10B981), const Color(0xFF059669)]
                      : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (netBalance >= 0 ? Colors.green : Colors.red).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Saldo Netto',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    model.format(netBalance.abs()),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
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
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: isDarkMode ? Colors.grey[600] : Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nessuna transazione nel periodo',
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalCard(String label, double amount, Color color, MoneyModel model, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? color.withOpacity(0.4) : color.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(isDark ? 0.2 : 0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: isDark ? color.withOpacity(0.9) : color, size: 28),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            model.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<MoneyTx> transactions, MoneyModel model, bool isDarkMode) {
    if (transactions.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900]!.withOpacity(0.6) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.receipt_long_rounded,
                size: 64,
                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Nessuna transazione trovata',
                style: TextStyle(
                  fontSize: 16,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900]!.withOpacity(0.8) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transazioni (${transactions.length})',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    letterSpacing: 0.2,
                  ),
                ),
                if (transactions.isNotEmpty)
                  Text(
                    'Swipe ← elimina',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                    ),
                  ),
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
              final isRecurring = tx.isFromRecurring ?? false;
              final isGoalSaving = tx.category == 'Risparmio' && tx.note != null && tx.note!.contains('Aggiunto a obiettivo:');

              return Dismissible(
                key: Key('${tx.id}_${tx.date.millisecondsSinceEpoch}_${tx.category}'),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: index == 0 ? 0 : 4,
                    bottom: index == transactions.length - 1 ? 16 : 4,
                  ),
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.delete, color: Colors.white, size: 28),
                ),
                confirmDismiss: (direction) async {
                  HapticFeedback.mediumImpact();
                  
                  if (isRecurring) {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                        title: Text('Elimina Ricorrente', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                        content: Text('Vuoi eliminare questa transazione ricorrente? Non apparirà più nei report futuri.', style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    ) ?? false;
                  }
                  
                  if (isGoalSaving) {
                    return await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                        title: Text('Elimina Risparmio', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                        content: Text('Eliminando questo risparmio, l\'importo sarà rimosso dall\'obiettivo e tornerà sul saldo netto.', style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Elimina'),
                          ),
                        ],
                      ),
                    ) ?? false;
                  }
                  
                  return await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
                      title: Text('Elimina Transazione', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black87)),
                      content: Text('Sei sicuro di voler eliminare questa transazione?', style: TextStyle(color: isDarkMode ? Colors.grey[300] : Colors.black87)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annulla')),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Elimina', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ) ?? false;
                },
                onDismissed: (direction) async {
                  if (isRecurring) {
                    final recurring = model.recurringTransactions.firstWhere(
                      (r) => r.category == tx.category && r.amount == tx.amount && r.isIncome == tx.isIncome,
                    );
                    if (recurring.id != null) {
                      await model.deleteRecurring(recurring.id!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transazione ricorrente eliminata'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  } else if (isGoalSaving && tx.note != null) {
                    final goalTitle = tx.note!.replaceAll('Aggiunto a obiettivo: ', '');
                    final goal = model.goals.firstWhere((g) => g.title == goalTitle, orElse: () => model.goals.first);
                    
                    if (goal.id != null) {
                      final updatedGoal = goal.copyWith(saved: goal.saved - tx.amount);
                      await model.updateGoal(updatedGoal);
                    }
                    
                    if (tx.id != null) {
                      await model.deleteTransaction(tx.id!);
                    }
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Risparmio eliminato. €${tx.amount.toStringAsFixed(2)} rimossi dall\'obiettivo'), backgroundColor: Colors.orange),
                      );
                    }
                  } else {
                    if (tx.id != null) {
                      await model.deleteTransaction(tx.id!);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transazione eliminata'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
                        );
                      }
                    }
                  }
                },
                child: InkWell(
                  onTap: !isRecurring && !isGoalSaving ? () {
                    _showEditTransactionDialog(tx, model, isDarkMode);
                  } : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: index == 0 ? 0 : 4,
                      bottom: index == transactions.length - 1 ? 16 : 4,
                    ),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850]!.withOpacity(0.5) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isRecurring
                            ? const Color(0xFF6366F1).withOpacity(isDarkMode ? 0.4 : 0.3)
                            : isDarkMode ? Colors.white.withOpacity(0.08) : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (isRecurring)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.repeat, color: Color(0xFF6366F1), size: 16),
                          ),
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [style.color, style.color.withOpacity(0.8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: style.color.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(style.icon, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.category,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tx.note ?? DateFormat('d MMMM yyyy', 'it_IT').format(tx.date),
                                style: TextStyle(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontSize: 13,
                                  letterSpacing: 0.1,
                                ),
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
                                color: tx.isIncome
                                    ? (isDarkMode ? const Color(0xFF34D399) : Colors.green.shade700)
                                    : (isDarkMode ? const Color(0xFFFF6B6B) : Colors.red.shade700),
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('HH:mm', 'it_IT').format(tx.date),
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditTransactionDialog(MoneyTx tx, MoneyModel model, bool isDark) {
    final amountController = TextEditingController(text: tx.amount.toStringAsFixed(2));
    final noteController = TextEditingController(text: tx.note ?? '');
    DateTime selectedDate = tx.date;
    PaymentMethod selectedPayment = tx.payment;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text('Modifica ${tx.category}', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Importo',
                    prefixText: '€ ',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Data: ${DateFormat('d MMMM yyyy', 'it_IT').format(selectedDate)}',
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) {
                      setDialogState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedPayment,
                  decoration: InputDecoration(
                    labelText: 'Metodo di pagamento',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                  dropdownColor: isDark ? Colors.grey[800] : Colors.white,
                  items: PaymentMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.name.toUpperCase(), style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setDialogState(() => selectedPayment = val);
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    labelText: 'Note (opzionale)',
                    labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annulla')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), foregroundColor: Colors.white),
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Inserisci un importo valido'), backgroundColor: Colors.red),
                  );
                  return;
                }
                
                final updated = MoneyTx(
                  id: tx.id,
                  isIncome: tx.isIncome,
                  category: tx.category,
                  amount: amount,
                  date: selectedDate,
                  payment: selectedPayment,
                  note: noteController.text.isEmpty ? null : noteController.text,
                );
                
                await model.updateTransaction(updated);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Transazione aggiornata!'), backgroundColor: Color(0xFF10B981)),
                  );
                }
              },
              child: const Text('Salva'),
            ),
          ],
        ),
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
        return '${DateFormat('d', 'it_IT').format(startOfWeek)} - ${DateFormat('d MMMM', 'it_IT').format(endOfWeek)}';
      case PeriodType.mese:
        return DateFormat('MMMM yyyy', 'it_IT').format(selectedDate);
      case PeriodType.anno:
        return DateFormat('yyyy', 'it_IT').format(selectedDate);
    }
  }

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
