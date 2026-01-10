import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:fl_chart/fl_chart.dart';
import 'package:table_calendar/table_calendar.dart';

import '../providers/wallet_provider.dart';
import '../providers/category_provider.dart';
import '../models/models.dart';
import 'add_tx_page.dart';

// --- LOGICA DI FILTRO GLOBALE ---
List<MoneyTx> filterTransactions(List<MoneyTx> allTxs, ReportType type, DateTime selectedDate) {
  return allTxs.where((tx) {
    switch (type) {
      case ReportType.giorno:
        return isSameDay(tx.date, selectedDate);
      case ReportType.settimana:
        final start = _getStartOfWeek(selectedDate);
        final end = start.add(const Duration(days: 6));
        final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
        final sDate = DateTime(start.year, start.month, start.day);
        final eDate = DateTime(end.year, end.month, end.day);
        return txDate.compareTo(sDate) >= 0 && txDate.compareTo(eDate) <= 0;
      case ReportType.mese:
        return tx.date.year == selectedDate.year && tx.date.month == selectedDate.month;
      case ReportType.anno:
        return tx.date.year == selectedDate.year;
    }
  }).toList();
}

DateTime _getStartOfWeek(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

enum ReportType { giorno, settimana, mese, anno }

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportType _currentType = ReportType.mese;
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.watch<WalletProvider>();

    final transactions = filterTransactions(wallet.transactions, _currentType, _selectedDate);
    final income = transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final expense = transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expense;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(
              'Report Finanziario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
            ),
            const SizedBox(height: 20),
            
            // SELETTORE TIPO (SLIDER)
            _buildTypeSelector(context, isDark),
            
            const SizedBox(height: 16),
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                _showCustomDatePicker(context, isDark);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_month, color: Color(0xFF6366F1), size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _getDateLabel(),
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_drop_down, color: isDark ? Colors.white70 : Colors.black54),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Column(
              children: [
                Text('Saldo Netto', style: TextStyle(fontSize: 14, color: isDark ? Colors.white60 : Colors.grey[600], fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(
                  wallet.format(balance),
                  style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: balance >= 0 ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildClickableSummaryCard(context: context, title: 'Entrate', amount: income, color: const Color(0xFF10B981), icon: Icons.arrow_upward, isDark: isDark, isIncome: true)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildClickableSummaryCard(context: context, title: 'Uscite', amount: expense, color: const Color(0xFFEF4444), icon: Icons.arrow_downward, isDark: isDark, isIncome: false)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    if (income > 0 || expense > 0) ...[
                      Align(alignment: Alignment.centerLeft, child: Text('Panoramica', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
                      const SizedBox(height: 20),
                      SizedBox(height: 250, child: _buildIncomeExpensePieChart(income, expense, isDark)),
                      const SizedBox(height: 40),
                    ] else ...[
                      const SizedBox(height: 40),
                      _buildEmptyChartState(isDark),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SELETTORE TIPO ANIMATO (SLIDER) ---
  Widget _buildTypeSelector(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      height: 50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / 4;
          
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white, width: 1.2),
                ),
                child: Stack(
                  children: [
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: _currentType.index * itemWidth,
                      top: 4,
                      bottom: 4,
                      width: itemWidth,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                      ),
                    ),
                    Row(
                      children: ReportType.values.map((type) {
                        final isSelected = _currentType == type;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() {
                                _currentType = type;
                                _selectedDate = DateTime.now();
                              });
                            },
                            child: Center(
                              child: Text(
                                type.name.capitalize(),
                                style: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  fontSize: 13,
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
            ),
          );
        }
      ),
    );
  }

  Widget _buildIncomeExpensePieChart(double income, double expense, bool isDark) {
    final total = income + expense;
    if (total == 0) return _buildEmptyChartState(isDark);
    final List<PieChartSectionData> sections = [];
    if (income > 0) {
      final percentage = (income / total * 100);
      sections.add(PieChartSectionData(color: const Color(0xFF10B981), value: income, title: '${percentage.toStringAsFixed(0)}%', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), badgeWidget: _buildIconBadge(Icons.arrow_upward, const Color(0xFF10B981)), badgePositionPercentageOffset: .98));
    }
    if (expense > 0) {
      final percentage = (expense / total * 100);
      sections.add(PieChartSectionData(color: const Color(0xFFEF4444), value: expense, title: '${percentage.toStringAsFixed(0)}%', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white), badgeWidget: _buildIconBadge(Icons.arrow_downward, const Color(0xFFEF4444)), badgePositionPercentageOffset: .98));
    }
    return PieChart(PieChartData(sectionsSpace: 4, centerSpaceRadius: 50, sections: sections));
  }

  Widget _buildIconBadge(IconData icon, Color color) {
    return Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]), child: Icon(icon, size: 16, color: color));
  }

  Widget _buildClickableSummaryCard({required BuildContext context, required String title, required double amount, required Color color, required IconData icon, required bool isDark, required bool isIncome}) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); Navigator.push(context, MaterialPageRoute(builder: (context) => ReportCategoryDetailPage(title: title, isIncome: isIncome, currentType: _currentType, selectedDate: _selectedDate, color: color))); },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.white), boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle), child: Icon(icon, color: color, size: 24)),
            const SizedBox(height: 16),
            Text(title, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(NumberFormat.currency(locale: 'it_IT', symbol: '€', decimalDigits: 0).format(amount), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87))),
            const SizedBox(height: 8),
            Row(children: [Text('Vedi dettagli', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)), const SizedBox(width: 4), Icon(Icons.arrow_forward_ios, size: 10, color: color)]),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChartState(bool isDark) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.pie_chart_outline, size: 60, color: isDark ? Colors.white24 : Colors.grey[300]), const SizedBox(height: 16), Text("Nessun dato per questo periodo", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey))]));
  }

  String _getDateLabel() {
    final locale = 'it_IT';
    switch (_currentType) {
      case ReportType.giorno:
        if (isSameDay(_selectedDate, DateTime.now())) return "Oggi";
        return DateFormat('EEE d MMM yyyy', locale).format(_selectedDate);
      case ReportType.settimana:
        final start = _getStartOfWeek(_selectedDate);
        final end = start.add(const Duration(days: 6));
        return "${DateFormat('d MMM', locale).format(start)} - ${DateFormat('d MMM', locale).format(end)}";
      case ReportType.mese:
        return DateFormat('MMMM yyyy', locale).format(_selectedDate).capitalize();
      case ReportType.anno:
        return DateFormat('yyyy').format(_selectedDate);
    }
  }

  void _showCustomDatePicker(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent, isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 500,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B).withOpacity(0.95) : Colors.white.withOpacity(0.95), borderRadius: const BorderRadius.vertical(top: Radius.circular(28)), border: Border.all(color: Colors.white.withOpacity(0.2))),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),
                  Text(_getPickerTitle(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 20),
                  Expanded(child: _buildSpecificPickerContent(ctx, isDark)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getPickerTitle() {
    switch (_currentType) {
      case ReportType.giorno: return "Seleziona Giorno";
      case ReportType.settimana: return "Seleziona Settimana";
      case ReportType.mese: return "Seleziona Mese";
      case ReportType.anno: return "Seleziona Anno";
    }
  }

  Widget _buildSpecificPickerContent(BuildContext ctx, bool isDark) {
    final now = DateTime.now();
    switch (_currentType) {
      case ReportType.giorno:
        return TableCalendar(
          firstDay: DateTime(2020), lastDay: now, focusedDay: _selectedDate.isAfter(now) ? now : _selectedDate, currentDay: now, calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 18, fontWeight: FontWeight.bold), leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black87), rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black87)),
          calendarStyle: CalendarStyle(defaultTextStyle: TextStyle(color: isDark ? Colors.white : Colors.black87), weekendTextStyle: const TextStyle(color: Color(0xFFEF4444)), todayDecoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.3), shape: BoxShape.circle), selectedDecoration: const BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle), disabledTextStyle: const TextStyle(color: Colors.grey)),
          selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
          onDaySelected: (selectedDay, focusedDay) { setState(() { _selectedDate = selectedDay; }); Navigator.pop(ctx); },
        );
      case ReportType.settimana:
        return ListView.builder(
          itemCount: 52 * 5,
          itemBuilder: (context, index) {
            final currentWeekStart = _getStartOfWeek(now);
            final startOfWeek = currentWeekStart.subtract(Duration(days: index * 7));
            final endOfWeek = startOfWeek.add(const Duration(days: 6));
            final isSelected = isSameDay(startOfWeek, _getStartOfWeek(_selectedDate));
            final label = "${DateFormat('d MMM', 'it_IT').format(startOfWeek)} - ${DateFormat('d MMM yyyy', 'it_IT').format(endOfWeek)}";
            return InkWell(onTap: () { setState(() => _selectedDate = startOfWeek); Navigator.pop(ctx); }, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(gradient: isSelected ? const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]) : null, color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 16)), if (isSelected) const Icon(Icons.check_circle, color: Colors.white, size: 20)])));
          },
        );
      case ReportType.mese:
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.8, crossAxisSpacing: 12, mainAxisSpacing: 12),
          itemCount: 36,
          itemBuilder: (context, index) {
            final date = DateTime(now.year, now.month - index, 1);
            final isSelected = date.year == _selectedDate.year && date.month == _selectedDate.month;
            final label = "${DateFormat('MMM', 'it_IT').format(date).toUpperCase()} ${DateFormat('yy').format(date)}";
            return InkWell(onTap: () { setState(() => _selectedDate = date); Navigator.pop(ctx); }, child: Container(decoration: BoxDecoration(color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)))));
          },
        );
      case ReportType.anno:
        return ListView.builder(
          itemCount: 10,
          itemBuilder: (context, index) {
            final year = now.year - index;
            final isSelected = year == _selectedDate.year;
            return InkWell(onTap: () { setState(() => _selectedDate = DateTime(year, 1, 1)); Navigator.pop(ctx); }, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: isSelected ? const Color(0xFF6366F1) : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]), borderRadius: BorderRadius.circular(12)), alignment: Alignment.center, child: Text("$year", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87)))));
          },
        );
    }
  }
}

class ReportCategoryDetailPage extends StatelessWidget {
  final String title;
  final bool isIncome;
  final ReportType currentType;
  final DateTime selectedDate;
  final Color color;

  const ReportCategoryDetailPage({
    super.key,
    required this.title,
    required this.isIncome,
    required this.currentType,
    required this.selectedDate,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new, color: isDark ? Colors.white : Colors.black87), onPressed: () => Navigator.pop(context)),
      ),
      body: Consumer<WalletProvider>(
        builder: (context, wallet, child) {
          final currentTransactions = filterTransactions(wallet.transactions, currentType, selectedDate).where((t) => t.isIncome == isIncome).toList();

          if (currentTransactions.isEmpty) return Center(child: Text("Nessuna transazione", style: TextStyle(color: isDark ? Colors.white54 : Colors.grey)));

          final Map<String, List<MoneyTx>> grouped = {};
          for (var tx in currentTransactions) {
            if (!grouped.containsKey(tx.category)) grouped[tx.category] = [];
            grouped[tx.category]!.add(tx);
          }
          final sortedKeys = grouped.keys.toList()..sort((k1, k2) => grouped[k2]!.fold(0.0, (s, t) => s + t.amount).compareTo(grouped[k1]!.fold(0.0, (s, t) => s + t.amount)));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedKeys.length,
            itemBuilder: (context, index) {
              final category = sortedKeys[index];
              final txs = grouped[category]!;
              final total = txs.fold(0.0, (sum, t) => sum + t.amount);
              final catStyle = context.read<CategoryProvider>().getTransactionStyle(category);

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4))]),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: catStyle.color.withOpacity(0.2), shape: BoxShape.circle), child: Icon(catStyle.icon, color: catStyle.color, size: 24)),
                    title: Text(category, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                    trailing: Text(wallet.format(total), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
                    children: txs.map((tx) => _buildSlideTransactionCard(context, tx, wallet, isDark)).toList(),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSlideTransactionCard(BuildContext context, MoneyTx tx, WalletProvider wallet, bool isDark) {
    return Dismissible(
      key: Key(tx.id.toString()),
      direction: DismissDirection.horizontal,
      background: Container(alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 20), color: Colors.blue, child: const Icon(Icons.edit, color: Colors.white)),
      secondaryBackground: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.symmetric(horizontal: 20), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // 🔥 FIX: Usa il dialog Glass personalizzato
          return await _showGlassConfirmDialog(context, 'Eliminare?', 'Vuoi davvero eliminare questa transazione?', 'Elimina', Colors.red, isDark);
        } else {
          Navigator.push(context, MaterialPageRoute(builder: (context) => AddTxPage(isIncome: tx.isIncome, existingTx: tx)));
          return false;
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart && tx.id != null) {
          wallet.deleteTransaction(tx.id!);
        }
      },
      child: _buildTransactionCard(context, tx, wallet, isDark),
    );
  }

  // 🔥 NUOVO DIALOGO GLASS PER CONFERMA
  Future<bool?> _showGlassConfirmDialog(BuildContext context, String title, String content, String confirmText, Color confirmColor, bool isDark) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
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
                Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text(content, style: TextStyle(fontSize: 16, color: isDark ? Colors.white70 : Colors.black54), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, false),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(16)), child: Text('Annulla', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold))),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => Navigator.pop(ctx, true),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: confirmColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: confirmColor.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))]), child: Text(confirmText, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, MoneyTx tx, WalletProvider wallet, bool isDark) {
    final style = context.read<CategoryProvider>().getTransactionStyle(tx.category);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200, width: 1)),
      child: Row(
        children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(gradient: LinearGradient(colors: [style.color, style.color.withOpacity(0.7)]), borderRadius: BorderRadius.circular(12)), child: Icon(style.icon, color: Colors.white, size: 24)),
          const SizedBox(width: 12),
          Expanded(
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // ✅ MODIFICA QUI
      Row(
        children: [
          Flexible( // Usa Flexible per evitare overflow se il testo è lungo
            child: Text(
              tx.note != null && tx.note!.isNotEmpty ? tx.note! : tx.category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
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
        DateFormat('d MMM yyyy - HH:mm', 'it_IT').format(tx.date),
        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey[600]),
      ),
    ],
  ),
),
          Text('${tx.isIncome ? '+' : '-'} ${wallet.format(tx.amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tx.isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444), fontSize: 14)),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
